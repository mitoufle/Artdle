extends Node2D



@export var float_distance = 50
@export var float_duration = 0.8

func start(text: String, color: Color = Color(1,1,1,1)):
	$Label.text = text
	$Label.modulate = color
	var mouse_pos = get_viewport().get_mouse_position()
	position = mouse_pos
	var offset_x = randf_range(-10,10)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", position + Vector2(offset_x, -float_distance), float_duration)
	tween.tween_property($Label, "modulate:a", 0.0, float_duration)
	tween.finished.connect(self.queue_free)

	
