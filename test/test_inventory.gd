extends GutTest

var inventory: Inventory

func before_each():
    inventory = Inventory.new()

func after_each():
    if inventory != null:
        inventory.free()
        inventory = null

func test_initial_empty():
    assert_eq(inventory.owned_items.size(), 0)
    assert_eq(inventory.equipped["brush"], null)

func test_add_item():
    var item = {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1}
    inventory.add_item(item)
    assert_eq(inventory.owned_items.size(), 1)

func test_equip_success():
    var item = {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1}
    inventory.add_item(item)
    var ok = inventory.equip("basic_brush")
    assert_true(ok)
    assert_eq(inventory.equipped["brush"]["id"], "basic_brush")

func test_equip_unknown_fails():
    var ok = inventory.equip("nonexistent")
    assert_false(ok)

func test_equip_replaces_existing_in_slot():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.add_item({"id": "b", "slot": "brush", "gold_mult": 0.2})
    inventory.equip("a")
    inventory.equip("b")
    assert_eq(inventory.equipped["brush"]["id"], "b")

func test_unequip():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    inventory.unequip("brush")
    assert_eq(inventory.equipped["brush"], null)

func test_canvas_gold_mult_sums_equipped():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.2})
    inventory.add_item({"id": "b", "slot": "palette", "gold_mult": 0.3})
    inventory.equip("a")
    inventory.equip("b")
    assert_almost_eq(inventory.canvas_gold_mult(), 1.5, 0.0001)

func test_reset_clears_items_and_slots():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    inventory.reset()
    assert_eq(inventory.owned_items.size(), 0)
    assert_eq(inventory.equipped["brush"], null)

func test_serialize_roundtrip():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    var data = inventory.serialize()
    var fresh = Inventory.new()
    fresh.deserialize(data)
    assert_eq(fresh.owned_items.size(), 1)
    assert_eq(fresh.equipped["brush"]["id"], "a")
    fresh.free()
