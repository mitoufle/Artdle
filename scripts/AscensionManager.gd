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
	
	# Augmenter le coût pour la prochaine ascension
	ascendancy_cost = int(ascendancy_cost * GameConfig.ASCENDANCY_COST_MULTIPLIER)
	
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
	# Réinitialiser les devises principales
	GameState.currency_manager.set_currency("inspiration", 0)
	GameState.currency_manager.set_currency("gold", 0)
	
	# Réinitialiser le canvas
	GameState.canvas_manager.reset_canvas()
	
	# Réinitialiser le système de clic
	GameState.clicker_manager.reset_clicker()

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
