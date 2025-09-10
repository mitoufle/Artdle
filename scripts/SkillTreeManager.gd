extends Node
class_name SkillTreeManager

## Gère l'arbre de compétences d'ascension
## Permet de débloquer et améliorer les compétences

#==============================================================================
# Signals
#==============================================================================
signal skill_unlocked(skill_name: String)
signal skill_upgraded(skill_name: String, new_level: int)
signal autoclick_unlocked()

#==============================================================================
# Skill Definitions
#==============================================================================
enum SkillType {
	PASSIVE,    # Effet permanent
	UNLOCK,     # Débloque une fonctionnalité
	UPGRADE     # Améliore une fonctionnalité existante
}

class Skill:
	var name: String
	var description: String
	var effect: String
	var base_cost: int
	var cost_multiplier: float
	var multiple_buy: bool
	var parent: String
	var skill_type: SkillType
	var unlocked: bool = false
	var level: int = 0
	var max_level: int = 1
	
	func _init(skill_name: String, skill_description: String, skill_effect: String, 
			   skill_base_cost: int, skill_cost_multiplier: float, skill_multiple_buy: bool, 
			   skill_parent: String, skill_type: SkillType = SkillType.PASSIVE):
		name = skill_name
		description = skill_description
		effect = skill_effect
		base_cost = skill_base_cost
		cost_multiplier = skill_cost_multiplier
		multiple_buy = skill_multiple_buy
		parent = skill_parent
		skill_type = skill_type
		max_level = 1 if not skill_multiple_buy else 999

#==============================================================================
# Skills Database
#==============================================================================
var skills: Dictionary = {}

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_initialize_skills()

#==============================================================================
# Public API
#==============================================================================

## Initialise tous les skills depuis le fichier skill_tree.txt
func _initialize_skills() -> void:
	# Skills exactement comme dans skill_tree.txt
	_add_skill("Devotion", 
		"Periodically pray to the tree of wisdom to get passive inspiration income",
		"Passive inspiration generation",
		1, 2.0, true, "root", SkillType.PASSIVE)
	
	# Limiter Devotion à 5 niveaux maximum
	skills["Devotion"].max_level = 5
	
	_add_skill("Icon influence", 
		"Unlock Painting",
		"Unlocks painting functionality",
		2, 1.0, false, "Devotion", SkillType.UNLOCK)
	
	_add_skill("Capitalist", 
		"your canvas sell for higher prices",
		"Increases canvas sell price",
		2, 2.0, true, "Icon influence", SkillType.UPGRADE)
	
	_add_skill("Swift brush", 
		"Unlock an upgrade to speed up canvas completion",
		"Unlocks autoclick functionality",
		10, 1.0, false, "Capitalist", SkillType.UNLOCK)
	
	_add_skill("Storage room", 
		"Unlock an upgrade to be able to store canvas once completed and bulk sell",
		"Unlocks canvas storage",
		15, 1.0, false, "Capitalist", SkillType.UNLOCK)
	
	_add_skill("Taylorism", 
		"Increase gold and inspiration gain while painting",
		"Increases painting rewards",
		2, 2.0, true, "Capitalist", SkillType.UPGRADE)
	
	_add_skill("Megalomania", 
		"Unlock an upgrade to be able to paint bigger canvas",
		"Unlocks canvas size upgrades",
		25, 1.0, false, "Capitalist", SkillType.UNLOCK)
	
	# Débloquer automatiquement le skill racine
	skills["Devotion"].unlocked = true

## Ajoute un skill à la base de données
func _add_skill(name: String, description: String, effect: String, 
				base_cost: int, cost_multiplier: float, multiple_buy: bool, 
				parent: String, skill_type: SkillType) -> void:
	var skill = Skill.new(name, description, effect, base_cost, cost_multiplier, multiple_buy, parent, skill_type)
	skills[name] = skill

## Tente d'acheter un skill
func buy_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		GameState.logger.error("Skill '%s' not found" % skill_name)
		return false
	
	var skill = skills[skill_name]
	
	# Vérifier si le skill est déjà au niveau maximum
	if skill.level >= skill.max_level:
		GameState.logger.warning("Skill '%s' is already at maximum level" % skill_name)
		return false
	
	# Vérifier si le parent est débloqué
	if skill.parent != "root" and not is_skill_unlocked(skill.parent):
		GameState.logger.warning("Parent skill '%s' not unlocked for '%s'" % [skill.parent, skill_name])
		return false
	
	# Calculer le coût
	var cost = _calculate_skill_cost(skill)
	if not GameState.currency_manager.has_enough("ascendancy_points", cost):
		GameState.logger.warning("Not enough ascendancy points to buy skill '%s' (need %d)" % [skill_name, cost])
		return false
	
	# Acheter le skill
	GameState.currency_manager.subtract_currency("ascendancy_points", cost)
	skill.level += 1
	skill.unlocked = true
	
	# Appliquer l'effet du skill
	_apply_skill_effect(skill)
	
	# Émettre les signaux
	skill_upgraded.emit(skill_name, skill.level)
	if skill.level == 1:  # Premier achat
		skill_unlocked.emit(skill_name)
	
	GameState.logger.info("Skill '%s' purchased (level %d)" % [skill_name, skill.level])
	return true

