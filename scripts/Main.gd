extends Control
# On récupère des références directes pour éviter les erreurs de chemin plus tard
@onready var top_bar: HBoxContainer = $MainLayout/VBoxContainer/TopBar
@onready var btn_accueil = $MainLayout/VBoxContainer/TopBar/btnAccueil
@onready var btn_peinture = $MainLayout/VBoxContainer/TopBar/btnPeinture
@onready var btn_ascendancy = $MainLayout/VBoxContainer/TopBar/btnAscendancy
@onready var content: PanelContainer = $MainLayout/VBoxContainer/Content
@onready var bottom_bar = $MainLayout/VBoxContainer/BottomGroup/BottomBar
@onready var main_layout: CanvasLayer = $MainLayout
@onready var feedback_layer: CanvasLayer = $FeedbackLayer
@onready var Floating_text_scene = preload("res://Scenes/floating_text.tscn")


const VIEWS_PATH := "res://views/"

func _ready() -> void:
	# Connexions des signaux des boutons (tu peux aussi les connecter dans l'éditeur)
	btn_accueil.pressed.connect(_on_btn_accueil_pressed)
	btn_peinture.pressed.connect(_on_btn_peinture_pressed)
	btn_ascendancy.pressed.connect(_on_btn_ascendancy_pressed)
	
	GameState.level_changed.connect(_on_level_changed)
	
	# Pass the SceneContainer node to the manager.
	SceneManager.set_scene_container(content)
	
	# Charger la sauvegarde au démarrage
	load_save_on_startup()
	
	# Charger la vue d'accueil au démarrage
	load_view_by_name("AccueilView")
	
	# Disable buttons at start
	btn_peinture.disabled = true
	btn_ascendancy.disabled = true

	# Initial check - utiliser call_deferred pour s'assurer que tout est prêt
	call_deferred("_update_ui_after_load")

func _update_ui_after_load() -> void:
	# Mettre à jour l'UI après le chargement de la sauvegarde
	_on_level_changed(GameState.experience_manager.get_level())
	
	# Forcer la mise à jour de la barre d'XP en émettant les signaux
	GameState.experience_manager.emit_experience_changed()
	GameState.experience_manager.emit_level_changed()

func _on_level_changed(new_level: int):
	if new_level >= 2:
		btn_peinture.disabled = false
	if new_level >= 5: # Example level for ascendancy
		btn_ascendancy.disabled = false

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
	ft.set_as_top_level(true)
	ft.start("+%d" % amount, icon, Color(1,1,0))

#==============================================================================
# Save System
#==============================================================================

## Charge la sauvegarde au démarrage du jeu
func load_save_on_startup() -> void:
	if GameState.has_save_file():
		var success = GameState.load_game()
		if success:
			print("✅ Sauvegarde chargée au démarrage")
		else:
			print("❌ Échec du chargement de la sauvegarde")
	else:
		print("ℹ️ Aucune sauvegarde trouvée, démarrage avec les valeurs par défaut")

## Sauvegarde automatique périodique
func _on_autosave_timer_timeout() -> void:
	var success = GameState.save_game()
	if success:
		print("💾 Sauvegarde automatique réussie")
	else:
		print("❌ Échec de la sauvegarde automatique")

## Sauvegarde à la fermeture du jeu
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("🔄 Fermeture du jeu - Sauvegarde en cours...")
		var success = GameState.save_game()
		if success:
			print("✅ Sauvegarde finale réussie")
		else:
			print("❌ Échec de la sauvegarde finale")
		get_tree().quit()

func _input(event):
	# Raccourcis clavier pour les tests
	if event.is_action_pressed("ui_accept"):  # Entrée
		_run_integration_test()

func _run_integration_test():
	print("🧪 Lancement du test complet...")
	var test = preload("res://scripts/TestCompleteSystem.gd").new()
	add_child(test)
	
