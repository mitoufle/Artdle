extends Control
class_name LevelDisplay

## Affichage unifié des niveaux courants
## S'adapte automatiquement aux différents types de features

#==============================================================================
# Properties
#==============================================================================
@export var feature_name: String = ""
@export var level_prefix: String = "Level"
@export var show_progress: bool = false
@export var show_percentage: bool = false

#==============================================================================
# UI References
#==============================================================================
var level_label: Label
var progress_bar: ProgressBar
var progress_label: Label

#==============================================================================
# Data
#==============================================================================
var current_level: int = 0
var current_progress: Dictionary = {}

#==============================================================================
# Lifecycle
#==============================================================================

func _ready():
	_setup_ui()
	_update_display()

func _setup_ui():
	# Container principal
	var container = VBoxContainer.new()
	add_child(container)
	
	# Label du niveau
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(level_label)
	
	# Barre de progression (optionnelle)
	if show_progress:
		progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(120, 8)
		container.add_child(progress_bar)
		
		# Label de progression (optionnel)
		if show_percentage:
			progress_label = Label.new()
			progress_label.add_theme_font_size_override("font_size", 12)
			progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(progress_label)

#==============================================================================
# Public API
#==============================================================================

## Met à jour les données de niveau
func update_level_data(level: int, progress: Dictionary = {}):
	current_level = level
	current_progress = progress
	_update_display()

## Met à jour l'affichage
func _update_display():
	_update_level_text()
	_update_progress_display()

## Met à jour le texte du niveau
func _update_level_text():
	if not level_label:
		return
	
	var level_text = UIDisplayFormatter.format_level(current_level, level_prefix)
	if feature_name != "":
		level_text = "%s: %s" % [feature_name, level_text]
	
	level_label.text = level_text

## Met à jour l'affichage de la progression
func _update_progress_display():
	if not show_progress or not progress_bar:
		return
	
	if current_progress.has("current") and current_progress.has("max"):
		progress_bar.min_value = 0
		progress_bar.max_value = current_progress["max"]
		progress_bar.value = current_progress["current"]
		
		# Mettre à jour le label de pourcentage
		if show_percentage and progress_label:
			var percentage = (current_progress["current"] / current_progress["max"]) * 100 if current_progress["max"] > 0 else 0
			progress_label.text = "%.0f%%" % percentage

#==============================================================================
# Static Helpers
#==============================================================================

## Crée un affichage de niveau simple
static func create_simple_level_display(feature_name: String, level: int, prefix: String = "Level") -> LevelDisplay:
	var display = LevelDisplay.new()
	display.feature_name = feature_name
	display.level_prefix = prefix
	display.update_level_data(level)
	return display

## Crée un affichage de niveau avec progression
static func create_progress_level_display(feature_name: String, level: int, current: float, max: float, prefix: String = "Level") -> LevelDisplay:
	var display = LevelDisplay.new()
	display.feature_name = feature_name
	display.level_prefix = prefix
	display.show_progress = true
	display.show_percentage = true
	display.update_level_data(level, {"current": current, "max": max})
	return display
