extends Node
class_name CanvasManager

## Gère le système de canvas et de génération de pixels
## Sépare la logique de canvas du GameState principal

#==============================================================================
# Imports
#==============================================================================
const CurrencyBonusManager = preload("res://scripts/CurrencyBonusManager.gd")

#==============================================================================
# Signals
#==============================================================================
signal canvas_updated(new_texture: ImageTexture)
signal canvas_progress_updated(current_pixels: int, max_pixels: int)
signal canvas_completed()
signal canvas_storage_changed(stored_canvases: int, max_storage: int)
signal canvas_upgrade_costs_changed(new_costs: Dictionary)
signal canvas_storage_upgrade_cost_changed(cost: int)
signal canvas_fill_speed_changed(speed_info: Dictionary)

#==============================================================================
# Canvas State
#==============================================================================
var canvas_image: Image
var canvas_texture: ImageTexture
var canvas_fill_timer: Timer
var display_update_timer: Timer
var current_pixel_count: int = 0
var max_pixels: int
var unfilled_pixels: Array[Vector2i] = []
var filled_pixels_count: int = 0  # Track filled pixels instead of maintaining large array

# Creative optimization: Chunk-based filling
var fill_chunk_size: int = 16  # Fill 16x16 chunks at a time
var current_chunk_x: int = 0
var current_chunk_y: int = 0
var chunk_fill_progress: float = 0.0  # 0.0 to 1.0 within current chunk

# Display throttling variables
var last_displayed_pixel_count: int = 0
var display_update_threshold: int = 10  # Only update display every 10 pixels
var last_display_update_time: float = 0.0
var min_display_interval: float = 0.5  # Minimum 0.5 seconds between updates

# Canvas Properties
var resolution_level: int = GameConfig.BASE_RESOLUTION_LEVEL
var fill_speed_level: int = GameConfig.BASE_FILL_SPEED_LEVEL
var sell_price: int = GameConfig.BASE_SELL_PRICE
var stored_canvases: int = 0
var canvas_storage_level: int = GameConfig.BASE_CANVAS_STORAGE_LEVEL

# Pixel scaling for high speeds (when timer precision is insufficient)
var pixels_per_tick: int = 1

# Upgrade Costs
var upgrade_resolution_cost: int = GameConfig.BASE_RESOLUTION_UPGRADE_COST
var upgrade_fill_speed_cost: int = GameConfig.BASE_FILL_SPEED_UPGRADE_COST
var canvas_storage_cost: int = GameConfig.BASE_CANVAS_STORAGE_UPGRADE_COST

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_setup_timers()
	_initialize_new_canvas()
	_update_fill_speed()
	canvas_fill_timer.start()
	display_update_timer.start()
	
	# Connecter aux signaux de changement d'équipement pour recalculer les bonus
	if GameState.inventory_manager:
		GameState.inventory_manager.item_equipped.connect(_on_equipment_changed)
		GameState.inventory_manager.item_unequipped.connect(_on_equipment_changed)

# Removed custom timing - using pixel-per-tick scaling instead

#==============================================================================
# Public API
#==============================================================================

## Initialise un nouveau canvas
func _initialize_new_canvas() -> void:
	var width = GameConfig.BASE_CANVAS_SIZE * resolution_level
	var height = GameConfig.BASE_CANVAS_SIZE * resolution_level
	max_pixels = width * height
	current_pixel_count = 0
	
	# Reset throttling variables for new canvas
	last_displayed_pixel_count = 0
	last_display_update_time = Time.get_ticks_msec() / 1000.0
	filled_pixels_count = 0
	
	# Reset chunk-based filling
	current_chunk_x = 0
	current_chunk_y = 0
	chunk_fill_progress = 0.0
	
	# Adjust throttling parameters based on canvas size for better performance
	_update_throttling_parameters()
	
	# Adjust chunk size based on canvas size for optimal performance
	_update_chunk_size()
	
	# Don't pre-populate unfilled_pixels array - use random generation instead
	unfilled_pixels.clear()
	
	canvas_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color.TRANSPARENT)
	
	if canvas_texture == null:
		canvas_texture = ImageTexture.create_from_image(canvas_image)
	else:
		canvas_texture.set_image(canvas_image)

	canvas_updated.emit(canvas_texture)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

