extends GutTest

var currency: Currency
var workshop: Workshop

func before_each():
    currency = Currency.new()
    workshop = Workshop.new()
    workshop.currency = currency

func after_each():
    if currency != null:
        currency.free()
        currency = null
    if workshop != null:
        workshop.free()
        workshop = null

func test_initial_tier_zero():
    assert_eq(workshop.tier, 0)

func test_initial_multipliers_are_one():
    assert_almost_eq(workshop.canvas_gold_mult(), 1.0, 0.0001)
    assert_almost_eq(workshop.canvas_speed_mult(), 1.0, 0.0001)

func test_upgrade_tier_success_spends_gold():
    currency.add("gold", BigNumber.from_float(1000.0))
    var cost = Workshop.tier_upgrade_cost(0).value
    var ok = workshop.upgrade_tier()
    assert_true(ok)
    assert_eq(workshop.tier, 1)
    assert_eq(currency.get_amount("gold").value, 1000.0 - cost)

func test_upgrade_tier_insufficient_fails():
    var ok = workshop.upgrade_tier()
    assert_false(ok)
    assert_eq(workshop.tier, 0)

func test_higher_tier_gives_higher_multipliers():
    workshop.tier = 3
    assert_gt(workshop.canvas_gold_mult(), 1.0)
    assert_gt(workshop.canvas_speed_mult(), 1.0)

func test_reset_returns_tier_zero():
    workshop.tier = 5
    workshop.reset()
    assert_eq(workshop.tier, 0)

func test_serialize_roundtrip():
    workshop.tier = 4
    var data = workshop.serialize()
    var fresh = Workshop.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.tier, 4)
    fresh.free()
