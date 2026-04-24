extends Node

# Signal hub. Systems emit here; UI and other systems listen here.
# All subsystems held as children so they participate in the scene tree.
# Preload (not class_name typing) to avoid Godot 4.6 autoload-ordering parse failures.

const CurrencyClass = preload("res://scripts/systems/Currency.gd")
const SaveClass = preload("res://scripts/systems/Save.gd")
const CanvasClass = preload("res://scripts/systems/Canvas.gd")
const InspirationTreeClass = preload("res://scripts/systems/InspirationTree.gd")
const PaintMasteryClass = preload("res://scripts/systems/PaintMastery.gd")

signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)

var currency: CurrencyClass
var save_system: SaveClass
var canvas: CanvasClass
var tree: InspirationTreeClass
var paint_mastery: PaintMasteryClass

func _ready() -> void:
	currency = CurrencyClass.new()
	currency.name = "Currency"
	add_child(currency)

	save_system = SaveClass.new()
	save_system.name = "Save"
	add_child(save_system)

	canvas = CanvasClass.new()
	canvas.name = "Canvas"
	add_child(canvas)
	canvas.sold.connect(_on_canvas_sold)

	paint_mastery = PaintMasteryClass.new()
	paint_mastery.name = "PaintMastery"
	paint_mastery.currency = currency
	add_child(paint_mastery)

	tree = InspirationTreeClass.new()
	tree.name = "InspirationTree"
	tree.currency = currency
	add_child(tree)
	tree.stage_entered.connect(_on_stage_entered)
	tree.possibility_unlocked.connect(_on_possibility_unlocked)

	currency.changed.connect(_on_currency_changed)

# Called explicitly by the main scene (Phase 4). Kept out of _process so tests stay deterministic.
func tick(delta: float) -> void:
	tree.tick(delta)
	canvas.tick(delta)

func _on_canvas_sold(tier: int, gold_amount: float) -> void:
	currency.add("gold", BigNumber.from_float(gold_amount))
	paint_mastery.on_canvas_sold(tier, BigNumber.from_float(gold_amount))
	canvas_sold.emit(tier, gold_amount)

func _on_stage_entered(stage_index: int) -> void:
	stage_entered.emit(stage_index)

func _on_possibility_unlocked(mechanic_id: String) -> void:
	possibility_unlocked.emit(mechanic_id)

func _on_currency_changed(kind: String, _new_value: float) -> void:
	if kind == "paint_mastery":
		tree.external_multiplier = paint_mastery.current_multiplier()

func save_game() -> bool:
	var payload: Dictionary = {
		"currency":   currency.serialize(),
		"canvas":     canvas.serialize(),
		"inspi_tree": tree.serialize(),
	}
	return save_system.write(payload)

func load_game() -> bool:
	var data = save_system.read()
	if data == null:
		return false
	if data.has("currency"):
		currency.deserialize(data["currency"])
	if data.has("canvas"):
		canvas.deserialize(data["canvas"])
	if data.has("inspi_tree"):
		tree.deserialize(data["inspi_tree"])
	tree.external_multiplier = paint_mastery.current_multiplier()
	return true