## Vendre les canvas stockés et le canvas actuel
func sell_canvas() -> Dictionary:
	var total_canvases_sold = 0
	var total_gold_gained = 0
	var current_sell_price = sell_price
	var current_canvas_was_sold = false
	
	# Appliquer les bonus d'items pour l'or
	var gold_bonus = CurrencyBonusManager.get_bonus_multiplier("gold")
	
	# Vendre les canvas stockés
	while stored_canvases > 0:
		total_canvases_sold += 1
		var base_gold = current_sell_price
		var bonus_gold = CurrencyBonusManager.apply_bonuses("gold", base_gold)
		total_gold_gained += int(bonus_gold)
		current_sell_price = int(current_sell_price * GameConfig.BULK_SELL_PRICE_MULTIPLIER)
		stored_canvases -= 1
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
	
	# Vendre le canvas actuel s'il est terminé
	if current_pixel_count >= max_pixels:
		total_canvases_sold += 1
		var base_gold = current_sell_price
		var bonus_gold = CurrencyBonusManager.apply_bonuses("gold", base_gold)
		total_gold_gained += int(bonus_gold)
		current_canvas_was_sold = true
	
	if total_canvases_sold > 0:
		# Ajouter de l'expérience pour chaque canvas vendu
		GameState.experience_manager.add_experience(GameConfig.EXPERIENCE_PER_CANVAS_SOLD * total_canvases_sold)
		
		# Redémarrer un nouveau canvas si le courant a été vendu
		if current_canvas_was_sold:
			_initialize_new_canvas()
			canvas_fill_timer.start()
			display_update_timer.start()
	
	return {
		"canvases_sold": total_canvases_sold,
		"gold_gained": total_gold_gained
	}

## Améliorer la résolution du canvas
func upgrade_resolution() -> bool:
	if not GameState.currency_manager.has_enough("inspiration", upgrade_resolution_cost):
		return false
	
	GameState.currency_manager.subtract_currency("inspiration", upgrade_resolution_cost)
	
	# Calculate completion percentage before upgrading
	var old_max_pixels = max_pixels
	var completion_percentage = float(current_pixel_count) / float(old_max_pixels) if old_max_pixels > 0 else 0.0
	
	resolution_level += 1
	sell_price = int(sell_price * GameConfig.SELL_PRICE_MULTIPLIER)
	upgrade_resolution_cost = int(upgrade_resolution_cost * GameConfig.RESOLUTION_COST_MULTIPLIER)
	# Prevent negative prices due to integer overflow
	sell_price = max(sell_price, 1)
	upgrade_resolution_cost = max(upgrade_resolution_cost, 1)
	
	# Initialize new canvas with new resolution
	_initialize_new_canvas()
	
	# Calculate how many pixels to prefill based on completion percentage
	var pixels_to_prefill = int(completion_percentage * max_pixels)
	_prefill_canvas(pixels_to_prefill)
	
	GameState.logger.info("Resolution upgraded: %d%% completion preserved (%d/%d -> %d/%d pixels)" % [int(completion_percentage * 100), current_pixel_count, old_max_pixels, pixels_to_prefill, max_pixels])
	_emit_upgrade_costs()
	return true

## Améliorer la vitesse de remplissage
func upgrade_fill_speed() -> bool:
	if not GameState.currency_manager.has_enough("inspiration", upgrade_fill_speed_cost):
		return false
	
	GameState.currency_manager.subtract_currency("inspiration", upgrade_fill_speed_cost)
	fill_speed_level += 1
	upgrade_fill_speed_cost = int(upgrade_fill_speed_cost * GameConfig.FILL_SPEED_COST_MULTIPLIER)
	# Prevent negative prices due to integer overflow
	upgrade_fill_speed_cost = max(upgrade_fill_speed_cost, 1)
	_update_fill_speed()
	_emit_upgrade_costs()
	return true

