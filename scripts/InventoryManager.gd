extends Node
class_name InventoryManager

## Gère l'inventaire et l'équipement du joueur
## Sépare la logique d'inventaire du GameState principal

#==============================================================================
# Signals
#==============================================================================
signal item_equipped(slot: String, item: Item)
signal item_unequipped(slot: String, item: Item)
signal inventory_changed()

#==============================================================================
# Item System
#==============================================================================
enum ItemTier {
	TIER_1,  # Normal
	TIER_2,  # Magic
	TIER_3,  # Rare
	TIER_4,  # Epic
	TIER_5   # Legendary
}

enum ItemType {
	HAT,      # Chapeau
	SHIRT,    # Chemise
	BOOTS,    # Bottes
	GLOVES,   # Gants
	BRUSH,    # Pinceau
	PALETTE,  # Palette
	RING,     # Anneau
	AMULET,   # Amulette
	BADGE     # Badge
}

class Item:
	var id: String
	var name: String
	var type: ItemType
	var tier: ItemTier
	var stats: Dictionary = {}
	var description: String = ""
	var icon_path: String = ""
	
	func _init(item_id: String, item_name: String, item_type: ItemType, item_tier: ItemTier):
		id = item_id
		name = item_name
		type = item_type
		tier = item_tier
		_generate_stats()
		_generate_description()
	
	func _generate_stats():
		# Générer des stats aléatoires selon le tier
		match tier:
			ItemTier.TIER_1:
				stats = _generate_tier_1_stats()
			ItemTier.TIER_2:
				stats = _generate_tier_2_stats()
			ItemTier.TIER_3:
				stats = _generate_tier_3_stats()
			ItemTier.TIER_4:
				stats = _generate_tier_4_stats()
			ItemTier.TIER_5:
				stats = _generate_tier_5_stats()
	
	func _generate_tier_1_stats() -> Dictionary:
		var base_stats = {}
		match type:
			ItemType.HAT, ItemType.SHIRT, ItemType.BOOTS, ItemType.GLOVES:
				base_stats["inspiration_gain"] = randf_range(1.0, 3.0)
				base_stats["gold_gain"] = randf_range(0.5, 1.5)
			ItemType.BRUSH, ItemType.PALETTE:
				base_stats["painting_speed"] = randf_range(1.1, 1.3)
				base_stats["pixel_gain"] = randf_range(1.0, 2.0)
			ItemType.RING, ItemType.AMULET:
				base_stats["ascendancy_gain"] = randf_range(1.0, 2.0)
				base_stats["experience_gain"] = randf_range(1.1, 1.2)
			ItemType.BADGE:
				base_stats["special_effect"] = randf_range(1.0, 1.5)
		return base_stats
	
	func _generate_tier_2_stats() -> Dictionary:
		var base_stats = _generate_tier_1_stats()
		# Améliorer les stats de 50-100%
		for stat in base_stats.keys():
			base_stats[stat] *= randf_range(1.5, 2.0)
		return base_stats
	
	func _generate_tier_3_stats() -> Dictionary:
		var base_stats = _generate_tier_1_stats()
		# Améliorer les stats de 100-200%
		for stat in base_stats.keys():
			base_stats[stat] *= randf_range(2.0, 3.0)
		return base_stats
	
	func _generate_tier_4_stats() -> Dictionary:
		var base_stats = _generate_tier_1_stats()
		# Améliorer les stats de 200-400%
		for stat in base_stats.keys():
			base_stats[stat] *= randf_range(3.0, 5.0)
		return base_stats
	
	func _generate_tier_5_stats() -> Dictionary:
		var base_stats = _generate_tier_1_stats()
		# Améliorer les stats de 400-800%
		for stat in base_stats.keys():
			base_stats[stat] *= randf_range(5.0, 9.0)
		return base_stats
	
	func _generate_description():
		var tier_names = ["Normal", "Magic", "Rare", "Epic", "Legendary"]
		var tier_colors = ["#FFFFFF", "#00FF00", "#0080FF", "#8000FF", "#FF8000"]
		
		description = "[color=%s]%s %s[/color]\n" % [tier_colors[tier], tier_names[tier], name]
		
		for stat_name in stats.keys():
			var stat_value = stats[stat_name]
			var stat_display = _format_stat_name(stat_name)
			description += "%s: +%.1f%%\n" % [stat_display, (stat_value - 1.0) * 100]
	
	func _format_stat_name(stat: String) -> String:
		match stat:
			"inspiration_gain": return "Gain d'inspiration"
			"gold_gain": return "Gain d'or"
			"painting_speed": return "Vitesse de peinture"
			"pixel_gain": return "Gain de pixels"
			"ascendancy_gain": return "Gain d'ascension"
			"experience_gain": return "Gain d'expérience"
			"special_effect": return "Effet spécial"
			_: return stat

