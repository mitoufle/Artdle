extends Node

## Test complet du système inventaire + craft + vente

func _ready():
	print("🧪 === TEST COMPLET SYSTÈME INVENTAIRE + CRAFT + VENTE ===")
	
	# Attendre que GameState soit prêt
	await get_tree().process_frame
	
	# Donner des ressources
	GameState.currency_manager.set_currency("gold", 2000)
	GameState.currency_manager.set_currency("inspiration", 5000)
	GameState.currency_manager.set_currency("fame", 100)
	print("💰 Ressources données")
	
	# Test 1: Créer des items de test
	print("\n🔧 Test création d'items...")
	_create_test_items()
	
	# Test 2: Tester l'équipement
	print("\n👕 Test équipement...")
	_test_equipment()
	
	# Test 3: Tester le craft
	print("\n🔨 Test craft...")
	await _test_craft()
	
	# Test 4: Tester la vente
	print("\n💰 Test vente d'items...")
	_test_selling()
	
	# Test 5: Afficher les stats finales
	print("\n📊 Stats finales...")
	_show_final_stats()
	
	print("\n✅ === TEST COMPLET TERMINÉ ===")
	queue_free()

func _create_test_items():
	# Créer des items de différents tiers
	var test_items = [
		{"type": InventoryManager.ItemType.HAT, "tier": InventoryManager.ItemTier.TIER_1},
		{"type": InventoryManager.ItemType.BRUSH, "tier": InventoryManager.ItemTier.TIER_2},
		{"type": InventoryManager.ItemType.RING, "tier": InventoryManager.ItemTier.TIER_3},
		{"type": InventoryManager.ItemType.BADGE, "tier": InventoryManager.ItemTier.TIER_1}
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

func _test_equipment():
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
				var bonuses = GameState.inventory_manager.get_total_bonuses()
				if bonuses.size() > 0:
					print("  📈 Bonus appliqués:")
					for stat in bonuses.keys():
						var value = bonuses[stat]
						var percent = (value - 1.0) * 100
						print("    %s: +%.1f%%" % [stat, percent])
			else:
				print("  ❌ Échec de l'équipement")
		else:
			print("  ⚠️ Aucun slot disponible")

func _test_craft():
	var craft_cost = GameState.craft_manager.get_craft_cost(InventoryManager.ItemType.BRUSH)
	print("  💰 Coût du craft: %d gold" % craft_cost)
	
	if GameState.currency_manager.has_enough("gold", craft_cost):
		var craft_success = GameState.craft_manager.start_craft(InventoryManager.ItemType.BRUSH, 1)
		if craft_success:
			print("  ✅ Craft démarré!")
			
			# Simuler la progression
			for i in range(10):
				GameState.craft_manager.update_craft_progress(0.1)  # 10% par frame
				await get_tree().process_frame
			
			var progress = GameState.craft_manager.get_craft_progress()
			print("  📊 Progression: %.1f%%" % (progress * 100))
		else:
			print("  ❌ Échec du démarrage du craft")
	else:
		print("  ❌ Pas assez d'or pour le craft")

func _test_selling():
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	
	if inventory_items.size() > 0:
		var item = inventory_items[0]
		var initial_fame = GameState.currency_manager.get_currency("fame")
		var initial_xp = GameState.experience_manager.get_experience()
		
		print("  📊 Avant vente - Renommée: %.1f, XP: %.1f" % [initial_fame, initial_xp])
		
		# Calculer le prix de vente
		var sell_price = _calculate_sell_price(item)
		print("  💰 Prix de vente: %d renommée, %d XP" % [sell_price.fame, sell_price.experience])
		
		# Vendre l'item
		GameState.inventory_manager.inventory_items.erase(item)
		GameState.currency_manager.add_currency("fame", sell_price.fame)
		GameState.experience_manager.add_experience(sell_price.experience)
		
		var final_fame = GameState.currency_manager.get_currency("fame")
		var final_xp = GameState.experience_manager.get_experience()
		
		print("  ✅ Item vendu: %s" % item.name)
		print("  📊 Après vente - Renommée: %.1f, XP: %.1f" % [final_fame, final_xp])
	else:
		print("  ℹ️ Aucun item à vendre")

func _show_final_stats():
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	var equipped_items = GameState.inventory_manager.get_all_equipped_items()
	var fame = GameState.currency_manager.get_currency("fame")
	var xp = GameState.experience_manager.get_experience()
	var level = GameState.experience_manager.get_level()
	
	print("  📦 Items en inventaire: %d" % inventory_items.size())
	print("  👕 Items équipés: %d" % equipped_items.size())
	print("  🌟 Renommée: %.1f" % fame)
	print("  ⭐ XP: %.1f (Niveau %d)" % [xp, level])

# Helper methods
func _find_slot_for_item(item: InventoryManager.Item) -> String:
	var equipment_slots = GameState.inventory_manager.equipment_slots
	
	if item.type == InventoryManager.ItemType.RING:
		if not GameState.inventory_manager.get_equipped_item("ring_1"):
			return "ring_1"
		elif not GameState.inventory_manager.get_equipped_item("ring_2"):
			return "ring_2"
		else:
			return ""
	
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

func _calculate_sell_price(item: InventoryManager.Item) -> Dictionary:
	var base_fame = 0
	var base_experience = 0
	
	match item.tier:
		InventoryManager.ItemTier.TIER_1:
			base_fame = 10
			base_experience = 5
		InventoryManager.ItemTier.TIER_2:
			base_fame = 25
			base_experience = 12
		InventoryManager.ItemTier.TIER_3:
			base_fame = 50
			base_experience = 25
		InventoryManager.ItemTier.TIER_4:
			base_fame = 100
			base_experience = 50
		InventoryManager.ItemTier.TIER_5:
			base_fame = 200
			base_experience = 100
	
	var type_multiplier = 1.0
	match item.type:
		InventoryManager.ItemType.BRUSH, InventoryManager.ItemType.PALETTE:
			type_multiplier = 1.5
		InventoryManager.ItemType.RING, InventoryManager.ItemType.AMULET:
			type_multiplier = 1.3
		InventoryManager.ItemType.BADGE:
			type_multiplier = 2.0
	
	return {
		"fame": int(base_fame * type_multiplier),
		"experience": int(base_experience * type_multiplier)
	}
