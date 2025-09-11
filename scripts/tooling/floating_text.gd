extends Node2D

@export var amount: String

@export var float_distance = 50
@export var float_duration = 0.8
@export var scale_multiplier = 2.0

@onready var sprite: Sprite2D                  = $Sprite2D
@onready var label: Label                      = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start(text: String, icon_texture: Texture2D, hframes: int, vframes: int, animation_name: String, _color: Color = Color(1,1,1,1), amount: float = 1.0):
	set_as_top_level(true)
	
	# Format the text using BigNumberManager for proper M, B, T formatting
	var formatted_text = text
	if text.begins_with("+"):
		# Extract the number part and format it
		var number_part = text.substr(1)  # Remove the "+"
		var number_value = number_part.to_float()
		var formatted_number = BigNumberManager.format_number(number_value)
		formatted_text = "+" + formatted_number
	else:
		# Try to format as number if it's a valid number
		var number_value = text.to_float()
		if number_value > 0:
			formatted_text = BigNumberManager.format_number(number_value)
	
	label.text     = formatted_text
	sprite.texture = icon_texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	
	# Calculate dynamic scale based on amount
	# Base scale is 1.0, scales up with amount
	# Formula: base_scale + (log(amount) * 0.1) for logarithmic scaling
	var base_scale = 1.0
	var amount_scale = 1.0 + (log(amount + 1.0) * 0.1)  # +1 to avoid log(0)
	var final_scale = base_scale * amount_scale
	
	# Clamp scale between 0.8 and 3.0 to prevent too small or too large text
	final_scale = clamp(final_scale, 0.8, 3.0)
	scale = Vector2(final_scale, final_scale)
	
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
	

	
