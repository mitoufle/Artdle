extends Node

## Script de test pour le système de sauvegarde
## Teste toutes les fonctionnalités de sauvegarde et de chargement

#==============================================================================
# Test Configuration
#==============================================================================
const TEST_SAVE_FILE = "test_save.json"

#==============================================================================
# Test Data
#==============================================================================
var test_data = {
	"currencies": {
		"inspiration": 1000.0,
		"gold": 500.0,
		"fame": 100.0,
		"ascendancy_points": 5.0,
		"paint_mastery": 50.0
	},
	"experience": {
		"experience": 250.0,
		"level": 3,
		"experience_to_next_level": 500.0
	},
	"canvas": {
		"resolution_level": 2,
		"fill_speed_level": 3,
		"sell_price": 15,
		"stored_canvases": 2,
		"canvas_storage_level": 1,
		"upgrade_resolution_cost": 50,
		"upgrade_fill_speed_cost": 75,
		"canvas_storage_cost": 100
	},
	"clicker": {
		"click_power": 2.5,
		"autoclick_speed": 1.5
	},
	"ascension": {
		"ascendancy_cost": 1000.0,
		"ascend_level": 1
	}
}

#==============================================================================
# Test Execution
#==============================================================================
func _ready():
	print("=== TEST DU SYSTÈME DE SAUVEGARDE ===")
	
	# Attendre que GameState soit initialisé
	await get_tree().process_frame
	
	# Exécuter les tests
	await run_all_tests()

func run_all_tests():
	print("\n1. Test de sauvegarde...")
	await test_save_game()
	
	print("\n2. Test de chargement...")
	await test_load_game()
	
	print("\n3. Test de vérification de fichier...")
	await test_has_save_file()
	
	print("\n4. Test d'informations de sauvegarde...")
	await test_get_save_info()
	
	print("\n5. Test de suppression de sauvegarde...")
	await test_clear_save()
	
	print("\n6. Test de sauvegarde avec données réelles...")
	await test_save_with_real_data()
	
	print("\n=== TOUS LES TESTS TERMINÉS ===")

#==============================================================================
# Individual Tests
#==============================================================================

func test_save_game():
	print("  - Sauvegarde des données de test...")
	
	# Configurer des données de test
	setup_test_data()
	
	# Sauvegarder
	var success = GameState.save_game()
	
	if success:
		print("  ✅ Sauvegarde réussie")
	else:
		print("  ❌ Échec de la sauvegarde")

func test_load_game():
	print("  - Chargement des données de test...")
	
	# Charger la sauvegarde
	var success = GameState.load_game()
	
	if success:
		print("  ✅ Chargement réussi")
		verify_loaded_data()
	else:
		print("  ❌ Échec du chargement")

func test_has_save_file():
	print("  - Vérification de l'existence du fichier...")
	
	var has_file = GameState.has_save_file()
	
	if has_file:
		print("  ✅ Fichier de sauvegarde trouvé")
	else:
		print("  ❌ Fichier de sauvegarde non trouvé")

func test_get_save_info():
	print("  - Récupération des informations de sauvegarde...")
	
	var save_info = GameState.get_save_info()
	
	if save_info.has("success") and save_info.success:
		print("  ✅ Informations récupérées:")
		print("     - Date: %s" % save_info.data.date)
		print("     - Version: %s" % save_info.data.version)
		print("     - Taille: %d bytes" % save_info.data.size)
	else:
		print("  ❌ Impossible de récupérer les informations: %s" % save_info.get("message", "Erreur inconnue"))

func test_clear_save():
	print("  - Suppression de la sauvegarde...")
	
	var success = GameState.clear_save()
	
	if success:
		print("  ✅ Sauvegarde supprimée")
		
		# Vérifier que le fichier n'existe plus
		var has_file = GameState.has_save_file()
		if not has_file:
			print("  ✅ Fichier confirmé supprimé")
		else:
			print("  ❌ Fichier encore présent après suppression")
	else:
		print("  ❌ Échec de la suppression")

func test_save_with_real_data():
	print("  - Sauvegarde avec données de jeu réelles...")
	
	# Ajouter des données de jeu
	GameState.currency_manager.add_currency("inspiration", 100)
	GameState.currency_manager.add_currency("gold", 50)
	GameState.experience_manager.add_experience(25)
	GameState.clicker_manager.manual_click()
	
	# Sauvegarder
	var success = GameState.save_game()
	
	if success:
		print("  ✅ Sauvegarde des données réelles réussie")
		
		# Charger et vérifier
		var load_success = GameState.load_game()
		if load_success:
			print("  ✅ Chargement des données réelles réussi")
		else:
			print("  ❌ Échec du chargement des données réelles")
	else:
		print("  ❌ Échec de la sauvegarde des données réelles")

