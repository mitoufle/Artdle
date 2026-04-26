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
    slots.add_child(mastery)
    slots.set_slot_count(1)

func after_each():
    if slots != null:
        slots.free()

func test_drop_chance_at_quality_zero():
    # spec §11.1: 0.05 + 0.001 * quality
    assert_almost_eq(CanvasSlots.drop_chance(0.0), 0.05, 0.0001)

func test_drop_chance_at_quality_30():
    assert_almost_eq(CanvasSlots.drop_chance(30.0), 0.08, 0.0001)

func test_drop_chance_at_quality_75():
    assert_almost_eq(CanvasSlots.drop_chance(75.0), 0.125, 0.0001)

func test_drop_event_emitted_when_force_drop():
    slots.force_drop = true  # test-only deterministic switch
    slots.paint_time_override = 1.0
    # before_each already started a slot with formula-derived paint_time (3s).
    # Restart so the override actually applies to a fresh canvas.
    slots.set_slot_count(0)
    slots.set_slot_count(1)
    var captured: Array = []
    slots.drop_rolled.connect(func(p: Dictionary): captured.append(p))
    slots.tick(1.5)
    assert_eq(captured.size(), 1)
    assert_true(captured[0].has("slot_type"))
    assert_true(captured[0].has("set_id"))
    assert_true(captured[0].has("tier"))
