extends GutTest

var currency: Currency
var pm: PaintMastery

func before_each():
    currency = Currency.new()
    pm = PaintMastery.new()
    pm.currency = currency

func after_each():
    if currency != null:
        currency.free()
    if pm != null:
        pm.free()

func test_on_canvas_sold_adds_paint_mastery():
    pm.on_canvas_sold(1, BigNumber.from_float(10.0))
    var stored = currency.get_amount("paint_mastery")
    assert_gt(stored.value, 0.0)

func test_higher_tier_yields_more_pm():
    pm.on_canvas_sold(1, BigNumber.from_float(100.0))
    var low = currency.get_amount("paint_mastery").value
    currency.reset(["paint_mastery"])
    pm.on_canvas_sold(5, BigNumber.from_float(100.0))
    var high = currency.get_amount("paint_mastery").value
    assert_gt(high, low)

func test_multiplier_scales_with_pm():
    var m0 = pm.current_multiplier()
    pm.on_canvas_sold(5, BigNumber.from_float(1_000_000.0))
    var m1 = pm.current_multiplier()
    assert_gt(m1, m0)
    assert_almost_eq(m0, 1.0, 0.001)

func test_multiplier_log_curve_bounded():
    currency.add("paint_mastery", BigNumber.from_float(1.0e10))
    var m = pm.current_multiplier()
    assert_lt(m, 10.0)

func test_persists_through_reset():
    pm.on_canvas_sold(3, BigNumber.from_float(1000.0))
    var before = currency.get_amount("paint_mastery").value
    currency.reset(["inspiration", "gold"])
    assert_eq(currency.get_amount("paint_mastery").value, before)