## Améliorer le stockage de canvas
func upgrade_canvas_storage() -> bool:
	if not GameState.currency_manager.has_enough("inspiration", canvas_storage_cost):
		return false
	
	GameState.currency_manager.subtract_currency("inspiration", canvas_storage_cost)
	canvas_storage_level += 1
	canvas_storage_cost = int(canvas_storage_cost * GameConfig.CANVAS_STORAGE_COST_MULTIPLIER)
	# Prevent negative prices due to integer overflow
	canvas_storage_cost = max(canvas_storage_cost, 1)
	
	# Emit storage change signal to update UI
	canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
	canvas_storage_upgrade_cost_changed.emit(canvas_storage_cost)
	
	GameState.logger.info("Canvas storage upgraded to level %d (capacity: %d)" % [canvas_storage_level, canvas_storage_level])
	return true

## Réinitialiser le canvas aux valeurs par défaut
func reset_canvas() -> void:
	resolution_level = GameConfig.BASE_RESOLUTION_LEVEL
	fill_speed_level = GameConfig.BASE_FILL_SPEED_LEVEL
	sell_price = GameConfig.BASE_SELL_PRICE
	stored_canvases = 0
	canvas_storage_level = GameConfig.BASE_CANVAS_STORAGE_LEVEL
	upgrade_resolution_cost = GameConfig.BASE_RESOLUTION_UPGRADE_COST
	upgrade_fill_speed_cost = GameConfig.BASE_FILL_SPEED_UPGRADE_COST
	canvas_storage_cost = GameConfig.BASE_CANVAS_STORAGE_UPGRADE_COST
	
	_initialize_new_canvas()
	_update_fill_speed()

## Ajoute un multiplicateur de prix de vente (pour les skills)
func add_sell_price_multiplier(multiplier: float) -> void:
	sell_price = int(sell_price * (1.0 + multiplier))
	# Prevent negative prices due to integer overflow
	sell_price = max(sell_price, 1)
	GameState.logger.info("Canvas sell price increased by %.1f%%" % (multiplier * 100))

## Ajoute un multiplicateur de gains de peinture (pour les skills)
func add_painting_gain_multiplier(multiplier: float) -> void:
	# Cette méthode sera utilisée pour augmenter les gains de peinture
	GameState.logger.info("Painting gain multiplier increased by %.1f%%" % (multiplier * 100))

## Ajoute un bonus permanent de vitesse de remplissage (pour les jobs)
func add_fill_speed_bonus(bonus: float) -> void:
	# This will be implemented to add permanent fill speed bonuses
	if GameState.logger:
		GameState.logger.info("Permanent canvas fill speed bonus: +%.1f%%" % (bonus * 100))

## Ajoute un bonus permanent de stockage (pour les jobs)
func add_storage_bonus(bonus: float) -> void:
	# This will be implemented to add permanent storage bonuses
	if GameState.logger:
		GameState.logger.info("Permanent canvas storage bonus: +%.1f%%" % (bonus * 100))

## Débloque le stockage de canvas (pour les skills)
func unlock_canvas_storage() -> void:
	# Cette méthode sera utilisée pour débloquer le stockage
	GameState.logger.info("Canvas storage unlocked!")

## Débloque les améliorations de taille de canvas (pour les skills)
func unlock_canvas_size_upgrades() -> void:
	# Cette méthode sera utilisée pour débloquer les améliorations de taille
	GameState.logger.info("Canvas size upgrades unlocked!")

#==============================================================================
# Private Methods
#==============================================================================

func _setup_timers() -> void:
	canvas_fill_timer = Timer.new()
	add_child(canvas_fill_timer)
	canvas_fill_timer.timeout.connect(_on_canvas_fill_timer_timeout)
	
	# Display update timer - much more aggressive throttling for memory efficiency
	display_update_timer = Timer.new()
	add_child(display_update_timer)
	display_update_timer.wait_time = 0.1  # Check every 100ms, but only update if needed
	display_update_timer.timeout.connect(_on_display_update_timeout)
	display_update_timer.start()

