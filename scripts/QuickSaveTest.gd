extends Node

## Test rapide du système de sauvegarde
## Utilise les touches F5-F8 pour tester rapidement

var reset_confirmation_pending = false

func _ready():
	print("=== TEST RAPIDE DE SAUVEGARDE ===")
	print("F1: Sauvegarder")
	print("F2: Charger")
	print("F3: Supprimer sauvegarde")
	print("F4: Afficher infos sauvegarde")
	print("F5: RESET COMPLET DU JEU")
	print("F10: Test avec données de test")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				test_save()
			KEY_F2:
				test_load()
			KEY_F3:
				test_clear()
			KEY_F4:
				test_info()
			KEY_F5:
				reset_game_completely()
			KEY_F10:
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
	
	# Supprimer la sauvegarde
	GameState.clear_save()
	
	# Forcer la mise à jour de l'UI
	GameState.experience_manager.emit_experience_changed()
	GameState.experience_manager.emit_level_changed()
	
	print("✅ Reset complet terminé !")
	print("Toutes les données ont été remises à zéro")
	print("La sauvegarde a été supprimée")
