extends GutTest

var currency: Currency
var inventory: Inventory
var craft: Craft

func before_each():
    currency = Currency.new()
    inventory = Inventory.new()
    craft = Craft.new()
    craft.currency = currency
    craft.inventory = inventory

func after_each():
    if currency != null:
        currency.free()
        currency = null
    if inventory != null:
        inventory.free()
        inventory = null
    if craft != null:
        craft.free()
        craft = null

func test_craft_success_adds_item():
    currency.add("gold", BigNumber.from_float(1000.0))
    var ok = craft.craft("basic_brush")
    assert_true(ok)
    assert_eq(inventory.owned_items.size(), 1)
    assert_eq(inventory.owned_items[0]["id"], "basic_brush")

func test_craft_spends_gold():
    currency.add("gold", BigNumber.from_float(1000.0))
    var cost = CraftRecipes.get_recipe("basic_brush")["gold_cost"]
    craft.craft("basic_brush")
    assert_eq(currency.get_amount("gold").value, 1000.0 - cost)

func test_craft_insufficient_gold_fails():
    var ok = craft.craft("basic_brush")
    assert_false(ok)
    assert_eq(inventory.owned_items.size(), 0)

func test_craft_unknown_recipe_fails():
    currency.add("gold", BigNumber.from_float(1.0e6))
    var ok = craft.craft("nonexistent_recipe")
    assert_false(ok)
