extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState._canvas_tier = 1
    GameState.slots.paint_time_override = -1.0
    GameState.tree.reset()
    GameState.workshop.reset()
    GameState.inventory.reset()
    GameState.painter_office.reset()
    GameState.skill_tree.unlocked_nodes = {}
    GameState.ascend.ascend_count = 0
    GameState._active_mechanics.clear()
    GameState._possible_mechanics.clear()
    # Refresh slot multipliers from the freshly-reset state, so any
    # set_slot_count() call later in the test reads zeroed aggregators
    # (not values left over from a previous test file's tick).
    GameState.tick(0.0)

func test_default_gold_multiplier_is_one():
    assert_almost_eq(GameState.canvas_gold_multiplier(), 1.0, 0.0001)

func test_default_speed_multiplier_is_one():
    assert_almost_eq(GameState.canvas_speed_multiplier(), 1.0, 0.0001)

func test_canvas_sale_with_modifiers_applies_all_of_them():
    GameState.workshop.tier = 2  # gold_mult = 1 + 0.25*2 = 1.5
    GameState.currency.add("fame", BigNumber.from_float(5.0))
    GameState.skill_tree.unlock("gilded_frame")  # +0.10 gold
    # GameState._ready already started slot 0 with formula paint_time (3s).
    # Restart the slot so the override applies to a fresh canvas.
    GameState.slots.paint_time_override = 0.001
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    GameState.tick(0.01)
    var expected_mult = (1.0 + 2 * Workshop.GOLD_MULT_PER_TIER) * 1.0 * 1.10
    # Default canvas: tier 1, style 1, palette 1, mastery 0 → quality = 3 → gold = 3 * 1 * 10 = 30
    var expected_gold = 30.0 * expected_mult
    assert_almost_eq(GameState.currency.get_amount("gold").value, expected_gold, 0.001)

func test_try_activate_mechanic_requires_possibility():
    var ok = GameState.try_activate_mechanic("workshop")
    assert_false(ok)

func test_try_activate_mechanic_spends_inspi_and_activates():
    GameState._possible_mechanics["workshop"] = true
    GameState.currency.add("inspiration", BigNumber.from_float(1000.0))
    var cost = TreeStages.unlock_cost("workshop").value
    var ok = GameState.try_activate_mechanic("workshop")
    assert_true(ok)
    assert_true(GameState.is_active("workshop"))
    assert_eq(GameState.currency.get_amount("inspiration").value, 1000.0 - cost)

func test_full_loop_run_then_ascend():
    GameState.currency.add("inspiration", Balance.palier_ascend(0))
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    var ok = GameState.ascend.perform()
    assert_true(ok)
    assert_eq(GameState.currency.get_amount("inspiration").value, 0.0)
    assert_eq(GameState.currency.get_amount("gold").value, 0.0)
    assert_gt(GameState.currency.get_amount("fame").value, 0.0)
    assert_eq(GameState.ascend.ascend_count, 1)

func test_ascend_resets_active_and_possible_mechanics():
    GameState._possible_mechanics["workshop"] = true
    GameState._active_mechanics["workshop"] = true
    GameState.currency.add("inspiration", Balance.palier_ascend(0))
    GameState.ascend.perform()
    assert_false(GameState.is_active("workshop"))
    assert_false(GameState.is_possible("workshop"))

func test_full_save_load_roundtrip():
    GameState.save_system.save_path = "user://test_full_loop.save"
    GameState.currency.add("gold", BigNumber.from_float(1234.0))
    GameState.currency.add("fame", BigNumber.from_float(7.0))
    GameState.currency.add("paint_mastery", BigNumber.from_float(42.0))
    GameState.workshop.tier = 3
    GameState.inventory.add_item({"id": "basic_brush", "slot": "brush", "gold_mult": 0.1})
    GameState.inventory.equip("basic_brush")
    GameState.painter_office.worker_count = 2
    GameState.skill_tree.unlocked_nodes["gilded_frame"] = true
    GameState.ascend.ascend_count = 3
    GameState._possible_mechanics["workshop"] = true
    GameState._active_mechanics["workshop"] = true

    assert_true(GameState.save_game())

    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState.workshop.reset()
    GameState.inventory.reset()
    GameState.painter_office.reset()
    GameState.skill_tree.unlocked_nodes = {}
    GameState.ascend.ascend_count = 0
    GameState._active_mechanics.clear()
    GameState._possible_mechanics.clear()

    assert_true(GameState.load_game())

    assert_eq(GameState.currency.get_amount("gold").value, 1234.0)
    assert_eq(GameState.currency.get_amount("fame").value, 7.0)
    assert_eq(GameState.currency.get_amount("paint_mastery").value, 42.0)
    assert_eq(GameState.workshop.tier, 3)
    assert_eq(GameState.inventory.owned_items.size(), 1)
    assert_eq(GameState.inventory.equipped["brush"]["id"], "basic_brush")
    assert_eq(GameState.painter_office.worker_count, 2)
    assert_true(GameState.skill_tree.unlocked_nodes.has("gilded_frame"))
    assert_eq(GameState.ascend.ascend_count, 3)
    assert_true(GameState.is_possible("workshop"))
    assert_true(GameState.is_active("workshop"))

    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
    GameState.save_system.save_path = "user://artdle.save"