#==============================================================================
# Inventory State
#==============================================================================
var equipped_items: Dictionary = {}
var inventory_items: Array[Item] = []

# Slots d'équipement disponibles
var equipment_slots = {
	"hat": ItemType.HAT,
	"shirt": ItemType.SHIRT,
	"boots": ItemType.BOOTS,
	"gloves": ItemType.GLOVES,
	"brush": ItemType.BRUSH,
	"palette": ItemType.PALETTE,
	"ring_1": ItemType.RING,
	"ring_2": ItemType.RING,
	"amulet": ItemType.AMULET,
	"badge_1": ItemType.BADGE,
	"badge_2": ItemType.BADGE
}

#==============================================================================
# Public API
#==============================================================================

## Ajoute un item à l'inventaire
func add_item(item: Item) -> void:
	inventory_items.append(item)
	inventory_changed.emit()
	GameState.logger.info("Item added to inventory: %s (%s)" % [item.name, _get_tier_name(item.tier)])

## Équipe un item
func equip_item(item: Item, slot: String) -> bool:
	if not equipment_slots.has(slot):
		GameState.logger.warning("Invalid equipment slot: %s" % slot)
		return false
	
	if equipment_slots[slot] != item.type:
		GameState.logger.warning("Item type %s doesn't match slot %s" % [item.type, slot])
		return false
	
	# Déséquiper l'item actuel s'il y en a un
	if equipped_items.has(slot):
		unequip_item(slot)
	
	# Équiper le nouvel item
	equipped_items[slot] = item
	item_equipped.emit(slot, item)
	
	# Appliquer les stats de l'item
	_apply_item_stats(item)
	
	GameState.logger.info("Item equipped: %s in slot %s" % [item.name, slot])
	return true

## Déséquipe un item
func unequip_item(slot: String) -> bool:
	if not equipped_items.has(slot):
		return false
	
	var item = equipped_items[slot]
	equipped_items.erase(slot)
	item_unequipped.emit(slot, item)
	
	# Retirer les stats de l'item
	_remove_item_stats(item)
	
	GameState.logger.info("Item unequipped: %s from slot %s" % [item.name, slot])
	return true

## Récupère l'item équipé dans un slot
func get_equipped_item(slot: String) -> Item:
	return equipped_items.get(slot, null)

## Récupère tous les items équipés
func get_all_equipped_items() -> Dictionary:
	return equipped_items.duplicate()

## Récupère tous les items de l'inventaire
func get_inventory_items() -> Array[Item]:
	return inventory_items.duplicate()

## Récupère les items d'un type spécifique
func get_items_by_type(item_type: ItemType) -> Array[Item]:
	var filtered_items = []
	for item in inventory_items:
		if item.type == item_type:
			filtered_items.append(item)
	return filtered_items

## Récupère les items d'un tier spécifique
func get_items_by_tier(tier: ItemTier) -> Array[Item]:
	var filtered_items = []
	for item in inventory_items:
		if item.tier == tier:
			filtered_items.append(item)
	return filtered_items

## Calcule les bonus totaux de tous les items équipés
func get_total_bonuses() -> Dictionary:
	var total_bonuses = {}
	
	for item in equipped_items.values():
		for stat_name in item.stats.keys():
			if not total_bonuses.has(stat_name):
				total_bonuses[stat_name] = 1.0
			total_bonuses[stat_name] *= item.stats[stat_name]
	
	# Log pour debug
	if total_bonuses.size() > 0:
		GameState.logger.debug("Total bonuses calculated: %s" % total_bonuses)
	
	return total_bonuses

## Réinitialise l'inventaire
func reset_inventory() -> void:
	equipped_items.clear()
	inventory_items.clear()
	inventory_changed.emit()
	GameState.logger.info("Inventory reset")

#==============================================================================
# Private Methods
#==============================================================================

func _apply_item_stats(item: Item) -> void:
	# Cette fonction sera appelée par les managers concernés
	# pour appliquer les stats des items
	pass

func _remove_item_stats(item: Item) -> void:
	# Cette fonction sera appelée par les managers concernés
	# pour retirer les stats des items
	pass

func _get_tier_name(tier: ItemTier) -> String:
	match tier:
		ItemTier.TIER_1: return "Normal"
		ItemTier.TIER_2: return "Magic"
		ItemTier.TIER_3: return "Rare"
		ItemTier.TIER_4: return "Epic"
		ItemTier.TIER_5: return "Legendary"
		_: return "Unknown"
