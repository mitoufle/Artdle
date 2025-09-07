extends Node

## Test du système de bonus d'équipement

func _ready():
	print("🎯 TEST BONUS SYSTEM")
	_test_bonus_system()
	print("✅ Test terminé")

func _test_bonus_system():
	print("\n=== ÉTAPE 1: Test sans équipement ===")
	
	# Test d'un clic sans équipement
	var initial_inspiration = GameState.currency_manager.get_currency("inspiration")
	var result = GameState.clicker_manager.manual_click()
	var final_inspiration = GameState.currency_manager.get_currency("inspiration")
	var actual_gain = final_inspiration - initial_inspiration
	print("Clic sans équipement: gain = %s" % actual_gain)
	
	print("\n=== ÉTAPE 2: Création et équipement d'un item ===")
	
	# Créer un item avec bonus
	var item = InventoryManager.Item.new(
		"test_hat_001",
		"Test Hat",
		InventoryManager.ItemType.HAT,
		InventoryManager.ItemTier.TIER_1
	)
	
	# Ajouter des bonus
	item.stats["inspiration_generation"] = 2.0
	item.stats["coin_generation"] = 3.0
	item.stats["generation_bonus"] = 1.5
	
	print("Item créé: %s" % item.name)
	print("Stats: %s" % item.stats)
	
	# Équiper l'item
	var equip_success = GameState.inventory_manager.equip_item(item, "hat")
	if not equip_success:
		print("❌ ÉCHEC: Impossible d'équiper l'item")
		return
	
	print("✅ Item équipé avec succès")
	
	print("\n=== ÉTAPE 3: Test des bonus calculés ===")
	
	# Vérifier les bonus totaux
	var total_bonuses = GameState.inventory_manager.get_total_bonuses()
	print("Bonus totaux: %s" % total_bonuses)
	
	# Tester l'application des bonus
	var base_amount = 1.0
	var bonus_amount = GameState.apply_currency_bonus("inspiration", base_amount)
	print("Test de bonus inspiration: %.1f -> %.1f" % [base_amount, bonus_amount])
	
	print("\n=== ÉTAPE 4: Test d'un clic avec équipement ===")
	
	# Test d'un clic avec équipement
	var initial_inspiration2 = GameState.currency_manager.get_currency("inspiration")
	var result2 = GameState.clicker_manager.manual_click()
	var final_inspiration2 = GameState.currency_manager.get_currency("inspiration")
	var actual_gain2 = final_inspiration2 - initial_inspiration2
	print("Clic avec équipement: gain = %s" % actual_gain2)
	
	# Vérifier que le gain correspond au bonus
	var expected_gain = 1.0 * 2.0 * 1.5  # click_power * inspiration_generation * generation_bonus
	print("Gain attendu: %s" % expected_gain)
	
	if abs(actual_gain2 - expected_gain) < 0.01:
		print("✅ SUCCÈS: Bonus correctement appliqué!")
	else:
		print("❌ ÉCHEC: Bonus non appliqué")
		print("  Différence: %s" % abs(actual_gain2 - expected_gain))
	
	# Vérifier que l'expérience gagnée = inspiration gagnée
	var experience_gained = result2.get("experience_gained", 0)
	print("Expérience gagnée: %s (devrait être égale à l'inspiration)" % experience_gained)
	
	if abs(experience_gained - actual_gain2) < 0.01:
		print("✅ SUCCÈS: Expérience = Inspiration!")
	else:
		print("❌ ÉCHEC: Expérience ≠ Inspiration")
		print("  Différence: %s" % abs(experience_gained - actual_gain2))
	
	print("\n=== ÉTAPE 5: Test de la vente de canvas ===")
	
	# Créer un canvas complet
	GameState.canvas_manager._initialize_new_canvas()
	GameState.canvas_manager.current_pixel_count = GameState.canvas_manager.max_pixels
	print("Canvas créé: %d/%d pixels" % [GameState.canvas_manager.current_pixel_count, GameState.canvas_manager.max_pixels])
	
	# Tester la vente
	var canvas_result = GameState.sell_canvas()
	print("Résultat de la vente: %s" % canvas_result)
	
	# Vérifier que les gains sont bonifiés
	var expected_gold = 1000 * 3.0 * 1.5  # sell_price * coin_generation * generation_bonus
	var expected_fame = 10 * 3.0 * 1.5   # fame * coin_generation * generation_bonus
	print("Or attendu: %d, Or reçu: %d" % [expected_gold, canvas_result.get("gold_gained", 0)])
	print("Renommée attendue: %d, Renommée reçue: %d" % [expected_fame, canvas_result.get("fame_gained", 0)])
	
	print("\n=== ÉTAPE 6: Test de la renommée par niveau ===")
	
	# Vérifier la renommée actuelle
	var current_fame = GameState.currency_manager.get_currency("fame")
	var current_level = GameState.experience_manager.get_level()
	print("Niveau actuel: %d, Renommée actuelle: %s" % [current_level, current_fame])
	
	# Ajouter assez d'expérience pour monter de niveau
	var exp_needed = GameState.experience_manager.get_experience_to_next_level()
	print("Expérience nécessaire pour le niveau suivant: %s" % exp_needed)
	
	# Ajouter l'expérience nécessaire + un peu plus
	GameState.add_experience(exp_needed + 1)
	
	var new_level = GameState.experience_manager.get_level()
	var new_fame = GameState.currency_manager.get_currency("fame")
	var fame_gained = new_fame - current_fame
	print("Nouveau niveau: %d, Nouvelle renommée: %s" % [new_level, new_fame])
	print("Renommée gagnée: %s (devrait être 1 par niveau)" % fame_gained)
	
	if fame_gained >= 1.0:
		print("✅ SUCCÈS: Renommée gagnée par niveau!")
	else:
		print("❌ ÉCHEC: Pas de renommée gagnée")
	
	print("\n=== ÉTAPE 7: Test des probabilités de tiers ===")
	
	# Tester les probabilités de tiers à différents niveaux
	for level in [1, 5, 10, 20]:
		GameState.craft_manager.workshop_level = level
		var chances = GameState.craft_manager.get_tier_chances()
		print("Niveau %d: %s" % [level, chances])
	
	print("\n=== ÉTAPE 8: Nettoyage ===")
	
	# Déséquiper l'item
	GameState.inventory_manager.unequip_item("hat")
	print("Item déséquipé")
	
	# Test final sans équipement
	var final_result = GameState.clicker_manager.manual_click()
	var final_inspiration3 = GameState.currency_manager.get_currency("inspiration")
	var final_gain = final_inspiration3 - final_inspiration2
	print("Clic final sans équipement: gain = %s" % final_gain)
