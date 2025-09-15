extends BaseView
class_name AccueilView

## Vue d'accueil principale - Interface de clic et d'upgrades
## Gère l'interaction de base du joueur avec le jeu

#==============================================================================
# Exports
#==============================================================================
@export var inspiration_spritesheet: Texture2D

#==============================================================================
# Constants
#==============================================================================
const FLOATING_TEXT_SCENE = preload("res://Scenes/floating_text.tscn")
const DEBUG_CURRENCY_AMOUNT = 100000000
const DEBUG_LEVEL_AMOUNT = 10

#==============================================================================
# Scene References
#==============================================================================
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var click_power_label: Label = $Layout/ClickPowerLabel
@onready var autoclick_speed_label: Label = $Layout/AutoclickSpeedLabel
@onready var click_button: TextureButton = $ClickButton
@onready var new_game_button: Button = $Layout/NewGameButton
@onready var upgrade_click_power_button: UpgradeButton = $Layout/UpgradeClickPowerButton
@onready var upgrade_autoclick_speed_button: UpgradeButton = $Layout/UpgradeAutoclickSpeedButton
@onready var btn_debug: Button = $debug

#==============================================================================
# Click and Hold Variables
#==============================================================================
var is_holding: bool = false
var hold_timer: Timer
var base_click_interval: float = 0.1  # Base click interval (slowest speed)

# UI Components (utilise les boutons existants de la scène)
#==============================================================================

#==============================================================================
# BaseView Overrides
#==============================================================================
func _initialize_view() -> void:
	# Initialization specific to AccueilView
	_setup_unified_ui()
	_setup_hold_timer()

func _connect_view_signals() -> void:
	# Connect to GameState signals
	GameState.click_stats_changed.connect(_on_click_stats_changed)
	
	# Connect UI signals
	if not click_button.pressed.is_connected(_on_click_button_pressed):
		click_button.pressed.connect(_on_click_button_pressed)
	if not click_button.button_down.is_connected(_on_click_button_down):
		click_button.button_down.connect(_on_click_button_down)
	if not click_button.button_up.is_connected(_on_click_button_up):
		click_button.button_up.connect(_on_click_button_up)
	if not new_game_button.pressed.is_connected(_on_new_game_pressed):
		new_game_button.pressed.connect(_on_new_game_pressed)
	if not upgrade_click_power_button.upgrade_purchased.is_connected(_on_upgrade_click_power_purchased):
		upgrade_click_power_button.upgrade_purchased.connect(_on_upgrade_click_power_purchased)
	if not upgrade_autoclick_speed_button.upgrade_purchased.is_connected(_on_upgrade_autoclick_speed_purchased):
		upgrade_autoclick_speed_button.upgrade_purchased.connect(_on_upgrade_autoclick_speed_purchased)
	if not btn_debug.pressed.is_connected(_on_debug_pressed):
		btn_debug.pressed.connect(_on_debug_pressed)

func _initialize_ui() -> void:
	# Initial UI state
	var initial_stats = GameState.clicker_manager.get_click_stats()
	_on_click_stats_changed(initial_stats)
	_update_unified_ui()

#==============================================================================
# Unified UI System
#==============================================================================

func _setup_unified_ui():
	# Configurer les boutons d'upgrade
	_setup_upgrade_buttons()

func _setup_hold_timer():
	# Create timer for rapid clicking when holding
	hold_timer = Timer.new()
	hold_timer.wait_time = _get_current_click_interval()
	hold_timer.one_shot = false
	hold_timer.timeout.connect(_on_hold_timer_timeout)
	add_child(hold_timer)

func _setup_upgrade_buttons():
	# Configurer le bouton de click power
	var click_level = GameState.clicker_manager.click_power
	var click_prices = _get_click_power_prices(click_level)
	upgrade_click_power_button.update_upgrade_data(click_level, click_prices)
	
	# Configurer le bouton d'autoclick
	var autoclick_level = GameState.clicker_manager.autoclick_speed
	var autoclick_prices = _get_autoclick_prices(autoclick_level)
	upgrade_autoclick_speed_button.update_upgrade_data(autoclick_level, autoclick_prices)


