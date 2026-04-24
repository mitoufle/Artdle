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

# No reset() — skill tree is permanent by design.

func serialize() -> Dictionary:
    return {"unlocked": unlocked_nodes.keys()}

func deserialize(data: Dictionary) -> void:
    unlocked_nodes = {}
    for id in data.get("unlocked", []):
        unlocked_nodes[id] = true
