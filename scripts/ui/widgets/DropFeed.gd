class_name DropFeed
extends HBoxContainer

const MAX_DROPS: int = 5

const SLOT_NAMES: Dictionary = {
    "brush": "Brush",
    "palette_item": "Palette",
    "chapeau": "Hat",
    "blouse": "Smock",
    "gants": "Gloves",
    "chevalet": "Easel",
    "couteau": "Knife",
    "broche": "Brooch",
}

const SET_NAMES: Dictionary = {
    "risque_tout": "Risk-Taker",
    "maitre": "Master",
    "rendement": "Yield",
    "erudit": "Scholar",
    "atelier_prolifique": "Prolific Studio",
    "heritage": "Legacy",
}

func add_drop(payload: Dictionary) -> void:
    var slot_id: String = String(payload.get("slot_type", "?"))
    var set_id: String = String(payload.get("set_id", ""))
    var tier: int = int(payload.get("tier", 1))
    var slot_name: String = String(SLOT_NAMES.get(slot_id, slot_id))
    var set_suffix: String = ""
    if set_id != "":
        set_suffix = " (%s)" % String(SET_NAMES.get(set_id, set_id))
    var label := Label.new()
    label.text = "%s T%d%s" % [slot_name, tier, set_suffix]
    add_child(label)
    while get_child_count() > MAX_DROPS:
        var oldest := get_child(0)
        remove_child(oldest)
        oldest.queue_free()
