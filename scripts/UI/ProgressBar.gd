extends ProgressBar
class_name GameProgressBar

## Barre de progression standardisée
## Gère l'affichage des barres de progression avec des fonctionnalités avancées

#==============================================================================
# Exports
#==============================================================================
@export var progress_type: String  # Type de progression (canvas, experience, etc.)
@export var show_percentage: bool = true
@export var show_fraction: bool = false
@export var percentage_label: Label  # Label pour afficher le pourcentage
@export var fraction_label: Label  # Label pour afficher la fraction
@export var animation_duration: float = 0.3  # Durée de l'animation de progression

#==============================================================================
# State
#==============================================================================
var current_value: float = 0.0
var max_value: float = 100.0
var target_value: float = 0.0
var is_animating: bool = false

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_connect_signals()
	_initialize_progress_bar()

#==============================================================================
# Initialization
#==============================================================================
func _connect_signals() -> void:
	match progress_type:
		"canvas":
			GameState.canvas_progress_updated.connect(_on_canvas_progress_updated)
		"experience":
			GameState.experience_changed.connect(_on_experience_changed)
		_:
			GameState.logger.error("Unknown progress type: %s" % progress_type, "GameProgressBar")

func _initialize_progress_bar() -> void:
	# Set initial values
	max_value = 100.0
	current_value = 0.0
	value = 0.0
	
	# Update labels
	_update_labels()
	
	GameState.logger.debug("GameProgressBar initialized for type: %s" % progress_type, "GameProgressBar")

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_canvas_progress_updated(current_pixels: int, max_pixels: int) -> void:
	set_progress_values(float(current_pixels), float(max_pixels))

func _on_experience_changed(experience: float, experience_to_next: float) -> void:
	set_progress_values(experience, experience_to_next)

#==============================================================================
# Progress Management
#==============================================================================
func set_progress_values(current: float, maximum: float) -> void:
	current_value = current
	max_value = maximum
	target_value = current
	
	# Update progress bar
	max_value = maximum
	value = current
	
	# Animate if needed
	if animation_duration > 0:
		_animate_to_value(current)
	else:
		value = current
	
	_update_labels()

func set_progress_percentage(percentage: float) -> void:
	percentage = clamp(percentage, 0.0, 1.0)
	target_value = percentage * max_value
	set_progress_values(target_value, max_value)

func _animate_to_value(target: float) -> void:
	if is_animating:
		return
	
	is_animating = true
	var tween = create_tween()
	tween.tween_method(_update_progress_value, value, target, animation_duration)
	tween.finished.connect(_on_animation_finished)

func _update_progress_value(new_value: float) -> void:
	value = new_value
	_update_labels()

func _on_animation_finished() -> void:
	is_animating = false

#==============================================================================
# Label Updates
#==============================================================================
func _update_labels() -> void:
	if not is_inside_tree():
		return
	
	# Update percentage label
	if percentage_label and show_percentage:
		var percentage = (value / max_value) * 100.0 if max_value > 0 else 0.0
		percentage_label.text = "%.1f%%" % percentage
	
	# Update fraction label
	if fraction_label and show_fraction:
		fraction_label.text = "%.0f / %.0f" % [value, max_value]

#==============================================================================
# Public API
#==============================================================================
## Met à jour manuellement la progression
func refresh_progress() -> void:
	_update_labels()

## Définit la durée d'animation
func set_animation_duration(duration: float) -> void:
	animation_duration = duration

## Récupère la valeur actuelle
func get_current_value() -> float:
	return value

## Récupère la valeur maximale
func get_max_value() -> float:
	return max_value

## Récupère le pourcentage de progression
func get_progress_percentage() -> float:
	return (value / max_value) * 100.0 if max_value > 0 else 0.0

## Vérifie si la barre est pleine
func is_full() -> bool:
	return value >= max_value

## Vérifie si la barre est vide
func is_empty() -> bool:
	return value <= 0.0
