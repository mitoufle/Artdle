extends Control

#==============================================================================
# Variables locales à la vue Peinture
#==============================================================================

# Atelier
var atelier_count: int = 0
var atelier_cost: int = 10
var atelier_production: float = 0.2   # inspiration/sec/atelier

#==============================================================================
# Variables internes
#==============================================================================

var canvas_popup_instance
var clicker_popup_instance

#==============================================================================
# Références OnReady
#==============================================================================

@onready var canvas_popup_scene = preload("res://Scenes/CanvasPopup.tscn")
@onready var clicker_popup_scene = preload("res://Scenes/ClickerPopup.tscn")
@onready var paintingscreen_instance = $paintingscreen

@onready var btn_atelier: Button = $BtnBuildStuff
@onready var btn_open_canvas: Button = $BtnOpenCanvas
@onready var btn_open_clicker_popup: Button = $BtnOpenClickerPopup

#==============================================================================
# Fonctions Godot
#==============================================================================

func _ready() -> void:
	# --- Instance des popups ---
	canvas_popup_instance = canvas_popup_scene.instantiate()
	canvas_popup_instance.hide()
	add_child(canvas_popup_instance)
	
	clicker_popup_instance = clicker_popup_scene.instantiate()
	clicker_popup_instance.hide()
	add_child(clicker_popup_instance)
	
	# --- Connexion des signaux des boutons ---
	btn_open_canvas.pressed.connect(_on_btn_open_canvas_pressed)
	btn_open_clicker_popup.pressed.connect(_on_btn_open_clicker_popup_pressed)
	
	# Center the Camera2D in paintingscreen
	var camera_node = paintingscreen_instance.find_child("Camera2D")
	if camera_node:
		camera_node.position = get_size() / 2

func _process(delta: float) -> void:
	# Production automatique par atelier
	if atelier_count > 0:
		GameState.set_inspiration(atelier_count * atelier_production * delta)

#==============================================================================
# Fonctions connectées aux signaux
#==============================================================================

func _on_btn_build_workshop_pressed() -> void:
	if GameState.get_inspiration() >= atelier_cost:
		GameState.set_inspiration(-atelier_cost)
		atelier_count += 1
		atelier_cost = int(atelier_cost * 1.5)

func _on_btn_open_canvas_pressed() -> void:
	canvas_popup_instance.popup()

func _on_btn_open_clicker_popup_pressed() -> void:
	clicker_popup_instance.popup()
