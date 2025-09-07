extends BaseView
class_name SkillTreeView

## Vue pour l'arbre de compétences d'ascension

#==============================================================================
# UI References
#==============================================================================
@onready var skill_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var ascendancy_points_label: Label = $TopPanel/AscendancyPointsLabel

#==============================================================================
# State
#==============================================================================
var skill_buttons: Dictionary = {}

#==============================================================================
# BaseView Implementation
#==============================================================================
func _ready() -> void:
	super._ready()
	_connect_view_signals()
	_update_ui()

func _connect_view_signals() -> void:
	# Connecter les signaux du skill tree manager
	if not GameState.skill_tree_manager.skill_unlocked.is_connected(_on_skill_unlocked):
		GameState.skill_tree_manager.skill_unlocked.connect(_on_skill_unlocked)
	
	if not GameState.skill_tree_manager.skill_upgraded.is_connected(_on_skill_upgraded):
		GameState.skill_tree_manager.skill_upgraded.connect(_on_skill_upgraded)
	
	if not GameState.skill_tree_manager.autoclick_unlocked.is_connected(_on_autoclick_unlocked):
		GameState.skill_tree_manager.autoclick_unlocked.connect(_on_autoclick_unlocked)
	
	# Connecter les signaux de devises
	if not GameState.currency_manager.currency_changed.is_connected(_on_currency_changed):
		GameState.currency_manager.currency_changed.connect(_on_currency_changed)
	
	# Connecter le signal de changement de niveau pour mettre à jour les tooltips
	if not GameState.experience_manager.level_changed.is_connected(_on_level_changed):
		GameState.experience_manager.level_changed.connect(_on_level_changed)

func _update_ui() -> void:
	_update_ascendancy_points()
	_create_skill_buttons()
	# Mettre à jour tous les tooltips existants
	for skill_name in skill_buttons.keys():
		_update_skill_button(skill_name)

func _on_skill_unlocked(skill_name: String) -> void:
	GameState.logger.info("Skill unlocked: %s" % skill_name)
	_update_skill_button(skill_name)

func _on_skill_upgraded(skill_name: String, new_level: int) -> void:
	GameState.logger.info("Skill upgraded: %s (level %d)" % [skill_name, new_level])
	_update_skill_button(skill_name)

func _on_autoclick_unlocked() -> void:
	GameState.logger.info("Autoclick unlocked!")
	# Pas de feedback visuel sur l'écran skill tree

func _on_currency_changed(currency_type: String, new_value: float) -> void:
	if currency_type == "ascendancy_points":
		_update_ascendancy_points()

func _on_level_changed(new_level: int) -> void:
	# Mettre à jour tous les tooltips car certains dépendent du niveau du joueur
	for skill_name in skill_buttons.keys():
		_update_skill_button(skill_name)

#==============================================================================
# UI Methods
#==============================================================================

func _update_ascendancy_points() -> void:
	var points = GameState.currency_manager.get_currency("ascendancy_points")
	ascendancy_points_label.text = "Points d'Ascension: %d" % int(points)

func _create_skill_buttons() -> void:
	# Nettoyer les boutons existants
	for child in skill_container.get_children():
		child.queue_free()
	skill_buttons.clear()
	
	# Créer les boutons pour chaque skill
	var skills = GameState.skill_tree_manager.skills
	for skill_name in skills.keys():
		_create_skill_button(skills[skill_name])

func _create_skill_button(skill: SkillTreeManager.Skill) -> void:
	var button = Button.new()
	button.text = "%s (Niveau %d)" % [skill.name, skill.level]
	button.custom_minimum_size = Vector2(300, 60)
	
	# Style du bouton selon l'état
	if skill.unlocked:
		button.modulate = Color.GREEN
	elif _can_buy_skill(skill):
		button.modulate = Color.WHITE
	else:
		button.modulate = Color.GRAY
		button.disabled = true
	
	# Tooltip avec description
	var tooltip_text = "%s\n%s\nCoût: %d points" % [skill.description, skill.effect, GameState.skill_tree_manager.get_skill_cost(skill.name)]
	button.tooltip_text = tooltip_text
	
	# Connecter le signal
	button.pressed.connect(_on_skill_button_pressed.bind(skill.name))
	
	skill_container.add_child(button)
	skill_buttons[skill.name] = button

func _update_skill_button(skill_name: String) -> void:
	if not skill_buttons.has(skill_name):
		return
	
	var skill = GameState.skill_tree_manager.skills[skill_name]
	var button = skill_buttons[skill_name]
	
	button.text = "%s (Niveau %d)" % [skill.name, skill.level]
	
	# Mettre à jour le style
	if skill.unlocked:
		button.modulate = Color.GREEN
	elif _can_buy_skill(skill):
		button.modulate = Color.WHITE
		button.disabled = false
	else:
		button.modulate = Color.GRAY
		button.disabled = true
	
	# Mettre à jour le tooltip avec les effets dynamiques
	var tooltip_text = _generate_dynamic_tooltip(skill)
	button.tooltip_text = tooltip_text

