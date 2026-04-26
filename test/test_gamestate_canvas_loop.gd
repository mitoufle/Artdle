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

func test_gamble_amount_is_per_slot_not_shared():
    # C1 regression guard: with 2+ slots, the per-canvas gamble_amount meta
    # must not be clobbered by neighbors starting. Player has only 30 inspi
    # so the picker amount of 10 is affordable just twice but config holds 100.
    # Each canvas's meta must reflect ITS OWN start, not whichever started last.
    GameState.canvas_config.set_gamble(100)
    GameState.currency.add("inspiration", BigNumber.from_float(100.0))
    GameState.slots.paint_time_override = 100.0  # never auto-finish during this test
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(2)
    var c0: Canvas = GameState.slots.get_canvas(0)
    var c1: Canvas = GameState.slots.get_canvas(1)
    assert_eq(int(c0.get_meta("gamble_amount", -1)), 100,
        "slot 0 paid 100 for gamble")
    assert_eq(int(c1.get_meta("gamble_amount", -1)), 0,
        "slot 1 had insufficient funds, amount stamped as 0")
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 0.0, 0.01,
        "exactly one slot's gamble cost was debited")

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

func test_auto_gamble_picks_largest_affordable_preset():
    # C4b regression guard: spec §8.3 — auto-gamble picks max affordable preset.
    GameState.currency.add("fame", BigNumber.from_float(15.0))
    GameState.skill_tree.unlock("always_gamble_toggle")
    GameState.canvas_config.set_auto_gamble()
    # 150 inspi: levels 10, 100 are affordable; 1000 is not. Should pick 100.
    GameState.currency.add("inspiration", BigNumber.from_float(150.0))
    GameState.slots.paint_time_override = 100.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    var c0: Canvas = GameState.slots.get_canvas(0)
    assert_eq(int(c0.get_meta("gamble_amount", -1)), 100,
        "auto-gamble picked max affordable preset (100)")
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 50.0, 0.01,
        "150 - 100 = 50 inspi remaining")

func test_auto_gamble_no_debit_when_below_smallest_preset():
    GameState.currency.add("fame", BigNumber.from_float(15.0))
    GameState.skill_tree.unlock("always_gamble_toggle")
    GameState.canvas_config.set_auto_gamble()
    GameState.currency.add("inspiration", BigNumber.from_float(5.0))  # below 10
    GameState.slots.paint_time_override = 100.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    var c0: Canvas = GameState.slots.get_canvas(0)
    assert_eq(int(c0.get_meta("gamble_amount", -1)), 0)
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 5.0, 0.01,
        "no debit; player keeps 5 inspi")

func test_gamble_safety_net_refunds_half_on_failure():
    # C4a regression guard: spec §8.3 — 50% inspi refund on gamble failure when unlocked.
    GameState.currency.add("fame", BigNumber.from_float(25.0))
    GameState.skill_tree.unlock("gamble_safety_net")
    GameState.canvas_config.set_gamble(100)
    GameState.currency.add("inspiration", BigNumber.from_float(100.0))
    GameState.slots.gamble_success_chance = 0.0  # deterministic failure
    GameState.slots.paint_time_override = 1.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    # set_slot_count fires _start_slot → canvas_starting → 100 inspi spent (now 0).
    # Bypass GameState.tick to avoid aggregator overrides on gamble_success_chance.
    GameState.slots.tick(1.5)
    # Canvas finishes, gamble fails, safety net refunds 50 inspi (now 50).
    # Auto-restart fires canvas_starting, 50 < 100 → silent skip, no further debit.
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 50.0, 0.5,
        "100 spent, 50 refunded on failure, no further spend on auto-restart")

func test_gamble_no_refund_without_safety_net_node():
    # Same setup as above but WITHOUT unlocking gamble_safety_net.
    GameState.canvas_config.set_gamble(100)
    GameState.currency.add("inspiration", BigNumber.from_float(100.0))
    GameState.slots.gamble_success_chance = 0.0
    GameState.slots.paint_time_override = 1.0
    GameState.slots.set_slot_count(0)
    GameState.slots.set_slot_count(1)
    GameState.slots.tick(1.5)
    # 100 spent. No refund (node not unlocked). Inspi at 0.
    assert_almost_eq(GameState.currency.get_amount("inspiration").value, 0.0, 0.5)

