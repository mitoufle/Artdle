extends Control


@onready var Tooltip_Scn = preload("res://views/tooltip.tscn")

@export_category("meta")
@export var name1: String

@export_category("data")
@export var line1: String
@export var line2: String

func _on_mouse_entered() -> void:
	var Tooltip = Tooltip_Scn.instantiate()
	
func _on_mouse_exited() -> void:
	var Tooltip = Tooltip_Scn.instantiate()
	Tooltip.hide_tooltip()
