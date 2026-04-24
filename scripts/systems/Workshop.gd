class_name Workshop
extends Node

signal tier_upgraded(new_tier: int)

const GOLD_MULT_PER_TIER: float = 0.25
const SPEED_MULT_PER_TIER: float = 0.10
const MAX_TIER: int = 20
const UPGRADE_COST_BASE: float = 1000.0
const UPGRADE_COST_GROWTH: float = 3.0

var currency: Currency
var tier: int = 0

static func tier_upgrade_cost(from_tier: int) -> BigNumber:
    return BigNumber.from_float(UPGRADE_COST_BASE * pow(UPGRADE_COST_GROWTH, float(from_tier)))

func upgrade_tier() -> bool:
    if currency == null:
        return false
    if tier >= MAX_TIER:
        return false
    var cost = Workshop.tier_upgrade_cost(tier)
    if not currency.spend("gold", cost):
        return false
    tier += 1
    tier_upgraded.emit(tier)
    return true

func canvas_gold_mult() -> float:
    return 1.0 + GOLD_MULT_PER_TIER * float(tier)

func canvas_speed_mult() -> float:
    return 1.0 + SPEED_MULT_PER_TIER * float(tier)

func reset() -> void:
    tier = 0

func serialize() -> Dictionary:
    return {"tier": tier}

func deserialize(data: Dictionary) -> void:
    tier = int(data.get("tier", 0))
