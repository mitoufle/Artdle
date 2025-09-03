extends PanelContainer

func _ready():
	pass

func set_view_specific_currencies(view_name: String):
	match view_name:
		"PaintingView":
			$MarginContainer/HBoxContainer/PaintMasteryDisplay.visible = true
		_:
			$MarginContainer/HBoxContainer/PaintMasteryDisplay.visible = false
