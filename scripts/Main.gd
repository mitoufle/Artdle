extends Control

@export var accueil_scene: PackedScene
@export var painting_scene: PackedScene
@export var ascendancy_scene: PackedScene
@export var skill_tree_scene: PackedScene

@onready var content: PanelContainer = $MainLayout/VBoxContainer/Content
@onready var btn_accueil: Button = $MainLayout/VBoxContainer/TopBar/btnAccueil
@onready var btn_peinture: Button = $MainLayout/VBoxContainer/TopBar/btnPeinture
@onready var btn_ascendancy: Button = $MainLayout/VBoxContainer/TopBar/btnAscendancy
@onready var btn_skill: Button = $MainLayout/VBoxContainer/TopBar/btnSkillTree
@onready var btn_speed: Button = $MainLayout/VBoxContainer/TopBar/btnSpeed

const SPEED_STEPS: Array[float] = [1.0, 10.0, 100.0]

var _current_view: Node = null
var _speed_index: int = 0

func _ready() -> void:
	btn_accueil.pressed.connect(func(): _switch_view(accueil_scene))
	btn_peinture.pressed.connect(func(): _switch_view(painting_scene))
	btn_ascendancy.pressed.connect(func(): _switch_view(ascendancy_scene))
	btn_skill.pressed.connect(func(): _switch_view(skill_tree_scene))
	btn_speed.pressed.connect(_cycle_speed)
	_refresh_speed_label()
	GameState.load_game()
	_switch_view(accueil_scene)

func _process(delta: float) -> void:
	GameState.tick(delta * SPEED_STEPS[_speed_index])

func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEED_STEPS.size()
	_refresh_speed_label()

func _refresh_speed_label() -> void:
	btn_speed.text = "x%d" % int(SPEED_STEPS[_speed_index])

func _switch_view(scene: PackedScene) -> void:
	if scene == null:
		return
	if _current_view != null:
		_current_view.queue_free()
	_current_view = scene.instantiate()
	content.add_child(_current_view)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()
		get_tree().quit()