## Vérifie si un skill est débloqué
func is_skill_unlocked(skill_name: String) -> bool:
	if not skills.has(skill_name):
		return false
	return skills[skill_name].unlocked

## Récupère le niveau d'un skill
func get_skill_level(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 0
	return skills[skill_name].level

## Récupère le coût d'un skill
func get_skill_cost(skill_name: String) -> int:
	if not skills.has(skill_name):
		return 0
	return _calculate_skill_cost(skills[skill_name])

## Récupère tous les skills disponibles
func get_available_skills() -> Array[String]:
	var available: Array[String] = []
	
	for skill_name in skills.keys():
		var skill = skills[skill_name]
		if skill.level < skill.max_level and _can_buy_skill(skill):
			available.append(skill_name)
	
	return available

## Récupère tous les skills débloqués
func get_unlocked_skills() -> Array[String]:
	var unlocked: Array[String] = []
	
	for skill_name in skills.keys():
		if is_skill_unlocked(skill_name):
			unlocked.append(skill_name)
	
	return unlocked

#==============================================================================
# Private Methods
#==============================================================================

## Calcule le coût d'un skill
func _calculate_skill_cost(skill: Skill) -> int:
	if skill.cost_multiplier == 1.0:
		return skill.base_cost
	
	return int(skill.base_cost * pow(skill.cost_multiplier, skill.level))

## Vérifie si un skill peut être acheté
func _can_buy_skill(skill: Skill) -> bool:
	# Vérifier le parent
	if skill.parent != "root" and not is_skill_unlocked(skill.parent):
		return false
	
	# Vérifier le niveau maximum
	if skill.level >= skill.max_level:
		return false
	
	return true

## Applique l'effet d'un skill
func _apply_skill_effect(skill: Skill) -> void:
	match skill.name:
		"Devotion":
			# Utiliser la fonction de mise à jour qui gère l'évolution dynamique
			update_devotion_passive_income()
			GameState.logger.info("Devotion level %d activated with dynamic scaling" % skill.level)
		
		"Swift brush":
			if skill.level == 1:
				# Débloquer l'autoclick
				GameState.clicker_manager.set_autoclick_enabled(true)
				autoclick_unlocked.emit()
				GameState.logger.info("Autoclick unlocked!")
		
		"Capitalist":
			# Améliorer le prix de vente des canvas
			var price_increase = skill.level * 0.1  # 10% par niveau
			GameState.canvas_manager.add_sell_price_multiplier(price_increase)
		
		"Taylorism":
			# Améliorer les gains de peinture
			var gain_increase = skill.level * 0.05  # 5% par niveau
			GameState.canvas_manager.add_painting_gain_multiplier(gain_increase)
		
		"Storage room":
			if skill.level == 1:
				# Débloquer le stockage de canvas
				GameState.canvas_manager.unlock_canvas_storage()
		
		"Megalomania":
			if skill.level == 1:
				# Débloquer les améliorations de taille de canvas
				GameState.canvas_manager.unlock_canvas_size_upgrades()

## Met à jour le revenu passif de Devotion (appelé quand le niveau change)
func update_devotion_passive_income() -> void:
	if not skills.has("Devotion"):
		return
	
	var devotion_skill = skills["Devotion"]
	if devotion_skill.level >= 1:
		# Recalculer les effets basés sur le niveau actuel
		var base_amount = 1.0
		var base_interval = 0.5  # Changé de 5.0 à 0.5 (2 fois par seconde)
		var player_level = GameState.experience_manager.get_level()
		
		# Niveau 2: Multiplier le taux par le niveau du joueur (évolue dynamiquement)
		if devotion_skill.level >= 2:
			base_amount *= player_level
		
		# Niveau 3: Augmenter le rythme en fonction du niveau (évolue dynamiquement)
		if devotion_skill.level >= 3:
			base_interval = max(0.05, 0.5 - (player_level * 0.02))  # Min 0.05 seconde (20 fois par seconde max)
		
		# Niveau 4: Doubler le gain passif
		if devotion_skill.level >= 4:
			base_amount *= 2.0
		
		# Mettre à jour le revenu passif avec les nouvelles valeurs
		GameState.passive_income_manager.add_passive_income(
			"devotion_prayer", 
			"inspiration", 
			base_amount,
			base_interval
		)
		
		# Log pour debug
		GameState.logger.debug("Devotion updated: Level %d, Player Level %d, Amount %.1f, Interval %.1f" % [devotion_skill.level, player_level, base_amount, base_interval])

## Réinitialise tous les skills
func reset_skills() -> void:
	for skill in skills.values():
		skill.unlocked = false
		skill.level = 0
	
	# Redébloquer le skill racine
	skills["Devotion"].unlocked = true

## Alias pour la compatibilité avec SaveManager
func reset_skill_tree() -> void:
	reset_skills()
