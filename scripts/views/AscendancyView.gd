extends BaseView
class_name AscendancyView

## Vue d'ascendance - Système de prestige et d'ascension
## Gère l'interface d'ascension et l'accès à l'arbre de compétences

#==============================================================================
# Constants
#==============================================================================
const SKILL_TREE_SCENE_PATH = "res://views/SkillTreeView.tscn"

#==============================================================================
# UI References
#==============================================================================
@onready var ascendency2d_view_instance = $Ascendency2DView
@onready var ascendancy_points_label: Label = $AscendancyPointsLabel
@onready var ascend_cost_label: Label = $AscendCostLabel
@onready var ascend_button: TextureButton = $AscendButton
@onready var skill_tree_button: TextureButton = $SkillTreeButton

#==============================================================================
# BaseView Overrides
#==============================================================================
func _initialize_view() -> void:
	# Initialization specific to AscendancyView
	pass

func _connect_view_signals() -> void:
	# Connect to GameState signals
	GameState.fame_changed.connect(_on_currency_changed)
	GameState.ascendancy_point_changed.connect(_on_currency_changed)
	GameState.ascended.connect(_on_ascended)
	
	# Connect UI signals
	ascend_button.pressed.connect(_on_ascend_button_pressed)
	
	if skill_tree_button:
		skill_tree_button.pressed.connect(_on_skill_tree_button_pressed)
		GameState.logger.debug("Skill Tree button signal connected successfully", "AscendancyView")
	else:
		GameState.logger.error("Skill Tree button node not found!", "AscendancyView")

func _initialize_ui() -> void:
	# Center camera
	center_camera_in_child(ascendency2d_view_instance)
	_update_ui()

func get_class_name() -> String:
	return "AscendancyView"

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_currency_changed(_value = null) -> void:
	_update_ui()

func _on_ascended() -> void:
	_update_ui()
	GameState.logger.info("Ascension completed!", "AscendancyView")

func _on_ascend_button_pressed() -> void:
	var success = GameState.ascension_manager.ascend()
	if not success:
		GameState.logger.warning("Ascension failed - insufficient fame", "AscendancyView")

func _on_skill_tree_button_pressed() -> void:
	GameState.logger.debug("Loading SkillTreeView", "AscendancyView")
	SceneManager.load_game_scene(SKILL_TREE_SCENE_PATH)

#==============================================================================
# UI Updates
#==============================================================================
func _update_ui() -> void:
	var ascendancy_points = GameState.ascension_manager.get_ascendancy_points()
	var ascendancy_cost = GameState.ascension_manager.get_ascendancy_cost()
	var can_ascend = GameState.ascension_manager.can_ascend()
	
	ascendancy_points_label.text = "Ascendancy Points: %d" % ascendancy_points
	ascend_cost_label.text = "Ascend Cost: %d Fame" % ascendancy_cost
	ascend_button.disabled = not can_ascend

#==============================================================================
# Public API
#==============================================================================
## Force la mise à jour de l'UI
func update_ui() -> void:
	_update_ui()
