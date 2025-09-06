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
@onready var upgrade_click_power_button: Button = $Layout/UpgradeClickPowerButton
@onready var upgrade_autoclick_speed_button: Button = $Layout/UpgradeAutoclickSpeedButton
@onready var btn_debug: Button = $debug

#==============================================================================
# BaseView Overrides
#==============================================================================
func _initialize_view() -> void:
	# Initialization specific to AccueilView
	pass

func _connect_view_signals() -> void:
	# Connect to GameState signals
	GameState.click_stats_changed.connect(_on_click_stats_changed)
	
	# Connect UI signals
	if not click_button.pressed.is_connected(_on_click_button_pressed):
		click_button.pressed.connect(_on_click_button_pressed)
	if not upgrade_click_power_button.pressed.is_connected(_on_upgrade_click_power_pressed):
		upgrade_click_power_button.pressed.connect(_on_upgrade_click_power_pressed)
	if not upgrade_autoclick_speed_button.pressed.is_connected(_on_upgrade_autoclick_speed_pressed):
		upgrade_autoclick_speed_button.pressed.connect(_on_upgrade_autoclick_speed_pressed)
	if not btn_debug.pressed.is_connected(_on_debug_pressed):
		btn_debug.pressed.connect(_on_debug_pressed)

func _initialize_ui() -> void:
	# Initial UI state
	var initial_stats = GameState.clicker_manager.get_click_stats()
	_on_click_stats_changed(initial_stats)

func get_class_name() -> String:
	return "AccueilView"

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_click_stats_changed(new_stats: Dictionary) -> void:
	click_power_label.text = "Click Power: %d" % new_stats["click_power"]
	autoclick_speed_label.text = "Autoclick Speed: %.1f" % new_stats["autoclick_speed"]

func _on_click_button_pressed() -> void:
	var result = GameState.clicker_manager.manual_click()
	click_sound.play(0.3)
	_show_feedback(result.inspiration_gained, inspiration_spritesheet, 12, 1, "inspiration_rotate")

func _on_upgrade_click_power_pressed() -> void:
	var success = GameState.clicker_manager.upgrade_click_power()
	if not success:
		GameState.logger.warning("Failed to upgrade click power - insufficient funds", "AccueilView")

func _on_upgrade_autoclick_speed_pressed() -> void:
	var success = GameState.clicker_manager.upgrade_autoclick_speed()
	if not success:
		GameState.logger.warning("Failed to upgrade autoclick speed - insufficient funds", "AccueilView")

func _on_debug_pressed() -> void:
	GameState.currency_manager.set_currency("inspiration", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("gold", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("fame", DEBUG_CURRENCY_AMOUNT)
	GameState.experience_manager.set_level_direct(DEBUG_LEVEL_AMOUNT)
	GameState.logger.info("Debug mode activated - currencies and level set", "AccueilView")

#==============================================================================
# Feedback System
#==============================================================================
func _show_feedback(amount: int, icon: Texture2D, hframes: int, vframes: int, animation_name: String) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	add_child(ft)
	ft.start("+%d" % amount, icon, hframes, vframes, animation_name, Color(1,1,0))
