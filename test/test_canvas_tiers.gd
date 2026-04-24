extends GutTest

func test_tier_1_exists():
    var t = CanvasTiers.get_tier(1)
    assert_ne(t, null)
    assert_eq(t["tier"], 1)

func test_tier_gold_value_increases():
    var t1 = CanvasTiers.get_tier(1)
    var t2 = CanvasTiers.get_tier(2)
    assert_gt(t2["gold_value"], t1["gold_value"])

func test_tier_paint_time_defined():
    var t = CanvasTiers.get_tier(1)
    assert_gt(t["paint_seconds"], 0.0)

func test_upgrade_cost_increases():
    var c1 = CanvasTiers.upgrade_cost(1).value
    var c2 = CanvasTiers.upgrade_cost(2).value
    assert_gt(c2, c1)

func test_max_tier_defined():
    assert_gte(CanvasTiers.MAX_TIER, 3)
