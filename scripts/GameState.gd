extends Node

## GameState refactorisé - Gestion centralisée de l'état du jeu
## Utilise des managers spécialisés pour une meilleure organisation

#==============================================================================
# Big Number Management
#==============================================================================
const BigNumberManager = preload("res://scripts/BigNumberManager.gd")
const CurrencyBonusManager = preload("res://scripts/CurrencyBonusManager.gd")

#==============================================================================
# Bonus System
#==============================================================================

## Applique les bonus d'équipement à un gain d'expérience
func apply_experience_bonus(base_amount: float) -> float:
	if not inventory_manager:
		return base_amount
	
	var bonuses = inventory_manager.get_total_bonuses()
	var bonus_multiplier = _get_experience_bonus(bonuses)
	
	var final_amount = base_amount * bonus_multiplier
	logger.debug("Experience bonus: %.2f -> %.2f (%.2fx)" % [base_amount, final_amount, bonus_multiplier])
	return final_amount

## Applique les bonus d'équipement à un gain de devise
func apply_currency_bonus(currency_type: String, base_amount: float) -> float:
	if not inventory_manager:
		return base_amount
	
	var bonuses = inventory_manager.get_total_bonuses()
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
			bonus_multiplier = _get_generic_bonus(bonuses)
		_:
			bonus_multiplier = _get_generic_bonus(bonuses)
	
	var final_amount = base_amount * bonus_multiplier
	logger.debug("Currency bonus: %s %.2f -> %.2f (%.2fx)" % [currency_type, base_amount, final_amount, bonus_multiplier])
	return final_amount

## Récupère le multiplicateur de bonus pour l'inspiration
func _get_inspiration_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	if bonuses.has("inspiration_gain"):
		multiplier *= bonuses["inspiration_gain"]
	return multiplier

## Récupère le multiplicateur de bonus pour l'or
func _get_gold_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	if bonuses.has("gold_gain"):
		multiplier *= bonuses["gold_gain"]
	return multiplier

## Récupère le multiplicateur de bonus pour la renommée
func _get_fame_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	# Pas de stat spécifique pour la renommée dans les items
	# Utiliser les bonus génériques si disponibles
	return multiplier

## Récupère le multiplicateur de bonus pour l'ascendancy
func _get_ascendancy_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	if bonuses.has("ascendancy_gain"):
		multiplier *= bonuses["ascendancy_gain"]
	return multiplier


## Récupère le multiplicateur de bonus pour l'expérience
func _get_experience_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	if bonuses.has("experience_gain"):
		multiplier *= bonuses["experience_gain"]
	return multiplier

## Récupère le multiplicateur de bonus générique
func _get_generic_bonus(bonuses: Dictionary) -> float:
	var multiplier = 1.0
	# Pas de bonus générique dans les items actuels
	return multiplier

#==============================================================================
# Signals (Legacy - pour compatibilité avec l'UI existante)
#==============================================================================
signal inspiration_changed(new_inspiration_value: float)
signal ascendancy_level_changed(new_ascendancy_level_value: float)
signal ascendancy_point_changed(new_ascendancy_point_value: float)
signal gold_changed(new_gold_value: float)
signal paint_mastery_changed(new_paint_mastery_value: float)
signal fame_changed(new_fame_value: float)
signal ascended()

signal canvas_updated(new_texture: ImageTexture)
signal canvas_progress_updated(current_pixels: int, max_pixels: int)
signal canvas_completed()
signal canvas_upgrade_costs_changed(new_costs: Dictionary)
signal canvas_storage_changed(stored_canvases: int, max_storage: int)
signal canvas_storage_upgrade_cost_changed(cost: int)

signal click_stats_changed(new_stats: Dictionary)

signal experience_changed(new_experience_value: float, experience_to_next_level: float)
signal level_changed(new_level_value: int)

