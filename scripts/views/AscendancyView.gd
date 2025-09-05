extends Control

@onready var ascendency2d_view_instance = $Ascendency2DView
@onready var ascendancy_points_label: Label = $AscendancyPointsLabel
@onready var ascend_cost_label: Label = $AscendCostLabel
@onready var ascend_button: TextureButton = $AscendButton

func _ready():
	var camera_node = ascendency2d_view_instance.find_child("Camera2D")
	if camera_node:
		camera_node.position = get_size() / 2

	# Connect to GameState signals
	GameState.fame_changed.connect(update_ui)
	GameState.ascendancy_point_changed.connect(update_ui)
	GameState.ascended.connect(update_ui)

	# Connect UI signals
	ascend_button.pressed.connect(GameState.ascend)

	update_ui()

func update_ui(_value = null):
	ascendancy_points_label.text = "Ascendancy Points: %d" % GameState.ascendancy_point
	ascend_cost_label.text = "Ascend Cost: %d Fame" % GameState.ascendancy_cost

	if GameState.fame >= GameState.ascendancy_cost:
		ascend_button.disabled = false
	else:
		ascend_button.disabled = true
