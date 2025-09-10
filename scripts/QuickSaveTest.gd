extends Node

## Test rapide du système de sauvegarde
## Utilise les touches F5-F8 pour tester rapidement

var reset_confirmation_pending = false

func _ready():
	print("=== TEST RAPIDE DE SAUVEGARDE ===")
	print("1: Sauvegarder")
	print("2: Charger")
	print("3: Supprimer sauvegarde")
	print("4: Afficher infos sauvegarde")
	print("5: RESET COMPLET DU JEU")
	print("6: Donner points d'ascension")
	print("7: Test feedback")
	print("8: Test inventaire et craft")
	print("Ctrl+9: Activer Devotion (revenu passif)")
	print("0: Test avec données de test")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				test_save()
			KEY_2:
				test_load()
			KEY_3:
				test_clear()
			KEY_4:
				test_info()
			KEY_5:
				reset_game_completely()
			KEY_6:
				give_ascendancy_points()
			KEY_7:
				test_feedback()
			KEY_8:
				test_inventory_craft()
			KEY_9:
				if event.ctrl_pressed:
					activate_devotion()
			KEY_0:
				test_with_data()

func test_save():
	print("\n--- SAUVEGARDE ---")
	
	# Sauvegarder les données actuelles sans les modifier
	var success = GameState.save_game()
	
	if success:
		print("✅ Sauvegarde réussie")
		print("Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
		print("Gold: %s" % GameState.currency_manager.get_currency("gold"))
		print("Experience: %s" % GameState.experience_manager.get_experience())
		print("Level: %s" % GameState.experience_manager.get_level())
	else:
		print("❌ Échec de la sauvegarde")

func test_load():
	print("\n--- CHARGEMENT ---")
	
	var success = GameState.load_game()
	
	if success:
		print("✅ Chargement réussi")
		print("Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
		print("Gold: %s" % GameState.currency_manager.get_currency("gold"))
		print("Experience: %s" % GameState.experience_manager.get_experience())
		print("Level: %s" % GameState.experience_manager.get_level())
	else:
		print("❌ Échec du chargement")

func test_clear():
	print("\n--- SUPPRESSION ---")
	
	var success = GameState.clear_save()
	
	if success:
		print("✅ Suppression réussie")
	else:
		print("❌ Échec de la suppression")

func test_info():
	print("\n--- INFORMATIONS ---")
	
	var save_info = GameState.get_save_info()
	
	if save_info.has("success") and save_info.success:
		print("✅ Informations récupérées:")
		print("  Date: %s" % save_info.data.date)
		print("  Version: %s" % save_info.data.version)
		print("  Taille: %d bytes" % save_info.data.size)
		print("  Level: %s" % save_info.data.level)
		print("  Ascendancy Points: %s" % save_info.data.ascendancy_points)
	else:
		print("❌ Échec: %s" % save_info.get("message", "Impossible de récupérer les informations"))
		print("💡 Conseil: Sauvegardez d'abord avec F1")

func test_with_data():
	print("\n--- TEST AVEC DONNÉES ---")
	
	# Ajouter des données de test
	GameState.currency_manager.add_currency("inspiration", 100)
	GameState.currency_manager.add_currency("gold", 50)
	GameState.experience_manager.add_experience(25)
	
	print("Données ajoutées:")
	print("Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
	print("Gold: %s" % GameState.currency_manager.get_currency("gold"))
	print("Experience: %s" % GameState.experience_manager.get_experience())
	print("Level: %s" % GameState.experience_manager.get_level())
	
	# Sauvegarder
	var success = GameState.save_game()
	if success:
		print("✅ Sauvegarde avec données de test réussie")
	else:
		print("❌ Échec de la sauvegarde avec données de test")

func reset_game_completely():
	if not reset_confirmation_pending:
		print("\n--- RESET COMPLET DU JEU ---")
		print("⚠️  ATTENTION: Cette action va remettre le jeu à zéro !")
		print("Appuyez sur F5 à nouveau pour confirmer...")
		reset_confirmation_pending = true
		
		# Annuler la confirmation après 5 secondes
		await get_tree().create_timer(5.0).timeout
		if reset_confirmation_pending:
			print("❌ Reset annulé (timeout)")
			reset_confirmation_pending = false
		return
	
	# Confirmation reçue, procéder au reset
	print("🔄 Reset en cours...")
	reset_confirmation_pending = false
	
	# Reset de tous les managers
	GameState.currency_manager.reset_all_currencies()
	GameState.experience_manager.reset_experience()
	GameState.canvas_manager.reset_canvas()
	GameState.clicker_manager.reset_clicker()
	GameState.ascension_manager.reset_ascension()
	GameState.skill_tree_manager.reset_skills()
	GameState.passive_income_manager.reset_passive_income()
	
	# Supprimer la sauvegarde
	GameState.clear_save()
	
	# Forcer la mise à jour de l'UI
	GameState.experience_manager.emit_experience_changed()
	GameState.experience_manager.emit_level_changed()
	
	print("✅ Reset complet terminé !")
	print("Toutes les données ont été remises à zéro")
	print("La sauvegarde a été supprimée")

func give_ascendancy_points():
	print("\n--- POINTS D'ASCENSION ---")
	
	# Donner 50 points d'ascension pour tester
	GameState.currency_manager.add_currency("ascendancy_points", 50)
	
	var current_points = GameState.currency_manager.get_currency("ascendancy_points")
	print("✅ 50 points d'ascension ajoutés")
	print("Points d'ascension actuels: %d" % current_points)
	print("💡 Allez dans Ascendancy > Skill Tree pour acheter des compétences")

func test_feedback():
	print("\n--- TEST FEEDBACK ---")
	
	# Test différents types de feedback
	GameState.feedback_manager.show_feedback("Test feedback simple!", Color.WHITE)
	GameState.feedback_manager.show_feedback("Test feedback vert!", Color.GREEN)
	GameState.feedback_manager.show_feedback("Test feedback rouge!", Color.RED)
	
	# Test feedback de devise
	GameState.feedback_manager.show_currency_feedback(100, "inspiration")
	GameState.feedback_manager.show_currency_feedback(50, "gold")
	
	print("✅ Tests de feedback lancés")
	print("💡 Regardez l'écran pour voir les effets visuels")

func test_inventory_craft():
	print("\n--- TEST INVENTAIRE ET CRAFT ---")
	
	# Donner de l'or pour tester
	GameState.currency_manager.add_currency("gold", 1000)
	print("✅ 1000 gold ajouté")
	
	# Tester le craft d'un item
	var success = GameState.craft_manager.start_craft(InventoryManager.ItemType.HAT, 1)
	if success:
		print("✅ Craft de chapeau démarré!")
		print("💡 Allez dans l'atelier pour voir le progrès")
	else:
		print("❌ Impossible de démarrer le craft")
	
	# Afficher les informations de l'atelier
	var workshop_level = GameState.craft_manager.get_workshop_level()
	var upgrade_cost = GameState.craft_manager.get_upgrade_cost()
	var tier_chances = GameState.craft_manager.get_tier_chances()
	
	print("🏭 Niveau de l'atelier: %d" % workshop_level)
	print("💰 Coût d'amélioration: %d gold" % upgrade_cost)
	print("🎲 Chances de tiers:")
	for tier in tier_chances.keys():
		var tier_name = _get_tier_name(tier)
		var chance = tier_chances[tier] * 100
		print("  %s: %.1f%%" % [tier_name, chance])
	
	print("💡 Allez dans l'inventaire et l'atelier pour tester!")

func _get_tier_name(tier: InventoryManager.ItemTier) -> String:
	match tier:
		InventoryManager.ItemTier.TIER_1: return "Normal"
		InventoryManager.ItemTier.TIER_2: return "Magic"
		InventoryManager.ItemTier.TIER_3: return "Rare"
		InventoryManager.ItemTier.TIER_4: return "Epic"
		InventoryManager.ItemTier.TIER_5: return "Legendary"
		_: return "Unknown"

func activate_devotion():
	print("\n--- ACTIVATION DEVOTION ---")
	
	# Acheter le skill Devotion
	var success = GameState.skill_tree_manager.buy_skill("Devotion")
	if success:
		var level = GameState.skill_tree_manager.get_skill_level("Devotion")
		print("✅ Devotion niveau %d activé!" % level)
		
		# Vérifier le niveau maximum
		if level >= 5:
			print("🎯 Niveau maximum atteint! (5/5)")
		
		# Afficher les effets selon le niveau (avec évolution dynamique)
		var player_level = GameState.experience_manager.get_level()
		var base_amount = 1.0
		var base_interval = 0.5  # Changé de 5.0 à 0.5 (2 fois par seconde)
		
		# Calculer les effets actuels
		if level >= 2:
			base_amount *= player_level
		if level >= 3:
			base_interval = max(0.05, 0.5 - (player_level * 0.02))  # Scaling plus rapide
		if level >= 4:
			base_amount *= 2.0
		
		match level:
			1:
				print("Effet: 1 inspiration toutes les 0.5 secondes (2/s)")
			2:
				print("Effet: %d inspiration toutes les 0.5 secondes (ÉVOLUE avec votre niveau!)" % int(base_amount))
			3:
				print("Effet: %d inspiration toutes les %.2f secondes (rythme ÉVOLUTIF!)" % [int(base_amount), base_interval])
			4:
				print("Effet: %d inspiration toutes les %.2f secondes (gain doublé + ÉVOLUTIF!)" % [int(base_amount), base_interval])
			5:
				print("Effet: %d inspiration toutes les %.2f secondes + 0.1%% conservée à l'ascension (ÉVOLUTIF!)" % [int(base_amount), base_interval])
		
		print("💡 Le revenu passif s'améliore automatiquement quand vous montez de niveau!")
		print("💡 Regardez les tooltips dans l'écran skill tree pour voir les effets détaillés!")
	else:
		var current_level = GameState.skill_tree_manager.get_skill_level("Devotion")
		if current_level >= 5:
			print("❌ Devotion niveau maximum atteint! (5/5)")
		else:
			print("❌ Impossible d'acheter Devotion")
			print("Points d'ascension nécessaires: %d" % GameState.skill_tree_manager.get_skill_cost("Devotion"))