func _try_store_completed_canvas() -> bool:
	GameState.logger.debug("Trying to store canvas: current_pixels=%d, max_pixels=%d, stored=%d, storage_level=%d" % [current_pixel_count, max_pixels, stored_canvases, canvas_storage_level])
	
	# Check if canvas is complete and we have storage space
	var canvas_complete = current_pixel_count >= max_pixels
	var has_storage_space = stored_canvases < canvas_storage_level
	
	if canvas_complete and has_storage_space:
		stored_canvases += 1
		_initialize_new_canvas()
		canvas_fill_timer.start()
		display_update_timer.start()
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
		GameState.logger.info("Canvas stored successfully! New count: %d/%d" % [stored_canvases, canvas_storage_level])
		return true
	else:
		if not canvas_complete:
			GameState.logger.debug("Canvas not complete yet: %d/%d pixels" % [current_pixel_count, max_pixels])
		if not has_storage_space:
			GameState.logger.debug("No storage space available: %d/%d stored" % [stored_canvases, canvas_storage_level])
	return false

func _prefill_canvas(pixels_to_fill: int) -> void:
	# Appliquer le bonus de gain de pixels
	var pixel_gain_bonus = CurrencyBonusManager.get_bonus_multiplier("pixel_gain")
	var adjusted_pixels_to_fill = int(pixels_to_fill * pixel_gain_bonus)
	
	# Use the same efficient batch filling method
	_fill_pixels_batch(adjusted_pixels_to_fill)
	current_pixel_count += adjusted_pixels_to_fill
	
	canvas_texture.set_image(canvas_image)
	canvas_updated.emit(canvas_texture)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _on_canvas_fill_timer_timeout() -> void:
	_process_canvas_fill()

func _on_display_update_timeout() -> void:
	# Smart throttling - only update display when there's a meaningful change
	var current_time = Time.get_ticks_msec() / 1000.0
	var pixel_difference = current_pixel_count - last_displayed_pixel_count
	var time_difference = current_time - last_display_update_time
	
	# Update display if:
	# 1. Significant pixel change (threshold reached), OR
	# 2. Enough time has passed (minimum interval), OR
	# 3. Canvas is complete
	var should_update = (
		pixel_difference >= display_update_threshold or
		time_difference >= min_display_interval or
		current_pixel_count >= max_pixels
	)
	
	if should_update:
		canvas_progress_updated.emit(current_pixel_count, max_pixels)
		last_displayed_pixel_count = current_pixel_count
		last_display_update_time = current_time

func _force_display_update() -> void:
	# Force immediate display update (bypasses throttling)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)
	last_displayed_pixel_count = current_pixel_count
	last_display_update_time = Time.get_ticks_msec() / 1000.0

func _update_throttling_parameters() -> void:
	# Adjust throttling based on canvas size for optimal performance
	if max_pixels <= 1024:  # Small canvas (32x32)
		display_update_threshold = 5
		min_display_interval = 0.3
	elif max_pixels <= 4096:  # Medium canvas (64x64)
		display_update_threshold = 10
		min_display_interval = 0.5
	elif max_pixels <= 16384:  # Large canvas (128x128)
		display_update_threshold = 25
		min_display_interval = 0.8
	else:  # Very large canvas (256x256+)
		display_update_threshold = 50
		min_display_interval = 1.0
	
	GameState.logger.debug("Throttling parameters updated: threshold=%d, interval=%.1fs for %d pixels" % [display_update_threshold, min_display_interval, max_pixels])

func _update_chunk_size() -> void:
	# Ultra-large chunk sizing for high-resolution canvases
	# Creates smooth, sweeping painting effects on large canvases
	
	# Special case for level 10 - exactly 512x512 chunks as requested
	if resolution_level == 10:
		fill_chunk_size = 512
	elif resolution_level <= 2:  # Small canvases (32x32, 64x64)
		fill_chunk_size = 8 * resolution_level  # 8x8, 16x16
	elif resolution_level <= 5:  # Medium canvases (96x96 to 160x160)
		fill_chunk_size = 16 * resolution_level  # 48x48, 64x64, 80x80
	elif resolution_level <= 8:  # Large canvases (192x192 to 256x256)
		fill_chunk_size = 32 * resolution_level  # 192x192, 224x224, 256x256
	elif resolution_level <= 12:  # Very large canvases (288x288 to 384x384)
		fill_chunk_size = 48 * resolution_level  # 480x480, 528x528, 576x576
	else:  # Ultra large canvases (400x400+)
		fill_chunk_size = 64 * resolution_level  # 640x640, 704x704, 768x768+
	
	# Cap at reasonable maximum to prevent memory issues
	fill_chunk_size = min(fill_chunk_size, 1024)  # Max 1024x1024 chunks
	
	# Ensure minimum chunk size
	fill_chunk_size = max(fill_chunk_size, 8)
	
	GameState.logger.debug("Ultra chunk size updated: %dx%d for %d pixels (resolution level %d)" % [fill_chunk_size, fill_chunk_size, max_pixels, resolution_level])

