extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState.canvas.reset()
    GameState.tree.reset()

func test_canvas_sell_adds_gold_and_paint_mastery():
    pending("Canvas.sell removed in Canvas plan; replaced by CanvasSlots.canvas_completed in Task 14")

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
    pending("Canvas tier moved to GameState; save schema replaces canvas with canvas_tier in Task 14")
