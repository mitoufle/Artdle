extends Node
class_name ExperienceManager

## Gère le système d'expérience et de niveaux
## Sépare la logique d'expérience du GameState principal

#==============================================================================
# Signals
#==============================================================================
signal experience_changed(new_experience: float, experience_to_next_level: float)
signal level_changed(new_level: int)

#==============================================================================
# Experience State
#==============================================================================
var experience: float = GameConfig.DEFAULT_EXPERIENCE
var level: int = GameConfig.DEFAULT_LEVEL
var experience_to_next_level: float = GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL

#==============================================================================
# Public API
#==============================================================================

## Ajoute de l'expérience
func add_experience(amount: float) -> void:
	if amount <= 0:
		return
	
	experience += amount
	
	# Vérifier les montées de niveau
	while experience >= experience_to_next_level:
		level += 1
		experience -= experience_to_next_level
		experience_to_next_level = int(experience_to_next_level * GameConfig.EXPERIENCE_MULTIPLIER)
		level_changed.emit(level)
	
	experience_changed.emit(experience, experience_to_next_level)

## Récupère l'expérience actuelle
func get_experience() -> float:
	return experience

## Récupère le niveau actuel
func get_level() -> int:
	return level

## Définit l'expérience (pour le système de sauvegarde)
func set_experience(value: float) -> void:
	experience = value
	emit_experience_changed()

## Définit le niveau (pour le système de sauvegarde)
func set_level(value: int) -> void:
	level = value
	emit_level_changed()

## Définit l'expérience nécessaire pour le niveau suivant (pour le système de sauvegarde)
func set_experience_to_next_level(value: float) -> void:
	experience_to_next_level = value

## Récupère l'expérience nécessaire pour le prochain niveau
func get_experience_to_next_level() -> float:
	return experience_to_next_level

## Récupère le pourcentage de progression vers le prochain niveau
func get_level_progress() -> float:
	if experience_to_next_level <= 0:
		return 1.0
	
	return experience / experience_to_next_level

## Réinitialise l'expérience et les niveaux
func reset_experience() -> void:
	experience = GameConfig.DEFAULT_EXPERIENCE
	level = GameConfig.DEFAULT_LEVEL
	experience_to_next_level = GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL
	
	experience_changed.emit(experience, experience_to_next_level)
	level_changed.emit(level)

## Définit directement le niveau (pour les tests/debug)
func set_level_direct(new_level: int) -> void:
	if new_level < 1:
		return
	
	level = new_level
	experience = 0
	experience_to_next_level = GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL
	
	# Calculer l'expérience nécessaire pour ce niveau
	for i in range(1, level):
		experience_to_next_level = int(experience_to_next_level * GameConfig.EXPERIENCE_MULTIPLIER)
	
	level_changed.emit(level)
	experience_changed.emit(experience, experience_to_next_level)

#==============================================================================
# Private Methods
#==============================================================================

## Émet le signal d'expérience changée
func emit_experience_changed() -> void:
	experience_changed.emit(experience, experience_to_next_level)

## Émet le signal de niveau changé
func emit_level_changed() -> void:
	level_changed.emit(level)