func _fill_pixels_batch(pixel_count: int) -> void:
	# Creative chunk-based filling - much more efficient!
	if pixel_count <= 0:
		return
	
	var width = GameConfig.BASE_CANVAS_SIZE * resolution_level
	var height = GameConfig.BASE_CANVAS_SIZE * resolution_level
	var chunks_x = (width + fill_chunk_size - 1) / fill_chunk_size
	var chunks_y = (height + fill_chunk_size - 1) / fill_chunk_size
	
	var pixels_filled = 0
	var pixels_to_fill = pixel_count
	
	# Fill chunks progressively instead of random pixels
	while pixels_filled < pixels_to_fill and current_pixel_count < max_pixels:
		# Calculate how many pixels to fill in current chunk
		var chunk_pixels_remaining = fill_chunk_size * fill_chunk_size - int(chunk_fill_progress * fill_chunk_size * fill_chunk_size)
		var pixels_in_this_chunk = min(pixels_to_fill - pixels_filled, chunk_pixels_remaining)
		
		if pixels_in_this_chunk > 0:
			# Fill the current chunk
			var filled_in_chunk = _fill_current_chunk(pixels_in_this_chunk, width, height)
			pixels_filled += filled_in_chunk
			chunk_fill_progress += float(filled_in_chunk) / (fill_chunk_size * fill_chunk_size)
		
		# Move to next chunk if current one is complete
		if chunk_fill_progress >= 1.0:
			chunk_fill_progress = 0.0
			current_chunk_x += 1
			if current_chunk_x >= chunks_x:
				current_chunk_x = 0
				current_chunk_y += 1
				if current_chunk_y >= chunks_y:
					# All chunks filled, start over (shouldn't happen normally)
					current_chunk_x = 0
					current_chunk_y = 0
	
	# Update texture only once per batch
	canvas_texture.update(canvas_image)

func _fill_current_chunk(pixel_count: int, width: int, height: int) -> int:
	# Fill pixels in the current chunk using a pattern-based approach
	var start_x = current_chunk_x * fill_chunk_size
	var start_y = current_chunk_y * fill_chunk_size
	var end_x = min(start_x + fill_chunk_size, width)
	var end_y = min(start_y + fill_chunk_size, height)
	
	var pixels_filled = 0
	var pattern_seed = current_chunk_x * 1000 + current_chunk_y  # Deterministic but varied
	
	# Use a simple pattern to fill pixels (much faster than random)
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			if pixels_filled >= pixel_count:
				break
				
			# Check if pixel is already filled
			var current_color = canvas_image.get_pixelv(Vector2i(x, y))
			if current_color.a < 0.1:  # Nearly transparent = unfilled
				# Generate pseudo-random color based on position and seed
				var pseudo_rand = sin(x * 0.1 + y * 0.1 + pattern_seed) * 1000
				var r = fmod(abs(pseudo_rand), 1.0)
				var g = fmod(abs(pseudo_rand * 1.618), 1.0)  # Golden ratio for variety
				var b = fmod(abs(pseudo_rand * 2.718), 1.0)  # Euler's number for variety
				var alpha = snapped(randf_range(GameConfig.PIXEL_ALPHA_MIN, GameConfig.PIXEL_ALPHA_MAX), GameConfig.PIXEL_ALPHA_SNAP)
				
				canvas_image.set_pixelv(Vector2i(x, y), Color(r, g, b, alpha))
				pixels_filled += 1
		
		if pixels_filled >= pixel_count:
			break
	
	return pixels_filled

