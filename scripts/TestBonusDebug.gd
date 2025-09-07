extends Node

func _ready():
	print("🔍 DIAGNOSTIC DES BONUS D'ÉQUIPEMENT")
	print("=".repeat(50))
	
	# Vérifier que GameState est initialisé
	if not GameState:
		print("❌ GameState non initialisé!")
		return
	
	if not GameState.inventory_manager:
		print("❌ InventoryManager non initialisé!")
		return
	
	# Vérifier les items équipés
	print("📦 Items équipés:")
	var equipped_items = GameState.inventory_manager.equipped_items
	if equipped_items.is_empty():
		print("  Aucun item équipé")
	else:
		for slot in equipped_items.keys():
			var item = equipped_items[slot]
			print("  %s: %s (Tier %d)" % [slot, item.name, item.tier])
			print("    Stats: %s" % item.stats)
	
	# Vérifier les bonus calculés
	print("\n🎯 Bonus calculés:")
	var bonuses = GameState.inventory_manager.get_total_bonuses()
	if bonuses.is_empty():
		print("  Aucun bonus calculé")
	else:
		for stat in bonuses.keys():
			print("  %s: %.2fx" % [stat, bonuses[stat]])
	
	# Test du click power
	print("\n🖱️ Test du click power:")
	var click_power = GameState.clicker_manager.click_power
	print("  Click power de base: %.2f" % click_power)
	
	# Test de l'application des bonus
	var bonus_inspiration = GameState.apply_currency_bonus("inspiration", click_power)
	print("  Inspiration avec bonus: %.2f" % bonus_inspiration)
	print("  Multiplicateur inspiration: %.2fx" % (bonus_inspiration / click_power))
	
	# Test des bonus d'expérience
	var bonus_experience = GameState.apply_experience_bonus(click_power)
	print("  Expérience avec bonus: %.2f" % bonus_experience)
	print("  Multiplicateur expérience: %.2fx" % (bonus_experience / click_power))
	
	# Test d'un click réel
	print("\n🎮 Test d'un click réel:")
	var result = GameState.clicker_manager.manual_click()
	print("  Inspiration gagnée: %.2f" % result.get("inspiration_gained", 0))
	print("  Expérience gagnée: %.2f" % result.get("experience_gained", 0))
	
	print("\n✅ Diagnostic terminé")
	queue_free()
