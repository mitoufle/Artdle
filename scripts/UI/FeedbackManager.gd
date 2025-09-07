extends Node
class_name FeedbackManager

## Gestionnaire centralisé pour les effets de feedback
## Gère l'affichage des animations et effets visuels

#==============================================================================
# Constants
#==============================================================================
const FLOATING_TEXT_SCENE = preload("res://Scenes/floating_text.tscn")

#==============================================================================
# Configuration
#==============================================================================
var feedback_layer: CanvasLayer
var max_feedback_instances: int = 20
var feedback_instances: Array[Node] = []

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_setup_feedback_layer()
	GameState.logger.info("FeedbackManager initialized", "FeedbackManager")

#==============================================================================
# Initialization
#==============================================================================
func _setup_feedback_layer() -> void:
	# Create feedback layer
	feedback_layer = CanvasLayer.new()
	feedback_layer.name = "FeedbackLayer"
	feedback_layer.layer = 100  # High layer to appear on top
	
	# Add to scene tree
	get_tree().current_scene.add_child(feedback_layer)
	
	GameState.logger.debug("Feedback layer created", "FeedbackManager")

#==============================================================================
# Public API
#==============================================================================
## Affiche un feedback de gain de devise
func show_currency_feedback(amount: float, currency_type: String, position: Vector2 = Vector2.ZERO) -> void:
	var icon = _get_currency_icon(currency_type)
	var color = _get_currency_color(currency_type)
	var text = _format_currency_amount(amount, currency_type)
	
	_show_feedback(text, icon, position, color)

## Affiche un feedback de gain d'expérience
func show_experience_feedback(amount: float, position: Vector2 = Vector2.ZERO) -> void:
	var icon = preload("res://artdleAsset/Currency/Experience.png")  # TODO: Add experience icon
	var color = Color(0.2, 0.8, 1.0, 1.0)  # Blue color for experience
	var text = "+%.0f XP" % amount
	
	_show_feedback(text, icon, position, color)

## Affiche un feedback de niveau
func show_level_feedback(level: int, position: Vector2 = Vector2.ZERO) -> void:
	var icon = preload("res://artdleAsset/Currency/level.png")  # TODO: Add level icon
	var color = Color(1.0, 0.8, 0.2, 1.0)  # Gold color for level
	var text = "Level %d!" % level
	
	_show_feedback(text, icon, position, color)

## Affiche un feedback d'ascension
func show_ascension_feedback(ascendancy_points: float, position: Vector2 = Vector2.ZERO) -> void:
	var icon = preload("res://artdleAsset/Currency/Ascendancy_point.png")
	var color = Color(0.8, 0.2, 1.0, 1.0)  # Purple color for ascension
	var text = "Ascended! +%.0f AP" % ascendancy_points
	
	_show_feedback(text, icon, position, color)

## Affiche un feedback personnalisé
func show_custom_feedback(text: String, icon: Texture2D, position: Vector2 = Vector2.ZERO, color: Color = Color.WHITE) -> void:
	_show_feedback(text, icon, position, color)

## Affiche un feedback simple avec texte et couleur (méthode de convenance)
func show_feedback(text: String, color: Color = Color.WHITE, position: Vector2 = Vector2.ZERO) -> void:
	var icon = preload("res://artdleAsset/Currency/coin.png")  # Icône par défaut
	show_custom_feedback(text, icon, position, color)

## Affiche un feedback de canvas vendu
func show_canvas_sold_feedback(gold_gained: int, fame_gained: int, position: Vector2 = Vector2.ZERO) -> void:
	# Show gold feedback
	var gold_icon = preload("res://artdleAsset/Currency/coin.png")
	var gold_color = Color(1.0, 0.8, 0.2, 1.0)
	_show_feedback("+%d Gold" % gold_gained, gold_icon, position, gold_color)
	
	# Show fame feedback slightly offset
	var fame_icon = preload("res://artdleAsset/Currency/fame.png")
	var fame_color = Color(0.8, 0.2, 0.2, 1.0)
	_show_feedback("+%d Fame" % fame_gained, fame_icon, position + Vector2(0, -30), fame_color)

#==============================================================================
# Private Methods
#==============================================================================
func _show_feedback(text: String, icon: Texture2D, position: Vector2, color: Color) -> void:
	# Clean up old feedback instances
	_cleanup_feedback_instances()
	
	# Create new feedback instance
	var ft = FLOATING_TEXT_SCENE.instantiate()
	feedback_layer.add_child(ft)
	ft.set_as_top_level(true)
	
	# Configure feedback
	ft.start(text, icon, 12, 1, "rotate", color)
	ft.position = position
	
	# Add to instances array
	feedback_instances.append(ft)
	
	# The floating text will automatically queue_free itself when the tween finishes
	# No need to connect a finished signal

func _cleanup_feedback_instances() -> void:
	# Remove finished instances
	for i in range(feedback_instances.size() - 1, -1, -1):
		var instance = feedback_instances[i]
		if not is_instance_valid(instance) or instance.is_queued_for_deletion():
			feedback_instances.remove_at(i)
	
	# Limit the number of feedback instances
	while feedback_instances.size() > max_feedback_instances:
		var oldest_instance = feedback_instances.pop_front()
		if is_instance_valid(oldest_instance):
			oldest_instance.queue_free()

# Note: _on_feedback_finished removed because floating_text automatically queue_frees itself

func _get_currency_icon(currency_type: String) -> Texture2D:
	match currency_type:
		"inspiration":
			return preload("res://artdleAsset/Currency/Inspiration.png")
		"gold":
			return preload("res://artdleAsset/Currency/coin.png")
		"fame":
			return preload("res://artdleAsset/Currency/fame.png")
		"ascendancy_points":
			return preload("res://artdleAsset/Currency/Ascendancy_point.png")
		"paint_mastery":
			return preload("res://artdleAsset/Currency/Painting_mastery.png")
		_:
			return preload("res://artdleAsset/Currency/coin.png")  # Default icon

func _get_currency_color(currency_type: String) -> Color:
	match currency_type:
		"inspiration":
			return Color(0.2, 0.8, 0.2, 1.0)  # Green
		"gold":
			return Color(1.0, 0.8, 0.2, 1.0)  # Gold
		"fame":
			return Color(0.8, 0.2, 0.2, 1.0)  # Red
		"ascendancy_points":
			return Color(0.8, 0.2, 1.0, 1.0)  # Purple
		"paint_mastery":
			return Color(0.2, 0.2, 0.8, 1.0)  # Blue
		_:
			return Color.WHITE

func _format_currency_amount(amount: float, currency_type: String) -> String:
	if amount >= 1000000:
		return "+%.1fM %s" % [amount / 1000000.0, currency_type.capitalize()]
	elif amount >= 1000:
		return "+%.1fK %s" % [amount / 1000.0, currency_type.capitalize()]
	else:
		return "+%.0f %s" % [amount, currency_type.capitalize()]

#==============================================================================
# Public API - Configuration
#==============================================================================
## Définit le nombre maximum d'instances de feedback
func set_max_feedback_instances(max_instances: int) -> void:
	max_feedback_instances = max_instances

## Nettoie tous les feedbacks actifs
func clear_all_feedback() -> void:
	for instance in feedback_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	feedback_instances.clear()

## Récupère le nombre d'instances de feedback actives
func get_active_feedback_count() -> int:
	return feedback_instances.size()
