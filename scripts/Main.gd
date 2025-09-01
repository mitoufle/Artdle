extends Control
# On récupère des références directes pour éviter les erreurs de chemin plus tard
@onready var top_bar: HBoxContainer  = $MainLayout/TopBar
@onready var btn_accueil: Button     = $MainLayout/TopBar/btnAccueil
@onready var btn_peinture: Button    = $MainLayout/TopBar/btnPeinture
@onready var btn_ascendancy: Button  = $MainLayout/TopBar/btnAscendancy
@onready var content: PanelContainer = $MainLayout/Content
@onready var lblInspiCount: Label    = $MainLayout/TopBar/lblInspiCount
@onready var Floating_text_scene     = preload("res://Scenes/floating_text.tscn")


const VIEWS_PATH := "res://views/"

func _ready() -> void:
	# Connexions des signaux des boutons (tu peux aussi les connecter dans l’éditeur)
	btn_accueil.pressed.connect(_on_btn_accueil_pressed)
	btn_peinture.pressed.connect(_on_btn_peinture_pressed)
	btn_ascendancy.pressed.connect(_on_btn_ascendancy_pressed)
	GameState.inspiration_changed.connect(update_ui)
	

	# Charger la vue d’accueil au démarrage
	load_view("AccueilView.tscn")

func _on_btn_accueil_pressed() -> void:
	load_view("AccueilView.tscn")

func _on_btn_peinture_pressed() -> void:
	load_view("PaintingView.tscn")
	
func _on_btn_ascendancy_pressed() -> void:
	load_view("AscendancyView.tscn")
	
func load_view(scene_file: String) -> void:
	# 1) Vider la zone de contenu (supprimer l’ancienne vue)
	for child in content.get_children():
		child.queue_free()

	# 2) Charger et instancier la nouvelle vue
	var path := VIEWS_PATH + scene_file
	var packed_scene := load(path)
	if packed_scene == null:
		push_warning("Impossible de charger la vue : " + path)
		return

	var view_instance: Node = (packed_scene as PackedScene).instantiate()
	# 3) Ajouter la vue dans la zone de contenu
	content.add_child(view_instance)

func update_ui(key:String, value: Variant) -> void:
	match key:
		"inspiration":
			lblInspiCount.text = "inspiration : " + str(round(value * 1000) /1000.0)
		_:
			push_warning("Unhandled UI update for key: %s" % key)

func add_ressource_feedback(amount: int= 1 ):
	var ft = Floating_text_scene.instantiate()
	add_child(ft)
	ft.start("+%d" % amount, Color(1,1,0))
	
