extends Node
class_name TestPaintingIntegration

## Script de test pour valider l'intégration inventaire/craft dans PaintingView

#==============================================================================
# Test Methods
#==============================================================================

## Test rapide de l'intégration
func run_quick_test() -> void:
	print("🧪 === TEST INTÉGRATION PAINTING VIEW ===")
	
	# Donner des ressources pour les tests
	GameState.currency_manager.set_currency("gold", 5000)
	GameState.currency_manager.set_currency("inspiration", 10000)
	print("💰 Ressources données pour les tests")
	
	# Test 1: Créer quelques items de test
	_create_test_items()
	
	# Test 2: Tester le craft
	_test_craft_system()
	
	# Test 3: Tester l'équipement
	_test_equipment_system()
	
	# Test 4: Tester l'expérience du craft
	_test_craft_experience()
	
	print("✅ === TEST TERMINÉ ===")

## Créer des items de test
func _create_test_items() -> void:
	print("\n🔧 Création d'items de test")
	
	# Créer quelques items de différents types
	var test_items = [
		{"type": InventoryManager.ItemType.HAT, "tier": InventoryManager.ItemTier.TIER_1},
		{"type": InventoryManager.ItemType.BRUSH, "tier": InventoryManager.ItemTier.TIER_2},
		{"type": InventoryManager.ItemType.RING, "tier": InventoryManager.ItemTier.TIER_1}
	]
	
	for item_data in test_items:
		var item = InventoryManager.Item.new(
			"test_%s_%d" % [item_data.type, item_data.tier],
			"Test %s" % item_data.type,
			item_data.type,
			item_data.tier
		)
		GameState.inventory_manager.add_item(item)
		print("  ✅ Item créé: %s (%s)" % [item.name, _get_tier_name(item_data.tier)])

## Tester le système de craft
func _test_craft_system() -> void:
	print("\n🔨 Test du système de craft")
	
	# Tester le craft d'un chapeau
	var hat_type = InventoryManager.ItemType.HAT
	var cost = GameState.craft_manager.get_craft_cost(hat_type)
	var duration = GameState.craft_manager.get_craft_duration(hat_type)
	
	print("  💰 Coût: %d gold" % cost)
	print("  ⏱️ Durée: %.1f secondes" % duration)
	
	# Démarrer le craft
	var success = GameState.craft_manager.start_craft(hat_type, 1)
	if success:
		print("  ✅ Craft démarré!")
		
		# Simuler quelques frames de progression
		for i in range(10):
			GameState.craft_manager.update_craft_progress(0.1)  # 10% par frame
			await get_tree().process_frame
		
		var progress = GameState.craft_manager.get_craft_progress()
		print("  📊 Progression: %.1f%%" % (progress * 100))
	else:
		print("  ❌ Échec du démarrage du craft")

## Tester le système d'équipement
func _test_equipment_system() -> void:
	print("\n👕 Test du système d'équipement")
	
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	
	# Équiper le premier item disponible
	if inventory_items.size() > 0:
		var item = inventory_items[0]
		var slot_name = _find_slot_for_item(item)
		
		if slot_name != "":
			var success = GameState.inventory_manager.equip_item(item, slot_name)
			if success:
				print("  ✅ Item équipé: %s dans %s" % [item.name, slot_name])
				
				# Afficher les bonus
				var total_bonuses = GameState.inventory_manager.get_total_bonuses()
				if total_bonuses.size() > 0:
					print("  📈 Bonus appliqués:")
					for stat_name in total_bonuses.keys():
						var stat_value = total_bonuses[stat_name]
						var bonus_percent = (stat_value - 1.0) * 100
						print("    %s: +%.1f%%" % [_format_stat_name(stat_name), bonus_percent])
			else:
				print("  ❌ Échec de l'équipement")
		else:
			print("  ⚠️ Aucun slot disponible pour cet item")
	else:
		print("  ℹ️ Aucun item en inventaire")

## Tester l'expérience du craft
func _test_craft_experience() -> void:
	print("\n⭐ Test de l'expérience du craft")
	
	var initial_xp = GameState.experience_manager.get_experience()
	var initial_level = GameState.experience_manager.get_level()
	
	print("  📊 XP initial: %.1f (Niveau %d)" % [initial_xp, initial_level])
	
	# Créer un item de test pour simuler un craft
	var item = InventoryManager.Item.new(
		"test_craft_xp",
		"Test Craft XP",
		InventoryManager.ItemType.HAT,
		InventoryManager.ItemTier.TIER_2
	)
	
	# Simuler l'événement de craft terminé
	var xp_gained = 10 + (item.tier * 5)  # Même calcul que dans PaintingView
	GameState.experience_manager.add_experience(xp_gained)
	
	var final_xp = GameState.experience_manager.get_experience()
	var final_level = GameState.experience_manager.get_level()
	
	print("  ✅ XP gagné: %d" % xp_gained)
	print("  📊 XP final: %.1f (Niveau %d)" % [final_xp, final_level])
	
	if final_level > initial_level:
		print("  🎉 Niveau augmenté!")

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
