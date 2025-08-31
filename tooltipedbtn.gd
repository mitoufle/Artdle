extends Control

@onready var Tooltip_Scn = preload("res://views/tooltip.tscn")

func _on_mouse_entered() -> void:
	var Tooltip = Tooltip_Scn.instantiate()
	Tooltip.show_tooltip(Rect2i( Vector2i(global_position), Vector2i(size)), null, null)
	

func _on_mouse_exited() -> void:
	var Tooltip = Tooltip_Scn.instantiate()
	Tooltip.hide_tooltip()