func _can_buy_skill(skill: SkillTreeManager.Skill) -> bool:
	# Vérifier le parent
	if skill.parent != "root" and not GameState.skill_tree_manager.is_skill_unlocked(skill.parent):
		return false
	
	# Vérifier le niveau maximum
	if skill.level >= skill.max_level:
		return false
	
	# Vérifier les points d'ascension
	var cost = GameState.skill_tree_manager.get_skill_cost(skill.name)
	return GameState.currency_manager.has_enough("ascendancy_points", cost)

func _generate_dynamic_tooltip(skill: SkillTreeManager.Skill) -> String:
	var tooltip = ""
	var cost = GameState.skill_tree_manager.get_skill_cost(skill.name)
	var player_level = GameState.experience_manager.get_level()
	
	# En-tête avec nom et niveau
	tooltip += "%s" % skill.name
	if skill.level > 0:
		tooltip += " (Niveau %d)" % skill.level
	tooltip += "\n\n"
	
	# Description de base
	tooltip += "%s\n\n" % skill.description
	
	# Effets dynamiques selon le skill
	match skill.name:
		"Devotion":
			tooltip += _get_devotion_tooltip(skill, player_level)
		"Capitalist":
			tooltip += _get_capitalist_tooltip(skill)
		"Taylorism":
			tooltip += _get_taylorism_tooltip(skill)
		"Swift brush":
			tooltip += "Débloque l'autoclick pour générer des pixels automatiquement"
		"Storage room":
			tooltip += "Débloque le stockage de canvas pour la vente en lot"
		"Megalomania":
			tooltip += "Débloque les améliorations de taille de canvas"
		"Icon influence":
			tooltip += "Débloque le système de peinture"
		_:
			tooltip += skill.effect
	
	tooltip += "\n\n"
	
	# Coût et disponibilité
	if skill.level >= skill.max_level:
		tooltip += "✅ Niveau maximum atteint"
	elif GameState.currency_manager.has_enough("ascendancy_points", cost):
		tooltip += "💰 Coût: %d points d'ascension" % cost
	else:
		tooltip += "❌ Coût: %d points d'ascension (insuffisant)" % cost
	
	return tooltip

func _get_devotion_tooltip(skill: SkillTreeManager.Skill, player_level: int) -> String:
	var tooltip = ""
	var base_amount = 1.0
	var base_interval = 5.0
	
	# Calculer les effets actuels
	if skill.level >= 1:
		if skill.level >= 2:
			base_amount *= player_level
		if skill.level >= 3:
			base_interval = max(0.1, 5.0 - (player_level * 0.2))
		if skill.level >= 4:
			base_amount *= 2.0
	
	# Afficher l'effet actuel
	tooltip += "Effet actuel: %.1f inspiration toutes les %.1f secondes\n" % [base_amount, base_interval]
	
	# Afficher l'amélioration si on peut acheter
	if skill.level < skill.max_level:
		var new_amount = base_amount
		var new_interval = base_interval
		
		# Calculer le prochain niveau
		var next_level = skill.level + 1
		if next_level >= 2 and skill.level < 2:
			new_amount *= player_level
		if next_level >= 3 and skill.level < 3:
			new_interval = max(0.1, 5.0 - (player_level * 0.2))
		if next_level >= 4 and skill.level < 4:
			new_amount *= 2.0
		
		tooltip += "Prochain niveau: %.1f inspiration toutes les %.1f secondes\n" % [new_amount, new_interval]
		
		# Détails des niveaux
		if next_level == 2:
			tooltip += "→ Multiplie le gain par votre niveau (%d×)" % player_level
		elif next_level == 3:
			tooltip += "→ Améliore le rythme selon votre niveau"
		elif next_level == 4:
			tooltip += "→ Double le gain passif"
		elif next_level == 5:
			tooltip += "→ Garde 0.1% d'inspiration à l'ascension"
		else:
			tooltip += "→ Niveau maximum atteint"
	
	return tooltip

func _get_capitalist_tooltip(skill: SkillTreeManager.Skill) -> String:
	var current_bonus = skill.level * 10
	var next_bonus = (skill.level + 1) * 10
	
	var tooltip = "Bonus actuel: +%d%% prix de vente\n" % current_bonus
	
	if skill.level < skill.max_level:
		tooltip += "Prochain niveau: +%d%% prix de vente\n" % next_bonus
		tooltip += "→ +10%% supplémentaire"
	
	return tooltip

func _get_taylorism_tooltip(skill: SkillTreeManager.Skill) -> String:
	var current_bonus = skill.level * 5
	var next_bonus = (skill.level + 1) * 5
	
	var tooltip = "Bonus actuel: +%d%% gains d'or et d'inspiration\n" % current_bonus
	
	if skill.level < skill.max_level:
		tooltip += "Prochain niveau: +%d%% gains d'or et d'inspiration\n" % next_bonus
		tooltip += "→ +5%% supplémentaire"
	
	return tooltip

func _on_skill_button_pressed(skill_name: String) -> void:
	var success = GameState.skill_tree_manager.buy_skill(skill_name)
	if success:
		# Pas de feedback visuel sur l'écran skill tree
		_update_ui()
	else:
		# Pas de feedback visuel sur l'écran skill tree
		pass
