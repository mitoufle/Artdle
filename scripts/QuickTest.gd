extends Node

## Script de test rapide pour valider l'intégration inventaire/craft

func _ready():
	print("🧪 === TEST RAPIDE INVENTAIRE + CRAFT ===")
	
	# Attendre que GameState soit prêt
	await get_tree().process_frame
	
	# Donner des ressources
	GameState.currency_manager.set_currency("gold", 1000)
	GameState.currency_manager.set_currency("inspiration", 5000)
	print("💰 Ressources données")
	
	# Test 1: Créer un item
	print("\n🔧 Test création d'item...")
	var item = InventoryManager.Item.new(
		"test_hat_1",
		"Chapeau de Test",
		InventoryManager.ItemType.HAT,
		InventoryManager.ItemTier.TIER_2
	)
	GameState.inventory_manager.add_item(item)
	print("✅ Item créé: %s" % item.name)
	
	# Test 2: Équiper l'item
	print("\n👕 Test équipement...")
	var success = GameState.inventory_manager.equip_item(item, "hat")
	if success:
		print("✅ Item équipé avec succès")
		
		# Afficher les bonus
		var bonuses = GameState.inventory_manager.get_total_bonuses()
		if bonuses.size() > 0:
			print("📈 Bonus appliqués:")
			for stat in bonuses.keys():
				var value = bonuses[stat]
				var percent = (value - 1.0) * 100
				print("  %s: +%.1f%%" % [stat, percent])
	else:
		print("❌ Échec de l'équipement")
	
	# Test 3: Craft d'un item
	print("\n🔨 Test craft...")
	var craft_cost = GameState.craft_manager.get_craft_cost(InventoryManager.ItemType.BRUSH)
	print("💰 Coût du craft: %d gold" % craft_cost)
	
	if GameState.currency_manager.has_enough("gold", craft_cost):
		var craft_success = GameState.craft_manager.start_craft(InventoryManager.ItemType.BRUSH, 1)
		if craft_success:
			print("✅ Craft démarré!")
			
			# Simuler la progression
			for i in range(5):
				GameState.craft_manager.update_craft_progress(0.2)  # 20% par frame
				await get_tree().process_frame
			
			var progress = GameState.craft_manager.get_craft_progress()
			print("📊 Progression: %.1f%%" % (progress * 100))
		else:
			print("❌ Échec du démarrage du craft")
	else:
		print("❌ Pas assez d'or pour le craft")
	
	# Test 4: Vérifier l'inventaire final
	print("\n📦 Inventaire final:")
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	print("  Items en inventaire: %d" % inventory_items.size())
	
	var equipped_items = GameState.inventory_manager.get_all_equipped_items()
	print("  Items équipés: %d" % equipped_items.size())
	
	print("\n✅ === TEST TERMINÉ ===")
	
	# Se supprimer après le test
	queue_free()
