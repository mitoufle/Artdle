extends Node

@export var tooltip_scene = preload("res://Scenes/Tooltip.tscn")
var tooltip_instance: Control = null

func show_tooltip(line1: String, line2: String, position: Vector2):
	if tooltip_instance == null:
		tooltip_instance = tooltip_scene.instantiate()
		get_tree().current_scene.add_child(tooltip_instance)
	tooltip_instance.show_tooltip(line1, line2, position)

func hide_tooltip():
	if tooltip_instance:
		tooltip_instance.hide_tooltip()
		tooltip_instance = null
