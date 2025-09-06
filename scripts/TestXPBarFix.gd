extends Node

## Test pour vérifier que la barre d'XP s'initialise correctement après le chargement

func _ready():
	print("=== TEST BARRE D'XP APRÈS CHARGEMENT ===")
	print("Ce script teste que la barre d'XP s'affiche correctement après le chargement d'une sauvegarde")
	print("")
	print("Instructions:")
	print("1. Sauvegardez avec F1 (ajoutez de l'XP avec F10 si nécessaire)")
	print("2. Rechargez le jeu")
	print("3. Vérifiez que la barre d'XP affiche le bon pourcentage")
	print("")
	print("Appuyez sur F12 pour tester manuellement")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			test_xp_bar_initialization()

func test_xp_bar_initialization():
	print("\n--- TEST INITIALISATION BARRE D'XP ---")
	
	# Ajouter de l'XP pour tester
	GameState.experience_manager.add_experience(150)
	
	var current_exp = GameState.experience_manager.get_experience()
	var exp_to_next = GameState.experience_manager.get_experience_to_next_level()
	var level = GameState.experience_manager.get_level()
	var progress = GameState.experience_manager.get_level_progress()
	
	print("📊 Données actuelles:")
	print("  Level: %d" % level)
	print("  XP: %.1f / %.1f" % [current_exp, exp_to_next])
	print("  Progression: %.1f%%" % (progress * 100))
	
	# Forcer la mise à jour de la barre d'XP
	GameState.experience_manager.emit_experience_changed()
	GameState.experience_manager.emit_level_changed()
	
	print("✅ Signaux émis pour mettre à jour la barre d'XP")
	print("💡 Vérifiez visuellement que la barre affiche %.1f%%" % (progress * 100))
