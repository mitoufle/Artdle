extends Node2D

@export var amount: String
@export var icon: Texture2D

@export var float_distance = 50
@export var float_duration = 0.8

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

func start(text: String, icon_texture: Texture2D, color: Color = Color(1,1,1,1)):
	label.text = text
	texture_rect.texture = icon_texture
	
	var mouse_pos = get_viewport().get_mouse_position()
	position = mouse_pos
	
	var offset_x = randf_range(-10,10)
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "position", position + Vector2(offset_x, -float_distance), float_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, float_duration)
	tween.finished.connect(self.queue_free)
	

	
