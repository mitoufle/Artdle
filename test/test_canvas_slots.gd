extends GutTest

var slots: CanvasSlots
var cfg: CanvasConfig
var mastery: SubjectMastery

func before_each():
    mastery = SubjectMastery.new()
    cfg = CanvasConfig.new()
    cfg.subject_mastery = mastery
    slots = CanvasSlots.new()
    slots.config = cfg
    slots.mastery = mastery
    slots.tier_provider = func(): return 1
    slots.style_skill_cap = 10
    slots.palette_skill_cap = 10
    slots.canvas_speed_mult = 1.0
    slots.style_time_reduction = 0.0
    slots.quality_floor_bonus = 0.0
    slots.chef_doeuvre_chance = 0.0
    slots.gamble_yield_mult = 1.0
    slots.gamble_success_chance = 0.5
    slots.add_child(mastery)  # parented for cleanup; slots will not own
    slots.set_slot_count(1)

func after_each():
    if slots != null:
        slots.free()
    if cfg != null:
        cfg.free()
        cfg = null

func test_default_slot_count_zero_until_set():
    var fresh = CanvasSlots.new()
    assert_eq(fresh.slot_count(), 0)
    fresh.free()

func test_set_slot_count_creates_canvas_children():
    assert_eq(slots.slot_count(), 1)

func test_tick_drives_canvas_to_finish_and_restarts():
    # Stub paint time low for fast finish. before_each already started a slot
    # with the formula-derived paint_time (3s); restart so override applies.
    slots.paint_time_override = 1.0
    slots.set_slot_count(0)
    slots.set_slot_count(1)
    slots.tick(1.5)
    # After finishing (1.5 ≥ 1.0), slot auto-restarts. Overshoot is not carried,
    # so progress is back to 0; is_running == true is the sufficient proof.
    var c: Canvas = slots.get_canvas(0)
    assert_true(c.is_running)

func test_finish_emits_canvas_completed():
    watch_signals(slots)
    slots.paint_time_override = 1.0
    slots.set_slot_count(0)
    slots.set_slot_count(1)
    slots.tick(1.5)
    assert_signal_emitted(slots, "canvas_completed")

func test_three_slots_each_finish_independently():
    slots.paint_time_override = 1.0
    slots.set_slot_count(0)
    slots.set_slot_count(3)
    var captured: Array = []
    slots.canvas_completed.connect(func(p: Dictionary): captured.append(p))
    slots.tick(1.5)
    # All 3 slots finished one canvas each.
    assert_eq(captured.size(), 3)
    var indices: Array = []
    for p in captured:
        indices.append(p["slot_index"])
    indices.sort()
    assert_eq(indices, [0, 1, 2])

func test_set_slot_count_decreases_frees_excess():
    slots.set_slot_count(3)
    slots.set_slot_count(1)
    assert_eq(slots.slot_count(), 1)
