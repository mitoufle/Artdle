class_name UIFormatter
extends RefCounted

## Formateur d'interface utilisateur pour les très grands nombres
## Centralise le formatage des nombres dans toute l'UI

#==============================================================================
# Public Methods
#==============================================================================

## Formate un nombre pour l'affichage dans l'UI
static func format_currency(value: float) -> String:
	return BigNumberManager.format_number(value)

## Formate un nombre pour l'affichage de l'expérience
static func format_experience(value: float) -> String:
	return BigNumberManager.format_number(value)

## Formate un nombre pour l'affichage des points d'ascension
static func format_ascendancy_points(value: float) -> String:
	return BigNumberManager.format_number(value)

## Formate un nombre pour l'affichage des pixels
static func format_pixels(value: int) -> String:
	return BigNumberManager.format_number(float(value))

## Formate un nombre pour l'affichage des pourcentages
static func format_percentage(value: float, decimals: int = 1) -> String:
	if value == 0:
		return "0%"
	
	var formatted_value = "%.*f" % [decimals, value]
	return formatted_value + "%"

## Formate un nombre pour l'affichage des coûts
static func format_cost(value: float, currency_type: String = "g") -> String:
	var formatted_number = BigNumberManager.format_number(value)
	return formatted_number + " " + currency_type

## Formate un nombre pour l'affichage des bonus
static func format_bonus(value: float, stat_name: String) -> String:
	var formatted_number = BigNumberManager.format_number(value)
	return "%s: +%s" % [stat_name, formatted_number]

## Formate un nombre pour l'affichage des niveaux
static func format_level(value: int) -> String:
	return "Level " + str(value)

## Formate un nombre pour l'affichage des quantités
static func format_quantity(value: int) -> String:
	return BigNumberManager.format_number(float(value))

## Formate un nombre pour l'affichage des durées (en secondes)
static func format_duration(seconds: float) -> String:
	if seconds < 60:
		return "%.1fs" % seconds
	elif seconds < 3600:
		var minutes = seconds / 60
		return "%.1fm" % minutes
	elif seconds < 86400:
		var hours = seconds / 3600
		return "%.1fh" % hours
	else:
		var days = seconds / 86400
		return "%.1fd" % days

## Formate un nombre pour l'affichage des taux (par seconde)
static func format_rate(value: float) -> String:
	var formatted_number = BigNumberManager.format_number(value)
	return formatted_number + "/s"

## Formate un nombre pour l'affichage des multiplicateurs
static func format_multiplier(value: float) -> String:
	if value == 1.0:
		return "1x"
	elif value < 1.0:
		return "%.2fx" % value
	else:
		return "%.1fx" % value

## Formate un nombre pour l'affichage des statistiques
static func format_stat(value: float, stat_name: String) -> String:
	var formatted_number = BigNumberManager.format_number(value)
	return "%s: %s" % [stat_name, formatted_number]

## Formate un nombre pour l'affichage des coûts d'amélioration
static func format_upgrade_cost(value: float, currency_type: String = "g") -> String:
	if value <= 0:
		return "Free"
	
	var formatted_number = BigNumberManager.format_number(value)
	return "Cost: %s %s" % [formatted_number, currency_type]

## Formate un nombre pour l'affichage des gains
static func format_gain(value: float, gain_type: String = "") -> String:
	var formatted_number = BigNumberManager.format_number(value)
	if gain_type.is_empty():
		return "+" + formatted_number
	else:
		return "+%s %s" % [formatted_number, gain_type]

## Formate un nombre pour l'affichage des pertes
static func format_loss(value: float, loss_type: String = "") -> String:
	var formatted_number = BigNumberManager.format_number(value)
	if loss_type.is_empty():
		return "-" + formatted_number
	else:
		return "-%s %s" % [formatted_number, loss_type]

## Formate un nombre pour l'affichage des comparaisons
static func format_comparison(current: float, target: float) -> String:
	var current_formatted = BigNumberManager.format_number(current)
	var target_formatted = BigNumberManager.format_number(target)
	return "%s / %s" % [current_formatted, target_formatted]

## Formate un nombre pour l'affichage des progressions
static func format_progress(current: float, max: float) -> String:
	if max <= 0:
		return "0%"
	
	var percentage = (current / max) * 100
	var current_formatted = BigNumberManager.format_number(current)
	var max_formatted = BigNumberManager.format_number(max)
	var percentage_formatted = format_percentage(percentage, 1)
	
	return "%s / %s (%s)" % [current_formatted, max_formatted, percentage_formatted]
