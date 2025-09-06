extends Node
class_name TestUISystem

## Script de test pour vérifier que le système UI refactorisé fonctionne
## À supprimer après validation

func _ready():
	# Attendre que le GameState soit initialisé
	await get_tree().process_frame
	
	_test_currency_display()
	_test_upgrade_buttons()
	_test_progress_bars()
	_test_navigation_buttons()
	_test_action_buttons()
	_test_feedback_manager()
	
	print("=== Tests UI terminés ===")

func _test_currency_display():
	print("--- Test Currency Display ---")
	
	# Test affichage des devises
	GameState.currency_manager.set_currency("gold", 1500)
	GameState.currency_manager.set_currency("inspiration", 250)
	GameState.currency_manager.set_currency("fame", 50)
	
	print("Currencies set for testing")

func _test_upgrade_buttons():
	print("--- Test Upgrade Buttons ---")
	
	# Test upgrade de clic
	var click_success = GameState.clicker_manager.upgrade_click_power()
	print("Click power upgrade: %s" % click_success)
	
	# Test upgrade de canvas
	var canvas_success = GameState.canvas_manager.upgrade_resolution()
	print("Canvas resolution upgrade: %s" % canvas_success)

func _test_progress_bars():
	print("--- Test Progress Bars ---")
	
	# Test progression d'expérience
	GameState.experience_manager.add_experience(25)
	print("Experience added, level: %d" % GameState.experience_manager.get_level())

func _test_navigation_buttons():
	print("--- Test Navigation Buttons ---")
	
	# Test déblocage des vues
	var current_level = GameState.experience_manager.get_level()
	print("Current level: %d" % current_level)
	
	if current_level >= 2:
		print("PaintingView should be unlocked")
	if current_level >= 5:
		print("AscendancyView should be unlocked")

func _test_action_buttons():
	print("--- Test Action Buttons ---")
	
	# Test vente de canvas
	GameState.canvas_manager.stored_canvases = 3
	var sell_result = GameState.canvas_manager.sell_canvas()
	print("Canvas sold: %s" % sell_result)
	
	# Test ascension
	GameState.currency_manager.set_currency("fame", 2000)
	var ascend_success = GameState.ascension_manager.ascend()
	print("Ascension: %s" % ascend_success)

func _test_feedback_manager():
	print("--- Test Feedback Manager ---")
	
	# Test feedback de devises
	GameState.feedback_manager.show_currency_feedback(100, "gold")
	GameState.feedback_manager.show_currency_feedback(50, "inspiration")
	
	# Test feedback d'expérience
	GameState.feedback_manager.show_experience_feedback(25)
	
	# Test feedback de niveau
	GameState.feedback_manager.show_level_feedback(5)
	
	# Test feedback d'ascension
	GameState.feedback_manager.show_ascension_feedback(1)
	
	print("Feedback tests completed")
