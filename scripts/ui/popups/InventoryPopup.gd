extends PopupPanel

@onready var brush_label: Label = $MarginContainer/VBoxContainer/EquippedSection/BrushSlotLabel
@onready var brush_btn: Button = $MarginContainer/VBoxContainer/EquippedSection/BrushUnequipBtn
@onready var palette_label: Label = $MarginContainer/VBoxContainer/EquippedSection/PaletteSlotLabel
@onready var palette_btn: Button = $MarginContainer/VBoxContainer/EquippedSection/PaletteUnequipBtn
@onready var owned_list: VBoxContainer = $MarginContainer/VBoxContainer/OwnedList
@onready var close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    close_btn.pressed.connect(queue_free)
    brush_btn.pressed.connect(func(): GameState.inventory.unequip("brush"); _refresh())
    palette_btn.pressed.connect(func(): GameState.inventory.unequip("palette"); _refresh())
    GameState.inventory.item_added.connect(_on_item_added)
    GameState.inventory.item_equipped.connect(_on_item_equipped)
    GameState.inventory.item_unequipped.connect(_on_item_unequipped)
    _refresh()

func _on_item_added(_item_id: String) -> void: _refresh()
func _on_item_equipped(_slot: String, _item_id: String) -> void: _refresh()
func _on_item_unequipped(_slot: String) -> void: _refresh()

func _refresh() -> void:
    var b = GameState.inventory.equipped["brush"]
    brush_label.text = "Pinceau : %s" % ("—" if b == null else b.get("id", "?"))
    brush_btn.disabled = b == null
    var p = GameState.inventory.equipped["palette"]
    palette_label.text = "Palette : %s" % ("—" if p == null else p.get("id", "?"))
    palette_btn.disabled = p == null

    for child in owned_list.get_children():
        child.queue_free()
    for item in GameState.inventory.owned_items:
        var btn = Button.new()
        var id: String = item.get("id", "?")
        btn.text = "Équiper : %s" % id
        btn.pressed.connect(func(): GameState.inventory.equip(id); _refresh())
        owned_list.add_child(btn)
