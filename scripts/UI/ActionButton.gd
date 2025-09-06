extends Button
class_name ActionButton

## Bouton d'action standardisé
## Gère les boutons d'action avec validation et feedback

#==============================================================================
# Exports
#==============================================================================
@export var action_type: String  # Type d'action (sell, ascend, click, etc.)
@export var currency_type: String = ""  # Type de devise requise (optionnel)
@export var required_amount: float = 0.0  # Montant requis (optionnel)
@export var show_cost: bool = true
@export var cost_label: Label  # Label pour afficher le coût
@export var feedback_enabled: bool = true
@export var feedback_icon: Texture2D
@export var feedback_color: Color = Color(1, 1, 0, 1)

#==============================================================================
# State
#==============================================================================
var is_action_available: bool = false
var current_cost: float = 0.0

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_connect_signals()
	_initialize_button()
	_update_button_state()

#==============================================================================
# Initialization
#==============================================================================
func _connect_signals() -> void:
	# Connect to relevant signals based on action type
	match action_type:
		"sell_canvas":
			GameState.canvas_completed.connect(_on_canvas_state_changed)
			GameState.canvas_storage_changed.connect(_on_canvas_state_changed)
		"ascend":
			GameState.fame_changed.connect(_on_currency_changed)
		"click":
			# No specific signals needed for click
			pass
		_:
			GameState.logger.warning("Unknown action type: %s" % action_type, "ActionButton")
	
	# Connect currency signals if needed
	if not currency_type.is_empty():
		match currency_type:
			"inspiration":
				GameState.inspiration_changed.connect(_on_currency_changed)
			"gold":
				GameState.gold_changed.connect(_on_currency_changed)
			"fame":
				GameState.fame_changed.connect(_on_currency_changed)
			_:
				GameState.logger.error("Unknown currency type: %s" % currency_type, "ActionButton")
	
	# Connect button press
	pressed.connect(_on_button_pressed)

func _initialize_button() -> void:
	# Set initial cost
	current_cost = required_amount
	
	GameState.logger.debug("ActionButton initialized for action: %s" % action_type, "ActionButton")

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_currency_changed(_value: float) -> void:
	_update_button_state()

func _on_canvas_state_changed(_value = null) -> void:
	_update_button_state()

func _on_button_pressed() -> void:
	_execute_action()

#==============================================================================
# Action Execution
#==============================================================================
func _execute_action() -> void:
	var success = false
	
	match action_type:
		"sell_canvas":
			success = _execute_sell_canvas()
		"ascend":
			success = _execute_ascend()
		"click":
			success = _execute_click()
		_:
			GameState.logger.error("Unknown action type: %s" % action_type, "ActionButton")
			return
	
	if success:
		GameState.logger.info("Action executed successfully: %s" % action_type, "ActionButton")
		_show_feedback()
		_update_button_state()
	else:
		GameState.logger.warning("Action failed: %s" % action_type, "ActionButton")

func _execute_sell_canvas() -> bool:
	GameState.sell_canvas()
	return true  # sell_canvas always succeeds

func _execute_ascend() -> bool:
	return GameState.ascension_manager.ascend()

func _execute_click() -> bool:
	GameState.clicker_manager.manual_click()
	return true  # click always succeeds

#==============================================================================
# UI Updates
#==============================================================================
func _update_button_state() -> void:
	# Check if action is available
	is_action_available = _check_action_availability()
	
	# Update button state
	disabled = not is_action_available
	
	# Update cost label
	if cost_label and show_cost and current_cost > 0:
		cost_label.text = "Cost: %s" % _format_cost(current_cost)
	
	# Update button appearance
	if is_action_available:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 1.0)

func _check_action_availability() -> bool:
	match action_type:
		"sell_canvas":
			return GameState.canvas_manager.stored_canvases > 0 or GameState.canvas_manager.current_pixel_count >= GameState.canvas_manager.max_pixels
		"ascend":
			return GameState.ascension_manager.can_ascend()
		"click":
			return true  # Click is always available
		_:
			return false

#==============================================================================
# Feedback
#==============================================================================
func _show_feedback() -> void:
	if not feedback_enabled or not feedback_icon:
		return
	
	# Get feedback amount based on action type
	var feedback_amount = _get_feedback_amount()
	
	# Show feedback using BaseView method if available
	var parent_view = get_parent()
	while parent_view and not parent_view.has_method("show_feedback"):
		parent_view = parent_view.get_parent()
	
	if parent_view and parent_view.has_method("show_feedback"):
		parent_view.show_feedback(feedback_amount, feedback_icon, 12, 1, "rotate", feedback_color)
	else:
		# Fallback: create feedback directly
		const FLOATING_TEXT_SCENE = preload("res://Scenes/floating_text.tscn")
		var ft = FLOATING_TEXT_SCENE.instantiate()
		get_tree().current_scene.add_child(ft)
		ft.start("+%d" % feedback_amount, feedback_icon, 12, 1, "rotate", feedback_color)

func _get_feedback_amount() -> int:
	match action_type:
		"sell_canvas":
			return GameState.canvas_manager.sell_price
		"ascend":
			return 1  # Ascendancy point
		"click":
			return GameState.clicker_manager.click_power
		_:
			return 1

#==============================================================================
# Public API
#==============================================================================
## Force la mise à jour de l'état du bouton
func refresh_button_state() -> void:
	_update_button_state()

## Vérifie si l'action est disponible
func is_action_available() -> bool:
	return is_action_available

## Définit le coût de l'action
func set_action_cost(cost: float) -> void:
	current_cost = cost
	_update_button_state()

## Récupère le coût actuel
func get_action_cost() -> float:
	return current_cost

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
