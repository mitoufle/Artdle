extends PanelContainer

@onready var gold_label = $MarginContainer/HBoxContainer/GoldLabel
@onready var inspiration_label = $MarginContainer/HBoxContainer/InspirationLabel
@onready var ascendancy_point_label = $MarginContainer/HBoxContainer/AscendancyPointLabel
@onready var paint_mastery_label = $MarginContainer/HBoxContainer/PaintMasteryLabel

func _ready():
	GameState.inspiration_changed.connect(update_inspiration)
	GameState.ascendancy_point_changed.connect(update_ascendancy_points)
	GameState.gold_changed.connect(update_gold)
	GameState.paint_mastery_changed.connect(update_paint_mastery)

	update_inspiration("inspiration", GameState.inspiration)
	update_ascendancy_points(GameState.ascendancy_point)
	update_gold(GameState.gold)
	update_paint_mastery(GameState.paint_mastery)

func update_inspiration(key:String, value: float):
	inspiration_label.text = "Inspiration: " + str(round(value * 1000) / 1000.0)

func update_ascendancy_points(value: float):
	ascendancy_point_label.text = "Ascendancy Points: " + str(value)

func update_gold(value: float):
	gold_label.text = "Gold: " + str(value)

func update_paint_mastery(value: float):
	paint_mastery_label.text = "Paint Mastery: " + str(value)

func set_view_specific_currencies(view_name: String):
	match view_name:
		"PaintingView":
			paint_mastery_label.visible = true
		_:
			paint_mastery_label.visible = false
