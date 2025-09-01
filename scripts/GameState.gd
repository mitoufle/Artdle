extends Node
signal state_changed
signal inspiration_changed(type:String, new_inspiration_value:float)
signal ascendancy_level_changed(new_ascendancy_level_value:float)
signal ascendancy_point_changed(new_ascendancy_point_value:float)

#Global Currency
var ascendancy_point: float
var inspiration: float
var ascend_level: float
var paint_mastery: float
var gold: float
var Experience: float
var level: int

#Cost initiate
var ascendancy_cost: float = 1000
var level_cost: float = 1000
var mastery_cost: float = 1000

#Multipliers and shinanigans
var prestige_inspiration_multiplier: float
var painting_mastery_multiplier: float

func get_inspiration() -> float:
	return inspiration

func set_inspiration(amount:float):
	inspiration += amount 
	inspiration_changed.emit("inspiration",inspiration)

func reset_prestige():
	if inspiration >= ascendancy_cost:
		var remainder = reduce_by_max_multiple(ascendancy_cost,inspiration)
		
		
	
func reduce_by_max_multiple(cost: int, currency: int) -> int:
	if currency <= 0:
		push_error("y must be a positive integer")
		return cost
	return cost % currency
