class_name Canvas
extends Node

signal sold(tier: int, gold_amount: float)

var tier: int = 1
var progress_seconds: float = 0.0

func tick(delta: float) -> void:
    progress_seconds += delta

func is_ready_to_sell() -> bool:
    var needed: float = CanvasTiers.get_tier(tier)["paint_seconds"]
    return progress_seconds >= needed

func sell() -> void:
    if not is_ready_to_sell():
        return
    var gold_value: float = CanvasTiers.get_tier(tier)["gold_value"]
    progress_seconds = 0.0
    sold.emit(tier, gold_value)

func upgrade_tier() -> void:
    if tier < CanvasTiers.MAX_TIER:
        tier += 1

func reset() -> void:
    tier = 1
    progress_seconds = 0.0

func serialize() -> Dictionary:
    return {"tier": tier, "progress_seconds": progress_seconds}

func deserialize(data: Dictionary) -> void:
    tier = int(data.get("tier", 1))
    progress_seconds = float(data.get("progress_seconds", 0.0))
