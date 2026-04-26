extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState._canvas_tier = 1
    GameState.slots.paint_time_override = -1.0
    GameState.skill_tree.unlocked_nodes = {}
    GameState.canvas_config.reset()
    GameState.subject_mastery.reset()
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

func test_gamble_spends_inspiration_on_canvas_start():
    GameState.currency.add("inspiration", BigNumber.from_float(50.0))
    GameState.canvas_config.set_gamble(10)
    # Use a long paint_time so the canvas does not auto-restart during tick
    # (auto-restart would fire canvas_starting again and double-spend).
    GameState.slots.paint_time_override = 1.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)  # _start_slot fires canvas_starting → spend 10
    GameState.tick(0.01)               # progresses 0.01/1.0, canvas does not finish
    # After one canvas-start, 10 inspiration consumed.
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 40.0, 0.01)

func test_gamble_silently_skipped_when_insufficient_inspiration():
    GameState.canvas_config.set_gamble(100)
    GameState.slots.paint_time_override = 0.001
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    GameState.tick(0.01)
    # No spend (insufficient). Inspiration stays at 0.
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 0.0, 0.01)

func test_save_load_roundtrip_preserves_canvas_state():
    GameState.save_system.save_path = "user://test_canvas_loop.save"
    GameState.currency.add("fame", BigNumber.from_float(50.0))
    GameState.skill_tree.unlock("style_cap_1")
    GameState.canvas_config.style_current_ceiling = 5
    GameState.canvas_config.set_style(3)
    GameState.canvas_config.set_gamble(100)
    # Tier 1 threshold = 200 XP. Gaining 250 → tier 1, leftover 50.
    GameState.subject_mastery.gain("nature", 250)
    GameState._canvas_tier = 4

    assert_true(GameState.save_game())

    # Reset in-place to simulate a fresh boot.
    GameState.canvas_config.reset()
    GameState.subject_mastery.reset()
    GameState._canvas_tier = 1
    GameState.skill_tree.unlocked_nodes = {}

    assert_true(GameState.load_game())
    assert_eq(GameState.canvas_config.style, 3)
    assert_eq(GameState.canvas_config.style_current_ceiling, 5)
    assert_eq(GameState.canvas_config.gamble_n_inspi, 100)
    assert_eq(GameState.subject_mastery.tier_of("nature"), 1)
    assert_eq(GameState._canvas_tier, 4)
    assert_true(GameState.skill_tree.unlocked_nodes.has("style_cap_1"))

    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
    GameState.save_system.save_path = "user://artdle.save"

func test_full_canvas_loop_yields_gold_and_mastery():
    # Default config: tier 1, style 1, palette 1, mastery 0 → quality 3.
    # Gold = quality * tier * 10 * gold_mult = 3 * 1 * 10 * 1.0 = 30.
    # Mastery gain = 1 + floor(quality / 20) = 1 + 0 = 1 to "nature".
    # Force one canvas to fire and stop before auto-restart.
    GameState.slots.paint_time_override = 1.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    # Drive the canvas to completion in a single tick big enough to overshoot.
    GameState.tick(1.5)
    assert_almost_eq(GameState.currency.get_amount("gold").value, 30.0, 0.5)
    # Mastery accrued to active subject (nature is the default starter).
    assert_eq(GameState.subject_mastery.tier_of("nature"), 0)
    assert_eq(GameState.subject_mastery.xp_of("nature"), 1)

func test_chef_doeuvre_overrides_quality_when_proc():
    GameState.currency.add("fame", BigNumber.from_float(20.0))
    GameState.skill_tree.unlock("chef_doeuvre_unlock")
    # Manually push aggregators (we will bypass GameState.tick below to keep
    # chef_doeuvre_chance at 1.0 — GameState.tick would reset it to 0.005).
    GameState.slots.style_skill_cap = GameState.skill_tree.style_cap()
    GameState.slots.palette_skill_cap = GameState.skill_tree.palette_cap()
    GameState.slots.quality_floor_bonus = GameState.skill_tree.quality_floor_bonus()
    GameState.slots.chef_doeuvre_chance = 1.0  # force proc deterministically
    GameState.slots.paint_time_override = 1.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    # Bypass GameState.tick — slots.tick still fires canvas_completed via
    # signal, so _on_canvas_completed runs and updates currency.
    GameState.slots.tick(1.5)
    # ideal_quality = tier(1) + style_skill_cap(10) + palette_skill_cap(10) + 10 + 0 = 31
    # gold = 31 * 1 * 10 * 1.0 = 310
    var observed_gold = GameState.currency.get_amount("gold").value
    assert_almost_eq(observed_gold, 310.0, 1.0)
