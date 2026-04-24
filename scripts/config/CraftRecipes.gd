class_name CraftRecipes
extends RefCounted

# recipe_id -> {name, gold_cost, produces (item dict for Inventory)}
const RECIPES: Dictionary = {
    "basic_brush": {
        "name":      "Pinceau basique",
        "gold_cost": 500.0,
        "produces":  {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1},
    },
    "fine_brush": {
        "name":      "Pinceau fin",
        "gold_cost": 5000.0,
        "produces":  {"id": "fine_brush", "slot": "brush", "gold_mult": 0.25},
    },
    "basic_palette": {
        "name":      "Palette basique",
        "gold_cost": 1000.0,
        "produces":  {"id": "basic_palette", "slot": "palette", "gold_mult": 0.1},
    },
    "fine_palette": {
        "name":      "Palette fine",
        "gold_cost": 10000.0,
        "produces":  {"id": "fine_palette", "slot": "palette", "gold_mult": 0.3},
    },
}

static func get_recipe(recipe_id: String) -> Dictionary:
    return RECIPES.get(recipe_id, {})

static func all_recipes() -> Array:
    return RECIPES.keys()
