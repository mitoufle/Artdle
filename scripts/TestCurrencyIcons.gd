extends Node

## Test des icônes de devises
## Vérifie que toutes les icônes se chargent correctement

func _ready():
	print("💰 TEST DES ICÔNES DE DEVISES")
	print("=".repeat(50))
	
	_test_currency_icons()
	
	print("\n✅ Test des icônes terminé")
	queue_free()

func _test_currency_icons():
	var currencies = ["inspiration", "gold", "fame", "ascendancy_points", "paint_mastery"]
	
	for currency in currencies:
		print("\n🔍 Test de %s:" % currency)
		
		# Test de l'icône de texte
		var text_icon = UIDisplayFormatter._get_currency_icon_text(currency)
		print("  Icône texte: %s" % text_icon)
		
		# Test de l'icône d'image
		var image_icon = UIDisplayFormatter.CURRENCY_ICONS.get(currency)
		if image_icon:
			print("  Icône image: ✅ Chargée")
			print("  Chemin: %s" % image_icon.resource_path)
		else:
			print("  Icône image: ❌ Non trouvée")
		
		# Test du formatage de prix
		var price_text = UIDisplayFormatter.format_price(currency, 1000)
		print("  Prix formaté: %s" % price_text)
