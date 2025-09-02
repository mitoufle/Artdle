extends Node
signal state_changed
signal inspiration_changed(type:String, new_inspiration_value:float)
signal ascendancy_level_changed(new_ascendancy_level_value:float)
signal ascendancy_point_changed(new_ascendancy_point_value:float)
signal gold_changed(new_gold_value:float)
signal paint_mastery_changed(new_paint_mastery_value:float)

#Global Currency
var ascendancy_point: float = 0
var inspiration: float = 0
var ascend_level: float = 0
var paint_mastery: float = 0
var gold: float = 0
var Experience: float = 0
var level: int = 1

#Cost initiate
var ascendancy_cost: float = 1000
var level_cost: float = 1000
var mastery_cost: float = 1000

#Multipliers and shinanigans
var prestige_inspiration_multiplier: float = 1
var painting_mastery_multiplier: float = 1

func get_inspiration() -> float:
	return inspiration

func set_inspiration(amount:float):
	inspiration += amount 
	inspiration_changed.emit("inspiration",inspiration)

func set_gold(amount:float):
	gold += amount
	gold_changed.emit(gold)

func set_paint_mastery(amount:float):
	paint_mastery += amount
	paint_mastery_changed.emit(paint_mastery)

func set_ascendancy_point(amount:float):
	ascendancy_point += amount
	ascendancy_point_changed.emit(ascendancy_point)

func set_ascend_level(amount:float):
	ascend_level += amount
	ascendancy_level_changed.emit(ascend_level)

func reset_prestige():
	if inspiration >= ascendancy_cost:
		var remainder = reduce_by_max_multiple(ascendancy_cost,inspiration)
		
		
	
func reduce_by_max_multiple(cost: int, currency: int) -> int:
	if currency <= 0:
		push_error("y must be a positive integer")
		return cost
	return cost % currency
