extends Node
class_name PassiveIncomeManager

## Gère les revenus passifs du jeu

#==============================================================================
# Big Number Management
#==============================================================================
const CurrencyBonusManager = preload("res://scripts/CurrencyBonusManager.gd")
## Système de génération automatique de ressources

#==============================================================================
# Signals
#==============================================================================
signal passive_income_generated(currency_type: String, amount: float)

#==============================================================================
# Passive Income Sources
#==============================================================================
var passive_sources: Dictionary = {}

#==============================================================================
# Timers
#==============================================================================
var income_timer: Timer

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	_setup_income_timer()

#==============================================================================
# Public API
#==============================================================================

## Ajoute une source de revenu passif
func add_passive_income(source_name: String, currency_type: String, amount: float, interval: float) -> void:
	if not passive_sources.has(source_name):
		passive_sources[source_name] = {}
	
	passive_sources[source_name] = {
		"currency_type": currency_type,
		"amount": amount,
		"interval": interval,
		"enabled": true
	}
	
	GameState.logger.info("Passive income added: %s (%s every %.1fs)" % [source_name, currency_type, interval])

## Supprime une source de revenu passif
func remove_passive_income(source_name: String) -> void:
	if passive_sources.has(source_name):
		passive_sources.erase(source_name)
		GameState.logger.info("Passive income removed: %s" % source_name)

## Active ou désactive une source de revenu passif
func set_passive_income_enabled(source_name: String, enabled: bool) -> void:
	if passive_sources.has(source_name):
		passive_sources[source_name]["enabled"] = enabled
		GameState.logger.info("Passive income %s: %s" % [source_name, "enabled" if enabled else "disabled"])

## Met à jour le montant d'une source de revenu passif
func update_passive_income_amount(source_name: String, new_amount: float) -> void:
	if passive_sources.has(source_name):
		passive_sources[source_name]["amount"] = new_amount
		GameState.logger.info("Passive income updated: %s (%.1f)" % [source_name, new_amount])

## Récupère toutes les sources de revenus passifs
func get_passive_sources() -> Dictionary:
	return passive_sources.duplicate()

## Calcule le revenu total par seconde pour une devise
func get_total_income_per_second(currency_type: String) -> float:
	var total = 0.0
	
	for source in passive_sources.values():
		if source["enabled"] and source["currency_type"] == currency_type:
			total += source["amount"] / source["interval"]
	
	return total

## Réinitialise tous les revenus passifs
func reset_passive_income() -> void:
	passive_sources.clear()
	GameState.logger.info("All passive income sources cleared")

#==============================================================================
# Private Methods
#==============================================================================

func _setup_income_timer() -> void:
	income_timer = Timer.new()
	income_timer.wait_time = 1.0  # Vérifier toutes les secondes
	income_timer.timeout.connect(_on_income_timer_timeout)
	add_child(income_timer)
	income_timer.start()

func _on_income_timer_timeout() -> void:
	_process_passive_income()

func _process_passive_income() -> void:
	for source_name in passive_sources.keys():
		var source = passive_sources[source_name]
		if not source["enabled"]:
			continue
		
		# Vérifier si c'est le moment de générer des revenus
		# Pour simplifier, on génère les revenus toutes les secondes
		# mais on ajuste le montant selon l'intervalle
		var amount_per_second = source["amount"] / source["interval"]
		
		if amount_per_second > 0:
			_generate_passive_income(source_name, source["currency_type"], amount_per_second)

func _generate_passive_income(source_name: String, currency_type: String, amount: float) -> void:
	# Appliquer les bonus d'équipement via GameState
	var bonus_amount = GameState.apply_currency_bonus(currency_type, amount)
	
	# Ajouter la devise avec bonus
	GameState.currency_manager.add_currency_raw(currency_type, bonus_amount)
	
	# Afficher le feedback avec le montant bonifié
	_show_passive_income_feedback(currency_type, bonus_amount)
	
	# Émettre le signal avec le montant bonifié
	passive_income_generated.emit(currency_type, bonus_amount)
	
	# Log pour debug
	GameState.logger.debug("Passive income: +%.1f %s from %s" % [amount, currency_type, source_name])

func _show_passive_income_feedback(currency_type: String, amount: float) -> void:
	# Show floating text for devotion procs centered on click button
	if currency_type == "inspiration" and amount > 0:
		_show_devotion_feedback(amount)

func _show_devotion_feedback(amount: float) -> void:
	# Get the AccueilView to show floating text centered on click button
	var accueil_view = GameState.scene_manager.get_current_view()
	if accueil_view and accueil_view.get_class_name() == "AccueilView":
		# Use the AccueilView's feedback system
		accueil_view._show_devotion_feedback(amount)
	else:
		# Fallback: try to find AccueilView in the scene tree
		var accueil_node = _find_accueil_view()
		if accueil_node:
			accueil_node._show_devotion_feedback(amount)

func _find_accueil_view() -> Node:
	# Search for AccueilView in the scene tree
	var root = get_tree().current_scene
	return _search_for_accueil_view(root)

func _search_for_accueil_view(node: Node) -> Node:
	if node.get_class_name() == "AccueilView":
		return node
	
	for child in node.get_children():
		var result = _search_for_accueil_view(child)
		if result:
			return result
	
	return null
