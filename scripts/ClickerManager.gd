extends Node
class_name ClickerManager

## Gère le système de clic et d'autoclick
## Sépare la logique de clic du GameState principal

#==============================================================================
# Signals
#==============================================================================
signal click_stats_changed(new_stats: Dictionary)

#==============================================================================
# Clicker State
#==============================================================================
var click_power: int = GameConfig.BASE_CLICK_POWER
var autoclick_speed: float = GameConfig.BASE_AUTOCLICK_SPEED
var autoclick_timer: Timer
var autoclick_enabled: bool = false
var autoclick_base_interval: float = 5.0  # 5 secondes de base
var autoclick_speed_multiplier: float = 1.0

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_setup_autoclick_timer()

#==============================================================================
# Public API
#==============================================================================

## Effectue un clic manuel
func manual_click() -> Dictionary:
	GameState.currency_manager.add_currency("inspiration", click_power)
	GameState.experience_manager.add_experience(GameConfig.EXPERIENCE_PER_CLICK)
	
	return {
		"inspiration_gained": click_power,
		"experience_gained": GameConfig.EXPERIENCE_PER_CLICK
	}

## Améliore la puissance de clic
func upgrade_click_power() -> bool:
	if not GameState.currency_manager.has_enough("gold", GameConfig.CLICK_POWER_UPGRADE_COST):
		return false
	
	GameState.currency_manager.subtract_currency("gold", GameConfig.CLICK_POWER_UPGRADE_COST)
	click_power += 1
	_emit_click_stats()
	return true

## Améliore la vitesse d'autoclick
func upgrade_autoclick_speed() -> bool:
	if not GameState.currency_manager.has_enough("gold", GameConfig.AUTOCLICK_SPEED_UPGRADE_COST):
		return false
	
	GameState.currency_manager.subtract_currency("gold", GameConfig.AUTOCLICK_SPEED_UPGRADE_COST)
	autoclick_speed += 1
	_update_autoclick_timer()
	_emit_click_stats()
	return true

## Active ou désactive l'autoclick
func set_autoclick_enabled(enabled: bool) -> void:
	autoclick_enabled = enabled
	
	if enabled:
		# Calculer la vitesse d'autoclick basée sur les améliorations
		_calculate_autoclick_speed()
	else:
		autoclick_speed = 0.0
	
	_update_autoclick_timer()
	_emit_click_stats()

## Réinitialise le système de clic
func reset_clicker() -> void:
	click_power = GameConfig.BASE_CLICK_POWER
	autoclick_speed = GameConfig.BASE_AUTOCLICK_SPEED
	autoclick_enabled = false
	autoclick_speed_multiplier = 1.0
	_update_autoclick_timer()
	_emit_click_stats()

## Récupère les statistiques de clic
func get_click_stats() -> Dictionary:
	return {
		"click_power": click_power,
		"autoclick_speed": autoclick_speed,
		"autoclick_enabled": autoclick_enabled,
		"autoclick_interval": autoclick_base_interval / autoclick_speed_multiplier if autoclick_enabled else 0.0
	}

#==============================================================================
# Private Methods
#==============================================================================

func _setup_autoclick_timer() -> void:
	autoclick_timer = Timer.new()
	add_child(autoclick_timer)
	autoclick_timer.timeout.connect(_on_autoclick_timer_timeout)

func _on_autoclick_timer_timeout() -> void:
	GameState.currency_manager.add_currency("inspiration", click_power)
	GameState.experience_manager.add_experience(GameConfig.EXPERIENCE_PER_CLICK)

func _update_autoclick_timer() -> void:
	if autoclick_enabled and autoclick_speed > 0:
		autoclick_timer.wait_time = 1.0 / autoclick_speed
		autoclick_timer.start()
	else:
		autoclick_timer.stop()

## Calcule la vitesse d'autoclick basée sur les améliorations
func _calculate_autoclick_speed() -> void:
	if not autoclick_enabled:
		autoclick_speed = 0.0
		return
	
	# Vitesse de base : 1 clic toutes les 5 secondes
	var base_speed = 1.0 / autoclick_base_interval
	
	# Appliquer le multiplicateur de vitesse
	autoclick_speed = base_speed * autoclick_speed_multiplier

## Améliore la vitesse d'autoclick (appelé par les skills)
func upgrade_autoclick_speed_multiplier(amount: float) -> void:
	autoclick_speed_multiplier += amount
	if autoclick_enabled:
		_calculate_autoclick_speed()
		_update_autoclick_timer()
	_emit_click_stats()

## Récupère le multiplicateur de vitesse d'autoclick
func get_autoclick_speed_multiplier() -> float:
	return autoclick_speed_multiplier

## Définit le multiplicateur de vitesse d'autoclick (pour la sauvegarde)
func set_autoclick_speed_multiplier(value: float) -> void:
	autoclick_speed_multiplier = value
	if autoclick_enabled:
		_calculate_autoclick_speed()
		_update_autoclick_timer()

#==============================================================================
# Public API Methods
#==============================================================================

## Définit la puissance de clic (pour le système de sauvegarde)
func set_click_power(value: float) -> void:
	click_power = value

## Définit la vitesse d'autoclick (pour le système de sauvegarde)
func set_autoclick_speed(value: float) -> void:
	autoclick_speed = value
	if autoclick_timer:
		autoclick_timer.wait_time = 1.0 / autoclick_speed

func _emit_click_stats() -> void:
	click_stats_changed.emit(get_click_stats())
