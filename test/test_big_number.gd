extends GutTest

func test_zero():
    var n = BigNumber.new()
    assert_eq(n.value, 0.0)
    assert_eq(str(n), "0")

func test_add_positive():
    var a = BigNumber.from_float(5.0)
    var b = BigNumber.from_float(3.0)
    var c = a.add(b)
    assert_eq(c.value, 8.0)

func test_subtract():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.from_float(3.0)
    assert_eq(a.subtract(b).value, 7.0)

func test_multiply():
    var a = BigNumber.from_float(4.0)
    var b = BigNumber.from_float(2.5)
    assert_eq(a.multiply(b).value, 10.0)

func test_divide():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.from_float(4.0)
    assert_eq(a.divide(b).value, 2.5)

func test_divide_by_zero_returns_zero():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.zero()
    assert_eq(a.divide(b).value, 0.0)

func test_overflow_caps_at_max_float():
    var huge = BigNumber.from_float(1.0e308)
    var result = huge.multiply(BigNumber.from_float(10.0))
    assert_eq(result.value, BigNumber.MAX_VALUE)
    assert_true(result.is_at_cap())

func test_overflow_does_not_return_zero():
    var huge = BigNumber.from_float(1.0e308)
    var result = huge.add(huge)
    assert_gt(result.value, 1.0e307)
    assert_eq(result.value, BigNumber.MAX_VALUE)

func test_compare_greater_equal():
    assert_true(BigNumber.from_float(5.0).gte(BigNumber.from_float(5.0)))
    assert_true(BigNumber.from_float(5.0).gte(BigNumber.from_float(3.0)))
    assert_false(BigNumber.from_float(2.0).gte(BigNumber.from_float(3.0)))

func test_serialize_roundtrip():
    var a = BigNumber.from_float(123.45)
    var data = a.serialize()
    var b = BigNumber.deserialize(data)
    assert_eq(b.value, 123.45)
