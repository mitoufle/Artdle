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
@onready var canvas_storage_label: Label = get_parent().get_node("CanvasStorageLabel")
@onready var upgrade_canvas_storage_button: Button = get_parent().get_node("UpgradeCanvasStorageButton")
@onready var upgrade_canvas_storage_cost_label: Label = get_parent().get_node("UpgradeCanvasStorageCostLabel")

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	# Connect to GameState signals
	GameState.canvas_updated.connect(_on_canvas_updated)
	GameState.canvas_progress_updated.connect(_on_canvas_progress_updated)
	GameState.canvas_completed.connect(_on_canvas_completed)
	GameState.canvas_upgrade_costs_changed.connect(_on_canvas_upgrade_costs_changed)
	GameState.canvas_storage_changed.connect(_on_canvas_storage_changed)
	GameState.canvas_storage_upgrade_cost_changed.connect(_on_canvas_storage_upgrade_cost_changed)
	
	# Connect UI signals
	sell_button.pressed.connect(_on_sell_button_pressed)
	upgrade_resolution_button.pressed.connect(Callable(GameState, "upgrade_resolution"))
	upgrade_fill_speed_button.pressed.connect(Callable(GameState, "upgrade_fill_speed"))
	upgrade_canvas_storage_button.pressed.connect(Callable(GameState, "upgrade_canvas_storage"))

	# Request initial state from GameState
	if GameState.canvas_texture != null:
		_on_canvas_updated(GameState.canvas_texture)
	_on_canvas_progress_updated(GameState.current_pixel_count, GameState.max_pixels)
	_on_canvas_upgrade_costs_changed({"resolution_cost": GameState.upgrade_resolution_cost, "fill_speed_cost": GameState.upgrade_fill_speed_cost})
	_on_canvas_storage_changed(GameState.stored_canvases, GameState.canvas_storage_level)
	_on_canvas_storage_upgrade_cost_changed(GameState.canvas_storage_cost)
	_update_sell_button_state() # Call here for initial state

#==============================================================================
# Signal Handlers (from GameState)
#==============================================================================
func _on_canvas_updated(new_texture: ImageTexture):
	canvas_display.texture = new_texture
	canvas_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _update_sell_button_state():
	var canvas_completed = GameState.current_pixel_count >= GameState.max_pixels
	var has_stored_canvases = GameState.stored_canvases > 0
	
	sell_button.disabled = not (canvas_completed or has_stored_canvases)

func _on_canvas_progress_updated(current_pixels: int, max_pixels: int):
	progress_bar.max_value = max_pixels
	progress_bar.value = current_pixels
	_update_sell_button_state() # Update button state on progress change

func _on_canvas_completed():
	_update_sell_button_state() # Update button state when canvas completes

func _on_canvas_upgrade_costs_changed(new_costs: Dictionary):
	upgrade_resolution_cost_label.text = "(Cost: %d)" % new_costs["resolution_cost"]
	upgrade_fill_speed_cost_label.text = "(Cost: %d)" % new_costs["fill_speed_cost"]

func _on_canvas_storage_changed(stored_canvases: int, max_storage: int):
	canvas_storage_label.text = "Stored Canvases: %d/%d" % [stored_canvases, max_storage]
	_update_sell_button_state() # Update button state when storage changes

func _on_canvas_storage_upgrade_cost_changed(cost: int):
	upgrade_canvas_storage_cost_label.text = "(Cost: %d)" % cost

#==============================================================================
# UI Event Handlers
#==============================================================================
func _on_sell_button_pressed():
	GameState.sell_canvas()
	_update_sell_button_state() # Update button state after selling
	show_feedback(GameState.sell_price, coin_spritesheet, 12, 1, "rotate")

#==============================================================================
# Feedback
#==============================================================================
func show_feedback(amount: int, icon: Texture2D, hframes: int, vframes: int, animation_name: String):
	var ft = FLOATING_TEXT_SCENE.instantiate()
	get_parent().add_child(ft)
	ft.start("+%d" % amount, icon, hframes, vframes, animation_name, Color(1,1,0))
