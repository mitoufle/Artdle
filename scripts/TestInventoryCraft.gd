extends Node
class_name TestInventoryCraft

## Script de test pour valider le système d'inventaire et de craft

#==============================================================================
# Test Configuration
#==============================================================================
var test_gold_amount: int = 10000
var test_items_to_create: int = 5

#==============================================================================
# Test Methods
#==============================================================================

## Test complet du système d'inventaire et de craft
func run_all_tests() -> void:
	print("🧪 === DÉBUT DES TESTS INVENTAIRE + CRAFT ===")
	
	# Donner de l'or pour les tests
	GameState.currency_manager.set_currency("gold", test_gold_amount)
	print("💰 Or donné pour les tests: %d" % test_gold_amount)
	
	# Test 1: Créer des items de test
	_test_create_test_items()
	
	# Test 2: Tester l'équipement
	_test_equipment_system()
	
	# Test 3: Tester le craft
	_test_craft_system()
	
	# Test 4: Tester l'amélioration d'atelier
	_test_workshop_upgrade()
	
	# Test 5: Tester les stats d'équipement
	_test_equipment_stats()
	
	print("✅ === TOUS LES TESTS TERMINÉS ===")

## Test 1: Créer des items de test
func _test_create_test_items() -> void:
	print("\n🔧 Test 1: Création d'items de test")
	
	# Créer des items de différents types et tiers
	var item_types = [
		InventoryManager.ItemType.HAT,
		InventoryManager.ItemType.SHIRT,
		InventoryManager.ItemType.BRUSH,
		InventoryManager.ItemType.RING,
		InventoryManager.ItemType.BADGE
	]
	
	var tiers = [
		InventoryManager.ItemTier.TIER_1,
		InventoryManager.ItemTier.TIER_2,
		InventoryManager.ItemTier.TIER_3
	]
	
	for item_type in item_types:
		for tier in tiers:
			var item = InventoryManager.Item.new(
				"test_%s_%d" % [item_type, tier],
				"Test %s" % item_type,
				item_type,
				tier
			)
			GameState.inventory_manager.add_item(item)
			print("  ✅ Item créé: %s (%s)" % [item.name, _get_tier_name(tier)])
	
	var total_items = GameState.inventory_manager.get_inventory_items().size()
	print("  📦 Total d'items en inventaire: %d" % total_items)

## Test 2: Tester l'équipement
func _test_equipment_system() -> void:
	print("\n👕 Test 2: Système d'équipement")
	
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	
	# Équiper quelques items
	var equipped_count = 0
	for item in inventory_items:
		if equipped_count >= 5:  # Limiter à 5 items équipés
			break
		
		var slot_name = _find_slot_for_item(item)
		if slot_name != "":
			var success = GameState.inventory_manager.equip_item(item, slot_name)
			if success:
				print("  ✅ Item équipé: %s dans %s" % [item.name, slot_name])
				equipped_count += 1
			else:
				print("  ❌ Échec équipement: %s" % item.name)
	
	print("  👕 Items équipés: %d" % equipped_count)

## Test 3: Tester le craft
func _test_craft_system() -> void:
	print("\n🔨 Test 3: Système de craft")
	
	# Tester le craft d'un chapeau
	var hat_type = InventoryManager.ItemType.HAT
	var cost = GameState.craft_manager.get_craft_cost(hat_type)
	var duration = GameState.craft_manager.get_craft_duration(hat_type)
	
	print("  💰 Coût du craft chapeau: %d gold" % cost)
	print("  ⏱️ Durée du craft: %.1f secondes" % duration)
	
	# Démarrer le craft
	var success = GameState.craft_manager.start_craft(hat_type, 1)
	if success:
		print("  ✅ Craft démarré avec succès")
		
		# Simuler le progrès du craft
		var start_time = Time.get_ticks_msec()
		while GameState.craft_manager.is_crafting():
			GameState.craft_manager.update_craft_progress(0.016)  # 60 FPS
			await get_tree().process_frame
			
			var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
			if elapsed > 5.0:  # Timeout après 5 secondes
				print("  ⚠️ Timeout du craft")
				break
		
		print("  🎉 Craft terminé!")
	else:
		print("  ❌ Échec du démarrage du craft")

## Test 4: Tester l'amélioration d'atelier
func _test_workshop_upgrade() -> void:
	print("\n🏭 Test 4: Amélioration d'atelier")
	
	var current_level = GameState.craft_manager.get_workshop_level()
	var upgrade_cost = GameState.craft_manager.get_workshop_upgrade_cost()
	
	print("  📊 Niveau actuel: %d" % current_level)
	print("  💰 Coût d'amélioration: %d gold" % upgrade_cost)
	
	# Améliorer l'atelier
	var success = GameState.craft_manager.upgrade_workshop()
	if success:
		var new_level = GameState.craft_manager.get_workshop_level()
		print("  ✅ Atelier amélioré niveau %d!" % new_level)
		
		# Afficher les nouvelles chances de tiers
		var tier_chances = GameState.craft_manager.get_tier_chances()
		print("  🎲 Nouvelles chances de tiers:")
		for tier in tier_chances.keys():
			var chance = tier_chances[tier] * 100
			print("    %s: %.1f%%" % [_get_tier_name(tier), chance])
	else:
		print("  ❌ Échec de l'amélioration d'atelier")

## Test 5: Tester les stats d'équipement
func _test_equipment_stats() -> void:
	print("\n📊 Test 5: Stats d'équipement")
	
	var total_bonuses = GameState.inventory_manager.get_total_bonuses()
	
	if total_bonuses.size() > 0:
		print("  📈 Bonus totaux d'équipement:")
		for stat_name in total_bonuses.keys():
			var stat_value = total_bonuses[stat_name]
			var bonus_percent = (stat_value - 1.0) * 100
			print("    %s: +%.1f%%" % [_format_stat_name(stat_name), bonus_percent])
	else:
		print("  ℹ️ Aucun équipement, pas de bonus")

#==============================================================================
# Helper Methods
#==============================================================================

func _find_slot_for_item(item: InventoryManager.Item) -> String:
	var equipment_slots = GameState.inventory_manager.equipment_slots
	
	# Pour les anneaux, chercher un slot libre
	if item.type == InventoryManager.ItemType.RING:
		if not GameState.inventory_manager.get_equipped_item("ring_1"):
			return "ring_1"
		elif not GameState.inventory_manager.get_equipped_item("ring_2"):
			return "ring_2"
		else:
			return ""
	
	# Pour les badges, chercher un slot libre
	if item.type == InventoryManager.ItemType.BADGE:
		if not GameState.inventory_manager.get_equipped_item("badge_1"):
			return "badge_1"
		elif not GameState.inventory_manager.get_equipped_item("badge_2"):
			return "badge_2"
		else:
			return ""
	
	# Pour les autres types, chercher le slot correspondant
	for slot_name in equipment_slots.keys():
		if equipment_slots[slot_name] == item.type:
			return slot_name
	
	return ""

func _get_tier_name(tier: InventoryManager.ItemTier) -> String:
	match tier:
		InventoryManager.ItemTier.TIER_1: return "Normal"
		InventoryManager.ItemTier.TIER_2: return "Magic"
		InventoryManager.ItemTier.TIER_3: return "Rare"
		InventoryManager.ItemTier.TIER_4: return "Epic"
		InventoryManager.ItemTier.TIER_5: return "Legendary"
		_: return "Unknown"

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
