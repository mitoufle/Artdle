class_name TreeStages
extends RefCounted

# Stage definition:
#   name: display name
#   parts: dict of part_id -> {base_rate, max_level, upgrade_base_cost, upgrade_growth}
#   unlocks: list of mechanic_ids unlocked upon entering this stage
#
# Cost to upgrade part to level N (from N-1) = upgrade_base_cost * upgrade_growth^(N-1)

const STAGES: Array = [
    {
        "name": "Pousse",
        "parts": {
            "roots": {"base_rate": 0.1, "max_level": 5, "upgrade_base_cost": 5.0, "upgrade_growth": 1.8},
        },
        "unlocks": [],
    },
    {
        "name": "Jeune",
        "parts": {
            "roots":  {"base_rate": 0.3, "max_level": 5, "upgrade_base_cost": 20.0, "upgrade_growth": 1.8},
            "leaves": {"base_rate": 0.2, "max_level": 5, "upgrade_base_cost": 30.0, "upgrade_growth": 1.8},
        },
        "unlocks": [],
    },
    {
        "name": "Rameaux",
        "parts": {
            "roots":    {"base_rate": 1.0, "max_level": 5, "upgrade_base_cost": 100.0,  "upgrade_growth": 1.9},
            "leaves":   {"base_rate": 0.8, "max_level": 5, "upgrade_base_cost": 150.0,  "upgrade_growth": 1.9},
            "branches": {"base_rate": 1.5, "max_level": 5, "upgrade_base_cost": 250.0,  "upgrade_growth": 1.9},
        },
        "unlocks": ["workshop"],
    },
    {
        "name": "Mature",
        "parts": {
            "roots":    {"base_rate": 3.0, "max_level": 5, "upgrade_base_cost": 1_000.0, "upgrade_growth": 2.0},
            "leaves":   {"base_rate": 2.5, "max_level": 5, "upgrade_base_cost": 1_500.0, "upgrade_growth": 2.0},
            "branches": {"base_rate": 4.0, "max_level": 5, "upgrade_base_cost": 2_500.0, "upgrade_growth": 2.0},
            "flowers":  {"base_rate": 5.0, "max_level": 5, "upgrade_base_cost": 5_000.0, "upgrade_growth": 2.0},
        },
        "unlocks": ["inventory"],
    },
    {
        "name": "Ancien",
        "parts": {
            "roots":    {"base_rate": 8.0,  "max_level": 5, "upgrade_base_cost": 20_000.0,  "upgrade_growth": 2.1},
            "leaves":   {"base_rate": 7.0,  "max_level": 5, "upgrade_base_cost": 30_000.0,  "upgrade_growth": 2.1},
            "branches": {"base_rate": 12.0, "max_level": 5, "upgrade_base_cost": 50_000.0,  "upgrade_growth": 2.1},
            "flowers":  {"base_rate": 18.0, "max_level": 5, "upgrade_base_cost": 80_000.0,  "upgrade_growth": 2.1},
            "fruits":   {"base_rate": 25.0, "max_level": 5, "upgrade_base_cost": 150_000.0, "upgrade_growth": 2.1},
        },
        "unlocks": ["painter_office"],
    },
]

const UNLOCK_COSTS: Dictionary = {
    "workshop":       500.0,
    "inventory":      2500.0,
    "painter_office": 10000.0,
}

static func count() -> int:
    return STAGES.size()

static func get_stage(index: int) -> Dictionary:
    if index < 0 or index >= STAGES.size():
        return {}
    return STAGES[index]

static func unlock_cost(mechanic_id: String) -> BigNumber:
    return BigNumber.from_float(UNLOCK_COSTS.get(mechanic_id, 0.0))

static func upgrade_cost(stage_index: int, part_id: String, current_level: int) -> BigNumber:
    var s = get_stage(stage_index)
    if s.is_empty() or not s["parts"].has(part_id):
        return BigNumber.from_float(0.0)
    var p = s["parts"][part_id]
    var cost: float = p["upgrade_base_cost"] * pow(p["upgrade_growth"], float(current_level))
    return BigNumber.from_float(cost)
