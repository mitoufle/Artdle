class_name SkillTree
extends Node

signal node_unlocked(node_id: String)

var currency: Currency
var unlocked_nodes: Dictionary = {}

func unlock(node_id: String) -> bool:
    if currency == null:
        return false
    if unlocked_nodes.has(node_id):
        return false
    var node = SkillTreeNodes.get_node(node_id)
    if node.is_empty():
        return false
    for required in node.get("prereq", []):
        if not unlocked_nodes.has(required):
            return false
    var cost = BigNumber.from_float(float(node["cost"]))
    if not currency.spend("fame", cost):
        return false
    unlocked_nodes[node_id] = true
    node_unlocked.emit(node_id)
    return true

func _sum_effect(effect_key: String) -> float:
    var total: float = 0.0
    for node_id in unlocked_nodes.keys():
        var node = SkillTreeNodes.get_node(node_id)
        total += float(node.get("effects", {}).get(effect_key, 0.0))
    return total

func canvas_gold_mult() -> float:
    return 1.0 + _sum_effect("canvas_gold_mult_add")

func canvas_speed_mult() -> float:
    return 1.0 + _sum_effect("canvas_speed_mult_add")

const STYLE_CAP_BASELINE: int = 10
const PALETTE_CAP_BASELINE: int = 10

func style_cap() -> int:
    return STYLE_CAP_BASELINE + int(_sum_effect("style_cap_add"))

func palette_cap() -> int:
    return PALETTE_CAP_BASELINE + int(_sum_effect("palette_cap_add"))

func multi_canvas_slots_grant() -> int:
    return int(_sum_effect("multi_canvas_slots_add"))

func quality_floor_bonus() -> float:
    return _sum_effect("quality_floor_add")

func subject_hint_count() -> int:
    return int(_sum_effect("subject_hint_add"))

func chef_doeuvre_unlocked() -> bool:
    return _sum_effect("chef_doeuvre_unlocked") > 0.0

func always_gamble_unlocked() -> bool:
    return _sum_effect("always_gamble_unlocked") > 0.0

func gamble_safety_net() -> bool:
    return _sum_effect("gamble_safety_net") > 0.0

func auto_mastery_rate() -> float:
    return _sum_effect("auto_mastery_rate")

# No reset() — skill tree is permanent by design.

func serialize() -> Dictionary:
    return {"unlocked": unlocked_nodes.keys()}

func deserialize(data: Dictionary) -> void:
    unlocked_nodes = {}
    for id in data.get("unlocked", []):
        unlocked_nodes[id] = true