#==============================================================================
# Managers
#==============================================================================
var currency_manager: CurrencyManager
var canvas_manager: CanvasManager
var clicker_manager: ClickerManager
var ascension_manager: AscensionManager
var experience_manager: ExperienceManager
var skill_tree_manager: SkillTreeManager
var passive_income_manager: PassiveIncomeManager
var inventory_manager: InventoryManager
var craft_manager: CraftManager
var data_validator: DataValidator
var logger: GameLogger
var save_manager: SaveManager
var feedback_manager: FeedbackManager

#==============================================================================
# Skill Tree Data (Legacy - à déplacer dans un manager dédié plus tard)
#==============================================================================
const SKILL_TREE_DATA = {
	"Devotion": {
		"effect": "Periodically pray to the tree of wisdom to get passive inspiration income",
		"cost": 1,
		"cost_multiplier": 1.0,
		"multiple_buy": false,
		"parent": null,
		"unlocked": false,
		"level": 0
	},
	"Icon influence": {
		"effect": "Unlock Painting",
		"cost": 2,
		"cost_multiplier": 1.0,
		"multiple_buy": false,
		"parent": "Devotion",
		"unlocked": false,
		"level": 0
	},
	"Capitalist": {
		"effect": "your canvas sell for higher prices",
		"cost": 2,
		"cost_multiplier": 2.0,
		"multiple_buy": true,
		"parent": "Icon influence",
		"unlocked": false,
		"level": 0
	},
	"Swift brush": {
		"effect": "Unlock an upgrade to speed up canvas completion",
		"cost": 10,
		"cost_multiplier": 1.0,
		"multiple_buy": false,
		"parent": "Capitalist",
		"unlocked": false,
		"level": 0
	},
	"Storage room": {
		"effect": "Unlock an upgrade to be able to store canvas once completed and bulk sell",
		"cost": 15,
		"cost_multiplier": 1.0,
		"multiple_buy": false,
		"parent": "Capitalist",
		"unlocked": false,
		"level": 0
	},
	"Taylorism": {
		"effect": "Increase gold and inspiration gain while painting",
		"cost": 2,
		"cost_multiplier": 2.0,
		"multiple_buy": true,
		"parent": "Capitalist",
		"unlocked": false,
		"level": 0
	},
	"Megalomania": {
		"effect": "Unlock an upgrade to be able to paint bigger canvas",
		"cost": 25,
		"cost_multiplier": 1.0,
		"multiple_buy": false,
		"parent": "Capitalist",
		"unlocked": false,
		"level": 0
	}
}

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_initialize_managers()
	_connect_manager_signals()

#==============================================================================
# Public API (Legacy - pour compatibilité avec l'UI existante)
#==============================================================================

# Currency Getters
func get_inspiration() -> float:
	return currency_manager.get_currency("inspiration")

func get_gold() -> float:
	return currency_manager.get_currency("gold")

func get_fame() -> float:
	return currency_manager.get_currency("fame")

func get_ascendancy_point() -> float:
	return currency_manager.get_currency("ascendancy_points")

func get_ascend_level() -> float:
	return currency_manager.get_currency("ascend_level")

func get_paint_mastery() -> float:
	return currency_manager.get_currency("paint_mastery")

func get_experience() -> float:
	return experience_manager.get_experience()

func get_level() -> int:
	return experience_manager.get_level()

# Currency Setters (Legacy)
func set_inspiration(amount: float) -> void:
	currency_manager.add_currency("inspiration", amount)

func set_gold(amount: float) -> void:
	currency_manager.add_currency("gold", amount)

func set_fame(amount: float) -> void:
	currency_manager.add_currency("fame", amount)

func set_ascendancy_point(amount: float) -> void:
	currency_manager.add_currency("ascendancy_points", amount)

func set_ascend_level(amount: float) -> void:
	currency_manager.add_currency("ascend_level", amount)

func set_paint_mastery(amount: float) -> void:
	currency_manager.add_currency("paint_mastery", amount)

