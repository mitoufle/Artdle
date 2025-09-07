extends Node

## Test de l'intégration du système unifié dans AccueilView
## Vérifie que les boutons d'upgrade fonctionnent correctement

func _ready():
	print("🏠 TEST D'INTÉGRATION ACCUEIL VIEW")
	print("=".repeat(50))
	
	# Vérifier que GameState est initialisé
	if not GameState:
		print("❌ GameState non initialisé!")
		return
	
	if not GameState.clicker_manager:
		print("❌ ClickerManager non initialisé!")
		return
	
	# Test des prix d'upgrade
	_test_upgrade_prices()
	
	# Test de l'achat d'upgrade
	_test_upgrade_purchase()
	
	print("\n✅ Tests d'intégration terminés")
	queue_free()

func _test_upgrade_prices():
	print("\n💰 TEST DES PRIX D'UPGRADE")
	print("-".repeat(30))
	
	# Test Click Power
	var click_level = GameState.clicker_manager.click_power
	var click_prices = _get_click_power_prices(click_level)
	print("Click Power Level %d: %s" % [click_level, UIDisplayFormatter.format_multi_price(click_prices)])
	
	# Test Autoclick Speed
	var autoclick_level = GameState.clicker_manager.autoclick_speed
	var autoclick_prices = _get_autoclick_prices(autoclick_level)
	print("Autoclick Level %d: %s" % [autoclick_level, UIDisplayFormatter.format_multi_price(autoclick_prices)])
	
	# Vérifier l'achat possible
	var can_afford_click = UIDisplayFormatter.can_afford_price(click_prices)
	var can_afford_autoclick = UIDisplayFormatter.can_afford_price(autoclick_prices)
	print("Peut acheter Click Power: %s" % can_afford_click)
	print("Peut acheter Autoclick: %s" % can_afford_autoclick)

func _test_upgrade_purchase():
	print("\n🛒 TEST D'ACHAT D'UPGRADE")
	print("-".repeat(30))
	
	# Vérifier les fonds actuels
	var gold = GameState.currency_manager.get_currency("gold")
	print("Or actuel: %s" % gold)
	
	# Tenter d'acheter Click Power
	var click_level_before = GameState.clicker_manager.click_power
	var click_prices = _get_click_power_prices(click_level_before)
	
	if UIDisplayFormatter.can_afford_price(click_prices):
		print("Achat de Click Power...")
		_handle_click_power_upgrade()
		var click_level_after = GameState.clicker_manager.click_power
		print("Niveau avant: %d, après: %d" % [click_level_before, click_level_after])
	else:
		print("❌ Pas assez d'or pour Click Power")

func _get_click_power_prices(level: int) -> Dictionary:
	var base_cost = GameConfig.CLICK_POWER_UPGRADE_COST
	var cost = int(base_cost * pow(1.5, level))
	return {"gold": cost}

func _get_autoclick_prices(level: int) -> Dictionary:
	var base_cost = GameConfig.AUTOCLICK_SPEED_UPGRADE_COST
	var cost = int(base_cost * pow(1.5, level))
	return {"gold": cost}

func _handle_click_power_upgrade():
	if not GameState or not GameState.clicker_manager:
		return
	
	var level = GameState.clicker_manager.click_power
	var prices = _get_click_power_prices(level)
	
	# Vérifier si on peut acheter
	if UIDisplayFormatter.can_afford_price(prices):
		# Déduire le coût
		for currency_type in prices.keys():
			GameState.currency_manager.add_currency(currency_type, -prices[currency_type])
		
		# Effectuer l'upgrade
		GameState.clicker_manager.upgrade_click_power()
		
		print("✅ Click Power upgraded to level %d" % GameState.clicker_manager.click_power)
	else:
		print("❌ Insufficient funds for Click Power upgrade")
