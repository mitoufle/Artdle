extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState._canvas_tier = 1
    GameState.slots.paint_time_override = -1.0
    GameState.skill_tree.unlocked_nodes = {}
    GameState.canvas_config.reset()
    GameState.painter_office.reset()
    # Reset slot count back to 1 (tests may have changed it).
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)

func test_canvas_slot_count_increases_when_multi_canvas_unlocked():
    # Player unlocks multi_canvas_1: slot count goes from 1 → 2
    GameState.currency.add("fame", BigNumber.from_float(60.0))
    GameState.skill_tree.unlock("multi_canvas_1")
    GameState.refresh_canvas_slot_count()
    assert_eq(GameState.slots.slot_count(), 2)

func test_quality_floor_propagates_to_slots_on_tick():
    GameState.currency.add("fame", BigNumber.from_float(20.0))
    GameState.skill_tree.unlock("quality_floor_1")
    GameState.tick(0.0)
    assert_eq(GameState.slots.quality_floor_bonus, 2.0)

func test_buy_style_ceiling_costs_gold_and_increments():
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    assert_true(GameState.buy_style_ceiling())
    assert_eq(GameState.canvas_config.style_current_ceiling, 2)
    # Spent 100 g → 400 g remaining
    assert_almost_eq(GameState.currency.get_amount("gold").value, 400.0, 0.01)

func test_buy_style_ceiling_blocked_when_insufficient_gold():
    assert_false(GameState.buy_style_ceiling())
    assert_eq(GameState.canvas_config.style_current_ceiling, 1)

func test_buy_style_ceiling_blocked_at_skill_cap():
    GameState.currency.add("gold", BigNumber.from_float(100_000_000.0))
    # Buy until skill cap (10 default)
    while GameState.canvas_config.style_current_ceiling < 10:
        assert_true(GameState.buy_style_ceiling())
    assert_false(GameState.buy_style_ceiling())
