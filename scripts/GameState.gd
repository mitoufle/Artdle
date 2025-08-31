extends Node
signal state_changed

var inspiration: float = 0.0
var prestige: int = 0
var enhanceInspi: int = 1 

var prestigeCost: int = 1000

var global_inspiration_multiplier: float = 1 + prestige/10

func add_inspiration(amount: float):
	inspiration += amount * global_inspiration_multiplier
	emit_signal("state_changed")
	
func update_inspiration(cost:float):
	inspiration += cost
	emit_signal("state_changed")

func reset_prestige():
	if inspiration >= prestigeCost:
		inspiration = 0
		enhanceInspi = 1
		prestige += 1
		global_inspiration_multiplier = 1 + prestige/10
	
	