func _update_unified_ui():
	_update_click_power_display()
	_update_autoclick_display()

func _update_click_power_display():
	if not GameState or not GameState.clicker_manager:
		return
	
	# Mettre à jour le bouton d'upgrade
	var level = GameState.clicker_manager.click_power
	var prices = _get_click_power_prices(level)
	upgrade_click_power_button.update_upgrade_data(level, prices)

func _update_autoclick_display():
	if not GameState or not GameState.clicker_manager:
		return
	
	# Mettre à jour le bouton d'upgrade
	var level = GameState.clicker_manager.autoclick_speed
	var prices = _get_autoclick_prices(level)
	upgrade_autoclick_speed_button.update_upgrade_data(level, prices)

func _get_click_power_prices(level: int) -> Dictionary:
	# Utiliser la même logique que ClickerManager
	var base_cost = GameConfig.CLICK_POWER_UPGRADE_COST
	var cost = int(base_cost * pow(1.5, level))  # Multiplicateur standard
	# Prevent negative prices due to integer overflow
	cost = max(cost, 1)
	return {"gold": cost}

func _get_autoclick_prices(level: int) -> Dictionary:
	# Utiliser la même logique que ClickerManager
	var base_cost = GameConfig.AUTOCLICK_SPEED_UPGRADE_COST
	var cost = int(base_cost * pow(1.5, level))  # Multiplicateur standard
	# Prevent negative prices due to integer overflow
	cost = max(cost, 1)
	return {"gold": cost}

func _get_current_click_interval() -> float:
	# Calculate click interval based on autoclick speed level using logarithmic progression
	var speed_level = GameState.clicker_manager.autoclick_speed
	
	# Logarithmic progression: each level adds less speed benefit
	# Level 20 should reach ~100 clicks per second (0.01s interval)
	var max_speed_level = 20.0  # Level where we reach max engine speed
	var max_clicks_per_second = 100.0  # Maximum clicks per second (engine limit)
	var min_interval = 1.0 / max_clicks_per_second  # 0.01 seconds
	
	if speed_level <= max_speed_level:
		# Logarithmic progression from base speed to max speed
		var progress = speed_level / max_speed_level
		var log_progress = log(1.0 + progress * 9.0) / log(10.0)  # log(1 + 9*progress) / log(10)
		var current_interval = base_click_interval - (base_click_interval - min_interval) * log_progress
		return max(current_interval, min_interval)
	else:
		# Beyond level 20, we're at max speed
		return min_interval

func get_class_name() -> String:
	return "AccueilView"

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_click_stats_changed(new_stats: Dictionary) -> void:
	# Mettre à jour les labels existants (pour compatibilité)
	click_power_label.text = "Click Power: %d" % new_stats["click_power"]
	autoclick_speed_label.text = "Autoclick Speed: %.1f" % new_stats["autoclick_speed"]
	
	# Mettre à jour l'UI unifiée
	_update_unified_ui()

func _on_click_button_pressed() -> void:
	# This handles single clicks
	_perform_click()

func _on_click_button_down() -> void:
	# Start holding - begin rapid clicking
	is_holding = true
	_update_timer_speed()
	hold_timer.start()

func _on_click_button_up() -> void:
	# Stop holding - stop rapid clicking
	is_holding = false
	hold_timer.stop()

func _on_hold_timer_timeout() -> void:
	# This fires every click_interval when holding
	if is_holding:
		_perform_click()

func _perform_click() -> void:
	# The actual click logic (shared between single click and hold)
	var result = GameState.clicker_manager.manual_click()
	
	# Apply speed bonus if we're beyond max speed level
	var speed_level = GameState.clicker_manager.autoclick_speed
	var max_speed_level = 20.0
	
	if speed_level > max_speed_level:
		# Calculate bonus multiplier using logarithmic progression
		var bonus_levels = speed_level - max_speed_level
		var bonus_multiplier = 1.0 + log(bonus_levels + 1.0)  # log(x+1) as requested
		
		# Apply bonus to inspiration gained
		result.inspiration_gained = int(result.inspiration_gained * bonus_multiplier)
	
	click_sound.play(0.3)
	_show_feedback(result.inspiration_gained, inspiration_spritesheet, 12, 1, "inspiration_rotate")