#==============================================================================
# Helper Functions
#==============================================================================

func setup_test_data():
	"""Configure les données de test dans GameState"""
	
	# Currencies
	for currency_type in test_data.currencies.keys():
		GameState.currency_manager.set_currency(currency_type, test_data.currencies[currency_type])
	
	# Experience
	GameState.experience_manager.set_experience(test_data.experience.experience)
	GameState.experience_manager.set_level(test_data.experience.level)
	GameState.experience_manager.set_experience_to_next_level(test_data.experience.experience_to_next_level)
	
	# Canvas
	GameState.canvas_manager.set_resolution_level(test_data.canvas.resolution_level)
	GameState.canvas_manager.set_fill_speed_level(test_data.canvas.fill_speed_level)
	GameState.canvas_manager.set_sell_price(test_data.canvas.sell_price)
	GameState.canvas_manager.set_stored_canvases(test_data.canvas.stored_canvases)
	GameState.canvas_manager.set_canvas_storage_level(test_data.canvas.canvas_storage_level)
	GameState.canvas_manager.set_upgrade_resolution_cost(test_data.canvas.upgrade_resolution_cost)
	GameState.canvas_manager.set_upgrade_fill_speed_cost(test_data.canvas.upgrade_fill_speed_cost)
	GameState.canvas_manager.set_canvas_storage_cost(test_data.canvas.canvas_storage_cost)
	
	# Clicker
	GameState.clicker_manager.set_click_power(test_data.clicker.click_power)
	GameState.clicker_manager.set_autoclick_speed(test_data.clicker.autoclick_speed)
	
	# Ascension
	GameState.ascension_manager.set_ascendancy_cost(test_data.ascension.ascendancy_cost)
	GameState.ascension_manager.set_ascend_level(test_data.ascension.ascend_level)

func verify_loaded_data():
	"""Vérifie que les données chargées correspondent aux données de test"""
	
	print("  - Vérification des données chargées...")
	
	# Vérifier les currencies
	for currency_type in test_data.currencies.keys():
		var loaded_value = GameState.currency_manager.get_currency(currency_type)
		var expected_value = test_data.currencies[currency_type]
		if abs(loaded_value - expected_value) < 0.001:
			print("    ✅ %s: %s" % [currency_type, loaded_value])
		else:
			print("    ❌ %s: attendu %s, obtenu %s" % [currency_type, expected_value, loaded_value])
	
	# Vérifier l'expérience
	var loaded_exp = GameState.experience_manager.get_experience()
	var loaded_level = GameState.experience_manager.get_level()
	var loaded_exp_to_next = GameState.experience_manager.get_experience_to_next_level()
	
	if abs(loaded_exp - test_data.experience.experience) < 0.001:
		print("    ✅ Experience: %s" % loaded_exp)
	else:
		print("    ❌ Experience: attendu %s, obtenu %s" % [test_data.experience.experience, loaded_exp])
	
	if loaded_level == test_data.experience.level:
		print("    ✅ Level: %s" % loaded_level)
	else:
		print("    ❌ Level: attendu %s, obtenu %s" % [test_data.experience.level, loaded_level])
	
	if abs(loaded_exp_to_next - test_data.experience.experience_to_next_level) < 0.001:
		print("    ✅ Experience to next level: %s" % loaded_exp_to_next)
	else:
		print("    ❌ Experience to next level: attendu %s, obtenu %s" % [test_data.experience.experience_to_next_level, loaded_exp_to_next])

#==============================================================================
# Manual Test Functions
#==============================================================================

func _input(event):
	"""Fonctions de test manuelles avec touches"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("=== TEST RAPIDE DE SAUVEGARDE ===")
				await test_save_game()
			KEY_F2:
				print("=== TEST RAPIDE DE CHARGEMENT ===")
				await test_load_game()
			KEY_F3:
				print("=== TEST RAPIDE DE SUPPRESSION ===")
				await test_clear_save()
			KEY_F4:
				print("=== TEST COMPLET ===")
				await run_all_tests()
