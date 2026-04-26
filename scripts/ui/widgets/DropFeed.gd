class_name DropFeed
extends HBoxContainer

const MAX_DROPS: int = 5

func add_drop(payload: Dictionary) -> void:
    var label := Label.new()
    var slot: String = String(payload.get("slot_type", "?"))
    var set_id: String = String(payload.get("set_id", ""))
    var tier: int = int(payload.get("tier", 1))
    var set_suffix: String = (" " + set_id.substr(0, 3)) if set_id != "" else ""
    label.text = "%s/T%d%s" % [slot.substr(0, 3), tier, set_suffix]
    add_child(label)
    while get_child_count() > MAX_DROPS:
        var oldest := get_child(0)
        remove_child(oldest)
        oldest.queue_free()
