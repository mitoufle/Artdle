extends Node
class_name CurrencyManager

## Gère toutes les devises du jeu de manière centralisée
## Fournit une interface propre pour les opérations sur les devises

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

## Ajoute une valeur à une devise existante
func add_currency(currency_type: String, amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(amount):
		return false
	
	_currencies[currency_type] += amount
	currency_changed.emit(currency_type, _currencies[currency_type])
	return true

## Retire une valeur d'une devise existante
func subtract_currency(currency_type: String, amount: float) -> bool:
	if not _validate_currency_type(currency_type):
		return false
	
	if not _validate_currency_value(amount):
		return false
	
	if _currencies[currency_type] < amount:
		insufficient_funds.emit(currency_type, amount, _currencies[currency_type])
		return false
	
	_currencies[currency_type] -= amount
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
