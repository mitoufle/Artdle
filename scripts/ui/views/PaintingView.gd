extends BaseView

@export var workshop_popup_scene: PackedScene
@export var inventory_popup_scene: PackedScene
@export var craft_popup_scene: PackedScene
@export var painter_office_popup_scene: PackedScene

@onready var tier_label: Label = $VBoxContainer/CanvasArea/TierLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/CanvasArea/ProgressBar
@onready var sell_button: Button = $VBoxContainer/CanvasArea/SellButton
@onready var btn_workshop: Button = $VBoxContainer/ButtonsRow/BtnWorkshop
@onready var btn_inventory: Button = $VBoxContainer/ButtonsRow/BtnInventory
@onready var btn_craft: Button = $VBoxContainer/ButtonsRow/BtnCraft
@onready var btn_office: Button = $VBoxContainer/ButtonsRow/BtnOffice

func _connect_view_signals() -> void:
    sell_button.pressed.connect(func(): GameState.canvas.sell())
    btn_workshop.pressed.connect(func(): _open_popup(workshop_popup_scene, "workshop"))
    btn_inventory.pressed.connect(func(): _open_popup(inventory_popup_scene, "inventory"))
    btn_craft.pressed.connect(func(): _open_popup(craft_popup_scene, "workshop"))
    btn_office.pressed.connect(func(): _open_popup(painter_office_popup_scene, "painter_office"))

func _initialize_ui() -> void:
    _refresh()

func _process(_delta: float) -> void:
    _refresh()

func _refresh() -> void:
    tier_label.text = "Tier %d" % GameState.canvas.tier
    var needed: float = CanvasTiers.get_tier(GameState.canvas.tier)["paint_seconds"]
    progress_bar.max_value = needed
    progress_bar.value = GameState.canvas.progress_seconds
    sell_button.disabled = not GameState.canvas.is_ready_to_sell()
    btn_workshop.disabled  = not GameState.is_active("workshop")
    btn_inventory.disabled = not GameState.is_active("inventory")
    btn_craft.disabled     = not GameState.is_active("workshop")
    btn_office.disabled    = not GameState.is_active("painter_office")

func _open_popup(scene: PackedScene, required_mechanic: String) -> void:
    if scene == null:
        return
    if not GameState.is_active(required_mechanic):
        return
    var popup = scene.instantiate()
    add_child(popup)
    if popup.has_method("popup_centered"):
        popup.popup_centered()
