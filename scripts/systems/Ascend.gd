class_name Ascend
extends Node

signal ascended(fame_gained: float, ascend_count: int)

var currency: Currency
var canvas: Canvas
var tree: InspirationTree
var workshop: Workshop
var inventory: Inventory
var painter_office: PainterOffice

var ascend_count: int = 0

func can_ascend() -> bool:
    if currency == null:
        return false
    var palier = Balance.palier_ascend(ascend_count)
    return currency.get_amount("inspiration").gte(palier)

func perform() -> bool:
    if not can_ascend():
        return false
    var fame_gain: BigNumber = Balance.fame_conversion(currency.get_amount("inspiration"))
    currency.add("fame", fame_gain)
    currency.reset(["inspiration", "gold"])
    if canvas:         canvas.reset()
    if tree:           tree.reset()
    if workshop:       workshop.reset()
    if inventory:      inventory.reset()
    if painter_office: painter_office.reset()
    ascend_count += 1
    ascended.emit(fame_gain.value, ascend_count)
    return true

func serialize() -> Dictionary:
    return {"ascend_count": ascend_count}

func deserialize(data: Dictionary) -> void:
    ascend_count = int(data.get("ascend_count", 0))
