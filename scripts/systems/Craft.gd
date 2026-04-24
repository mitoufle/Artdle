class_name Craft
extends Node

signal item_crafted(recipe_id: String, item: Dictionary)

var currency: Currency
var inventory: Inventory

func craft(recipe_id: String) -> bool:
    if currency == null or inventory == null:
        return false
    var recipe = CraftRecipes.get_recipe(recipe_id)
    if recipe.is_empty():
        return false
    var cost = BigNumber.from_float(float(recipe["gold_cost"]))
    if not currency.spend("gold", cost):
        return false
    var item: Dictionary = recipe["produces"].duplicate(true)
    inventory.add_item(item)
    item_crafted.emit(recipe_id, item)
    return true

func reset() -> void:
    pass
