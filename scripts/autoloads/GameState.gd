extends Node

# Signal hub. Systems emit here; UI and other systems listen here.
# All subsystems held as children so they participate in the scene tree.
# Preload (not class_name typing) to avoid Godot 4.6 autoload-ordering parse failures.

const CurrencyClass       = preload("res://scripts/systems/Currency.gd")
const SaveClass           = preload("res://scripts/systems/Save.gd")
const CanvasClass         = preload("res://scripts/systems/Canvas.gd")
const InspirationTreeClass = preload("res://scripts/systems/InspirationTree.gd")
const PaintMasteryClass   = preload("res://scripts/systems/PaintMastery.gd")
const WorkshopClass       = preload("res://scripts/systems/Workshop.gd")
const InventoryClass      = preload("res://scripts/systems/Inventory.gd")
const CraftClass          = preload("res://scripts/systems/Craft.gd")
const PainterOfficeClass  = preload("res://scripts/systems/PainterOffice.gd")
const SkillTreeClass      = preload("res://scripts/systems/SkillTree.gd")
const AscendClass         = preload("res://scripts/systems/Ascend.gd")
const SubjectMasteryClass = preload("res://scripts/systems/SubjectMastery.gd")
const CanvasConfigClass   = preload("res://scripts/systems/CanvasConfig.gd")

# -- Signals --
signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)
signal hover_info_pushed(title: String, body: String, footer: String)
signal hover_info_cleared()

# -- Systems --
var currency: CurrencyClass
var save_system: SaveClass
var canvas: CanvasClass
var tree: InspirationTreeClass
var paint_mastery: PaintMasteryClass
var workshop: WorkshopClass
var inventory: InventoryClass
var craft: CraftClass
var painter_office: PainterOfficeClass
var skill_tree: SkillTreeClass
var ascend: AscendClass
var subject_mastery: SubjectMasteryClass
var canvas_config: CanvasConfigClass

# Sub-mechanics the tree has unlocked as "possible" this run (reset on ascend).
var _possible_mechanics: Dictionary = {}
# Sub-mechanics the player has paid inspi to "activate" this run (reset on ascend).
var _active_mechanics: Dictionary = {}

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

	subject_mastery = SubjectMasteryClass.new()
	subject_mastery.name = "SubjectMastery"
	add_child(subject_mastery)

	canvas_config = CanvasConfigClass.new()
	canvas_config.name = "CanvasConfig"
	canvas_config.subject_mastery = subject_mastery
	add_child(canvas_config)

	paint_mastery = PaintMasteryClass.new()
	paint_mastery.name = "PaintMastery"
	paint_mastery.currency = currency
	add_child(paint_mastery)

	tree = InspirationTreeClass.new()
	tree.name = "InspirationTree"
	tree.currency = currency
	add_child(tree)

	workshop = WorkshopClass.new()
	workshop.name = "Workshop"
	workshop.currency = currency
	add_child(workshop)

	inventory = InventoryClass.new()
	inventory.name = "Inventory"
	add_child(inventory)

	craft = CraftClass.new()
	craft.name = "Craft"
	craft.currency = currency
	craft.inventory = inventory
	add_child(craft)

	painter_office = PainterOfficeClass.new()
	painter_office.name = "PainterOffice"
	painter_office.currency = currency
	add_child(painter_office)

	skill_tree = SkillTreeClass.new()
	skill_tree.name = "SkillTree"
	skill_tree.currency = currency
	add_child(skill_tree)

	ascend = AscendClass.new()
	ascend.name = "Ascend"
	ascend.currency = currency
	ascend.canvas = canvas
	ascend.tree = tree
	ascend.workshop = workshop
	ascend.inventory = inventory
	ascend.painter_office = painter_office
	add_child(ascend)

	# -- Signals --
	canvas.sold.connect(_on_canvas_sold)
	tree.stage_entered.connect(_on_stage_entered)
	tree.possibility_unlocked.connect(_on_possibility_unlocked)
	ascend.ascended.connect(_on_ascended)
	currency.changed.connect(_on_currency_changed)

# Called explicitly by the main scene (Phase 4). Keeps tests deterministic.
func tick(delta: float) -> void:
	tree.tick(delta)
	canvas.tick(delta * canvas_speed_multiplier())

