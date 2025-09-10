class_name CurrencyBonusManager
extends RefCounted

## Gestionnaire des bonus de devises basés sur l'équipement
## Applique les bonus des items équipés aux gains de devises

#==============================================================================
# Public Methods
#==============================================================================

## Récupère le multiplicateur de bonus pour un type de devise
static func get_bonus_multiplier(currency_type: String) -> float:
	if not GameState or not GameState.inventory_manager:
		return 1.0
	
	var bonuses = GameState.inventory_manager.get_total_bonuses()
	
	match currency_type:
		"inspiration":
			return _get_inspiration_bonus(bonuses)
			print(_get_inspiration_bonus(bonuses))
		"gold":
			return _get_gold_bonus(bonuses)
		"fame":
			return _get_fame_bonus(bonuses)
		"ascendancy_points":
			return _get_ascendancy_bonus(bonuses)
		"paint_mastery":
			return _get_paint_mastery_bonus(bonuses)
		"canvas_speed":
			return _get_canvas_speed_bonus(bonuses)
		"painting_speed":
			return _get_painting_speed_bonus(bonuses)
		"pixel_gain":
			return _get_pixel_gain_bonus(bonuses)
		_:
			return _get_generic_bonus(bonuses)

## Applique les bonus d'équipement à un gain de devise
static func apply_bonuses(currency_type: String, base_amount: float) -> float:
	if not GameState or not GameState.inventory_manager:
		GameState.logger.debug("No GameState or InventoryManager available for bonus calculation")
		return base_amount
	
	var bonuses = GameState.inventory_manager.get_total_bonuses()
	var bonus_multiplier = 1.0
	
	# Appliquer les bonus spécifiques à chaque type de devise
	match currency_type:
		"inspiration":
			bonus_multiplier = _get_inspiration_bonus(bonuses)
		"gold":
			bonus_multiplier = _get_gold_bonus(bonuses)
		"fame":
			bonus_multiplier = _get_fame_bonus(bonuses)
		"ascendancy_points":
			bonus_multiplier = _get_ascendancy_bonus(bonuses)
		"paint_mastery":
			bonus_multiplier = _get_paint_mastery_bonus(bonuses)
		_:
			# Pour les autres devises, utiliser un bonus générique
			bonus_multiplier = _get_generic_bonus(bonuses)
	
	var final_amount = base_amount * bonus_multiplier
	
	# Log pour debug (toujours logguer pour voir ce qui se passe)
	GameState.logger.debug("Currency bonus calculation: %s base=%.2f, multiplier=%.2f, final=%.2f, bonuses=%s" % [currency_type, base_amount, bonus_multiplier, final_amount, bonuses])
	
	return final_amount

## Récupère le multiplicateur de bonus pour l'inspiration
static func _get_inspiration_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct d'inspiration
	if bonuses.has("inspiration_generation"):
		multiplier *= bonuses["inspiration_generation"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour l'or
static func _get_gold_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct d'or
	if bonuses.has("coin_generation"):
		multiplier *= bonuses["coin_generation"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour la renommée
static func _get_fame_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de renommée
	if bonuses.has("fame_generation"):
		multiplier *= bonuses["fame_generation"]
	
	# Bonus de gain de renommée (anciennement ascendancy_gain)
	if bonuses.has("fame_gain"):
		multiplier *= bonuses["fame_gain"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour les points d'ascension
static func _get_ascendancy_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct d'ascension
	if bonuses.has("ascendancy_generation"):
		multiplier *= bonuses["ascendancy_generation"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour la renommée (remplace ascendancy_gain)
static func _get_fame_gain_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de renommée (anciennement ascendancy_gain)
	if bonuses.has("fame_gain"):
		multiplier *= bonuses["fame_gain"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour la maîtrise de peinture
static func _get_paint_mastery_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de maîtrise
	if bonuses.has("paint_mastery_generation"):
		multiplier *= bonuses["paint_mastery_generation"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour la vitesse de canvas
static func _get_canvas_speed_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de vitesse de canvas
	if bonuses.has("canvas_speed"):
		multiplier *= bonuses["canvas_speed"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour la vitesse de peinture
static func _get_painting_speed_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de vitesse de peinture
	if bonuses.has("painting_speed"):
		multiplier *= bonuses["painting_speed"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus pour le gain de pixels
static func _get_pixel_gain_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus direct de gain de pixels
	if bonuses.has("pixel_gain"):
		multiplier *= bonuses["pixel_gain"]
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier

## Récupère le multiplicateur de bonus générique
static func _get_generic_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	
	# Bonus générique de génération
	if bonuses.has("generation_bonus"):
		multiplier *= bonuses["generation_bonus"]
	
	return multiplier


## Formate les bonus pour l'affichage
static func format_bonus_info(currency_type: String) -> String:
	var multiplier = get_bonus_multiplier(currency_type)
	
	if multiplier <= 1.0:
		return "No bonus"
	elif multiplier < 2.0:
		return "%.1fx bonus" % multiplier
	else:
		return "%.1fx bonus" % multiplier