func set_level(amount: int) -> void:
	experience_manager.set_level(amount)

func add_experience(amount: float) -> void:
	var old_level = experience_manager.get_level()
	experience_manager.add_experience(amount)
	var new_level = experience_manager.get_level()
	
	# Donner 1 renommée par niveau gagné
	var levels_gained = new_level - old_level
	if levels_gained > 0:
		var fame_gained = levels_gained * 1.0
		currency_manager.add_currency_raw("fame", fame_gained)
		logger.info("Level up! Gained %d levels and %d fame" % [levels_gained, fame_gained])

# Canvas Methods (Legacy)
func sell_canvas() -> Dictionary:
	var result = canvas_manager.sell_canvas()
	if result.canvases_sold > 0:
		# Appliquer les bonus d'équipement
		var bonus_gold = apply_currency_bonus("gold", result.gold_gained)
		var bonus_fame = apply_currency_bonus("fame", result.canvases_sold * GameConfig.BASE_FAME_PER_CANVAS)
		
		# Ajouter les devises avec bonus
		currency_manager.add_currency_raw("gold", bonus_gold)
		currency_manager.add_currency_raw("fame", bonus_fame)
		
		# Retourner les montants avec bonus pour le feedback
		return {
			"canvases_sold": result.canvases_sold,
			"gold_gained": bonus_gold,
			"fame_gained": bonus_fame
		}
	
	return result

func upgrade_resolution() -> void:
	canvas_manager.upgrade_resolution()

func upgrade_fill_speed() -> void:
	canvas_manager.upgrade_fill_speed()

func upgrade_canvas_storage() -> void:
	canvas_manager.upgrade_canvas_storage()

# Clicker Methods (Legacy)
func manual_click() -> void:
	clicker_manager.manual_click()

func upgrade_click_power() -> void:
	clicker_manager.upgrade_click_power()

func upgrade_autoclick_speed() -> void:
	clicker_manager.upgrade_autoclick_speed()

# Ascension Methods (Legacy)
func ascend() -> void:
	ascension_manager.ascend()

# Utility Methods (Legacy)
func reduce_by_max_multiple(cost: int, currency: int) -> int:
	if currency <= 0:
		push_error("Currency must be a positive integer")
		return cost
	return cost % currency

func buy_fame_with_gold(amount: float, gold_cost: float) -> bool:
	return currency_manager.exchange_currency("gold", "fame", gold_cost, amount / gold_cost)

#==============================================================================
# Save System API
#==============================================================================

## Sauvegarde le jeu
func save_game() -> bool:
	return save_manager.save_game()

## Charge le jeu
func load_game() -> bool:
	return save_manager.load_game()

## Supprime la sauvegarde
func clear_save() -> bool:
	return save_manager.clear_save()

## Vérifie si une sauvegarde existe
func has_save_file() -> bool:
	return save_manager.has_save_file()

## Récupère les informations de sauvegarde
func get_save_info() -> Dictionary:
	return save_manager.get_save_info()

#==============================================================================
# Private Methods
#==============================================================================

func _initialize_managers() -> void:
	# Créer et initialiser les managers
	currency_manager = CurrencyManager.new()
	canvas_manager = CanvasManager.new()
	clicker_manager = ClickerManager.new()
	ascension_manager = AscensionManager.new()
	experience_manager = ExperienceManager.new()
	skill_tree_manager = SkillTreeManager.new()
	passive_income_manager = PassiveIncomeManager.new()
	inventory_manager = InventoryManager.new()
	craft_manager = CraftManager.new()
	data_validator = DataValidator.new()
	logger = GameLogger.new()
	save_manager = SaveManager.new()
	feedback_manager = FeedbackManager.new()
	
	# Ajouter les managers à la scène
	add_child(currency_manager)
	add_child(canvas_manager)
	add_child(clicker_manager)
	add_child(ascension_manager)
	add_child(experience_manager)
	add_child(skill_tree_manager)
	add_child(passive_income_manager)
	add_child(inventory_manager)
	add_child(craft_manager)
	add_child(data_validator)
	add_child(logger)
	add_child(save_manager)
	add_child(feedback_manager)
	
	# Configurer le logger
	logger.set_log_level(GameLogger.LogLevel.INFO)
	logger.info("GameState initialized with managers", "GameState")