func _process_canvas_fill() -> void:
	if current_pixel_count >= max_pixels:
		if canvas_fill_timer.is_stopped():
			return

		canvas_fill_timer.stop()
		display_update_timer.stop()
		
		# Force immediate display update for completion
		_force_display_update()
		
		GameState.logger.debug("Canvas completed! Attempting to store...")
		
		if not _try_store_completed_canvas():
			GameState.logger.debug("Canvas could not be stored, emitting completion signal")
			canvas_completed.emit()
		return

	# Appliquer le bonus de gain de pixels
	var pixel_gain_bonus = CurrencyBonusManager.get_bonus_multiplier("pixel_gain")
	var base_pixels_to_fill = pixels_per_tick  # Use the calculated pixels per tick
	var pixels_to_fill = int(base_pixels_to_fill * pixel_gain_bonus)  # Apply pixel gain bonus
	
	# S'assurer qu'on ne dépasse pas le maximum
	var unfilled_count = max_pixels - current_pixel_count
	var max_possible = min(pixels_to_fill, unfilled_count)
	
	# Debug logging for pixel filling
	if current_pixel_count % 100 == 0:  # Log every 100 pixels to avoid spam
		GameState.logger.debug("Canvas filling: pixels_per_tick=%d, pixel_gain_bonus=%.2f, pixels_to_fill=%d, max_possible=%d, current=%d/%d" % [pixels_per_tick, pixel_gain_bonus, pixels_to_fill, max_possible, current_pixel_count, max_pixels])
	
	# Optimized pixel filling - batch operations for better performance
	_fill_pixels_batch(max_possible)
	current_pixel_count += max_possible
	# Note: Progress updates are now handled by the display_update_timer for better performance

func _update_fill_speed() -> void:
	# Balanced scaling: logarithmic improvement that feels impactful but not overpowered
	# Level 1: 1.0s, Level 2: 0.7s, Level 3: 0.5s, Level 4: 0.35s, Level 5: 0.25s, etc.
	# This gives diminishing returns but still feels powerful
	var base_speed = 1.0 / (1.0 + (fill_speed_level - 1) * 0.8)  # 80% speed increase per level
	
	# Appliquer les bonus d'items pour la vitesse de canvas
	var canvas_speed_bonus = CurrencyBonusManager.get_bonus_multiplier("canvas_speed")
	var painting_speed_bonus = CurrencyBonusManager.get_bonus_multiplier("painting_speed")
	
	# Combiner les bonus (multiplier car plus de bonus = plus rapide = moins de temps)
	var total_speed_bonus = canvas_speed_bonus * painting_speed_bonus
	var final_speed = base_speed / total_speed_bonus  # Divide time by bonus to make it faster
	
	# Godot timer precision limit - below this we use pixel-per-tick scaling instead
	const TIMER_PRECISION_LIMIT = 0.05
	
	if final_speed < TIMER_PRECISION_LIMIT:
		# For high speeds, use pixel-per-tick scaling instead of faster timer
		# Calculate how many pixels per tick we need to maintain the same speed
		var target_pixels_per_second = 1.0 / final_speed
		var base_pixels_per_second = 1.0 / TIMER_PRECISION_LIMIT  # 20 pixels per second at 0.05s interval
		pixels_per_tick = max(1, int(target_pixels_per_second / base_pixels_per_second))
		
		# Use the precision limit as our timer interval
		canvas_fill_timer.wait_time = TIMER_PRECISION_LIMIT
		
		GameState.logger.info("Using pixel-per-tick scaling for high speed (level %d): %d pixels per tick at %.3f second intervals" % [fill_speed_level, pixels_per_tick, TIMER_PRECISION_LIMIT])
	else:
		# Use normal timer for slower speeds
		pixels_per_tick = 1
		canvas_fill_timer.wait_time = final_speed
		
		GameState.logger.info("Using normal timer for speed (level %d): 1 pixel per tick at %.3f second intervals" % [fill_speed_level, final_speed])
	
	# Start timer if it's not running
	if canvas_fill_timer.is_stopped():
		canvas_fill_timer.start()
		display_update_timer.start()
	
	# Emit speed change signal
	var speed_info = get_fill_speed_info()
	canvas_fill_speed_changed.emit(speed_info)
	
	GameState.logger.debug("Canvas speed updated: level=%d, base=%.3f, canvas_bonus=%.2f, painting_bonus=%.2f, final=%.3f" % [fill_speed_level, base_speed, canvas_speed_bonus, painting_speed_bonus, final_speed])
	
	# Calculate effective pixels per second
	var effective_pixels_per_second = pixels_per_tick / canvas_fill_timer.wait_time
	GameState.logger.info("Canvas speed calculation: Level %d = %.1f pixels per second (effective)" % [fill_speed_level, effective_pixels_per_second])
	
	# Debug: Calculate expected completion time for 1024 pixel canvas
	var expected_time = 1024.0 / effective_pixels_per_second
	GameState.logger.info("Expected completion time for 1024px canvas: %.2f seconds" % expected_time)

