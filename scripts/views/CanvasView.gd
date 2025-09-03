extends MarginContainer

#==============================================================================
# Exports
#==============================================================================
@export var coin_spritesheet: Texture2D

#==============================================================================
# Preloads
#==============================================================================
const FLOATING_TEXT_SCENE = preload("res://Scenes/floating_text.tscn")

#==============================================================================
# Scene References
#==============================================================================
@onready var canvas_display: TextureRect = $VBoxContainer/AspectRatioContainer/CanvasDisplay
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var sell_button: Button = $VBoxContainer/SellButton
@onready var upgrade_resolution_button: Button = get_parent().get_node("UpgradeHBox/UpgradeResolutionButton")
@onready var upgrade_resolution_cost_label: Label = get_parent().get_node("UpgradeHBox/UpgradeResolutionCostLabel")
@onready var upgrade_fill_speed_button: Button = get_parent().get_node("UpgradeHBox/UpgradeFillSpeedButton")
@onready var upgrade_fill_speed_cost_label: Label = get_parent().get_node("UpgradeHBox/UpgradeFillSpeedCostLabel")

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	sell_button.disabled = true
	# Connect to GameState signals
	GameState.canvas_updated.connect(_on_canvas_updated)
	GameState.canvas_progress_updated.connect(_on_canvas_progress_updated)
	GameState.canvas_completed.connect(_on_canvas_completed)
	GameState.canvas_upgrade_costs_changed.connect(_on_canvas_upgrade_costs_changed)
	
	# Connect UI signals
	sell_button.pressed.connect(_on_sell_button_pressed)
	upgrade_resolution_button.pressed.connect(GameState.upgrade_resolution)
	upgrade_fill_speed_button.pressed.connect(GameState.upgrade_fill_speed)

	# Request initial state from GameState
	if GameState.canvas_texture != null:
		_on_canvas_updated(GameState.canvas_texture)
	_on_canvas_progress_updated(GameState.current_pixel_count, GameState.max_pixels)
	if GameState.current_pixel_count >= GameState.max_pixels:
		_on_canvas_completed()
	_on_canvas_upgrade_costs_changed({"resolution_cost": GameState.upgrade_resolution_cost, "fill_speed_cost": GameState.upgrade_fill_speed_cost})

#==============================================================================
# Signal Handlers (from GameState)
#==============================================================================
func _on_canvas_updated(new_texture: ImageTexture):
	canvas_display.texture = new_texture
	canvas_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_canvas_progress_updated(current_pixels: int, max_pixels: int):
	progress_bar.max_value = max_pixels
	progress_bar.value = current_pixels

func _on_canvas_completed():
	sell_button.disabled = false

func _on_canvas_upgrade_costs_changed(new_costs: Dictionary):
	upgrade_resolution_cost_label.text = "(Cost: %d)" % new_costs["resolution_cost"]
	upgrade_fill_speed_cost_label.text = "(Cost: %d)" % new_costs["fill_speed_cost"]

#==============================================================================
# UI Event Handlers
#==============================================================================
func _on_sell_button_pressed():
	GameState.sell_canvas()
	sell_button.disabled = true
	show_feedback(GameState.sell_price, coin_spritesheet, 12, 1, "rotate")

#==============================================================================
# Feedback
#==============================================================================
func show_feedback(amount: int, icon: Texture2D, hframes: int, vframes: int, animation_name: String):
	var ft = FLOATING_TEXT_SCENE.instantiate()
	get_parent().add_child(ft)
	ft.start("+%d" % amount, icon, hframes, vframes, animation_name, Color(1,1,0))
