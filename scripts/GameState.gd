extends Node

#==============================================================================
# Signals
#==============================================================================
signal inspiration_changed(type:String, new_inspiration_value:float)
signal ascendancy_level_changed(new_ascendancy_level_value:float)
signal ascendancy_point_changed(new_ascendancy_point_value:float)
signal gold_changed(new_gold_value:float)
signal paint_mastery_changed(new_paint_mastery_value:float)

signal canvas_updated(new_texture: ImageTexture)
signal canvas_progress_updated(current_pixels: int, max_pixels: int)
signal canvas_completed()

signal click_stats_changed(new_stats: Dictionary)

#==============================================================================
# Global Currency
#==============================================================================
var ascendancy_point: float = 0
var inspiration: float = 0
var ascend_level: float = 0
var paint_mastery: float = 0
var gold: float = 0
var Experience: float = 0
var level: int = 1

#==============================================================================
# Costs & Multipliers
#==============================================================================
var ascendancy_cost: float = 1000
var level_cost: float = 1000
var mastery_cost: float = 1000
var prestige_inspiration_multiplier: float = 1
var painting_mastery_multiplier: float = 1

#==============================================================================
# Canvas State & Properties
#==============================================================================
var canvas_image: Image
var canvas_texture: ImageTexture
var canvas_fill_timer: Timer
var current_pixel_count: int = 0
var max_pixels: int
var unfilled_pixels: Array[Vector2i] = []

var resolution_level: int = 1
var fill_speed_level: int = 1
var sell_price:       int = 1000

#==============================================================================
# Clicker State & Properties
#==============================================================================
var click_power: int = 1
var autoclick_speed: float = 0.0 # Clicks per second, 0 = disabled
var autoclick_timer: Timer

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	# Canvas Timer
	canvas_fill_timer = Timer.new()
	add_child(canvas_fill_timer)
	canvas_fill_timer.timeout.connect(_on_canvas_fill_timer_timeout)
	
	# Autoclicker Timer
	autoclick_timer = Timer.new()
	add_child(autoclick_timer)
	autoclick_timer.timeout.connect(_on_autoclick_timer_timeout)
	
	# Initialize first canvas
	_initialize_new_canvas()
	_update_fill_speed()
	canvas_fill_timer.start()

#==============================================================================
# Currency Management
#==============================================================================
func get_inspiration() -> float:
	return inspiration

func set_inspiration(amount:float):
	inspiration += amount 
	inspiration_changed.emit("inspiration", inspiration)

func set_gold(amount:float):
	gold += amount
	gold_changed.emit(gold)

func set_paint_mastery(amount:float):
	paint_mastery += amount
	paint_mastery_changed.emit(paint_mastery)

func set_ascendancy_point(amount:float):
	ascendancy_point += amount
	ascendancy_point_changed.emit(ascendancy_point)

func set_ascend_level(amount:float):
	ascend_level += amount
	ascendancy_level_changed.emit(ascend_level)

#==============================================================================
# Prestige Logic
#==============================================================================
func reset_prestige():
	if inspiration >= ascendancy_cost:
		var remainder = reduce_by_max_multiple(ascendancy_cost, inspiration)
		# ... (logic to be implemented)

func reduce_by_max_multiple(cost: int, currency: int) -> int:
	if currency <= 0:
		push_error("y must be a positive integer")
		return cost
	return cost % currency

#==============================================================================
# Canvas Logic
#==============================================================================
func _initialize_new_canvas():
	var width = 32 * resolution_level
	var height = 32 * resolution_level
	max_pixels = width * height
	current_pixel_count = 0
	
	unfilled_pixels.clear()
	for y in range(height):
		for x in range(width):
			unfilled_pixels.append(Vector2i(x, y))
	
	canvas_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color.TRANSPARENT)
	
	if canvas_texture == null:
		canvas_texture = ImageTexture.create_from_image(canvas_image)
	else:
		canvas_texture.set_image(canvas_image)

	canvas_updated.emit(canvas_texture)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _on_canvas_fill_timer_timeout():
	if current_pixel_count >= max_pixels:
		if canvas_fill_timer.is_stopped():
			return

		print("Canvas terminé !")
		canvas_fill_timer.stop()
		canvas_completed.emit()
		return

	var random_index = randi() % unfilled_pixels.size()
	var pixel_pos = unfilled_pixels.pop_at(random_index)
	
	canvas_image.set_pixelv(pixel_pos, Color(randf(), randf(), randf(), snapped(randf_range(0.6,1), 0.01)))
	canvas_texture.update(canvas_image)
	
	current_pixel_count += 1
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _update_fill_speed():
	var speed = 1.0 / float(fill_speed_level)
	canvas_fill_timer.wait_time = speed

func sell_canvas():
	print("Vente du canvas !")
	set_inspiration(sell_price)
	
	_initialize_new_canvas()
	canvas_fill_timer.start()

func upgrade_resolution():
	resolution_level += 1
	_initialize_new_canvas()

func upgrade_fill_speed():
	fill_speed_level += 1
	_update_fill_speed()

#==============================================================================
# Clicker Logic
#==============================================================================
func manual_click():
	set_inspiration(click_power)

func _on_autoclick_timer_timeout():
	set_inspiration(click_power)

func upgrade_click_power():
	# Example upgrade logic, you can make this more complex
	if gold >= 10:
		set_gold(-10)
		click_power += 1
		emit_click_stats()

func upgrade_autoclick_speed():
	# Example upgrade logic
	if gold >= 50:
		set_gold(-50)
		autoclick_speed += 1
		_update_autoclick_timer()
		emit_click_stats()

func _update_autoclick_timer():
	if autoclick_speed > 0:
		autoclick_timer.wait_time = 1.0 / autoclick_speed
		autoclick_timer.start()
	else:
		autoclick_timer.stop()

func emit_click_stats():
	var stats = {
		"click_power": click_power,
		"autoclick_speed": autoclick_speed
	}
	click_stats_changed.emit(stats)
