extends Node2D

@export var amount: String

@export var float_distance = 50
@export var float_duration = 0.8

@onready var sprite: Sprite2D                  = $Sprite2D
@onready var label: Label                      = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start(text: String, icon_texture: Texture2D, hframes: int, vframes: int, animation_name: String, _color: Color = Color(1,1,1,1)):
	label.text     = text
	sprite.texture = icon_texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	
	animation_player.play(animation_name)
	
	global_position = get_global_mouse_position()
	
	var offset_x = randf_range(-10,10)
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "global_position", global_position + Vector2(offset_x, -float_distance), float_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, float_duration)
	tween.finished.connect(self.queue_free)
	

	
