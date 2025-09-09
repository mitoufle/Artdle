extends Node2D

@export var amount: String

@export var float_distance = 50
@export var float_duration = 0.8
@export var scale_multiplier = 2.0

@onready var sprite: Sprite2D                  = $Sprite2D
@onready var label: Label                      = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start(text: String, icon_texture: Texture2D, hframes: int, vframes: int, animation_name: String, _color: Color = Color(1,1,1,1)):
	set_as_top_level(true)
	label.text     = text
	sprite.texture = icon_texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	
	# Scale the floating text by the multiplier
	scale = Vector2(scale_multiplier, scale_multiplier)
	
	animation_player.play(animation_name)
	
	# Only set position to mouse if no position was already set
	if global_position == Vector2.ZERO:
		global_position = get_global_mouse_position()
	
	# More random movement - both X and Y directions with random distances
	var random_offset_x = randf_range(-80, 80)  # Increased from -10,10 to -80,80
	var random_offset_y = randf_range(-60, -20)  # Random Y offset between -60 and -20
	var random_distance = randf_range(40, 120)   # Random float distance between 40 and 120
	
	# Random duration between 0.6 and 1.4 seconds
	var random_duration = randf_range(0.6, 1.4)
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "global_position", global_position + Vector2(random_offset_x, random_offset_y - random_distance), random_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, random_duration)
	tween.finished.connect(self.queue_free)
	

	
