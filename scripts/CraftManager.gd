extends Node
class_name CraftManager

## Gère le système de craft dans l'atelier
## Sépare la logique de craft du GameState principal

#==============================================================================
# Signals
#==============================================================================
signal craft_started(item_type: InventoryManager.ItemType, quantity: int, duration: float)
signal craft_completed(item: InventoryManager.Item)
signal craft_finished()  # Signal émis quand tout le craft est terminé
signal craft_progress_updated(progress: float)
signal workshop_upgraded(new_level: int)

#==============================================================================
# Craft State
#==============================================================================
var current_craft: Dictionary = {}
var craft_progress: float = 0.0
var workshop_level: int = 1
var workshop_upgrade_cost: int = 100

# Définitions des items craftables
var craftable_items = {
	InventoryManager.ItemType.HAT: {
		"name": "Chapeau",
		"base_cost": 50,
		"base_duration": 30.0,  # 30 secondes
		"cost_per_level": 10
	},
	InventoryManager.ItemType.SHIRT: {
		"name": "Chemise",
		"base_cost": 75,
		"base_duration": 45.0,  # 45 secondes
		"cost_per_level": 15
	},
	InventoryManager.ItemType.BOOTS: {
		"name": "Bottes",
		"base_cost": 60,
		"base_duration": 35.0,  # 35 secondes
		"cost_per_level": 12
	},
	InventoryManager.ItemType.GLOVES: {
		"name": "Gants",
		"base_cost": 40,
		"base_duration": 25.0,  # 25 secondes
		"cost_per_level": 8
	},
	InventoryManager.ItemType.BRUSH: {
		"name": "Pinceau",
		"base_cost": 100,
		"base_duration": 60.0,  # 60 secondes
		"cost_per_level": 20
	},
	InventoryManager.ItemType.PALETTE: {
		"name": "Palette",
		"base_cost": 80,
		"base_duration": 50.0,  # 50 secondes
		"cost_per_level": 16
	},
	InventoryManager.ItemType.RING: {
		"name": "Anneau",
		"base_cost": 120,
		"base_duration": 70.0,  # 70 secondes
		"cost_per_level": 24
	},
	InventoryManager.ItemType.AMULET: {
		"name": "Amulette",
		"base_cost": 150,
		"base_duration": 90.0,  # 90 secondes
		"cost_per_level": 30
	},
	InventoryManager.ItemType.BADGE: {
		"name": "Badge",
		"base_cost": 200,
		"base_duration": 120.0,  # 120 secondes
		"cost_per_level": 40
	}
}

#==============================================================================
# Public API
#==============================================================================

## Commence un craft
func start_craft(item_type: InventoryManager.ItemType, quantity: int = 1) -> bool:
	if current_craft.size() > 0:
		GameState.logger.warning("Craft already in progress")
		return false
	
	var item_data = craftable_items.get(item_type)
	if not item_data:
		GameState.logger.warning("Item type not craftable: %s" % item_type)
		return false
	
	# Calculer le coût total
	var cost = _calculate_craft_cost(item_type, quantity)
	if not GameState.currency_manager.has_enough("gold", cost):
		GameState.logger.warning("Not enough gold to craft %s (need %d)" % [item_data.name, cost])
		return false
	
	# Calculer la durée totale
	var duration = _calculate_craft_duration(item_type, quantity)
	
	# Démarrer le craft
	current_craft = {
		"item_type": item_type,
		"quantity": quantity,
		"duration": duration,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"cost": cost
	}
	
	craft_progress = 0.0
	
	# Retirer l'or
	GameState.currency_manager.subtract_currency("gold", cost)
	
	# Émettre le signal
	craft_started.emit(item_type, quantity, duration)
	
	GameState.logger.info("Craft started: %s x%d (%.1fs)" % [item_data.name, quantity, duration])
	return true

## Met à jour le progrès du craft
func update_craft_progress(delta: float) -> void:
	if current_craft.size() == 0:
		return
	
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - current_craft.start_time
	craft_progress = min(elapsed_time / current_craft.duration, 1.0)
	
	craft_progress_updated.emit(craft_progress)
	
	# Vérifier si le craft est terminé
	if craft_progress >= 1.0:
		_complete_craft()

## Récupère le progrès actuel du craft
func get_craft_progress() -> float:
	return craft_progress

## Récupère les informations du craft en cours
func get_current_craft() -> Dictionary:
	return current_craft.duplicate()

## Vérifie si un craft est en cours
func is_crafting() -> bool:
	return current_craft.size() > 0

## Annule le craft en cours (rembourse 50% du coût)
func cancel_craft() -> bool:
	if current_craft.size() == 0:
		return false
	
	var refund = int(current_craft.cost * 0.5)
	GameState.currency_manager.add_currency("gold", refund)
	
	current_craft.clear()
	craft_progress = 0.0
	
	GameState.logger.info("Craft cancelled, refunded %d gold" % refund)
	return true

## Améliore l'atelier
func upgrade_workshop() -> bool:
	if not GameState.currency_manager.has_enough("gold", workshop_upgrade_cost):
		GameState.logger.warning("Not enough gold to upgrade workshop (need %d)" % workshop_upgrade_cost)
		return false
	
	GameState.currency_manager.subtract_currency("gold", workshop_upgrade_cost)
	workshop_level += 1
	workshop_upgrade_cost = int(workshop_upgrade_cost * 1.5)
	
	workshop_upgraded.emit(workshop_level)
	GameState.logger.info("Workshop upgraded to level %d" % workshop_level)
	return true

