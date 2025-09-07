extends Node

## Test de persistance de la sauvegarde
## Vérifie que les données sont bien sauvegardées et rechargées

func _ready():
	print("=== TEST DE PERSISTANCE DE SAUVEGARDE ===")
	print("Appuyez sur 8 pour exécuter le test de persistance")
	print("1: Sauvegarder | 2: Charger | 3: Supprimer | 4: Infos | 8: Test Persistance")

func test_save_persistence():
	print("\n1. Configuration des données de test...")
	
	# Ajouter des données de test
	GameState.currency_manager.add_currency("inspiration", 1000)
	GameState.currency_manager.add_currency("gold", 500)
	GameState.experience_manager.add_experience(50)
	
	print("   Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
	print("   Gold: %s" % GameState.currency_manager.get_currency("gold"))
	print("   Experience: %s" % GameState.experience_manager.get_experience())
	print("   Level: %s" % GameState.experience_manager.get_level())
	
	print("\n2. Sauvegarde des données...")
	var save_success = GameState.save_game()
	
	if save_success:
		print("   ✅ Sauvegarde réussie")
	else:
		print("   ❌ Échec de la sauvegarde")
		return
	
	print("\n3. Modification des données pour tester le chargement...")
	
	# Modifier les données
	GameState.currency_manager.set_currency("inspiration", 0)
	GameState.currency_manager.set_currency("gold", 0)
	GameState.experience_manager.set_experience(0)
	
	print("   Après modification:")
	print("   Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
	print("   Gold: %s" % GameState.currency_manager.get_currency("gold"))
	print("   Experience: %s" % GameState.experience_manager.get_experience())
	
	print("\n4. Chargement de la sauvegarde...")
	var load_success = GameState.load_game()
	
	if load_success:
		print("   ✅ Chargement réussi")
	else:
		print("   ❌ Échec du chargement")
		return
	
	print("\n5. Vérification des données rechargées...")
	print("   Inspiration: %s" % GameState.currency_manager.get_currency("inspiration"))
	print("   Gold: %s" % GameState.currency_manager.get_currency("gold"))
	print("   Experience: %s" % GameState.experience_manager.get_experience())
	print("   Level: %s" % GameState.experience_manager.get_level())
	
	# Vérifier que les données sont correctes
	var inspiration_ok = GameState.currency_manager.get_currency("inspiration") == 1000
	var gold_ok = GameState.currency_manager.get_currency("gold") == 500
	var experience_ok = GameState.experience_manager.get_experience() == 50
	
	if inspiration_ok and gold_ok and experience_ok:
		print("\n✅ TEST DE PERSISTANCE RÉUSSI !")
		print("   Les données sont correctement sauvegardées et rechargées.")
	else:
		print("\n❌ TEST DE PERSISTANCE ÉCHOUÉ !")
		print("   Les données ne correspondent pas aux valeurs attendues.")
	
	print("\n6. Test de persistance après redémarrage...")
	print("   Fermez et relancez le jeu pour tester la persistance complète.")
	print("   Les données devraient être automatiquement chargées au démarrage.")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_8:
				print("=== TEST RAPIDE DE PERSISTANCE ===")
				await test_save_persistence()
