extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState._canvas_tier = 1
    GameState.slots.paint_time_override = -1.0
    GameState.skill_tree.unlocked_nodes = {}
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
