class_name InspirationTree
extends Node

signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal part_upgraded(part_id: String, new_level: int)

var currency: Currency
var stage_index: int = 0

# part_id -> level (applies to current stage's parts)
var _part_levels: Dictionary = {}

# External multiplier applied to inspi production (e.g., from PaintMastery)
var external_multiplier: float = 1.0

func get_part_level(part_id: String) -> int:
    return int(_part_levels.get(part_id, 0))

func upgrade_part(part_id: String) -> bool:
    if currency == null:
        return false
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty() or not stage["parts"].has(part_id):
        return false
    var current_lvl: int = get_part_level(part_id)
    var max_lvl: int = int(stage["parts"][part_id]["max_level"])
    if current_lvl >= max_lvl:
        return false
    var cost = TreeStages.upgrade_cost(stage_index, part_id, current_lvl)
    if not currency.spend("gold", cost):
        return false
    _part_levels[part_id] = current_lvl + 1
    part_upgraded.emit(part_id, current_lvl + 1)
    _check_stage_advance()
    return true

func tick(delta: float) -> void:
    if currency == null:
        return
    var rate = _compute_rate()
    if rate <= 0.0:
        return
    currency.add("inspiration", BigNumber.from_float(rate * delta))

func _compute_rate() -> float:
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty():
        return 0.0
    var rate: float = 0.0
    for part_id in stage["parts"].keys():
        var lvl: int = get_part_level(part_id)
        var base: float = float(stage["parts"][part_id]["base_rate"])
        rate += base * float(lvl)
    return rate * external_multiplier

func _check_stage_advance() -> void:
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty():
        return
    for part_id in stage["parts"].keys():
        var max_lvl = int(stage["parts"][part_id]["max_level"])
        if get_part_level(part_id) < max_lvl:
            return
    # All parts maxed — advance
    if stage_index + 1 < TreeStages.count():
        stage_index += 1
        _part_levels = {}
        stage_entered.emit(stage_index)
        for unlock_id in TreeStages.get_stage(stage_index).get("unlocks", []):
            possibility_unlocked.emit(unlock_id)

func reset() -> void:
    stage_index = 0
    _part_levels = {}
    external_multiplier = 1.0

func serialize() -> Dictionary:
    return {
        "stage_index": stage_index,
        "part_levels": _part_levels.duplicate(),
    }

func deserialize(data: Dictionary) -> void:
    stage_index = int(data.get("stage_index", 0))
    _part_levels = data.get("part_levels", {}).duplicate()