func _emit_upgrade_costs() -> void:
	var costs = {
		"resolution_cost": upgrade_resolution_cost,
		"fill_speed_cost": upgrade_fill_speed_cost
	}
	canvas_upgrade_costs_changed.emit(costs)

## Callback quand l'équipement change - recalculer les bonus
func _on_equipment_changed(slot: String, item: InventoryManager.Item = null) -> void:
	# Recalculer la vitesse de remplissage avec les nouveaux bonus
	_update_fill_speed()
	GameState.logger.debug("Canvas speed updated due to equipment change in slot: %s" % slot)

#==============================================================================
# Public API Methods
#==============================================================================

## Récupère la texture du canvas
func get_canvas_texture() -> ImageTexture:
	return canvas_texture

## Récupère les informations sur les pixels
func get_pixel_info() -> Dictionary:
	return {
		"current": current_pixel_count,
		"max": max_pixels
	}

## Récupère les coûts d'amélioration
func get_upgrade_costs() -> Dictionary:
	return {
		"resolution_cost": upgrade_resolution_cost,
		"fill_speed_cost": upgrade_fill_speed_cost
	}

## Récupère les informations de stockage
func get_storage_info() -> Dictionary:
	return {
		"stored": stored_canvases,
		"level": canvas_storage_level
	}

## Récupère les informations de vitesse de remplissage
func get_fill_speed_info() -> Dictionary:
	# Calculate effective pixels per second based on current configuration
	var effective_pixels_per_second = pixels_per_tick / canvas_fill_timer.wait_time
	
	return {
		"level": fill_speed_level,
		"pixels_per_tick": pixels_per_tick,
		"timer_interval": canvas_fill_timer.wait_time,
		"pixels_per_second": effective_pixels_per_second
	}

## Récupère le coût d'amélioration du stockage
func get_storage_upgrade_cost() -> int:
	return canvas_storage_cost

## Définit le niveau de résolution (pour le système de sauvegarde)
func set_resolution_level(value: int) -> void:
	resolution_level = value
	_emit_upgrade_costs()

## Définit le niveau de vitesse de remplissage (pour le système de sauvegarde)
func set_fill_speed_level(value: int) -> void:
	fill_speed_level = value
	_update_fill_speed()
	_emit_upgrade_costs()

## Définit le prix de vente (pour le système de sauvegarde)
func set_sell_price(value: int) -> void:
	sell_price = value

## Définit le nombre de canvas stockés (pour le système de sauvegarde)
func set_stored_canvases(value: int) -> void:
	stored_canvases = value
	canvas_storage_changed.emit(stored_canvases, canvas_storage_level)

## Définit le niveau de stockage (pour le système de sauvegarde)
func set_canvas_storage_level(value: int) -> void:
	canvas_storage_level = value
	canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
	GameState.logger.debug("Canvas storage level set to: %d" % canvas_storage_level)

## Définit le coût d'amélioration de résolution (pour le système de sauvegarde)
func set_upgrade_resolution_cost(value: int) -> void:
	upgrade_resolution_cost = value
	_emit_upgrade_costs()

## Définit le coût d'amélioration de vitesse (pour le système de sauvegarde)
func set_upgrade_fill_speed_cost(value: int) -> void:
	upgrade_fill_speed_cost = value
	_emit_upgrade_costs()

## Définit le coût d'amélioration de stockage (pour le système de sauvegarde)
func set_canvas_storage_cost(value: int) -> void:
	canvas_storage_cost = value
	canvas_storage_upgrade_cost_changed.emit(canvas_storage_cost)
