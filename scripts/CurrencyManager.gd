extends Node
class_name CurrencyManager

## Gère toutes les devises du jeu de manière centralisée
## Fournit une interface propre pour les opérations sur les devises

#==============================================================================
# Big Number Management
#==============================================================================
const BigNumberManager = preload("res://scripts/BigNumberManager.gd")
const UIFormatter = preload("res://scripts/UIFormatter.gd")
const CurrencyBonusManager = preload("res://scripts/CurrencyBonusManager.gd")

#==============================================================================
# Signals
#==============================================================================
signal currency_changed(currency_type: String, new_value: float)
signal insufficient_funds(currency_type: String, required: float, available: float)

#==============================================================================
# Currency Storage
#==============================================================================
var _currencies: Dictionary = {
	"inspiration": GameConfig.DEFAULT_INSPIRATION,
	"gold": GameConfig.DEFAULT_GOLD,
	"fame": GameConfig.DEFAULT_FAME,
	"ascendancy_points": GameConfig.DEFAULT_ASCENDANCY_POINTS,
	"ascend_level": GameConfig.DEFAULT_ASCEND_LEVEL,
	"paint_mastery": GameConfig.DEFAULT_PAINT_MASTERY,
	"experience": GameConfig.DEFAULT_EXPERIENCE,
	"level": GameConfig.DEFAULT_LEVEL,
	"experience_to_next_level": GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL
}

#==============================================================================
# Public API
#==============================================================================

## Récupère la valeur d'une devise
func get_currency(currency_type: String) -> float:
	if not _currencies.has(currency_type):
		push_error("Currency type '%s' does not exist" % currency_type)
		return 0.0
	return _currencies[currency_type]

## Définit la valeur d'une devise (remplace la valeur actuelle)
func set_currency(currency_type: String, value: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(value):
		return false
	
	_currencies[currency_type] = value
	currency_changed.emit(currency_type, value)
	return true

## Ajoute une valeur à une devise existante (avec bonus d'équipement)
func add_currency(currency_type: String, amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(amount):
		return false
	
	# Appliquer les bonus d'équipement
	var bonus_amount = CurrencyBonusManager.apply_bonuses(currency_type, amount)
	
	# Utiliser l'addition sécurisée pour éviter les overflows
	var current_value = _currencies[currency_type]
	var new_value = BigNumberManager.safe_add(current_value, bonus_amount)
	
	if not BigNumberManager.is_valid_number(new_value):
		push_error("Currency overflow detected for %s: %s + %s" % [currency_type, current_value, bonus_amount])
		return false
	
	_currencies[currency_type] = new_value
	currency_changed.emit(currency_type, _currencies[currency_type])
	return true

## Retire une valeur d'une devise existante
func subtract_currency(currency_type: String, amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(amount):
		return false
	
	# Utiliser la soustraction sécurisée pour éviter les overflows
	var current_value = _currencies[currency_type]
	var new_value = BigNumberManager.safe_add(current_value, -amount)
	
	if not BigNumberManager.is_valid_number(new_value):
		push_error("Currency underflow detected for %s: %s - %s" % [currency_type, current_value, amount])
		return false
	
	if new_value < 0:
		insufficient_funds.emit(currency_type, amount, current_value)
		return false
	
	_currencies[currency_type] = new_value
	currency_changed.emit(currency_type, _currencies[currency_type])
	return true

## Vérifie si une devise a suffisamment de fonds
func has_enough(currency_type: String, required_amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	return _currencies[currency_type] >= required_amount

## Effectue un échange entre deux devises
func exchange_currency(from_currency: String, to_currency: String, amount: float, exchange_rate: float = 1.0) -> bool:
	if not has_enough(from_currency, amount):
		return false
	
	if not subtract_currency(from_currency, amount):
		return false
	
	var converted_amount = amount * exchange_rate
	return add_currency(to_currency, converted_amount)

## Réinitialise toutes les devises aux valeurs par défaut
func reset_all_currencies() -> void:
	_currencies = {
		"inspiration": GameConfig.DEFAULT_INSPIRATION,
		"gold": GameConfig.DEFAULT_GOLD,
		"fame": GameConfig.DEFAULT_FAME,
		"ascendancy_points": GameConfig.DEFAULT_ASCENDANCY_POINTS,
		"ascend_level": GameConfig.DEFAULT_ASCEND_LEVEL,
		"paint_mastery": GameConfig.DEFAULT_PAINT_MASTERY,
		"experience": GameConfig.DEFAULT_EXPERIENCE,
		"level": GameConfig.DEFAULT_LEVEL,
		"experience_to_next_level": GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL
	}
	
	# Émettre les signaux pour toutes les devises
	for currency_type in _currencies.keys():
		currency_changed.emit(currency_type, _currencies[currency_type])

## Récupère toutes les devises sous forme de dictionnaire
func get_all_currencies() -> Dictionary:
	return _currencies.duplicate()

## Ajoute une valeur à une devise existante SANS appliquer les bonus d'équipement
func add_currency_raw(currency_type: String, amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(amount):
		return false
	
	# Utiliser l'addition sécurisée pour éviter les overflows
	var current_value = _currencies[currency_type]
	var new_value = BigNumberManager.safe_add(current_value, amount)
	
	if not BigNumberManager.is_valid_number(new_value):
		push_error("Currency overflow detected for %s: %s + %s" % [currency_type, current_value, amount])
		return false
	
	_currencies[currency_type] = new_value
	currency_changed.emit(currency_type, _currencies[currency_type])
	return true

#==============================================================================
# Formatting Methods
#==============================================================================

## Formate une devise pour l'affichage dans l'UI
func format_currency(currency_type: String) -> String:
	if not _validate_currency_type(currency_type):
		return "0"
	
	var value = get_currency(currency_type)
	return UIFormatter.format_currency(value)

## Formate toutes les devises pour l'affichage
func format_all_currencies() -> Dictionary:
	var formatted = {}
	for currency_type in _currencies.keys():
		formatted[currency_type] = format_currency(currency_type)
	return formatted

## Formate un coût pour l'affichage
func format_cost(amount: float, currency_type: String) -> String:
	return UIFormatter.format_cost(amount, currency_type)

## Formate un gain pour l'affichage
func format_gain(amount: float, currency_type: String) -> String:
	return UIFormatter.format_gain(amount, currency_type)

## Formate une perte pour l'affichage
func format_loss(amount: float, currency_type: String) -> String:
	return UIFormatter.format_loss(amount, currency_type)

#==============================================================================
# Private Methods
#==============================================================================

func _validate_currency_type(currency_type: String) -> bool:
	if not _currencies.has(currency_type):
		GameState.logger.error("Currency type '%s' does not exist" % currency_type, "CurrencyManager")
		return false
	return true

func _validate_currency_value(value: float) -> bool:
	return GameState.data_validator.validate_currency_value(value, "CurrencyManager")
