extends PanelContainer

func _ready():
	pass
	GameState.ascendancy_point_changed.connect($MarginContainer/HBoxContainer/AscendancyPointDisplay._on_currency_changed)

func set_view_specific_currencies(view_name: String):
	match view_name:
		"PaintingView":
			$MarginContainer/HBoxContainer/PaintMasteryDisplay.visible = true
		"AscendancyView":
			$MarginContainer/HBoxContainer/AscendancyPointDisplay.visible = true
		_:
			$MarginContainer/HBoxContainer/PaintMasteryDisplay.visible = false
			$MarginContainer/HBoxContainer/AscendancyPointDisplay.visible = false
