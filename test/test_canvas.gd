extends GutTest

var canvas: Canvas

func before_each():
    canvas = Canvas.new()

func after_each():
    if canvas != null:
        canvas.free()

func test_initial_tier_1():
    assert_eq(canvas.tier, 1)

func test_initial_progress_zero():
    assert_eq(canvas.progress_seconds, 0.0)

func test_tick_accumulates_progress():
    canvas.tick(1.0)
    assert_eq(canvas.progress_seconds, 1.0)

func test_ready_to_sell_when_progress_complete():
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time + 0.5)
    assert_true(canvas.is_ready_to_sell())

func test_not_ready_before_paint_time():
    canvas.tick(0.5)
    assert_false(canvas.is_ready_to_sell())

func test_sell_emits_canvas_sold():
    watch_signals(canvas)
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time)
    canvas.sell()
    assert_signal_emitted(canvas, "sold")

func test_sell_resets_progress():
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time)
    canvas.sell()
    assert_eq(canvas.progress_seconds, 0.0)
    assert_false(canvas.is_ready_to_sell())

func test_sell_when_not_ready_does_nothing():
    watch_signals(canvas)
    canvas.sell()
    assert_signal_not_emitted(canvas, "sold")

func test_upgrade_tier_increases_tier():
    canvas.tier = 1
    canvas.upgrade_tier()
    assert_eq(canvas.tier, 2)

func test_upgrade_tier_caps_at_max():
    canvas.tier = CanvasTiers.MAX_TIER
    canvas.upgrade_tier()
    assert_eq(canvas.tier, CanvasTiers.MAX_TIER)

func test_reset_sets_tier_1_and_progress_zero():
    canvas.tier = 5
    canvas.tick(1.0)
    canvas.reset()
    assert_eq(canvas.tier, 1)
    assert_eq(canvas.progress_seconds, 0.0)

func test_serialize_roundtrip():
    canvas.tier = 4
    canvas.tick(2.5)
    var data = canvas.serialize()
    var fresh = Canvas.new()
    fresh.deserialize(data)
    assert_eq(fresh.tier, 4)
    assert_eq(fresh.progress_seconds, 2.5)
    fresh.free()