func _update_timer_speed() -> void:
	# Update the timer interval based on current speed level
	var new_interval = _get_current_click_interval()
	hold_timer.wait_time = new_interval

func _on_upgrade_click_power_purchased(upgrade_type: String, level: int) -> void:
	var current_prices = _get_click_power_prices(level)
	var cost = current_prices.get("gold", 0)
	var success = GameState.clicker_manager.upgrade_click_power(cost)
	if not success:
		GameState.logger.warning("Failed to upgrade click power - insufficient funds", "AccueilView")
	else:
		# Mettre à jour l'affichage du bouton
		var new_level = GameState.clicker_manager.click_power
		var new_prices = _get_click_power_prices(new_level)
		upgrade_click_power_button.update_upgrade_data(new_level, new_prices)

func _on_upgrade_autoclick_speed_purchased(upgrade_type: String, level: int) -> void:
	var current_prices = _get_autoclick_prices(level)
	var cost = current_prices.get("gold", 0)
	var success = GameState.clicker_manager.upgrade_autoclick_speed(cost)
	if not success:
		GameState.logger.warning("Failed to upgrade autoclick speed - insufficient funds", "AccueilView")
	else:
		# Mettre à jour l'affichage du bouton
		var new_level = GameState.clicker_manager.autoclick_speed
		var new_prices = _get_autoclick_prices(new_level)
		upgrade_autoclick_speed_button.update_upgrade_data(new_level, new_prices)
		
		# Update the hold click speed
		_update_timer_speed()


func _on_new_game_pressed() -> void:
	# Demander confirmation avant de réinitialiser
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Are you sure you want to start a new game? This will reset all your progress!"
	confirmation_dialog.get_ok_button().text = "Yes, Start New Game"
	confirmation_dialog.get_cancel_button().text = "Cancel"
	
	# Ajouter le dialogue à la scène
	get_tree().current_scene.add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
	
	# Connecter les signaux
	confirmation_dialog.confirmed.connect(_confirm_new_game)
	confirmation_dialog.canceled.connect(_cancel_new_game)

func _confirm_new_game() -> void:
	# Réinitialiser le jeu
	var success = GameState.save_manager.reset_game()
	
	if success:
		GameState.feedback_manager.show_feedback("New game started!", Color.GREEN)
		GameState.logger.info("New game started successfully", "AccueilView")
		
		# Mettre à jour l'UI
		_on_click_stats_changed(GameState.clicker_manager.get_click_stats())
	else:
		GameState.feedback_manager.show_feedback("Failed to start new game", Color.RED)
		GameState.logger.error("Failed to start new game", "AccueilView")

func _cancel_new_game() -> void:
	GameState.logger.info("New game cancelled by user", "AccueilView")

func _on_debug_pressed() -> void:
	GameState.currency_manager.set_currency("inspiration", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("gold", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("fame", DEBUG_CURRENCY_AMOUNT)
	GameState.experience_manager.set_level_direct(DEBUG_LEVEL_AMOUNT)
	GameState.logger.info("Debug mode activated - currencies and level set", "AccueilView")

#==============================================================================
# Feedback System
#==============================================================================
func _show_feedback(amount: float, icon: Texture2D, hframes: int, vframes: int, animation_name: String) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	add_child(ft)
	ft.start("+%.0f" % amount, icon, hframes, vframes, animation_name, Color(1,1,0), amount)

func _show_devotion_feedback(amount: float) -> void:
	# Show floating text for devotion procs centered on click button
	var ft = FLOATING_TEXT_SCENE.instantiate()
	add_child(ft)
	
	# Position the floating text at the center of the click button
	var button_center = click_button.get_global_rect().position + click_button.get_global_rect().size / 2
	ft.global_position = button_center
	
	# Use inspiration icon and animation
	ft.start("+%.0f" % amount, inspiration_spritesheet, 12, 1, "inspiration_rotate", Color(1,1,0), amount)
