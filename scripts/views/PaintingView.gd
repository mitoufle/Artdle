extends BaseView
class_name PaintingView

## Vue de peinture - Atelier et système de canvas
## Gère la production automatique et l'interface de peinture

#==============================================================================
# Constants
#==============================================================================
const CANVAS_POPUP_SCENE = preload("res://Scenes/CanvasPopup.tscn")
const INVENTORY_POPUP_SCENE = preload("res://Scenes/InventoryPopup.tscn")
const CRAFT_POPUP_SCENE = preload("res://Scenes/CraftPopup.tscn")
const DEBUG_CURRENCY_AMOUNT = 100000000

# Atelier Configuration
const ATELIER_BASE_COST = 10
const ATELIER_PRODUCTION_RATE = 0.2  # inspiration/sec/atelier
const ATELIER_COST_MULTIPLIER = 1.5

#==============================================================================
# Workshop State
#==============================================================================
var atelier_count: int = 0
var atelier_cost: int = ATELIER_BASE_COST

#==============================================================================
# Popup Instances
#==============================================================================
var inventory_popup_instance: InventoryPopup
var craft_popup_instance: CraftPopup

#==============================================================================
# UI References
#==============================================================================
var canvas_popup_instance: PopupPanel

@onready var paintingscreen_instance = $paintingscreen
@onready var btn_atelier: Button = $BtnBuildStuff
@onready var btn_debug: Button = $Debug
@onready var btn_open_canvas: Button = $BtnOpenCanvas

# Inventory & Craft UI (boutons pour ouvrir les modales)
@onready var btn_inventory: Button = $BtnInventory if has_node("BtnInventory") else null
@onready var btn_craft: Button = $BtnCraft if has_node("BtnCraft") else null

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _process(delta: float) -> void:
	_process_workshop_production(delta)
	# Mettre à jour le craft manager
	GameState.craft_manager.update_craft_progress(delta)

#==============================================================================
# BaseView Overrides
#==============================================================================
func _initialize_view() -> void:
	# Initialization specific to PaintingView
	pass

func _connect_view_signals() -> void:
	if not btn_open_canvas.pressed.is_connected(_on_open_canvas_pressed):
		btn_open_canvas.pressed.connect(_on_open_canvas_pressed)
	if not btn_atelier.pressed.is_connected(_on_build_workshop_pressed):
		btn_atelier.pressed.connect(_on_build_workshop_pressed)
	if not btn_debug.pressed.is_connected(_on_debug_pressed):
		btn_debug.pressed.connect(_on_debug_pressed)
	
	# Inventory & Craft signals (vérifier que les boutons existent)
	if btn_inventory and not btn_inventory.pressed.is_connected(_on_inventory_pressed):
		btn_inventory.pressed.connect(_on_inventory_pressed)
	if btn_craft and not btn_craft.pressed.is_connected(_on_craft_pressed):
		btn_craft.pressed.connect(_on_craft_pressed)
	
	# Connecter les signaux du craft manager
	if not GameState.craft_manager.craft_completed.is_connected(_on_craft_completed):
		GameState.craft_manager.craft_completed.connect(_on_craft_completed)

func _initialize_ui() -> void:
	# Initialize canvas popup
	canvas_popup_instance = CANVAS_POPUP_SCENE.instantiate()
	canvas_popup_instance.hide()
	add_child(canvas_popup_instance)
	
	# Initialize inventory popup
	inventory_popup_instance = INVENTORY_POPUP_SCENE.instantiate()
	inventory_popup_instance.hide()
	add_child(inventory_popup_instance)
	
	# Initialize craft popup
	craft_popup_instance = CRAFT_POPUP_SCENE.instantiate()
	craft_popup_instance.hide()
	add_child(craft_popup_instance)
	
	# Center camera - wait for next frame to ensure nodes are ready
	call_deferred("center_camera_in_child", paintingscreen_instance)

func get_class_name() -> String:
	return "PaintingView"

#==============================================================================
# Workshop Production
#==============================================================================
func _process_workshop_production(delta: float) -> void:
	if atelier_count > 0:
		var production = atelier_count * ATELIER_PRODUCTION_RATE * delta
		GameState.currency_manager.add_currency("inspiration", production)

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_build_workshop_pressed() -> void:
	if GameState.currency_manager.has_enough("inspiration", atelier_cost):
		GameState.currency_manager.subtract_currency("inspiration", atelier_cost)
		atelier_count += 1
		atelier_cost = int(atelier_cost * ATELIER_COST_MULTIPLIER)
		GameState.logger.info("Workshop built! Total workshops: %d" % atelier_count, "PaintingView")
	else:
		GameState.logger.warning("Insufficient inspiration to build workshop (need %d)" % atelier_cost, "PaintingView")

func _on_open_canvas_pressed() -> void:
	canvas_popup_instance.popup()
	GameState.logger.debug("Canvas popup opened", "PaintingView")

func _on_debug_pressed() -> void:
	GameState.currency_manager.set_currency("inspiration", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("gold", DEBUG_CURRENCY_AMOUNT)
	GameState.currency_manager.set_currency("fame", DEBUG_CURRENCY_AMOUNT)
	GameState.logger.info("Debug mode activated - currencies set", "PaintingView")

#==============================================================================
# Inventory & Craft Signal Handlers
#==============================================================================
func _on_inventory_pressed() -> void:
	if not inventory_popup_instance:
		print("⚠️ Modale d'inventaire non disponible")
		return
	
	inventory_popup_instance.popup()
	GameState.logger.info("Inventory popup opened", "PaintingView")

func _on_craft_pressed() -> void:
	if not craft_popup_instance:
		print("⚠️ Modale de craft non disponible")
		return
	
	craft_popup_instance.popup()
	GameState.logger.info("Craft popup opened", "PaintingView")

func _on_craft_completed(item: InventoryManager.Item) -> void:
	# Donner de l'expérience pour le craft
	var xp_gained = 10 + (item.tier * 5)  # Plus de XP pour les items de meilleure qualité
	GameState.experience_manager.add_experience(xp_gained)
	
	# Feedback visuel
	GameState.feedback_manager.show_feedback("Item créé: %s (+%d XP)" % [item.name, xp_gained], Color.GREEN)

#==============================================================================
# Public API
#==============================================================================
## Récupère le nombre d'ateliers
func get_workshop_count() -> int:
	return atelier_count

## Récupère le coût du prochain atelier
func get_next_workshop_cost() -> int:
	return atelier_cost

## Récupère la production totale par seconde
func get_total_production_per_second() -> float:
	return atelier_count * ATELIER_PRODUCTION_RATE
