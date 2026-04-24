class_name PaintMastery
extends Node

var currency: Currency

func on_canvas_sold(tier: int, gold_earned: BigNumber) -> void:
    if currency == null:
        return
    var gain = Balance.paint_mastery_gain(tier, gold_earned)
    currency.add("paint_mastery", gain)

func current_multiplier() -> float:
    if currency == null:
        return 1.0
    return Balance.paint_mastery_multiplier(currency.get_amount("paint_mastery"))
