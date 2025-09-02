extends Control

@onready var ascendency2d_view_instance = $Ascendency2DView

func _ready():
	var camera_node = ascendency2d_view_instance.find_child("Camera2D")
	if camera_node:
		camera_node.position = get_size() / 2
