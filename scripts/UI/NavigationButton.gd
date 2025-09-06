extends Button
class_name NavigationButton

## Bouton de navigation standardisé
## Gère la navigation entre les vues avec validation des niveaux

#==============================================================================
# Exports
#==============================================================================
@export var target_view: String  # Vue cible (AccueilView, PaintingView, etc.)
@export var required_level: int = 1  # Niveau requis pour débloquer
@export var unlock_message: String = "Reach level %d to unlock this view"  # Message de déblocage
@export var show_tooltip: bool = true
@export var tooltip_text: String = ""

#==============================================================================
# State
#==============================================================================
var is_unlocked: bool = false
var current_level: int = 1

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
	# Connect to level changes
	GameState.level_changed.connect(_on_level_changed)
	
	# Connect button press
	pressed.connect(_on_button_pressed)
	
	# Connect mouse events for tooltip
	if show_tooltip:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _initialize_button() -> void:
	# Set initial state
	current_level = GameState.experience_manager.get_level()
	is_unlocked = current_level >= required_level
	
	# Set tooltip text if not provided
	if tooltip_text.is_empty():
		tooltip_text = "Navigate to %s" % target_view
	
	GameState.logger.debug("NavigationButton initialized for view: %s" % target_view, "NavigationButton")

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_level_changed(new_level: int) -> void:
	current_level = new_level
	_update_button_state()

func _on_button_pressed() -> void:
	if is_unlocked:
		_navigate_to_view()
	else:
		_show_unlock_message()

func _on_mouse_entered() -> void:
	if not is_unlocked and show_tooltip:
		_show_unlock_tooltip()

func _on_mouse_exited() -> void:
	_hide_tooltip()

#==============================================================================
# Navigation Logic
#==============================================================================
func _navigate_to_view() -> void:
	GameState.logger.info("Navigating to view: %s" % target_view, "NavigationButton")
	SceneManager.load_game_scene("res://views/%s.tscn" % target_view)

func _show_unlock_message() -> void:
	var message = unlock_message % required_level
	GameState.logger.info("View locked: %s" % message, "NavigationButton")
	
	# TODO: Afficher un popup ou message à l'utilisateur
	# Pour l'instant, on log juste le message

func _show_unlock_tooltip() -> void:
	# TODO: Implémenter l'affichage d'un tooltip
	# Pour l'instant, on log juste le message
	GameState.logger.debug("Showing unlock tooltip: %s" % (unlock_message % required_level), "NavigationButton")

func _hide_tooltip() -> void:
	# TODO: Masquer le tooltip
	pass

#==============================================================================
# UI Updates
#==============================================================================
func _update_button_state() -> void:
	is_unlocked = current_level >= required_level
	
	# Update button appearance
	disabled = not is_unlocked
	
	if is_unlocked:
		modulate = Color.WHITE
		tooltip_text = "Navigate to %s" % target_view
	else:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
		tooltip_text = unlock_message % required_level

#==============================================================================
# Public API
#==============================================================================
## Force la mise à jour de l'état du bouton
func refresh_button_state() -> void:
	_update_button_state()

## Vérifie si la vue est débloquée
func is_view_unlocked() -> bool:
	return is_unlocked

## Récupère le niveau requis
func get_required_level() -> int:
	return required_level

## Récupère le niveau actuel
func get_current_level() -> int:
	return current_level

## Définit le niveau requis
func set_required_level(level: int) -> void:
	required_level = level
	_update_button_state()

## Définit le message de déblocage
func set_unlock_message(message: String) -> void:
	unlock_message = message
	_update_button_state()
