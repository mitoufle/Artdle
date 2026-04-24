extends GutTest

func test_small_integer():
    assert_eq(Formatter.short(BigNumber.from_float(42.0)), "42")

func test_thousand():
    assert_eq(Formatter.short(BigNumber.from_float(1500.0)), "1.50K")

func test_million():
    assert_eq(Formatter.short(BigNumber.from_float(2_500_000.0)), "2.50M")

func test_billion():
    assert_eq(Formatter.short(BigNumber.from_float(3_750_000_000.0)), "3.75B")

func test_trillion():
    assert_eq(Formatter.short(BigNumber.from_float(1.0e12)), "1.00T")

func test_very_large():
    assert_eq(Formatter.short(BigNumber.from_float(1.0e18)), "1.00Qi")

func test_zero():
    assert_eq(Formatter.short(BigNumber.zero()), "0")

func test_precision_integer_under_thousand():
    assert_eq(Formatter.short(BigNumber.from_float(999.0)), "999")
