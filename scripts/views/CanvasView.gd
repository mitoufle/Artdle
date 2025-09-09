extends MarginContainer

#==============================================================================
# Imports
#==============================================================================
const UpgradeButton = preload("res://scripts/UI/UpgradeButton.gd")

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
@onready var upgrade_resolution_button: UpgradeButton = get_parent().get_node("UpgradeHBox/UpgradeResolutionButton")
@onready var upgrade_fill_speed_button: UpgradeButton = get_parent().get_node("UpgradeHBox/UpgradeFillSpeedButton")
@onready var canvas_storage_label: Label = get_parent().get_node("CanvasStorageLabel")
@onready var upgrade_canvas_storage_button: UpgradeButton = get_parent().get_node("UpgradeCanvasStorageButton")

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
	upgrade_resolution_button.upgrade_purchased.connect(_on_upgrade_resolution_purchased)
	upgrade_fill_speed_button.upgrade_purchased.connect(_on_upgrade_fill_speed_purchased)
	upgrade_canvas_storage_button.upgrade_purchased.connect(_on_upgrade_canvas_storage_purchased)

	# Request initial state from GameState
	var canvas_texture = GameState.canvas_manager.get_canvas_texture()
	if canvas_texture != null:
		_on_canvas_updated(canvas_texture)
	
	var pixel_info = GameState.canvas_manager.get_pixel_info()
	_on_canvas_progress_updated(pixel_info.current, pixel_info.max)
	
	var upgrade_costs = GameState.canvas_manager.get_upgrade_costs()
	_on_canvas_upgrade_costs_changed(upgrade_costs)
	
	var storage_info = GameState.canvas_manager.get_storage_info()
	_on_canvas_storage_changed(storage_info.stored, storage_info.level)
	
	var storage_cost = GameState.canvas_manager.get_storage_upgrade_cost()
	_on_canvas_storage_upgrade_cost_changed(storage_cost)
	
	# Setup canvas storage upgrade button
	_setup_canvas_storage_upgrade_button()
	
	_update_sell_button_state() # Call here for initial state
	_setup_upgrade_buttons()

#==============================================================================
# Signal Handlers (from GameState)
#==============================================================================
func _on_canvas_updated(new_texture: ImageTexture):
	canvas_display.texture = new_texture
	canvas_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _update_sell_button_state():
	var pixel_info = GameState.canvas_manager.get_pixel_info()
	var storage_info = GameState.canvas_manager.get_storage_info()
	
	var canvas_completed = pixel_info.current >= pixel_info.max
	var has_stored_canvases = storage_info.stored > 0
	
	sell_button.disabled = not (canvas_completed or has_stored_canvases)

func _on_canvas_progress_updated(current_pixels: int, max_pixels: int):
	progress_bar.max_value = max_pixels
	progress_bar.value = current_pixels
	_update_sell_button_state() # Update button state on progress change

func _on_canvas_completed():
	_update_sell_button_state() # Update button state when canvas completes

func _on_canvas_upgrade_costs_changed(new_costs: Dictionary):
	# Update upgrade buttons with new costs
	_setup_upgrade_buttons()

func _on_canvas_storage_changed(stored_canvases: int, max_storage: int):
	canvas_storage_label.text = "Stored Canvases: %d/%d" % [stored_canvases, max_storage]
	_update_sell_button_state() # Update button state when storage changes

func _on_canvas_storage_upgrade_cost_changed(cost: int):
	# Update the upgrade button with new cost
	_setup_canvas_storage_upgrade_button()

#==============================================================================
# UI Event Handlers
#==============================================================================
func _on_sell_button_pressed():
	var result = GameState.sell_canvas()
	_update_sell_button_state() # Update button state after selling
	
	# Afficher le feedback avec le montant réel gagné
	if result.canvases_sold > 0:
		show_feedback(result.gold_gained, coin_spritesheet, 12, 1, "rotate")

#==============================================================================
# Feedback
#==============================================================================
func show_feedback(amount: float, icon: Texture2D, hframes: int, vframes: int, animation_name: String):
	var ft = FLOATING_TEXT_SCENE.instantiate()
	get_parent().add_child(ft)
	ft.start("+%.0f" % amount, icon, hframes, vframes, animation_name, Color(1,1,0))

#==============================================================================
# Upgrade Button Setup
#==============================================================================
func _setup_upgrade_buttons():
	# Setup resolution button
	var resolution_level = GameState.canvas_manager.resolution_level
	var resolution_prices = _get_resolution_prices(resolution_level)
	upgrade_resolution_button.update_upgrade_data(resolution_level, resolution_prices)
	
	# Set icon for resolution button (using experience icon)
	var currency_icon = preload("res://artdleAsset/Currency/Inspiration.png")
	upgrade_resolution_button.set_currency_icon(currency_icon)
	
	# Setup fill speed button
	var fill_speed_level = GameState.canvas_manager.fill_speed_level
	var fill_speed_prices = _get_fill_speed_prices(fill_speed_level)
	upgrade_fill_speed_button.update_upgrade_data(fill_speed_level, fill_speed_prices)
	
	# Set icon for fill speed button (using painting mastery icon)
	upgrade_fill_speed_button.set_currency_icon(currency_icon)

func _get_resolution_prices(level: int) -> Dictionary:
	var cost = GameState.canvas_manager.upgrade_resolution_cost
	return {"inspiration": cost}

func _get_fill_speed_prices(level: int) -> Dictionary:
	var cost = GameState.canvas_manager.upgrade_fill_speed_cost
	return {"inspiration": cost}

func _get_canvas_storage_prices(level: int) -> Dictionary:
	var cost = GameState.canvas_manager.get_storage_upgrade_cost()
	return {"inspiration": cost}

#==============================================================================
# Upgrade Event Handlers
#==============================================================================
func _on_upgrade_resolution_purchased(upgrade_type: String, level: int) -> void:
	GameState.upgrade_resolution()
	# Update button display
	var new_level = GameState.canvas_manager.resolution_level
	var new_prices = _get_resolution_prices(new_level)
	upgrade_resolution_button.update_upgrade_data(new_level, new_prices)

func _on_upgrade_fill_speed_purchased(upgrade_type: String, level: int) -> void:
	GameState.upgrade_fill_speed()
	# Update button display
	var new_level = GameState.canvas_manager.fill_speed_level
	var new_prices = _get_fill_speed_prices(new_level)
	upgrade_fill_speed_button.update_upgrade_data(new_level, new_prices)

func _on_upgrade_canvas_storage_purchased(upgrade_type: String, level: int) -> void:
	GameState.upgrade_canvas_storage()
	# Update button display
	var new_level = GameState.canvas_manager.canvas_storage_level
	var new_prices = _get_canvas_storage_prices(new_level)
	upgrade_canvas_storage_button.update_upgrade_data(new_level, new_prices)

func _setup_canvas_storage_upgrade_button():
	var storage_level = GameState.canvas_manager.canvas_storage_level
	var storage_prices = _get_canvas_storage_prices(storage_level)
	upgrade_canvas_storage_button.update_upgrade_data(storage_level, storage_prices)
	
	# Set a different icon for canvas storage
	var currency = preload("res://artdleAsset/Currency/Inspiration.png")
	upgrade_canvas_storage_button.set_currency_icon(currency)