func test_canvas_completed_grants_pm_per_spec_formula():
    # C3 regression guard: spec §6.4 formula = floor(quality/10) * burst * pm_gain_mult.
    # Sub-threshold quality yields no PM.
    GameState._on_canvas_completed({"tier": 1, "quality": 5.0, "subject_id": "nature"})
    assert_almost_eq(GameState.currency.get_amount("paint_mastery").value, 0.0, 0.01,
        "quality 5 → pm_base 0 → no PM gain")

    # Linear range (quality < 30): no burst.
    GameState.currency.reset(["paint_mastery"])
    GameState._on_canvas_completed({"tier": 1, "quality": 15.0, "subject_id": "nature"})
    assert_almost_eq(GameState.currency.get_amount("paint_mastery").value, 1.0, 0.01,
        "quality 15 → pm_base 1, burst=1 → 1 PM")

    # Burst threshold (quality > 30): 2x.
    GameState.currency.reset(["paint_mastery"])
    GameState._on_canvas_completed({"tier": 1, "quality": 35.0, "subject_id": "nature"})
    assert_almost_eq(GameState.currency.get_amount("paint_mastery").value, 6.0, 0.01,
        "quality 35 → pm_base 3, burst=2 → 6 PM")

func test_auto_mastery_passive_grants_to_other_unlocked_subjects():
    # C4c regression guard: spec §9 — passive grants rate * mastery_gain to
    # every unlocked subject other than the active one.
    GameState.currency.add("fame", BigNumber.from_float(120.0))  # 15 + 30 + 75
    GameState.skill_tree.unlock("subject_hint_1")
    GameState.skill_tree.unlock("subject_hint_2")
    GameState.skill_tree.unlock("auto_mastery_passive")
    # Quality 80 → mastery_gain = 1 + 4 = 5 → auto_gain = floor(5 * 0.25) = 1.
    GameState._on_canvas_completed({"tier": 1, "quality": 80.0, "subject_id": "nature"})
    assert_eq(GameState.subject_mastery.xp_of("nature"), 5,
        "active subject gets full mastery_gain")
    for sid in ["vie", "geometrie", "emotion", "mythe"]:
        assert_eq(GameState.subject_mastery.xp_of(sid), 1,
            "other unlocked starter %s gets auto_gain" % sid)
    # Locked subject (animaliere needs nature+vie at tier 5) gets nothing.
    assert_eq(GameState.subject_mastery.xp_of("animaliere"), 0,
        "locked subject does not receive auto-mastery")

func test_no_auto_mastery_without_passive_node():
    # Without the node unlocked, only active subject gains.
    GameState._on_canvas_completed({"tier": 1, "quality": 80.0, "subject_id": "nature"})
    assert_eq(GameState.subject_mastery.xp_of("nature"), 5)
    for sid in ["vie", "geometrie", "emotion", "mythe"]:
        assert_eq(GameState.subject_mastery.xp_of(sid), 0)

func test_subject_mastery_persists_across_ascend():
    # Mastery is a long-grind axis (10k canvases per fully-mastered subject).
    # Design call (2026-04-26): persist across ascends.
    GameState.subject_mastery.gain("nature", 250)  # tier 1 + 50 leftover xp
    assert_eq(GameState.subject_mastery.tier_of("nature"), 1)
    assert_eq(GameState.subject_mastery.xp_of("nature"), 50)

    GameState.currency.add("inspiration", Balance.palier_ascend(GameState.ascend.ascend_count))
    assert_true(GameState.ascend.perform())

    assert_eq(GameState.subject_mastery.tier_of("nature"), 1)
    assert_eq(GameState.subject_mastery.xp_of("nature"), 50)

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
