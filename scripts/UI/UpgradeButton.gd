extends Button
class_name UpgradeButton

## Bouton d'upgrade avec affichage unifié des prix et niveaux
## S'adapte automatiquement aux différents types d'upgrades

const BigNumberManager = preload("res://scripts/BigNumberManager.gd")

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
@onready var main_container: VBoxContainer = $MainContainer
@onready var level_container: VBoxContainer = $MainContainer/LevelContainer
@onready var level_label: Label = $MainContainer/LevelContainer/LevelLabel
@onready var price_container: HBoxContainer = $MainContainer/PriceContainer
@onready var price_label: Label = $MainContainer/PriceContainer/PriceLabel

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
	pressed.connect(_on_pressed)
	_update_display()

func _setup_ui():
	# Configuration du bouton
	custom_minimum_size = Vector2(200, 60)
	text = ""
	
	# Les nœuds sont déjà définis dans la scène
	# Pas besoin de créer des nœuds dynamiquement

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
	if not level_label or not show_level:
		return
	
	# Mettre à jour le texte du niveau
	level_label.text = "%s %d" % [level_prefix, current_level]

## Met à jour l'affichage du prix
func _update_price_display():
	if not price_label:
		return
	
	# Mettre à jour le texte du prix
	if current_prices.size() == 1:
		# Prix simple
		var currency_type = current_prices.keys()[0]
		var amount = current_prices[currency_type]
		price_label.text = "%s" % [BigNumberManager.format_number(amount)]
	else:
		# Prix multiple
		var price_strings = []
		for currency_type in current_prices.keys():
			var amount = current_prices[currency_type]
			if amount > 0:
				price_strings.append("%s" % [BigNumberManager.format_number(amount)])
		price_label.text = " + ".join(price_strings)

## Met à jour l'affichage de la progression
func _update_progress_display():
	# Pas de barre de progression dans la scène actuelle
	pass

## Met à jour l'état d'achat possible
func _update_affordability():
	# Simple affordability check
	var can_afford = true
	for currency_type in current_prices.keys():
		var required = current_prices[currency_type]
		var available = GameState.currency_manager.get_currency(currency_type)
		if available < required:
			can_afford = false
			break
	
	if can_afford:
		modulate = Color.WHITE
		disabled = false
	else:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
		disabled = true

#==============================================================================
# Event Handlers
#==============================================================================

func _on_pressed():
	print("UpgradeButton pressed: ", upgrade_type)
	print("Current prices: ", current_prices)
	
	# Check if we can afford the upgrade
	var can_afford = true
	for currency_type in current_prices.keys():
		var required = current_prices[currency_type]
		var available = GameState.currency_manager.get_currency(currency_type)
		print("Currency %s: required=%s, available=%s" % [currency_type, required, available])
		if available < required:
			can_afford = false
			break
	
	print("Can afford: ", can_afford)
	
	if can_afford:
		print("Emitting upgrade_purchased signal")
		upgrade_purchased.emit(upgrade_type, current_level)
		# L'upgrade sera géré par le parent
	else:
		print("Not enough funds")
		# Feedback visuel pour prix insuffisant
		_show_insufficient_funds_feedback()

func _show_insufficient_funds_feedback():
	# Animation de secousse ou changement de couleur
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
