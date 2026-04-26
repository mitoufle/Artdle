class_name SkillTreeNodes
extends RefCounted

# node_id -> {name, cost (fame), effects (dict of effect_key -> value)}
const NODES: Dictionary = {
    "gilded_frame": {
        "name":    "Cadre doré",
        "cost":    1.0,
        "branch":  "mvp",
        "effects": {"canvas_gold_mult_add": 0.10},
    },
    "quick_strokes": {
        "name":    "Coups rapides",
        "cost":    2.0,
        "branch":  "mvp",
        "effects": {"canvas_speed_mult_add": 0.15},
    },
    "master_palette": {
        "name":    "Palette de maître",
        "cost":    5.0,
        "branch":  "mvp",
        "effects": {"canvas_gold_mult_add": 0.25},
    },
    "tireless_hand": {
        "name":    "Main infatigable",
        "cost":    10.0,
        "branch":  "mvp",
        "effects": {"canvas_speed_mult_add": 0.30},
    },
    "golden_touch": {
        "name":    "Touche d'or",
        "cost":    25.0,
        "branch":  "mvp",
        "effects": {"canvas_gold_mult_add": 0.75},
    },
    # -- Canvas branch (spec 2026-04-25-canvas-design §9) --
    "chef_doeuvre_unlock": {
        "name":    "Chef d'œuvre",
        "cost":    10.0,
        "branch":  "canvas",
        "effects": {"chef_doeuvre_unlocked": 1.0},
    },
    "style_cap_1": {
        "name":    "Plafond de style I",
        "cost":    5.0,
        "branch":  "canvas",
        "prereq":  [],
        "effects": {"style_cap_add": 5.0},
    },
    "style_cap_2": {
        "name":    "Plafond de style II",
        "cost":    15.0,
        "branch":  "canvas",
        "prereq":  ["style_cap_1"],
        "effects": {"style_cap_add": 5.0},
    },
    "style_cap_3": {
        "name":    "Plafond de style III",
        "cost":    40.0,
        "branch":  "canvas",
        "prereq":  ["style_cap_2"],
        "effects": {"style_cap_add": 5.0},
    },
    "palette_cap_1": {
        "name":    "Plafond de palette I",
        "cost":    5.0,
        "branch":  "canvas",
        "prereq":  [],
        "effects": {"palette_cap_add": 5.0},
    },
    "palette_cap_2": {
        "name":    "Plafond de palette II",
        "cost":    15.0,
        "branch":  "canvas",
        "prereq":  ["palette_cap_1"],
        "effects": {"palette_cap_add": 5.0},
    },
    "palette_cap_3": {
        "name":    "Plafond de palette III",
        "cost":    40.0,
        "branch":  "canvas",
        "prereq":  ["palette_cap_2"],
        "effects": {"palette_cap_add": 5.0},
    },
    "subject_hint_1": {
        "name":    "Indice de sujet I",
        "cost":    15.0,
        "branch":  "canvas",
        "effects": {"subject_hint_add": 1.0},
    },
    "subject_hint_2": {
        "name":    "Indice de sujet II",
        "cost":    30.0,
        "branch":  "canvas",
        "prereq":  ["subject_hint_1"],
        "effects": {"subject_hint_add": 1.0},
    },
    "multi_canvas_1": {
        "name":    "Toile parallèle I",
        "cost":    50.0,
        "branch":  "canvas",
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "multi_canvas_2": {
        "name":    "Toile parallèle II",
        "cost":    150.0,
        "branch":  "canvas",
        "prereq":  ["multi_canvas_1"],
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "multi_canvas_3": {
        "name":    "Toile parallèle III",
        "cost":    400.0,
        "branch":  "canvas",
        "prereq":  ["multi_canvas_2"],
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "gamble_safety_net": {
        "name":    "Filet du gambleur",
        "cost":    25.0,
        "branch":  "canvas",
        "effects": {"gamble_safety_net": 1.0},
    },
    "always_gamble_toggle": {
        "name":    "Mise automatique",
        "cost":    15.0,
        "branch":  "canvas",
        "effects": {"always_gamble_unlocked": 1.0},
    },
    "quality_floor_1": {
        "name":    "Seuil de qualité I",
        "cost":    20.0,
        "branch":  "canvas",
        "effects": {"quality_floor_add": 2.0},
    },
    "quality_floor_2": {
        "name":    "Seuil de qualité II",
        "cost":    60.0,
        "branch":  "canvas",
        "prereq":  ["quality_floor_1"],
        "effects": {"quality_floor_add": 2.0},
    },
    "auto_mastery_passive": {
        "name":    "Maîtrise passive",
        "cost":    75.0,
        "branch":  "canvas",
        "prereq":  ["subject_hint_2"],
        "effects": {"auto_mastery_rate": 0.25},
    },
}

static func get_node(node_id: String) -> Dictionary:
    return NODES.get(node_id, {})

static func all_node_ids() -> Array:
    return NODES.keys()
