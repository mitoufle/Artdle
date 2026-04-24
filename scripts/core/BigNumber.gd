class_name BigNumber
extends RefCounted

const MAX_VALUE: float = 1.0e308

var value: float = 0.0

static func zero() -> BigNumber:
    var n = BigNumber.new()
    n.value = 0.0
    return n

static func from_float(v: float) -> BigNumber:
    var n = BigNumber.new()
    n.value = clamp(v, 0.0, MAX_VALUE)
    return n

func add(other: BigNumber) -> BigNumber:
    var r = value + other.value
    if is_inf(r) or r > MAX_VALUE:
        r = MAX_VALUE
    return BigNumber.from_float(r)

func subtract(other: BigNumber) -> BigNumber:
    return BigNumber.from_float(max(0.0, value - other.value))

func multiply(other: BigNumber) -> BigNumber:
    var r = value * other.value
    if is_inf(r) or r > MAX_VALUE:
        r = MAX_VALUE
    return BigNumber.from_float(r)

func divide(other: BigNumber) -> BigNumber:
    if other.value == 0.0:
        return BigNumber.zero()
    return BigNumber.from_float(value / other.value)

func gte(other: BigNumber) -> bool:
    return value >= other.value

func gt(other: BigNumber) -> bool:
    return value > other.value

func is_at_cap() -> bool:
    return value >= MAX_VALUE

func to_string() -> String:
    return str(value)

func serialize() -> float:
    return value

static func deserialize(data) -> BigNumber:
    return BigNumber.from_float(float(data))
