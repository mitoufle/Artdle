extends Button
class_name UpgradeButton

## Bouton d'upgrade standardisé
## Gère l'affichage du coût et la validation des fonds

#==============================================================================
# Exports
#==============================================================================
@export var upgrade_type: String  # Type d'upgrade (click_power, fill_speed, etc.)
@export var currency_type: String = "gold"  # Type de devise requise
@export var cost_label: Label  # Label pour afficher le coût
@export var show_cost: bool = true

#==============================================================================
# State
#==============================================================================
var current_cost: float = 0.0
var is_upgrade_available: bool = false

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_connect_signals()
	_update_button_state()

#==============================================================================
# Initialization
#==============================================================================
func _connect_signals() -> void:
	# Connect to currency changes
	match currency_type:
		"inspiration":
			GameState.inspiration_changed.connect(_on_currency_changed)
		"gold":
			GameState.gold_changed.connect(_on_currency_changed)
		"fame":
			GameState.fame_changed.connect(_on_currency_changed)
		_:
			GameState.logger.error("Unknown currency type for upgrade button: %s" % currency_type, "UpgradeButton")
	
	# Connect button press
	pressed.connect(_on_button_pressed)

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_currency_changed(_value: float) -> void:
	_update_button_state()

func _on_button_pressed() -> void:
	_attempt_upgrade()

#==============================================================================
# Upgrade Logic
#==============================================================================
func _attempt_upgrade() -> void:
	var success = false
	
	match upgrade_type:
		"click_power":
			success = GameState.clicker_manager.upgrade_click_power()
		"autoclick_speed":
			success = GameState.clicker_manager.upgrade_autoclick_speed()
		"canvas_resolution":
			success = GameState.canvas_manager.upgrade_resolution()
		"canvas_fill_speed":
			success = GameState.canvas_manager.upgrade_fill_speed()
		"canvas_storage":
			success = GameState.canvas_manager.upgrade_canvas_storage()
		_:
			GameState.logger.error("Unknown upgrade type: %s" % upgrade_type, "UpgradeButton")
			return
	
	if success:
		GameState.logger.info("Upgrade successful: %s" % upgrade_type, "UpgradeButton")
		_update_button_state()
	else:
		GameState.logger.warning("Upgrade failed - insufficient funds: %s" % upgrade_type, "UpgradeButton")

#==============================================================================
# UI Updates
#==============================================================================
func _update_button_state() -> void:
	# Check if upgrade is available
	var currency_amount = GameState.currency_manager.get_currency(currency_type)
	is_upgrade_available = currency_amount >= current_cost
	
	# Update button state
	disabled = not is_upgrade_available
	
	# Update cost label
	if cost_label and show_cost:
		cost_label.text = "Cost: %s" % _format_cost(current_cost)
	
	# Update button text color based on availability
	if is_upgrade_available:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 1.0)

#==============================================================================
# Public API
#==============================================================================
## Définit le coût de l'upgrade
func set_upgrade_cost(cost: float) -> void:
	current_cost = cost
	_update_button_state()

## Met à jour l'état du bouton
func refresh_button_state() -> void:
	_update_button_state()

## Récupère le coût actuel
func get_upgrade_cost() -> float:
	return current_cost

## Vérifie si l'upgrade est disponible
func is_available() -> bool:
	return is_upgrade_available

#==============================================================================
# Private Methods
#==============================================================================
func _format_cost(cost: float) -> String:
	if cost >= 1000000:
		return "%.1fM" % (cost / 1000000.0)
	elif cost >= 1000:
		return "%.1fK" % (cost / 1000.0)
	else:
		return "%.0f" % cost
