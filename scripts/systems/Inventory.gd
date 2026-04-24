class_name Inventory
extends Node

signal item_added(item_id: String)
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)

const SLOTS: Array[String] = ["brush", "palette"]

var owned_items: Array = []
var equipped: Dictionary = {}

func _init() -> void:
    for s in SLOTS:
        equipped[s] = null

func add_item(item: Dictionary) -> void:
    owned_items.append(item)
    item_added.emit(item.get("id", ""))

func _find_item(item_id: String) -> Variant:
    for it in owned_items:
        if it.get("id") == item_id:
            return it
    return null

func equip(item_id: String) -> bool:
    var item = _find_item(item_id)
    if item == null:
        return false
    var slot: String = item.get("slot", "")
    if not SLOTS.has(slot):
        return false
    equipped[slot] = item
    item_equipped.emit(slot, item_id)
    return true

func unequip(slot: String) -> void:
    if equipped.get(slot) != null:
        equipped[slot] = null
        item_unequipped.emit(slot)

func canvas_gold_mult() -> float:
    var m: float = 1.0
    for s in SLOTS:
        var it = equipped.get(s)
        if it != null:
            m += float(it.get("gold_mult", 0.0))
    return m

func reset() -> void:
    owned_items = []
    for s in SLOTS:
        equipped[s] = null

func serialize() -> Dictionary:
    var eq_ids: Dictionary = {}
    for s in SLOTS:
        eq_ids[s] = null if equipped[s] == null else equipped[s].get("id", null)
    return {
        "owned": owned_items.duplicate(true),
        "equipped_ids": eq_ids,
    }

func deserialize(data: Dictionary) -> void:
    owned_items = data.get("owned", []).duplicate(true)
    var eq_ids: Dictionary = data.get("equipped_ids", {})
    for s in SLOTS:
        var id = eq_ids.get(s, null)
        equipped[s] = null if id == null else _find_item(id)
