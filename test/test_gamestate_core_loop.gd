extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState._canvas_tier = 1
    GameState.slots.paint_time_override = -1.0
    GameState.tree.reset()

func test_canvas_sell_adds_gold_and_paint_mastery():
    GameState.slots.paint_time_override = 0.001
    GameState.tick(0.01)
    assert_gt(GameState.currency.get_amount("gold").value, 0.0)
    # Canvas at tier 1, default style 1, palette 1, mastery 0 → quality 3 → PM = 0 (sub-threshold).
    # PM gain via paint_mastery.on_canvas_sold requires pm_base > 0; quality 3 yields pm_base 0.
    # To ensure PM is added, use tier 10: quality = 10 + 1 + 1 + 0 = 12 → pm_base = 1.
    GameState.currency.reset(["gold", "paint_mastery"])
    GameState._canvas_tier = 10
    GameState.tick(0.01)
    assert_gt(GameState.currency.get_amount("gold").value, 0.0)
    assert_gt(GameState.currency.get_amount("paint_mastery").value, 0.0)

func test_tree_upgrade_then_tick_produces_inspiration():
    GameState.currency.add("gold", BigNumber.from_float(1000.0))
    var ok = GameState.tree.upgrade_part("roots")
    assert_true(ok)
    GameState.tree.tick(1.0)
    assert_gt(GameState.currency.get_amount("inspiration").value, 0.0)

func test_paint_mastery_boosts_tree_rate():
    GameState.currency.add("gold", BigNumber.from_float(1000.0))
    GameState.tree.upgrade_part("roots")
    GameState.tree.tick(1.0)
    var inspi_unboosted = GameState.currency.get_amount("inspiration").value
    GameState.currency.reset(["inspiration"])

    GameState.currency.add("paint_mastery", BigNumber.from_float(1.0e6))
    GameState.tree.external_multiplier = GameState.paint_mastery.current_multiplier()
    GameState.tree.tick(1.0)
    var inspi_boosted = GameState.currency.get_amount("inspiration").value
    assert_gt(inspi_boosted, inspi_unboosted)

func test_save_and_load_core_loop_roundtrip():
    GameState.save_system.save_path = "user://test_core_loop.save"
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    GameState._canvas_tier = 3
    GameState.tree.stage_index = 1
    GameState.tree._part_levels = {"roots": 2}

    assert_true(GameState.save_game())

    GameState.currency.reset(["gold"])
    GameState._canvas_tier = 1
    GameState.tree.reset()

    assert_true(GameState.load_game())
    assert_eq(GameState.currency.get_amount("gold").value, 500.0)
    assert_eq(GameState._canvas_tier, 3)
    assert_eq(GameState.tree.stage_index, 1)
    assert_eq(GameState.tree.get_part_level("roots"), 2)

    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
    GameState.save_system.save_path = "user://artdle.save"
