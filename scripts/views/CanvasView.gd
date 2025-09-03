extends MarginContainer

#==============================================================================
# Scene References
#==============================================================================
@onready var canvas_display: TextureRect = $VBoxContainer/AspectRatioContainer/CanvasDisplay
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var sell_button: Button = $VBoxContainer/SellButton

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	# Connect to GameState signals
	GameState.canvas_updated.connect(_on_canvas_updated)
	GameState.canvas_progress_updated.connect(_on_canvas_progress_updated)
	GameState.canvas_completed.connect(_on_canvas_completed)
	
	# Initial UI state
	sell_button.disabled = true
	sell_button.pressed.connect(_on_sell_button_pressed)

	# Request initial state from GameState
	if GameState.canvas_texture != null:
		_on_canvas_updated(GameState.canvas_texture)
	_on_canvas_progress_updated(GameState.current_pixel_count, GameState.max_pixels)
	if GameState.current_pixel_count >= GameState.max_pixels:
		_on_canvas_completed()

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

#==============================================================================
# UI Event Handlers
#==============================================================================
func _on_sell_button_pressed():
	GameState.sell_canvas()
	sell_button.disabled = true

#==============================================================================
# Public Functions (for upgrades, etc.)
#==============================================================================
func upgrade_resolution():
	GameState.upgrade_resolution()

func upgrade_fill_speed():
	GameState.upgrade_fill_speed()
