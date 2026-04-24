extends GutTest

var currency: Currency

func before_each():
	currency = Currency.new()

func after_each():
	if currency != null:
		currency.free()
		currency = null

func test_initial_zero():
	assert_eq(currency.get_amount("inspiration").value, 0.0)
	assert_eq(currency.get_amount("gold").value, 0.0)
	assert_eq(currency.get_amount("fame").value, 0.0)
	assert_eq(currency.get_amount("paint_mastery").value, 0.0)

func test_add():
	currency.add("gold", BigNumber.from_float(100.0))
	assert_eq(currency.get_amount("gold").value, 100.0)

func test_spend_success_returns_true():
	currency.add("gold", BigNumber.from_float(100.0))
	var ok = currency.spend("gold", BigNumber.from_float(30.0))
	assert_true(ok)
	assert_eq(currency.get_amount("gold").value, 70.0)

func test_spend_insufficient_returns_false_and_no_debit():
	currency.add("gold", BigNumber.from_float(50.0))
	var ok = currency.spend("gold", BigNumber.from_float(100.0))
	assert_false(ok)
	assert_eq(currency.get_amount("gold").value, 50.0)

func test_reset_preserves_permanents():
	currency.add("inspiration", BigNumber.from_float(500.0))
	currency.add("gold", BigNumber.from_float(200.0))
	currency.add("fame", BigNumber.from_float(10.0))
	currency.add("paint_mastery", BigNumber.from_float(42.0))
	currency.reset(["inspiration", "gold"])
	assert_eq(currency.get_amount("inspiration").value, 0.0)
	assert_eq(currency.get_amount("gold").value, 0.0)
	assert_eq(currency.get_amount("fame").value, 10.0)
	assert_eq(currency.get_amount("paint_mastery").value, 42.0)

func test_changed_signal_emitted_on_add():
	watch_signals(currency)
	currency.add("gold", BigNumber.from_float(5.0))
	assert_signal_emitted(currency, "changed")
	assert_signal_emitted_with_parameters(currency, "changed", ["gold", BigNumber.from_float(5.0).value], 0)

func test_unknown_kind_does_nothing():
	currency.add("unobtainium", BigNumber.from_float(100.0))
	assert_eq(currency.get_amount("unobtainium").value, 0.0)

func test_serialize_roundtrip():
	currency.add("gold", BigNumber.from_float(1234.0))
	currency.add("fame", BigNumber.from_float(5.0))
	var data = currency.serialize()
	var fresh = Currency.new()
	fresh.deserialize(data)
	assert_eq(fresh.get_amount("gold").value, 1234.0)
	assert_eq(fresh.get_amount("fame").value, 5.0)
	fresh.free()
