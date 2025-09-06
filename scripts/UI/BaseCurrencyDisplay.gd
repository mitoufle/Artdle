extends HBoxContainer
class_name BaseCurrencyDisplay

## Classe de base pour l'affichage des devises
## Standardise l'affichage et la mise à jour des devises

#==============================================================================
# Exports
#==============================================================================
@export var currency_type: String
@export var icon_texture: Texture2D
@export var display_format: String = "%.0f"  # Format d'affichage (%.0f, %.1f, etc.)
@export var show_icon: bool = true
@export var show_label: bool = true

#==============================================================================
# UI References
#==============================================================================
@onready var icon_node: TextureRect = $Icon
@onready var amount_label: Label = $Amount

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_initialize_display()
	_connect_currency_signal()
	_update_display(GameState.currency_manager.get_currency(currency_type))

#==============================================================================
# Initialization
#==============================================================================
func _initialize_display() -> void:
	# Configure icon
	if icon_texture and show_icon:
		icon_node.texture = icon_texture
		icon_node.visible = true
	else:
		icon_node.visible = false
	
	# Configure label
	amount_label.visible = show_label
	
	GameState.logger.debug("BaseCurrencyDisplay initialized for currency: %s" % currency_type, "BaseCurrencyDisplay")

func _connect_currency_signal() -> void:
	# Connect to the appropriate currency signal
	match currency_type:
		"inspiration":
			GameState.inspiration_changed.connect(_on_currency_changed)
		"gold":
			GameState.gold_changed.connect(_on_currency_changed)
		"fame":
			GameState.fame_changed.connect(_on_currency_changed)
		"ascendancy_points":
			GameState.ascendancy_point_changed.connect(_on_currency_changed)
		"ascend_level":
			GameState.ascendancy_level_changed.connect(_on_currency_changed)
		"paint_mastery":
			GameState.paint_mastery_changed.connect(_on_currency_changed)
		"experience":
			GameState.experience_changed.connect(_on_experience_changed)
		"level":
			GameState.level_changed.connect(_on_level_changed)
		_:
			GameState.logger.error("Unknown currency type: %s" % currency_type, "BaseCurrencyDisplay")

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_currency_changed(value: float) -> void:
	_update_display(value)

func _on_experience_changed(experience: float, _experience_to_next: float) -> void:
	_update_display(experience)

func _on_level_changed(level: int) -> void:
	_update_display(float(level))

#==============================================================================
# Display Updates
#==============================================================================
func _update_display(value: float) -> void:
	if not is_inside_tree():
		return
	
	amount_label.text = display_format % value
	GameState.logger.debug("Currency display updated: %s = %s" % [currency_type, amount_label.text], "BaseCurrencyDisplay")

#==============================================================================
# Public API
#==============================================================================
## Met à jour manuellement l'affichage
func refresh_display() -> void:
	var current_value = GameState.currency_manager.get_currency(currency_type)
	_update_display(current_value)

## Change le format d'affichage
func set_display_format(new_format: String) -> void:
	display_format = new_format
	refresh_display()

## Affiche ou masque l'icône
func set_icon_visible(visible: bool) -> void:
	show_icon = visible
	icon_node.visible = visible and icon_texture != null

## Affiche ou masque le label
func set_label_visible(visible: bool) -> void:
	show_label = visible
	amount_label.visible = visible
