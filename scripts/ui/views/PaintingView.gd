extends BaseView

const CanvasSlotCardScene = preload("res://Scenes/Widgets/CanvasSlotCard.tscn")

@export var canvas_popup_scene: PackedScene
@export var inventory_popup_scene: PackedScene
@export var craft_popup_scene: PackedScene
@export var painter_office_popup_scene: PackedScene

@onready var _slot_list: VBoxContainer = $VBoxContainer/ScrollContainer/SlotList
@onready var _drops: DropFeed = $VBoxContainer/Drops
@onready var btn_canvas: Button = $VBoxContainer/ButtonsRow/BtnCanvas
@onready var btn_inventory: Button = $VBoxContainer/ButtonsRow/BtnInventory
@onready var btn_craft: Button = $VBoxContainer/ButtonsRow/BtnCraft
@onready var btn_office: Button = $VBoxContainer/ButtonsRow/BtnOffice

var _cards: Array = []

func _connect_view_signals() -> void:
    GameState.slots.drop_rolled.connect(_drops.add_drop)
    GameState.skill_tree.node_unlocked.connect(func(_id): _refresh_cards())
    btn_canvas.pressed.connect(func(): _open_popup(canvas_popup_scene))
    btn_inventory.pressed.connect(func(): _open_popup(inventory_popup_scene, "inventory"))
    btn_craft.pressed.connect(func(): _open_popup(craft_popup_scene, "workshop"))
    btn_office.pressed.connect(func(): _open_popup(painter_office_popup_scene, "painter_office"))

func _initialize_ui() -> void:
    _refresh_cards()
    _refresh_buttons()

func _process(_delta: float) -> void:
    _refresh_buttons()

func _refresh_cards() -> void:
    for card in _cards:
        (card as Node).queue_free()
    _cards.clear()
    var n: int = GameState.slots.slot_count()
    for i in n:
        var card := CanvasSlotCardScene.instantiate() as CanvasSlotCard
        card.bind(i, GameState.slots.get_canvas(i))
        _slot_list.add_child(card)
        _cards.append(card)

func _refresh_buttons() -> void:
    # Canvas is always available — it's the central mechanic.
    btn_canvas.disabled = false
    btn_inventory.disabled = not GameState.is_active("inventory")
    btn_craft.disabled = not GameState.is_active("workshop")
    btn_office.disabled = not GameState.is_active("painter_office")

func _open_popup(scene: PackedScene, required_mechanic: String = "") -> void:
    if scene == null:
        return
    if required_mechanic != "" and not GameState.is_active(required_mechanic):
        return
    var popup = scene.instantiate()
    add_child(popup)
    if popup.has_method("popup_centered"):
        popup.popup_centered()
