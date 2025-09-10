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

#==============================================================================
# Canvas State
#==============================================================================
var canvas_image: Image
var canvas_texture: ImageTexture
var canvas_fill_timer: Timer
var current_pixel_count: int = 0
var max_pixels: int
var unfilled_pixels: Array[Vector2i] = []

# Canvas Properties
var resolution_level: int = GameConfig.BASE_RESOLUTION_LEVEL
var fill_speed_level: int = GameConfig.BASE_FILL_SPEED_LEVEL
var sell_price: int = GameConfig.BASE_SELL_PRICE
var stored_canvases: int = 0
var canvas_storage_level: int = GameConfig.BASE_CANVAS_STORAGE_LEVEL

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
	
	# Connecter aux signaux de changement d'équipement pour recalculer les bonus
	if GameState.inventory_manager:
		GameState.inventory_manager.item_equipped.connect(_on_equipment_changed)
		GameState.inventory_manager.item_unequipped.connect(_on_equipment_changed)

#==============================================================================
# Public API
#==============================================================================

## Initialise un nouveau canvas
func _initialize_new_canvas() -> void:
	var width = GameConfig.BASE_CANVAS_SIZE * resolution_level
	var height = GameConfig.BASE_CANVAS_SIZE * resolution_level
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
	
	return {
		"canvases_sold": total_canvases_sold,
		"gold_gained": total_gold_gained
	}

## Améliorer la résolution du canvas
func upgrade_resolution() -> bool:
	if not GameState.currency_manager.has_enough("inspiration", upgrade_resolution_cost):
		return false
	
	GameState.currency_manager.subtract_currency("inspiration", upgrade_resolution_cost)
	var pixels_to_prefill = current_pixel_count
	
	resolution_level += 1
	sell_price = int(sell_price * GameConfig.SELL_PRICE_MULTIPLIER)
	upgrade_resolution_cost = int(upgrade_resolution_cost * GameConfig.RESOLUTION_COST_MULTIPLIER)
	
	_initialize_new_canvas()
	_prefill_canvas(pixels_to_prefill)
	_emit_upgrade_costs()
	return true

## Améliorer la vitesse de remplissage
func upgrade_fill_speed() -> bool:
	if not GameState.currency_manager.has_enough("inspiration", upgrade_fill_speed_cost):
		return false
	
	GameState.currency_manager.subtract_currency("inspiration", upgrade_fill_speed_cost)
	fill_speed_level += 1
	upgrade_fill_speed_cost = int(upgrade_fill_speed_cost * GameConfig.FILL_SPEED_COST_MULTIPLIER)
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
	
	_try_store_completed_canvas()
	canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
	canvas_storage_upgrade_cost_changed.emit(canvas_storage_cost)
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
	GameState.logger.info("Canvas sell price increased by %.1f%%" % (multiplier * 100))

## Ajoute un multiplicateur de gains de peinture (pour les skills)
func add_painting_gain_multiplier(multiplier: float) -> void:
	# Cette méthode sera utilisée pour augmenter les gains de peinture
	GameState.logger.info("Painting gain multiplier increased by %.1f%%" % (multiplier * 100))

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

func _try_store_completed_canvas() -> bool:
	GameState.logger.debug("Trying to store canvas: current_pixels=%d, max_pixels=%d, stored=%d, storage_level=%d" % [current_pixel_count, max_pixels, stored_canvases, canvas_storage_level])
	if current_pixel_count >= max_pixels and stored_canvases < canvas_storage_level:
		stored_canvases += 1
		_initialize_new_canvas()
		canvas_fill_timer.start()
		canvas_storage_changed.emit(stored_canvases, canvas_storage_level)
		GameState.logger.debug("Canvas stored successfully! New count: %d" % stored_canvases)
		return true
	else:
		GameState.logger.debug("Canvas storage failed: canvas complete=%s, storage available=%s" % [current_pixel_count >= max_pixels, stored_canvases < canvas_storage_level])
	return false

func _prefill_canvas(pixels_to_fill: int) -> void:
	# Appliquer le bonus de gain de pixels
	var pixel_gain_bonus = CurrencyBonusManager.get_bonus_multiplier("pixel_gain")
	var adjusted_pixels_to_fill = int(pixels_to_fill * pixel_gain_bonus)
	
	var filled_count = 0
	while filled_count < adjusted_pixels_to_fill and unfilled_pixels.size() > 0:
		var random_index = randi() % unfilled_pixels.size()
		var pixel_pos = unfilled_pixels.pop_at(random_index)
		
		var alpha = snapped(randf_range(GameConfig.PIXEL_ALPHA_MIN, GameConfig.PIXEL_ALPHA_MAX), GameConfig.PIXEL_ALPHA_SNAP)
		canvas_image.set_pixelv(pixel_pos, Color(randf(), randf(), randf(), alpha))
		
		filled_count += 1
	
	canvas_texture.set_image(canvas_image)
	current_pixel_count = filled_count
	canvas_updated.emit(canvas_texture)
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _on_canvas_fill_timer_timeout() -> void:
	if current_pixel_count >= max_pixels:
		if canvas_fill_timer.is_stopped():
			return

		canvas_fill_timer.stop()
		GameState.logger.debug("Canvas completed! Attempting to store...")
		
		if not _try_store_completed_canvas():
			GameState.logger.debug("Canvas could not be stored, emitting completion signal")
			canvas_completed.emit()
		return

	# Appliquer le bonus de gain de pixels
	var pixel_gain_bonus = CurrencyBonusManager.get_bonus_multiplier("pixel_gain")
	var pixels_to_fill = int(pixel_gain_bonus)
	
	# S'assurer qu'on ne dépasse pas le maximum
	var max_possible = min(pixels_to_fill, unfilled_pixels.size(), max_pixels - current_pixel_count)
	
	for i in range(max_possible):
		var random_index = randi() % unfilled_pixels.size()
		var pixel_pos = unfilled_pixels.pop_at(random_index)
		
		var alpha = snapped(randf_range(GameConfig.PIXEL_ALPHA_MIN, GameConfig.PIXEL_ALPHA_MAX), GameConfig.PIXEL_ALPHA_SNAP)
		canvas_image.set_pixelv(pixel_pos, Color(randf(), randf(), randf(), alpha))
	
	canvas_texture.update(canvas_image)
	current_pixel_count += max_possible
	canvas_progress_updated.emit(current_pixel_count, max_pixels)

func _update_fill_speed() -> void:
	var base_speed = 1.0 / float(fill_speed_level)
	
	# Appliquer les bonus d'items pour la vitesse de canvas
	var canvas_speed_bonus = CurrencyBonusManager.get_bonus_multiplier("canvas_speed")
	var painting_speed_bonus = CurrencyBonusManager.get_bonus_multiplier("painting_speed")
	
	# Combiner les bonus (diviser car plus de bonus = plus rapide)
	var total_speed_bonus = canvas_speed_bonus * painting_speed_bonus
	var final_speed = base_speed / total_speed_bonus
	
	canvas_fill_timer.wait_time = final_speed
	GameState.logger.debug("Canvas speed updated: base=%.3f, canvas_bonus=%.2f, painting_bonus=%.2f, final=%.3f" % [base_speed, canvas_speed_bonus, painting_speed_bonus, final_speed])

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
