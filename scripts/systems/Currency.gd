class_name Currency
extends Node

signal changed(kind: String, new_value: float)

const KINDS: Array[String] = ["inspiration", "gold", "fame", "paint_mastery"]

var _pools: Dictionary = {}

func _init() -> void:
    for k in KINDS:
        _pools[k] = BigNumber.zero()

func get_amount(kind: String) -> BigNumber:
    if not _pools.has(kind):
        return BigNumber.zero()
    return _pools[kind]

func add(kind: String, amount: BigNumber) -> void:
    if not _pools.has(kind):
        return
    _pools[kind] = _pools[kind].add(amount)
    changed.emit(kind, _pools[kind].value)

func spend(kind: String, amount: BigNumber) -> bool:
    if not _pools.has(kind):
        return false
    if not _pools[kind].gte(amount):
        return false
    _pools[kind] = _pools[kind].subtract(amount)
    changed.emit(kind, _pools[kind].value)
    return true

func reset(kinds: Array) -> void:
    for k in kinds:
        if _pools.has(k):
            _pools[k] = BigNumber.zero()
            changed.emit(k, 0.0)

func serialize() -> Dictionary:
    var out: Dictionary = {}
    for k in KINDS:
        out[k] = _pools[k].serialize()
    return out

func deserialize(data: Dictionary) -> void:
    for k in KINDS:
        if data.has(k):
            _pools[k] = BigNumber.deserialize(data[k])
        else:
            _pools[k] = BigNumber.zero()
