extends GutTest

var currency: Currency
var office: PainterOffice

func before_each():
    currency = Currency.new()
    office = PainterOffice.new()
    office.currency = currency

func after_each():
    if currency != null:
        currency.free()
        currency = null
    if office != null:
        office.free()
        office = null

func test_initial_zero_workers():
    assert_eq(office.worker_count, 0)

func test_initial_speed_mult_one():
    assert_almost_eq(office.canvas_speed_mult(), 1.0, 0.0001)

func test_hire_worker_success():
    currency.add("gold", BigNumber.from_float(1.0e6))
    var cost_first = PainterOffice.hire_cost(0).value
    var ok = office.hire_worker()
    assert_true(ok)
    assert_eq(office.worker_count, 1)
    assert_eq(currency.get_amount("gold").value, 1.0e6 - cost_first)

func test_hire_cost_increases():
    var c0 = PainterOffice.hire_cost(0).value
    var c1 = PainterOffice.hire_cost(1).value
    var c2 = PainterOffice.hire_cost(2).value
    assert_gt(c1, c0)
    assert_gt(c2, c1)

func test_more_workers_higher_speed():
    currency.add("gold", BigNumber.from_float(1.0e9))
    office.hire_worker()
    office.hire_worker()
    office.hire_worker()
    assert_gt(office.canvas_speed_mult(), 1.0)

func test_hire_insufficient_fails():
    var ok = office.hire_worker()
    assert_false(ok)
    assert_eq(office.worker_count, 0)

func test_reset_clears_workers():
    currency.add("gold", BigNumber.from_float(1.0e6))
    office.hire_worker()
    office.reset()
    assert_eq(office.worker_count, 0)

func test_serialize_roundtrip():
    currency.add("gold", BigNumber.from_float(1.0e9))
    office.hire_worker()
    office.hire_worker()
    var data = office.serialize()
    var fresh = PainterOffice.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.worker_count, 2)
    fresh.free()
