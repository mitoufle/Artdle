extends GutTest

func test_palier_ascend_first():
    var p = Balance.palier_ascend(0)
    assert_eq(p.value, 1000.0)

func test_palier_ascend_doubles():
    var p0 = Balance.palier_ascend(0).value
    var p1 = Balance.palier_ascend(1).value
    assert_eq(p1, p0 * 2.0)
    var p2 = Balance.palier_ascend(2).value
    assert_eq(p2, p0 * 4.0)

func test_fame_conversion_below_threshold_zero():
    var fame = Balance.fame_conversion(BigNumber.from_float(500.0))
    assert_eq(fame.value, 0.0)

func test_fame_conversion_at_palier_gives_one():
    var fame = Balance.fame_conversion(BigNumber.from_float(1000.0))
    assert_gte(fame.value, 1.0)

func test_fame_conversion_monotonic():
    var low = Balance.fame_conversion(BigNumber.from_float(1000.0)).value
    var high = Balance.fame_conversion(BigNumber.from_float(100000.0)).value
    assert_gt(high, low)

func test_pm_gain_scales_with_tier():
    var t1 = Balance.paint_mastery_gain(1, BigNumber.from_float(10.0)).value
    var t5 = Balance.paint_mastery_gain(5, BigNumber.from_float(10.0)).value
    assert_gt(t5, t1)

func test_pm_multiplier_log_curve():
    var low = Balance.paint_mastery_multiplier(BigNumber.from_float(10.0))
    var mid = Balance.paint_mastery_multiplier(BigNumber.from_float(10_000.0))
    var high = Balance.paint_mastery_multiplier(BigNumber.from_float(10_000_000.0))
    assert_almost_eq(low, 1.0, 0.5)
    assert_gt(mid, low)
    assert_gt(high, mid)
    assert_lt(high, 10.0)