# -- Modifier aggregation --
# Each sub-mechanic contributes a multiplicative factor. Product is applied at sale/tick.

func canvas_gold_multiplier() -> float:
	return workshop.canvas_gold_mult() * inventory.canvas_gold_mult() * skill_tree.canvas_gold_mult()

func canvas_speed_multiplier() -> float:
	return workshop.canvas_speed_mult() * painter_office.canvas_speed_mult() * skill_tree.canvas_speed_mult()

# -- Signal handlers --

func _on_canvas_sold(tier: int, base_gold: float) -> void:
	var final_gold: float = base_gold * canvas_gold_multiplier()
	currency.add("gold", BigNumber.from_float(final_gold))
	paint_mastery.on_canvas_sold(tier, BigNumber.from_float(final_gold))
	canvas_sold.emit(tier, final_gold)

func _on_stage_entered(stage_index: int) -> void:
	stage_entered.emit(stage_index)

func _on_possibility_unlocked(mechanic_id: String) -> void:
	_possible_mechanics[mechanic_id] = true
	possibility_unlocked.emit(mechanic_id)

func _on_currency_changed(kind: String, _new_value: float) -> void:
	if kind == "paint_mastery":
		tree.external_multiplier = paint_mastery.current_multiplier()

func _on_ascended(fame_gained: float, count: int) -> void:
	_active_mechanics.clear()
	_possible_mechanics.clear()
	ascended.emit(fame_gained, count)

# -- Sub-mechanic gating --

func is_possible(mechanic_id: String) -> bool:
	return _possible_mechanics.has(mechanic_id)

func is_active(mechanic_id: String) -> bool:
	return _active_mechanics.has(mechanic_id)

func try_activate_mechanic(mechanic_id: String) -> bool:
	if not is_possible(mechanic_id):
		return false
	if is_active(mechanic_id):
		return false
	var cost = TreeStages.unlock_cost(mechanic_id)
	if not currency.spend("inspiration", cost):
		return false
	_active_mechanics[mechanic_id] = true
	sub_mechanic_activated.emit(mechanic_id)
	return true

# -- Save / Load --

func save_game() -> bool:
	var payload: Dictionary = {
		"currency":           currency.serialize(),
		"canvas":             canvas.serialize(),
		"inspi_tree":         tree.serialize(),
		"workshop":           workshop.serialize(),
		"inventory":          inventory.serialize(),
		"painter_office":     painter_office.serialize(),
		"skill_tree":         skill_tree.serialize(),
		"ascend":             ascend.serialize(),
		"subject_mastery":    subject_mastery.serialize(),
		"canvas_config":      canvas_config.serialize(),
		"active_mechanics":   _active_mechanics.keys(),
		"possible_mechanics": _possible_mechanics.keys(),
	}
	return save_system.write(payload)

func load_game() -> bool:
	var data = save_system.read()
	if data == null:
		return false
	if data.has("currency"):       currency.deserialize(data["currency"])
	if data.has("canvas"):         canvas.deserialize(data["canvas"])
	if data.has("inspi_tree"):     tree.deserialize(data["inspi_tree"])
	if data.has("workshop"):       workshop.deserialize(data["workshop"])
	if data.has("inventory"):      inventory.deserialize(data["inventory"])
	if data.has("painter_office"): painter_office.deserialize(data["painter_office"])
	if data.has("skill_tree"):     skill_tree.deserialize(data["skill_tree"])
	if data.has("ascend"):         ascend.deserialize(data["ascend"])
	if data.has("subject_mastery"): subject_mastery.deserialize(data["subject_mastery"])
	if data.has("canvas_config"):   canvas_config.deserialize(data["canvas_config"])
	_active_mechanics.clear()
	for id in data.get("active_mechanics", []):
		_active_mechanics[id] = true
	_possible_mechanics.clear()
	for id in data.get("possible_mechanics", []):
		_possible_mechanics[id] = true
	tree.external_multiplier = paint_mastery.current_multiplier()
	return true

# -- Hover info bus --

func push_hover_info(title: String, body: String, footer: String) -> void:
	hover_info_pushed.emit(title, body, footer)

func clear_hover_info() -> void:
	hover_info_cleared.emit()
