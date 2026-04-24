class_name PainterOffice
extends Node

signal worker_hired(new_count: int)

const HIRE_COST_BASE: float = 10_000.0
const HIRE_COST_GROWTH: float = 2.5
const SPEED_PER_WORKER: float = 0.20

var currency: Currency
var worker_count: int = 0

static func hire_cost(from_count: int) -> BigNumber:
    return BigNumber.from_float(HIRE_COST_BASE * pow(HIRE_COST_GROWTH, float(from_count)))

func hire_worker() -> bool:
    if currency == null:
        return false
    var cost = PainterOffice.hire_cost(worker_count)
    if not currency.spend("gold", cost):
        return false
    worker_count += 1
    worker_hired.emit(worker_count)
    return true

func canvas_speed_mult() -> float:
    return 1.0 + SPEED_PER_WORKER * float(worker_count)

func reset() -> void:
    worker_count = 0

func serialize() -> Dictionary:
    return {"worker_count": worker_count}

func deserialize(data: Dictionary) -> void:
    worker_count = int(data.get("worker_count", 0))
