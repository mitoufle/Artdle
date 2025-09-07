extends Button
class_name UpgradeButton

## Bouton d'upgrade avec affichage unifié des prix et niveaux
## S'adapte automatiquement aux différents types d'upgrades

#==============================================================================
# Signals
#==============================================================================
signal upgrade_purchased(upgrade_type: String, level: int)

#==============================================================================
# Properties
#==============================================================================
@export var upgrade_type: String = ""
@export var level_prefix: String = "Level"
@export var show_level: bool = true
@export var show_progress: bool = false

#==============================================================================
# UI References
#==============================================================================
var price_container: VBoxContainer
var level_container: VBoxContainer
var progress_bar: ProgressBar

#==============================================================================
# Upgrade Data
#==============================================================================
var current_level: int = 0
var current_prices: Dictionary = {}
var current_progress: Dictionary = {}

#==============================================================================
# Lifecycle
#==============================================================================

func _ready():
	_setup_ui()
	_update_display()

func _setup_ui():
	# Configuration du bouton
	custom_minimum_size = Vector2(200, 60)
	text = "Upgrade"
	
	# Container principal
	var main_container = VBoxContainer.new()
	add_child(main_container)
	
	# Container pour le niveau
	if show_level:
		level_container = VBoxContainer.new()
		main_container.add_child(level_container)
	
	# Container pour le prix
	price_container = VBoxContainer.new()
	main_container.add_child(price_container)
	
	# Barre de progression (optionnelle)
	if show_progress:
		progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(180, 8)
		main_container.add_child(progress_bar)

#==============================================================================
# Public API
#==============================================================================

## Met à jour les données d'upgrade
func update_upgrade_data(level: int, prices: Dictionary, progress: Dictionary = {}):
	current_level = level
	current_prices = prices
	current_progress = progress
	_update_display()

## Met à jour l'affichage
func _update_display():
	_update_level_display()
	_update_price_display()
	_update_progress_display()
	_update_affordability()

## Met à jour l'affichage du niveau
func _update_level_display():
	if not level_container or not show_level:
		return
	
	# Nettoyer l'affichage précédent
	for child in level_container.get_children():
		child.queue_free()
	
	# Créer le nouvel affichage
	var level_display = UIDisplayFormatter.create_level_display(current_level, level_prefix)
	level_container.add_child(level_display)

## Met à jour l'affichage du prix
func _update_price_display():
	if not price_container:
		return
	
	# Nettoyer l'affichage précédent
	for child in price_container.get_children():
		child.queue_free()
	
	# Créer le nouvel affichage
	if current_prices.size() == 1:
		# Prix simple
		var currency_type = current_prices.keys()[0]
		var amount = current_prices[currency_type]
		var price_display = UIDisplayFormatter.create_price_display(currency_type, amount)
		price_container.add_child(price_display)
	else:
		# Prix multiple
		var price_display = UIDisplayFormatter.create_multi_price_display(current_prices)
		price_container.add_child(price_display)

## Met à jour l'affichage de la progression
func _update_progress_display():
	if not progress_bar or not show_progress:
		return
	
	if current_progress.has("current") and current_progress.has("max"):
		progress_bar.min_value = 0
		progress_bar.max_value = current_progress["max"]
		progress_bar.value = current_progress["current"]

## Met à jour l'état d'achat possible
func _update_affordability():
	UIDisplayFormatter.apply_affordability_style(self, current_prices)

#==============================================================================
# Event Handlers
#==============================================================================

func _on_pressed():
	if UIDisplayFormatter.can_afford_price(current_prices):
		upgrade_purchased.emit(upgrade_type, current_level)
		# L'upgrade sera géré par le parent
	else:
		# Feedback visuel pour prix insuffisant
		_show_insufficient_funds_feedback()

func _show_insufficient_funds_feedback():
	# Animation de secousse ou changement de couleur
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
