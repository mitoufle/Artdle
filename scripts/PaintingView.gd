extends Control

#==============================================================================
# Variables locales à la vue Peinture
#==============================================================================

# Améliorations et coûts locaux
var painting_incrementer: float = 1
var enhanse_inspi_cost: int = 50

# Atelier
var atelier_count: int = 0
var atelier_cost: int = 10
var atelier_production: float = 0.2   # inspiration/sec/atelier

#==============================================================================
# Variables internes
#==============================================================================

var canvas_popup_instance
var blinking = false
var hover = false
var tooltip_txt = "Workshop"

#==============================================================================
# Références OnReady
#==============================================================================

@onready var canvas_popup_scene = preload("res://Scenes/CanvasPopup.tscn")

@onready var btn_peindre: Button = $BtnAddInspiration
@onready var btn_atelier: Button = $BtnBuildStuff
@onready var btn_enhancePainting: Button = $BtnEnhancePainting
@onready var btn_open_canvas: Button = $BtnOpenCanvas

#==============================================================================
# Fonctions Godot
#==============================================================================

func _ready() -> void:
	# --- Instance de la vue du Canvas ---
	canvas_popup_instance = canvas_popup_scene.instantiate()
	add_child(canvas_popup_instance)
	
	# --- Connexion des signaux des boutons ---
	btn_peindre.pressed.connect(_on_btn_peindre_pressed)
	btn_enhancePainting.pressed.connect(_on_btn_enhancepainting_pressed)
	btn_open_canvas.pressed.connect(_on_btn_open_canvas_pressed)
	
	update_ui()

func _process(delta: float) -> void:
	# Production automatique par atelier
	if atelier_count > 0:
		GameState.set_inspiration(atelier_count * atelier_production * delta)
		
	# Met à jour l'UI chaque frame
	update_ui()

#==============================================================================
# Fonctions connectées aux signaux
#==============================================================================

func _on_btn_peindre_pressed() -> void:
	var main_node = get_tree().get_root().get_node("Main")
	main_node.add_ressource_feedback(painting_incrementer)
	GameState.set_inspiration(painting_incrementer)
	update_ui()

func _on_btn_enhancepainting_pressed() -> void:
	if GameState.get_inspiration() >= enhanse_inspi_cost:
		GameState.set_inspiration(-enhanse_inspi_cost)
		enhanse_inspi_cost = enhanse_inspi_cost * 1.6
		painting_incrementer *= 2
	update_ui()

func _on_btn_build_workshop_pressed() -> void:
	if GameState.get_inspiration() >= atelier_cost:
		GameState.set_inspiration(-atelier_cost)
		atelier_count += 1
		atelier_cost = int(atelier_cost * 1.5)
		update_ui()

func _on_btn_open_canvas_pressed() -> void:
	canvas_popup_instance.popup()

#==============================================================================
# Fonctions UI
#==============================================================================

func update_ui() -> void:
	btn_peindre.text = "Peindre (+" + str(painting_incrementer) + ")"
	btn_enhancePainting.text = "Enhance Painting (" + str(int(enhanse_inspi_cost)) + " inspi)"