func _connect_manager_signals() -> void:
	# Connecter les signaux des managers aux signaux legacy
	currency_manager.currency_changed.connect(_on_currency_changed)
	canvas_manager.canvas_updated.connect(_on_canvas_updated)
	canvas_manager.canvas_progress_updated.connect(_on_canvas_progress_updated)
	canvas_manager.canvas_completed.connect(_on_canvas_completed)
	canvas_manager.canvas_storage_changed.connect(_on_canvas_storage_changed)
	canvas_manager.canvas_upgrade_costs_changed.connect(_on_canvas_upgrade_costs_changed)
	canvas_manager.canvas_storage_upgrade_cost_changed.connect(_on_canvas_storage_upgrade_cost_changed)
	
	clicker_manager.click_stats_changed.connect(_on_click_stats_changed)
	
	ascension_manager.ascended.connect(_on_ascended)
	
	experience_manager.experience_changed.connect(_on_experience_changed)
	experience_manager.level_changed.connect(_on_level_changed)
	experience_manager.level_changed.connect(_on_level_changed_for_devotion)
	
	# Connecter les signaux d'ascension
	ascension_manager.ascendancy_level_changed.connect(_on_ascendancy_level_changed)
	ascension_manager.ascendancy_point_changed.connect(_on_ascendancy_point_changed)

# Signal Handlers
func _on_currency_changed(currency_type: String, new_value: float) -> void:
	match currency_type:
		"inspiration":
			inspiration_changed.emit(new_value)
		"gold":
			gold_changed.emit(new_value)
		"fame":
			fame_changed.emit(new_value)
		"ascendancy_points":
			ascendancy_point_changed.emit(new_value)
		"ascend_level":
			ascendancy_level_changed.emit(new_value)
		"paint_mastery":
			paint_mastery_changed.emit(new_value)

func _on_canvas_updated(new_texture: ImageTexture) -> void:
	canvas_updated.emit(new_texture)

func _on_canvas_progress_updated(current_pixels: int, max_pixels: int) -> void:
	canvas_progress_updated.emit(current_pixels, max_pixels)

func _on_canvas_completed() -> void:
	canvas_completed.emit()

func _on_canvas_storage_changed(stored_canvases: int, max_storage: int) -> void:
	canvas_storage_changed.emit(stored_canvases, max_storage)

func _on_canvas_upgrade_costs_changed(new_costs: Dictionary) -> void:
	canvas_upgrade_costs_changed.emit(new_costs)

func _on_canvas_storage_upgrade_cost_changed(cost: int) -> void:
	canvas_storage_upgrade_cost_changed.emit(cost)

func _on_click_stats_changed(new_stats: Dictionary) -> void:
	click_stats_changed.emit(new_stats)

func _on_ascended() -> void:
	ascended.emit()

func _on_experience_changed(new_experience: float, experience_to_next_level: float) -> void:
	experience_changed.emit(new_experience, experience_to_next_level)

func _on_level_changed(new_level: int) -> void:
	level_changed.emit(new_level)

func _on_level_changed_for_devotion(new_level: int) -> void:
	# Mettre à jour le revenu passif de Devotion quand le niveau change
	skill_tree_manager.update_devotion_passive_income()

func _on_ascendancy_level_changed(new_level: float) -> void:
	ascendancy_level_changed.emit(new_level)

func _on_ascendancy_point_changed(new_points: float) -> void:
	ascendancy_point_changed.emit(new_points)
