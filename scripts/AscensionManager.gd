extends Node
class_name AscensionManager

## Gère le système d'ascension et de prestige
## Sépare la logique d'ascension du GameState principal

#==============================================================================
# Signals
#==============================================================================
signal ascended()
signal ascendancy_level_changed(new_level: float)
signal ascendancy_point_changed(new_points: float)

#==============================================================================
# Ascension State
#==============================================================================
var ascendancy_cost: float = GameConfig.BASE_ASCENDANCY_COST
var ascend_level: int = GameConfig.DEFAULT_ASCEND_LEVEL

#==============================================================================
# Public API
#==============================================================================

## Tente d'effectuer une ascension
func ascend() -> bool:
	if not GameState.currency_manager.has_enough("fame", ascendancy_cost):
		return false
	
	# Retirer le coût d'ascension
	GameState.currency_manager.subtract_currency("fame", ascendancy_cost)
	
	# Ajouter les points d'ascendance
	GameState.currency_manager.add_currency("ascendancy_points", GameConfig.ASCENDANCY_POINTS_PER_ASCENSION)
	GameState.currency_manager.add_currency("ascend_level", GameConfig.ASCEND_LEVELS_PER_ASCENSION)
	
	# Réinitialiser les systèmes
	_reset_game_systems()
	
	# Ascension cost remains fixed - no scaling
	# ascendancy_cost stays the same for all ascensions
	
	ascended.emit()
	return true

## Vérifie si l'ascension est possible
func can_ascend() -> bool:
	return GameState.currency_manager.has_enough("fame", ascendancy_cost)

## Récupère le coût d'ascension actuel
func get_ascendancy_cost() -> float:
	return ascendancy_cost

## Récupère les points d'ascendance actuels
func get_ascendancy_points() -> float:
	return GameState.currency_manager.get_currency("ascendancy_points")

## Récupère le niveau d'ascendance actuel
func get_ascend_level() -> float:
	return GameState.currency_manager.get_currency("ascend_level")

## Réinitialise le système d'ascension
func reset_ascension() -> void:
	ascendancy_cost = GameConfig.BASE_ASCENDANCY_COST

#==============================================================================
# Private Methods
#==============================================================================

func _reset_game_systems() -> void:
	# Vérifier si Devotion niveau 5 est actif
	var devotion_level = GameState.skill_tree_manager.get_skill_level("Devotion")
	var inspiration_to_keep = 0.0
	
	if devotion_level >= 5:
		# Garder 0.1% de l'inspiration actuelle
		var current_inspiration = GameState.currency_manager.get_currency("inspiration")
		inspiration_to_keep = current_inspiration * 0.001  # 0.1%
		GameState.logger.info("Devotion level 5: Keeping %.1f inspiration (0.1% of %.1f)" % [inspiration_to_keep, current_inspiration])
	
	# Réinitialiser les devises principales
	GameState.currency_manager.set_currency("inspiration", inspiration_to_keep)
	GameState.currency_manager.set_currency("gold", 0)
	GameState.currency_manager.set_currency("fame", 0)
	GameState.currency_manager.set_currency("paint_mastery", 0)
	
	# Réinitialiser le canvas (including all upgrades)
	GameState.canvas_manager.reset_canvas()
	
	# Réinitialiser le système de clic
	GameState.clicker_manager.reset_clicker()
	
	# Réinitialiser l'inventaire et l'atelier
	GameState.inventory_manager.reset_inventory()
	GameState.craft_manager.reset_workshop()
	
	# Réinitialiser l'expérience
	GameState.experience_manager.reset_experience()
	
	# Réinitialiser les revenus passifs
	GameState.passive_income_manager.reset_passive_income()
	
	GameState.logger.info("Complete game reset performed during ascension")

#==============================================================================
# Public API Methods
#==============================================================================

## Définit le coût d'ascension (pour le système de sauvegarde)
func set_ascendancy_cost(value: float) -> void:
	ascendancy_cost = value

## Définit le niveau d'ascension (pour le système de sauvegarde)
func set_ascend_level(value: int) -> void:
	ascend_level = value
	ascendancy_level_changed.emit(ascend_level)
