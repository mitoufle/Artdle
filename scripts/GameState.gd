extends Node

#==============================================================================
# Signals
#==============================================================================
signal inspiration_changed(new_inspiration_value:float)
signal ascendancy_level_changed(new_ascendancy_level_value:float)
signal ascendancy_point_changed(new_ascendancy_point_value:float)
signal gold_changed(new_gold_value:float)
signal paint_mastery_changed(new_paint_mastery_value:float)
signal fame_changed(new_fame_value:float)
signal ascended()

signal canvas_updated(new_texture: ImageTexture)
signal canvas_progress_updated(current_pixels: int, max_pixels: int)
signal canvas_completed()
signal canvas_upgrade_costs_changed(new_costs: Dictionary)
signal canvas_storage_changed(stored_canvases: int, max_storage: int)
signal canvas_storage_upgrade_cost_changed(cost: int)

signal click_stats_changed(new_stats: Dictionary)

#==============================================================================
# Global Currency
#==============================================================================
var ascendancy_point: float = 0
var inspiration: float = 0
var ascend_level: float = 0
var paint_mastery: float = 0
var gold: float = 0
var fame: float = 0
var Experience: float = 0
var level: int = 1

#==============================================================================
# Costs & Multipliers
#==============================================================================
var ascendancy_cost: float = 1000
var level_cost: float = 1000
var mastery_cost: float = 1000
var ascend_cost: float = 100
var prestige_inspiration_multiplier: float = 1
var painting_mastery_multiplier: float = 1

var upgrade_resolution_cost: int = 100
var upgrade_fill_speed_cost: int = 50

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
var stored_canvases: int = 0
var canvas_storage_level: int = 0
var canvas_storage_cost: int = 200   

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
	inspiration_changed.emit(inspiration)

func set_gold(amount:float):
	gold += amount
	gold_changed.emit(gold)

func set_fame(amount:float):
	fame += amount
	fame_changed.emit(fame)

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
func ascend():
	if fame >= ascendancy_cost:
		set_fame(-ascendancy_cost)
		set_ascendancy_point(1) # Gain 1 ascendancy point
		
		# Reset relevant game state
		inspiration = 0
		gold = 0
		
		resolution_level = 1
		fill_speed_level = 1
		sell_price = 1000
		
		click_power = 1
		autoclick_speed = 0.0
		
		_initialize_new_canvas()
		_update_fill_speed()
		_update_autoclick_timer()
		
		ascendancy_cost = int(ascendancy_cost * 2) # Double cost for next ascension
		
		ascended.emit()
		
		print("Ascended successfully!")
	else:
		print("Not enough fame to ascend!")

func reduce_by_max_multiple(cost: int, currency: int) -> int:
	if currency <= 0:
		push_error("y must be a positive integer")
		return cost
	return cost % currency

func buy_fame_with_gold(amount: float, gold_cost: float):
	if gold >= gold_cost:
		set_gold(-gold_cost)
		set_fame(amount)
		return true
	return false

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

func _try_store_completed_canvas():
	if current_pixel_count >= max_pixels and stored_canvases < canvas_storage_level:
		stored_canvases += 1
		_initialize_new_canvas()
		canvas_fill_timer.start()
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
		print("Canvas automatically stored.")
		return true
	return false

func _prefill_canvas(pixels_to_fill: int):
	var filled_count = 0
	while filled_count < pixels_to_fill and unfilled_pixels.size() > 0:
		var random_index = randi() % unfilled_pixels.size()
		var pixel_pos = unfilled_pixels.pop_at(random_index)
		
		canvas_image.set_pixelv(pixel_pos, Color(randf(), randf(), randf(), snapped(randf_range(0.6,1), 0.01)))
		
		filled_count += 1
	
	canvas_texture.set_image(canvas_image) # Update the texture after pre-filling
	current_pixel_count = filled_count # Update current_pixel_count
	canvas_updated.emit(canvas_texture)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _on_canvas_fill_timer_timeout():
	if current_pixel_count >= max_pixels:
		if canvas_fill_timer.is_stopped():
			return

		print("Canvas terminé !")
		canvas_fill_timer.stop()
		
		if not _try_store_completed_canvas():
			canvas_completed.emit() # Re-emit to signal UI to enable sell button
			print("Canvas completed, no storage available. Sell to continue.")
		else:
			print("Canvas completed and stored.")
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
	var total_canvases_sold = 0
	var total_gold_gained = 0
	var current_sell_price = sell_price # Use a temporary variable for current sell price
	var current_canvas_was_sold = false
	
	# Sell stored canvases
	while stored_canvases > 0:
		total_canvases_sold += 1
		total_gold_gained += current_sell_price
		current_sell_price = int(current_sell_price * 1.1) # Increase price for next canvas in group
		stored_canvases -= 1
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
		print("Sold stored canvas. Stored: %d" % stored_canvases)
	
	# Sell the currently displayed canvas if it's completed (current_pixel_count >= max_pixels)
	# and there's no storage available (meaning it wasn't stored automatically)
	if current_pixel_count >= max_pixels: # Check if current canvas is completed
		total_canvases_sold += 1
		total_gold_gained += current_sell_price
		current_sell_price = int(current_sell_price * 1.1) # Increase price for next canvas in group
		current_canvas_was_sold = true
		print("Sold current completed canvas.")
	
	if total_canvases_sold > 0:
		set_gold(total_gold_gained)
		set_fame(total_canvases_sold) # Gain 1 fame per canvas sold
		
		# Only start a new canvas if the current one was sold
		if current_canvas_was_sold:
			_initialize_new_canvas()
			canvas_fill_timer.start()
		print("Total canvases sold: %d. Total gold gained: %d" % [total_canvases_sold, total_gold_gained])
	else:
		print("No canvases to sell.")

func upgrade_resolution():
	if inspiration >= upgrade_resolution_cost:
		set_inspiration(-upgrade_resolution_cost)
		var pixels_to_prefill = current_pixel_count # Capture current progress
		
		resolution_level += 1
		sell_price = int(sell_price * 1.8)
		upgrade_resolution_cost = int(upgrade_resolution_cost * 1.5)
		
		_initialize_new_canvas() # Reset canvas to new resolution
		
		# Pre-fill the new canvas with the captured pixels
		_prefill_canvas(pixels_to_prefill)
		emit_canvas_upgrade_costs()

func upgrade_canvas_storage():
	if inspiration >= canvas_storage_cost:
		set_inspiration(-canvas_storage_cost)
		canvas_storage_level += 1
		canvas_storage_cost = int(canvas_storage_cost * 1.5) # Increase cost for next upgrade
		
		_try_store_completed_canvas() # Attempt to store if a canvas is completed
		
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
		canvas_storage_upgrade_cost_changed.emit(canvas_storage_cost)

func upgrade_fill_speed():
	if inspiration >= upgrade_fill_speed_cost:
		set_inspiration(-upgrade_fill_speed_cost)
		fill_speed_level += 1
		upgrade_fill_speed_cost = int(upgrade_fill_speed_cost * 1.2)
		_update_fill_speed()
		emit_canvas_upgrade_costs()

func emit_canvas_upgrade_costs():
	var costs = {
		"resolution_cost": upgrade_resolution_cost,
		"fill_speed_cost": upgrade_fill_speed_cost
	}
	canvas_upgrade_costs_changed.emit(costs)

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
