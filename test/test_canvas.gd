extends GutTest

var canvas: Canvas
var stub_quality: float = 18.0
var stub_paint_time: float = 5.0

func before_each():
    canvas = Canvas.new()

func after_each():
    if canvas != null:
        canvas.free()

func test_initial_progress_zero():
    assert_eq(canvas.progress_seconds, 0.0)

func test_tick_accumulates_progress():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(1.0)
    assert_eq(canvas.progress_seconds, 1.0)

func test_finishes_immediately_when_tick_exceeds_paint_time():
    watch_signals(canvas)
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time + 0.1)
    assert_signal_emitted(canvas, "finished")

func test_finished_payload_carries_quality():
    var captured: Array = []
    canvas.finished.connect(func(payload: Dictionary): captured.append(payload))
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time)
    assert_eq(captured.size(), 1)
    assert_eq(captured[0]["quality"], stub_quality)

func test_progress_resets_after_finish():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time + 0.5)
    # The slot manager re-starts immediately (auto-sale chain). Until then progress is 0.
    assert_eq(canvas.progress_seconds, 0.0)

func test_serialize_roundtrip():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(2.5)
    var data = canvas.serialize()
    var fresh = Canvas.new()
    fresh.deserialize(data)
    assert_eq(fresh.progress_seconds, 2.5)
    assert_eq(fresh.paint_time, stub_paint_time)
    assert_eq(fresh.quality, stub_quality)
    fresh.free()
