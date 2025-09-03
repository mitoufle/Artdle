extends Control
# On récupère des références directes pour éviter les erreurs de chemin plus tard
@onready var top_bar: HBoxContainer = $MainLayout/VBoxContainer/TopBar
@onready var btn_accueil: Button = $MainLayout/VBoxContainer/TopBar/btnAccueil
@onready var btn_peinture: Button = $MainLayout/VBoxContainer/TopBar/btnPeinture
@onready var btn_ascendancy: Button = $MainLayout/VBoxContainer/TopBar/btnAscendancy
@onready var content: PanelContainer = $MainLayout/VBoxContainer/Content
@onready var bottom_bar = $MainLayout/VBoxContainer/BottomBar
@onready var main_layout: CanvasLayer = $MainLayout
@onready var feedback_layer: CanvasLayer = $FeedbackLayer
@onready var Floating_text_scene = preload("res://Scenes/floating_text.tscn")


const VIEWS_PATH := "res://views/"

func _ready() -> void:
	# Connexions des signaux des boutons (tu peux aussi les connecter dans l’éditeur)
	btn_accueil.pressed.connect(_on_btn_accueil_pressed)
	btn_peinture.pressed.connect(_on_btn_peinture_pressed)
	btn_ascendancy.pressed.connect(_on_btn_ascendancy_pressed)
	
	# Pass the SceneContainer node to the manager.
	SceneManager.set_scene_container(content)
	
	# Charger la vue d’accueil au démarrage
	load_view_by_name("AccueilView")

func _on_btn_accueil_pressed() -> void:
	load_view_by_name("AccueilView")

func _on_btn_peinture_pressed() -> void:
	load_view_by_name("PaintingView")
	
func _on_btn_ascendancy_pressed() -> void:
	load_view_by_name("AscendancyView")
	
func load_view_by_name(view_name: String) -> void:
	SceneManager.load_game_scene(VIEWS_PATH + view_name + ".tscn")
	bottom_bar.set_view_specific_currencies(view_name)

func update_ui(_key:String, _value: Variant) -> void:
	pass

func add_ressource_feedback(amount: int, icon: Texture2D):
	var ft = Floating_text_scene.instantiate()
	feedback_layer.add_child(ft)
	ft.start("+%d" % amount, icon, Color(1,1,0))
	
