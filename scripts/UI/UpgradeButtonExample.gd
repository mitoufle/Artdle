extends Control
class_name UpgradeButtonExample

## Exemple d'utilisation du système d'upgrade unifié
## Montre comment intégrer UpgradeButton et LevelDisplay

#==============================================================================
# UI References
#==============================================================================
var click_power_button: UpgradeButton
var click_power_level: LevelDisplay
var workshop_button: UpgradeButton
var workshop_level: LevelDisplay

#==============================================================================
# Lifecycle
#==============================================================================

func _ready():
	_setup_ui()
	_connect_signals()
	_update_displays()

func _setup_ui():
	# Container principal
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	# Titre
	var title = Label.new()
	title.text = "Système d'Upgrade Unifié - Exemple"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Section Click Power
	var click_section = _create_section("Click Power", main_container)
	click_power_level = LevelDisplay.create_simple_level_display("Click Power", 1, "Level")
	click_section.add_child(click_power_level)
	
	click_power_button = UpgradeButton.new()
	click_power_button.upgrade_type = "click_power"
	click_power_button.level_prefix = "Level"
	click_power_button.show_level = true
	click_section.add_child(click_power_button)
	
	# Section Workshop
	var workshop_section = _create_section("Workshop", main_container)
	workshop_level = LevelDisplay.create_progress_level_display("Workshop", 1, 0, 100, "Level")
	workshop_section.add_child(workshop_level)
	
	workshop_button = UpgradeButton.new()
	workshop_button.upgrade_type = "workshop"
	workshop_button.level_prefix = "Level"
	workshop_button.show_level = true
	workshop_button.show_progress = true
	workshop_section.add_child(workshop_button)

func _create_section(title: String, parent: Control) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	
	var section_title = Label.new()
	section_title.text = title
	section_title.add_theme_font_size_override("font_size", 16)
	section.add_child(section_title)
	
	return section

func _connect_signals():
	if click_power_button:
		click_power_button.upgrade_purchased.connect(_on_upgrade_purchased)
	if workshop_button:
		workshop_button.upgrade_purchased.connect(_on_upgrade_purchased)

#==============================================================================
# Update Methods
#==============================================================================

func _update_displays():
	_update_click_power_display()
	_update_workshop_display()

func _update_click_power_display():
	if not GameState or not GameState.clicker_manager:
		return
	
	var level = GameState.clicker_manager.click_power
	var prices = _get_click_power_prices(level)
	
	# Mettre à jour le niveau
	click_power_level.update_level_data(level)
	
	# Mettre à jour le bouton
	click_power_button.update_upgrade_data(level, prices)

func _update_workshop_display():
	if not GameState or not GameState.craft_manager:
		return
	
	var level = GameState.craft_manager.workshop_level
	var prices = _get_workshop_prices(level)
	var progress = _get_workshop_progress(level)
	
	# Mettre à jour le niveau
	workshop_level.update_level_data(level, progress)
	
	# Mettre à jour le bouton
	workshop_button.update_upgrade_data(level, prices, progress)

#==============================================================================
# Price Calculation
#==============================================================================

func _get_click_power_prices(level: int) -> Dictionary:
	# Formule de prix pour click power
	var base_price = 100
	var price = base_price * pow(1.5, level)
	return {"inspiration": price}

func _get_workshop_prices(level: int) -> Dictionary:
	# Formule de prix pour workshop
	var base_price = 500
	var price = base_price * pow(2.0, level)
	return {"gold": price}

func _get_workshop_progress(level: int) -> Dictionary:
	# Simulation de progression (exemple)
	var current = (level * 25) % 100
	return {"current": current, "max": 100}

#==============================================================================
# Event Handlers
#==============================================================================

func _on_upgrade_purchased(upgrade_type: String, level: int):
	match upgrade_type:
		"click_power":
			_handle_click_power_upgrade()
		"workshop":
			_handle_workshop_upgrade()
	
	# Mettre à jour les affichages
	_update_displays()

func _handle_click_power_upgrade():
	if not GameState or not GameState.clicker_manager:
		return
	
	var prices = _get_click_power_prices(GameState.clicker_manager.click_power)
	
	# Vérifier si on peut acheter
	if UIDisplayFormatter.can_afford_price(prices):
		# Déduire le coût
		for currency_type in prices.keys():
			GameState.currency_manager.add_currency(currency_type, -prices[currency_type])
		
		# Effectuer l'upgrade
		GameState.clicker_manager.upgrade_click_power()
		
		print("✅ Click Power upgraded to level %d" % GameState.clicker_manager.click_power)

func _handle_workshop_upgrade():
	if not GameState or not GameState.craft_manager:
		return
	
	var prices = _get_workshop_prices(GameState.craft_manager.workshop_level)
	
	# Vérifier si on peut acheter
	if UIDisplayFormatter.can_afford_price(prices):
		# Déduire le coût
		for currency_type in prices.keys():
			GameState.currency_manager.add_currency(currency_type, -prices[currency_type])
		
		# Effectuer l'upgrade
		GameState.craft_manager.upgrade_workshop()
		
		print("✅ Workshop upgraded to level %d" % GameState.craft_manager.workshop_level)
