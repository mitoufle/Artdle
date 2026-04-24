class_name CanvasTiers
extends RefCounted

const MAX_TIER: int = 10

# tier -> {tier, gold_value, paint_seconds}
const TIERS: Dictionary = {
    1:  {"tier": 1,  "gold_value": 10.0,          "paint_seconds": 2.0},
    2:  {"tier": 2,  "gold_value": 50.0,          "paint_seconds": 3.0},
    3:  {"tier": 3,  "gold_value": 250.0,         "paint_seconds": 4.0},
    4:  {"tier": 4,  "gold_value": 1_500.0,       "paint_seconds": 5.0},
    5:  {"tier": 5,  "gold_value": 10_000.0,      "paint_seconds": 7.0},
    6:  {"tier": 6,  "gold_value": 75_000.0,      "paint_seconds": 10.0},
    7:  {"tier": 7,  "gold_value": 500_000.0,     "paint_seconds": 15.0},
    8:  {"tier": 8,  "gold_value": 5_000_000.0,   "paint_seconds": 20.0},
    9:  {"tier": 9,  "gold_value": 50_000_000.0,  "paint_seconds": 30.0},
    10: {"tier": 10, "gold_value": 500_000_000.0, "paint_seconds": 45.0},
}

static func get_tier(tier: int) -> Dictionary:
    return TIERS.get(tier, {"tier": tier, "gold_value": 0.0, "paint_seconds": 1.0})

static func upgrade_cost(from_tier: int) -> BigNumber:
    # Cost to go from `from_tier` to `from_tier + 1`
    var base: float = 100.0
    return BigNumber.from_float(base * pow(6.0, float(from_tier)))
