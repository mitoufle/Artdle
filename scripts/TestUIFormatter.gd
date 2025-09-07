extends Node

## Test du système d'affichage unifié
## Démonstration des capacités d'UIFormatter

func _ready():
	print("🎨 TEST DU SYSTÈME D'AFFICHAGE UNIFIÉ")
	print("=".repeat(50))
	
	# Test des prix
	_test_price_formatting()
	
	# Test des niveaux
	_test_level_formatting()
	
	# Test des composants
	_test_components()
	
	print("\n✅ Tests terminés")
	queue_free()

func _test_price_formatting():
	print("\n💰 TEST DES PRIX")
	print("-".repeat(30))
	
	# Prix simple
	var simple_price = UIDisplayFormatter.format_price("inspiration", 1250.5)
	print("Prix simple: %s" % simple_price)
	
	# Prix multiple
	var multi_price = {
		"inspiration": 1000,
		"gold": 500,
		"fame": 50
	}
	var formatted_multi = UIDisplayFormatter.format_multi_price(multi_price)
	print("Prix multiple: %s" % formatted_multi)
	
	# Vérification d'achat possible
	var can_afford = UIDisplayFormatter.can_afford_price(multi_price)
	print("Peut acheter: %s" % can_afford)

func _test_level_formatting():
	print("\n📊 TEST DES NIVEAUX")
	print("-".repeat(30))
	
	# Niveau simple
	var simple_level = UIDisplayFormatter.format_level(5, "Level")
	print("Niveau simple: %s" % simple_level)
	
	# Niveau avec progression
	var level_progress = UIDisplayFormatter.format_level_with_progress(3, 25, 100, "Level")
	print("Niveau avec progression: %s" % level_progress)
	
	# Niveau avec pourcentage
	var level_percentage = UIDisplayFormatter.format_level_with_percentage(7, 75, 100, "Level")
	print("Niveau avec pourcentage: %s" % level_percentage)

func _test_components():
	print("\n🧩 TEST DES COMPOSANTS")
	print("-".repeat(30))
	
	# Créer un nœud de test
	var test_node = Control.new()
	get_tree().current_scene.add_child(test_node)
	
	# Test UpgradeButton
	var upgrade_button = UpgradeButton.new()
	upgrade_button.upgrade_type = "test_upgrade"
	upgrade_button.level_prefix = "Level"
	upgrade_button.show_level = true
	upgrade_button.update_upgrade_data(3, {"inspiration": 1000, "gold": 500})
	test_node.add_child(upgrade_button)
	
	# Test LevelDisplay
	var level_display = LevelDisplay.create_simple_level_display("Test Feature", 5, "Level")
	test_node.add_child(level_display)
	
	# Test LevelDisplay avec progression
	var progress_display = LevelDisplay.create_progress_level_display("Test Progress", 2, 30, 100, "Level")
	test_node.add_child(progress_display)
	
	print("✅ Composants créés avec succès")
	
	# Nettoyer après 2 secondes
	await get_tree().create_timer(2.0).timeout
	test_node.queue_free()
