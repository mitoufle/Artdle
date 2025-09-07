class_name BigNumberManager
extends RefCounted

## Gestionnaire des très grands nombres pour éviter les overflows
## Utilise une notation scientifique avec des suffixes (K, M, B, T, etc.)

#==============================================================================
# Constants
#==============================================================================
const SUFFIXES = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg", "Novg", "Tg", "Utg", "Dtg", "Ttg", "Qatg", "Qitg", "Sxtg", "Sptg", "Octg", "Notg"
]

const SCIENTIFIC_THRESHOLD = 1e3  # Seuil pour commencer à utiliser les suffixes
const MAX_DECIMALS = 2  # Nombre maximum de décimales à afficher

#==============================================================================
# Public Methods
#==============================================================================

## Convertit un nombre en notation scientifique avec suffixe
static func format_number(value: float) -> String:
	if value < 0:
		return "-" + format_number(-value)
	
	if value == 0:
		return "0"
	
	if value < SCIENTIFIC_THRESHOLD:
		return _format_small_number(value)
	
	# Calculer l'ordre de grandeur
	var magnitude = int(log(value) / log(1000))
	magnitude = min(magnitude, SUFFIXES.size() - 1)
	
	# Calculer la valeur normalisée
	var normalized_value = value / pow(1000, magnitude)
	
	# Formater avec le bon nombre de décimales
	var decimals = _calculate_decimals(normalized_value)
	var formatted_value = "%.*f" % [decimals, normalized_value]
	
	# Nettoyer les zéros inutiles
	formatted_value = _clean_zeros(formatted_value)
	
	return formatted_value + SUFFIXES[magnitude]

## Convertit un nombre en notation scientifique complète (ex: 1.23e15)
static func format_scientific(value: float) -> String:
	if value == 0:
		return "0"
	
	# Utiliser la notation scientifique de GDScript
	var scientific_str = str(value)
	if "e" in scientific_str or "E" in scientific_str:
		return scientific_str
	else:
		# Pour les très grands nombres, forcer la notation scientifique
		var magnitude = int(log(value) / log(10))
		var normalized = value / pow(10, magnitude)
		return "%.2fe%d" % [normalized, magnitude]

## Convertit un nombre en notation compacte (ex: 1.23K, 4.56M)
static func format_compact(value: float) -> String:
	return format_number(value)

## Vérifie si un nombre est valide (pas d'overflow)
static func is_valid_number(value: float) -> bool:
	return is_finite(value) and not is_nan(value)

## Convertit un string formaté en nombre (pour les sauvegardes)
static func parse_formatted_number(formatted: String) -> float:
	if formatted.is_empty():
		return 0.0
	
	# Nettoyer le string
	formatted = formatted.strip_edges()
	
	# Gérer les nombres négatifs
	var is_negative = formatted.begins_with("-")
	if is_negative:
		formatted = formatted.substr(1)
	
	# Trouver le suffixe
	var suffix = ""
	var number_part = formatted
	
	for i in range(SUFFIXES.size() - 1, -1, -1):
		var current_suffix = SUFFIXES[i]
		if current_suffix != "" and formatted.ends_with(current_suffix):
			suffix = current_suffix
			number_part = formatted.substr(0, formatted.length() - current_suffix.length())
			break
	
	# Parser le nombre
	var number = number_part.to_float()
	if not is_valid_number(number):
		return 0.0
	
	# Appliquer le multiplicateur du suffixe
	var multiplier = pow(1000, SUFFIXES.find(suffix))
	number *= multiplier
	
	return -number if is_negative else number

#==============================================================================
# Private Methods
#==============================================================================

static func _format_small_number(value: float) -> String:
	if value == int(value):
		return str(int(value))
	else:
		return "%.2f" % value

static func _calculate_decimals(normalized_value: float) -> int:
	if normalized_value >= 100:
		return 0
	elif normalized_value >= 10:
		return 1
	else:
		return MAX_DECIMALS

static func _clean_zeros(formatted: String) -> String:
	# Supprimer les zéros inutiles à la fin
	if formatted.contains("."):
		formatted = formatted.rstrip("0")
		# Supprimer le point s'il n'y a plus de décimales
		if formatted.ends_with("."):
			formatted = formatted.substr(0, formatted.length() - 1)
	
	return formatted

#==============================================================================
# Utility Methods
#==============================================================================

## Additionne deux nombres en gérant les très grands nombres
static func safe_add(a: float, b: float) -> float:
	if not is_valid_number(a) or not is_valid_number(b):
		return 0.0
	
	var result = a + b
	return result if is_valid_number(result) else 0.0

## Multiplie deux nombres en gérant les très grands nombres
static func safe_multiply(a: float, b: float) -> float:
	if not is_valid_number(a) or not is_valid_number(b):
		return 0.0
	
	var result = a * b
	return result if is_valid_number(result) else 0.0

## Divise deux nombres en gérant les très grands nombres
static func safe_divide(a: float, b: float) -> float:
	if not is_valid_number(a) or not is_valid_number(b) or b == 0:
		return 0.0
	
	var result = a / b
	return result if is_valid_number(result) else 0.0

## Compare deux nombres en gérant les très grands nombres
static func safe_compare(a: float, b: float) -> int:
	if not is_valid_number(a) and not is_valid_number(b):
		return 0
	elif not is_valid_number(a):
		return -1
	elif not is_valid_number(b):
		return 1
	elif a < b:
		return -1
	elif a > b:
		return 1
	else:
		return 0
