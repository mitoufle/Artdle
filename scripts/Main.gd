extends Control
# On récupère des références directes pour éviter les erreurs de chemin plus tard
@onready var top_bar: HBoxContainer  = $MainLayout/TopBar
@onready var btn_accueil: Button     = $MainLayout/TopBar/BtnAccueil
@onready var btn_peinture: Button    = $MainLayout/TopBar/BtnPeinture
@onready var content: PanelContainer = $MainLayout/Content
@onready var lblInspiCount: Label    = $MainLayout/TopBar/lblInspiCount
@onready var Floating_text_scene = preload("res://views/floating_text.tscn")


const VIEWS_PATH := "res://views/"

func _ready() -> void:
	# Connexions des signaux des boutons (tu peux aussi les connecter dans l’éditeur)
	btn_accueil.pressed.connect(_on_btn_accueil_pressed)
	btn_peinture.pressed.connect(_on_btn_peinture_pressed)
	GameState.state_changed.connect(update_ui)
	update_ui()

	# Charger la vue d’accueil au démarrage
	load_view("AccueilView.tscn")

func _on_btn_accueil_pressed() -> void:
	load_view("AccueilView.tscn")

func _on_btn_peinture_pressed() -> void:
	load_view("PaintingView.tscn")

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

func update_ui() -> void:
	lblInspiCount.text = "inspiration : " + str(int(GameState.inspiration))

func add_ressource_feedback(amount: int= 1 ):
	var ft = Floating_text_scene.instantiate()
	add_child(ft)
	ft.start("+%d" % amount, Color(1,1,0))
	
