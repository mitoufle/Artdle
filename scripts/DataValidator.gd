extends Node
class_name DataValidator

## Système de validation des données pour améliorer la robustesse
## Valide les entrées utilisateur et les données de jeu

#==============================================================================
# Public API
#==============================================================================

## Valide une valeur de devise
func validate_currency_value(value: float, currency_name: String = "") -> bool:
	if not is_finite(value):
		GameState.logger.error("Currency value must be finite, got: %s" % str(value), currency_name)
		return false
	
	if value < 0:
		GameState.logger.warning("Currency value is negative: %s" % str(value), currency_name)
	
	return true

## Valide un niveau
func validate_level(level: int) -> bool:
	if level < 1:
		GameState.logger.error("Level must be positive, got: %d" % level)
		return false
	
	if level > 1000:  # Limite raisonnable
		GameState.logger.warning("Level is very high: %d" % level)
	
	return true

## Valide un coût d'upgrade
func validate_upgrade_cost(cost: float, upgrade_name: String = "") -> bool:
	if not is_finite(cost):
		GameState.logger.error("Upgrade cost must be finite, got: %s" % str(cost), upgrade_name)
		return false
	
	if cost < 0:
		GameState.logger.error("Upgrade cost cannot be negative: %s" % str(cost), upgrade_name)
		return false
	
	return true

## Valide un nom de devise
func validate_currency_name(currency_name: String) -> bool:
	if currency_name.is_empty():
		GameState.logger.error("Currency name cannot be empty")
		return false
	
	if not currency_name.is_valid_identifier():
		GameState.logger.error("Currency name must be a valid identifier: %s" % currency_name)
		return false
	
	return true

## Valide une configuration de canvas
func validate_canvas_config(width: int, height: int) -> bool:
	if width <= 0 or height <= 0:
		GameState.logger.error("Canvas dimensions must be positive: %dx%d" % [width, height])
		return false
	
	if width > 1000 or height > 1000:  # Limite de performance
		GameState.logger.warning("Canvas dimensions are very large: %dx%d" % [width, height])
	
	return true

## Valide un chemin de scène
func validate_scene_path(path: String) -> bool:
	if path.is_empty():
		GameState.logger.error("Scene path cannot be empty")
		return false
	
	if not path.ends_with(".tscn"):
		GameState.logger.error("Scene path must end with .tscn: %s" % path)
		return false
	
	return true

## Valide un dictionnaire de configuration
func validate_config_dict(config: Dictionary, required_keys: Array[String]) -> bool:
	for key in required_keys:
		if not config.has(key):
			GameState.logger.error("Configuration missing required key: %s" % key)
			return false
	
	return true

## Valide une valeur de pourcentage (0.0 à 1.0)
func validate_percentage(value: float, field_name: String = "") -> bool:
	if not is_finite(value):
		GameState.logger.error("Percentage value must be finite: %s" % str(value), field_name)
		return false
	
	if value < 0.0 or value > 1.0:
		GameState.logger.error("Percentage value must be between 0.0 and 1.0, got: %s" % str(value), field_name)
		return false
	
	return true

## Valide un ID de skill tree
func validate_skill_id(skill_id: String) -> bool:
	if skill_id.is_empty():
		GameState.logger.error("Skill ID cannot be empty")
		return false
	
	if not skill_id.is_valid_identifier():
		GameState.logger.error("Skill ID must be a valid identifier: %s" % skill_id)
		return false
	
	return true
