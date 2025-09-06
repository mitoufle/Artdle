extends Node
class_name TestRefactoredSystem

## Script de test pour vérifier que le système refactorisé fonctionne
## À supprimer après validation

func _ready():
	# Attendre que le GameState soit initialisé
	await get_tree().process_frame
	
	_test_currency_system()
	_test_canvas_system()
	_test_clicker_system()
	_test_ascension_system()
	_test_experience_system()
	_test_save_system()
	
	print("=== Tests terminés ===")

func _test_currency_system():
	print("--- Test Currency System ---")
	
	# Test ajout de devises
	GameState.currency_manager.add_currency("gold", 100)
	GameState.currency_manager.add_currency("inspiration", 50)
	
	print("Gold: %f" % GameState.currency_manager.get_currency("gold"))
	print("Inspiration: %f" % GameState.currency_manager.get_currency("inspiration"))
	
	# Test échange
	GameState.currency_manager.exchange_currency("gold", "fame", 50, 0.5)
	print("After exchange - Gold: %f, Fame: %f" % [
		GameState.currency_manager.get_currency("gold"),
		GameState.currency_manager.get_currency("fame")
	])

func _test_canvas_system():
	print("--- Test Canvas System ---")
	
	# Test upgrade de résolution
	var can_upgrade = GameState.canvas_manager.upgrade_resolution()
	print("Can upgrade resolution: %s" % can_upgrade)
	
	# Test upgrade de vitesse
	can_upgrade = GameState.canvas_manager.upgrade_fill_speed()
	print("Can upgrade fill speed: %s" % can_upgrade)

func _test_clicker_system():
	print("--- Test Clicker System ---")
	
	# Test clic manuel
	var result = GameState.clicker_manager.manual_click()
	print("Manual click result: %s" % result)
	
	# Test upgrade
	var can_upgrade = GameState.clicker_manager.upgrade_click_power()
	print("Can upgrade click power: %s" % can_upgrade)

func _test_ascension_system():
	print("--- Test Ascension System ---")
	
	# Ajouter de la fame pour tester l'ascension
	GameState.currency_manager.set_currency("fame", 2000)
	
	var can_ascend = GameState.ascension_manager.can_ascend()
	print("Can ascend: %s" % can_ascend)
	
	if can_ascend:
		var ascended = GameState.ascension_manager.ascend()
		print("Ascended successfully: %s" % ascended)

func _test_experience_system():
	print("--- Test Experience System ---")
	
	# Test ajout d'expérience
	GameState.experience_manager.add_experience(50)
	print("Level: %d, Experience: %f" % [
		GameState.experience_manager.get_level(),
		GameState.experience_manager.get_experience()
	])

func _test_save_system():
	print("--- Test Save System ---")
	
	# Test sauvegarde
	var saved = GameState.save_game()
	print("Game saved: %s" % saved)
	
	# Test chargement
	var loaded = GameState.load_game()
	print("Game loaded: %s" % loaded)
	
	# Test informations de sauvegarde
	var save_info = GameState.get_save_info()
	print("Save info: %s" % save_info)
