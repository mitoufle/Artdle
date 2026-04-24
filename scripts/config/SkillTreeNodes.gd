class_name SkillTreeNodes
extends RefCounted

# node_id -> {name, cost (fame), effects (dict of effect_key -> value)}
const NODES: Dictionary = {
    "gilded_frame": {
        "name":    "Cadre doré",
        "cost":    1.0,
        "effects": {"canvas_gold_mult_add": 0.10},
    },
    "quick_strokes": {
        "name":    "Coups rapides",
        "cost":    2.0,
        "effects": {"canvas_speed_mult_add": 0.15},
    },
    "master_palette": {
        "name":    "Palette de maître",
        "cost":    5.0,
        "effects": {"canvas_gold_mult_add": 0.25},
    },
    "tireless_hand": {
        "name":    "Main infatigable",
        "cost":    10.0,
        "effects": {"canvas_speed_mult_add": 0.30},
    },
    "golden_touch": {
        "name":    "Touche d'or",
        "cost":    25.0,
        "effects": {"canvas_gold_mult_add": 0.75},
    },
}

static func get_node(node_id: String) -> Dictionary:
    return NODES.get(node_id, {})

static func all_node_ids() -> Array:
    return NODES.keys()