## Récupère le niveau de l'atelier
func get_workshop_level() -> int:
	return workshop_level

## Récupère le coût d'amélioration de l'atelier
func get_workshop_upgrade_cost() -> int:
	return workshop_upgrade_cost

## Récupère les chances de tiers selon le niveau de l'atelier
func get_tier_chances() -> Dictionary:
	var chances = {}
	
	# Calculer les chances basées sur le niveau de l'atelier
	# Plus le niveau est élevé, plus on a de chances d'avoir des tiers élevés
	
	# Tier 1: Diminue progressivement
	var tier1_chance = max(0.1, 1.0 - (workshop_level - 1) * 0.08)
	
	# Tier 2: Apparaît à partir du niveau 2, augmente jusqu'au niveau 10
	var tier2_chance = 0.0
	if workshop_level >= 2:
		tier2_chance = min(0.6, (workshop_level - 1) * 0.06)
	
	# Tier 3: Apparaît à partir du niveau 5, augmente lentement
	var tier3_chance = 0.0
	if workshop_level >= 5:
		tier3_chance = min(0.3, (workshop_level - 4) * 0.03)
	
	# Tier 4: Apparaît à partir du niveau 10, très rare
	var tier4_chance = 0.0
	if workshop_level >= 10:
		tier4_chance = min(0.1, (workshop_level - 9) * 0.01)
	
	# Tier 5: Apparaît à partir du niveau 20, extrêmement rare
	var tier5_chance = 0.0
	if workshop_level >= 20:
		tier5_chance = min(0.05, (workshop_level - 19) * 0.005)
	
	# Normaliser les chances pour qu'elles totalisent 1.0
	var total_chance = tier1_chance + tier2_chance + tier3_chance + tier4_chance + tier5_chance
	if total_chance > 0:
		tier1_chance /= total_chance
		tier2_chance /= total_chance
		tier3_chance /= total_chance
		tier4_chance /= total_chance
		tier5_chance /= total_chance
	
	# Assigner les chances
	chances[InventoryManager.ItemTier.TIER_1] = tier1_chance
	if tier2_chance > 0:
		chances[InventoryManager.ItemTier.TIER_2] = tier2_chance
	if tier3_chance > 0:
		chances[InventoryManager.ItemTier.TIER_3] = tier3_chance
	if tier4_chance > 0:
		chances[InventoryManager.ItemTier.TIER_4] = tier4_chance
	if tier5_chance > 0:
		chances[InventoryManager.ItemTier.TIER_5] = tier5_chance
	
	# Log pour debug
	GameState.logger.debug("Tier chances at level %d: %s" % [workshop_level, chances])
	
	return chances

## Récupère le coût de craft d'un item
func get_craft_cost(item_type: InventoryManager.ItemType, quantity: int = 1) -> int:
	return _calculate_craft_cost(item_type, quantity)

## Récupère la durée de craft d'un item
func get_craft_duration(item_type: InventoryManager.ItemType, quantity: int = 1) -> float:
	return _calculate_craft_duration(item_type, quantity)

## Récupère les items craftables
func get_craftable_items() -> Dictionary:
	return craftable_items.duplicate()

## Réinitialise l'atelier
func reset_workshop() -> void:
	current_craft.clear()
	craft_progress = 0.0
	workshop_level = 1
	workshop_upgrade_cost = 100
	GameState.logger.info("Workshop reset")

#==============================================================================
# Private Methods
#==============================================================================

func _calculate_craft_cost(item_type: InventoryManager.ItemType, quantity: int) -> int:
	var item_data = craftable_items[item_type]
	var base_cost = item_data.base_cost
	var cost_per_level = item_data.cost_per_level
	var level_cost = (workshop_level - 1) * cost_per_level
	return (base_cost + level_cost) * quantity

func _calculate_craft_duration(item_type: InventoryManager.ItemType, quantity: int) -> float:
	var item_data = craftable_items[item_type]
	var base_duration = item_data.base_duration
	# L'atelier réduit la durée de 5% par niveau
	var duration_multiplier = max(0.1, 1.0 - (workshop_level - 1) * 0.05)
	return base_duration * duration_multiplier * quantity

func _complete_craft() -> void:
	if current_craft.size() == 0:
		return
	
	var item_type = current_craft.item_type
	var quantity = current_craft.quantity
	
	# Générer les items
	for i in range(quantity):
		var tier = _determine_item_tier()
		var item = _create_item(item_type, tier)
		
		# Ajouter à l'inventaire
		GameState.inventory_manager.add_item(item)
		
		# Émettre le signal
		craft_completed.emit(item)
	
	# Nettoyer le craft
	current_craft.clear()
	craft_progress = 0.0
	
	# Émettre le signal de fin de craft
	craft_finished.emit()
	
	GameState.logger.info("Craft completed: %d items created" % quantity)

func _determine_item_tier() -> InventoryManager.ItemTier:
	var chances = get_tier_chances()
	var random_value = randf()
	var cumulative_chance = 0.0
	
	for tier in chances.keys():
		cumulative_chance += chances[tier]
		if random_value <= cumulative_chance:
			return tier
	
	# Fallback: T1
	return InventoryManager.ItemTier.TIER_1

func _create_item(item_type: InventoryManager.ItemType, tier: InventoryManager.ItemTier) -> InventoryManager.Item:
	var item_data = craftable_items[item_type]
	var item_name = item_data.name
	var item_id = "%s_%d_%d" % [item_type, tier, Time.get_ticks_msec()]
	
	return InventoryManager.Item.new(item_id, item_name, item_type, tier)
