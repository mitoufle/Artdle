extends Node

func _ready():
	print("=== Test Button Icons ===")
	
	# Tester le chargement des icônes
	var currencies = ["inspiration", "gold", "fame", "ascendancy_points", "paint_mastery"]
	
	for currency in currencies:
		var icon = UIDisplayFormatter.get_currency_icon(currency)
		if icon:
			print("✓ %s: %s" % [currency, icon.resource_path])
		else:
			print("✗ %s: Failed to load" % currency)
	
	print("\n=== Test Button Setup ===")
	
	# Créer un bouton de test
	var test_button = Button.new()
	add_child(test_button)
	
	# Tester l'icône gold
	var gold_icon = UIDisplayFormatter.get_currency_icon("gold")
	if gold_icon:
		test_button.icon = gold_icon
		test_button.text = "Test Gold\n10"
		print("✓ Bouton créé avec icône gold")
	else:
		print("✗ Impossible de charger l'icône gold")
	
	# Attendre un peu puis nettoyer
	await get_tree().create_timer(2.0).timeout
	test_button.queue_free()
	print("✓ Test terminé")
