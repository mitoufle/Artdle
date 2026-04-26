extends Node

# Signal hub. Systems emit here; UI and other systems listen here.
# All subsystems held as children so they participate in the scene tree.
# Preload (not class_name typing) to avoid Godot 4.6 autoload-ordering parse failures.

const CurrencyClass       = preload("res://scripts/systems/Currency.gd")
const SaveClass           = preload("res://scripts/systems/Save.gd")
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
const CanvasSlotsClass    = preload("res://scripts/systems/CanvasSlots.gd")

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
var slots: CanvasSlotsClass
var _canvas_tier: int = 1
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

	subject_mastery = SubjectMasteryClass.new()
	subject_mastery.name = "SubjectMastery"
	add_child(subject_mastery)

	canvas_config = CanvasConfigClass.new()
	canvas_config.name = "CanvasConfig"
	canvas_config.subject_mastery = subject_mastery
	add_child(canvas_config)

	slots = CanvasSlotsClass.new()
	slots.name = "CanvasSlots"
	slots.config = canvas_config
	slots.mastery = subject_mastery
	slots.tier_provider = func(): return _current_canvas_tier()
	# Slot count is initialized below by refresh_canvas_slot_count(), AFTER
	# canvas_starting is connected. Setting here would emit before the listener exists.
	add_child(slots)

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
	ascend.on_reset = func(): _canvas_tier = 1; canvas_config.reset()
	ascend.tree = tree
	ascend.workshop = workshop
	ascend.inventory = inventory
	ascend.painter_office = painter_office
	add_child(ascend)

	# -- Signals --
	slots.canvas_completed.connect(_on_canvas_completed)
	slots.canvas_starting.connect(_on_canvas_starting)
	tree.stage_entered.connect(_on_stage_entered)
	tree.possibility_unlocked.connect(_on_possibility_unlocked)
	ascend.ascended.connect(_on_ascended)
	currency.changed.connect(_on_currency_changed)
	skill_tree.node_unlocked.connect(func(_id): refresh_canvas_slot_count())

	refresh_canvas_slot_count()

# Called explicitly by the main scene (Phase 4). Keeps tests deterministic.
func tick(delta: float) -> void:
	tree.tick(delta)
	slots.canvas_speed_mult = canvas_speed_multiplier()
	slots.style_time_reduction = inventory.style_time_reduction() if inventory.has_method("style_time_reduction") else 0.0
	slots.quality_floor_bonus = skill_tree.quality_floor_bonus() + (inventory.quality_floor_bonus() if inventory.has_method("quality_floor_bonus") else 0.0)
	slots.chef_doeuvre_chance = (0.005 if skill_tree.chef_doeuvre_unlocked() else 0.0) * (inventory.chef_doeuvre_chance_mult() if inventory.has_method("chef_doeuvre_chance_mult") else 1.0)
	slots.style_skill_cap = skill_tree.style_cap()
	slots.palette_skill_cap = skill_tree.palette_cap()
	slots.gamble_yield_mult = inventory.gamble_yield_mult() if inventory.has_method("gamble_yield_mult") else 1.0
	slots.gamble_success_chance = clamp(0.5 * (inventory.gamble_success_chance_mult() if inventory.has_method("gamble_success_chance_mult") else 1.0), 0.0, 0.95)
	slots.tick(delta)

# -- Modifier aggregation --
# Each sub-mechanic contributes a multiplicative factor. Product is applied at sale/tick.

func canvas_gold_multiplier() -> float:
	return workshop.canvas_gold_mult() * inventory.canvas_gold_mult() * skill_tree.canvas_gold_mult()

func canvas_speed_multiplier() -> float:
	return workshop.canvas_speed_mult() * painter_office.canvas_speed_mult() * skill_tree.canvas_speed_mult()

# -- Signal handlers --

func _on_canvas_starting(idx: int) -> void:
	# Per-slot meta `gamble_amount` records the inspi actually paid for THIS canvas.
	# 0 = not gambled (off, insufficient, or auto with nothing affordable).
	# Stored per-canvas (not on `slots`) so concurrent slots don't clobber each other.
	var c: Canvas = slots.get_canvas(idx)
	var n: int = _resolve_gamble_amount()
	if n <= 0:
		c.set_meta("gamble_amount", 0)
		return
	var cost: BigNumber = BigNumber.from_float(float(n))
	if currency.get_amount("inspiration").value < float(n):
		# Silent skip — canvas runs without gamble.
		c.set_meta("gamble_amount", 0)
		return
	currency.spend("inspiration", cost)
	c.set_meta("gamble_amount", n)

func _resolve_gamble_amount() -> int:
	# Auto mode (spec §8.3): pick the largest preset the player can afford right now.
	if canvas_config.auto_gamble:
		var inspi: float = currency.get_amount("inspiration").value
		# VALID_GAMBLE_LEVELS = [0, 10, 100, 1000, 10000]. Walk descending, skip 0.
		var levels: Array = CanvasConfig.VALID_GAMBLE_LEVELS.duplicate()
		levels.sort()
		levels.reverse()
		for level in levels:
			if int(level) > 0 and inspi >= float(level):
				return int(level)
		return 0
	return canvas_config.gamble_n_inspi

func _on_canvas_completed(payload: Dictionary) -> void:
	var tier: int = int(payload["tier"])
	var quality: float = float(payload["quality"])
	var subject_id: String = String(payload["subject_id"])
	var gold_value: float = Balance.canvas_gold(quality, tier, canvas_gold_multiplier())
	currency.add("gold", BigNumber.from_float(gold_value))
	# Paint mastery (spec §6.4): floor(quality/10) * (2 if burst else 1) * pm_gain_mult.
	var pm_base: int = Balance.canvas_pm_base(quality)
	if pm_base > 0:
		var burst_factor: float = 2.0 if Balance.canvas_pm_burst_eligible(quality) else 1.0
		var pm_gain: float = float(pm_base) * burst_factor * pm_gain_multiplier()
		currency.add("paint_mastery", BigNumber.from_float(pm_gain))
	# Gamble safety net (spec §8.3): refund 50% of inspi on gamble failure when unlocked.
	if bool(payload.get("gambled", false)) and not bool(payload.get("gamble_succeeded", false)):
		if skill_tree.gamble_safety_net():
			var spent: int = int(payload.get("gamble_inspi_spent", 0))
			if spent > 0:
				currency.add("inspiration", BigNumber.from_float(float(spent) * 0.5))
	# Mastery gain to current subject.
	var mastery_gain: int = 1 + int(quality / 20.0)
	subject_mastery.gain(subject_id, mastery_gain)
	# Auto-mastery passive (spec §9): rate * mastery_gain to every other unlocked subject.
	var auto_rate: float = skill_tree.auto_mastery_rate()
	if auto_rate > 0.0:
		var auto_gain: int = int(floor(float(mastery_gain) * auto_rate))
		if auto_gain > 0:
			for sid in Subjects.all_ids():
				if sid != subject_id and subject_mastery.is_unlocked(sid):
					subject_mastery.gain(sid, auto_gain)
	canvas_sold.emit(tier, gold_value)

func pm_gain_multiplier() -> float:
	# Spec §6.4 hook. Skill tree / inventory aggregators land with the Atelier plan.
	return 1.0

func _current_canvas_tier() -> int:
	return _canvas_tier

func upgrade_canvas_tier() -> void:
	if _canvas_tier < CanvasTiers.MAX_TIER:
		_canvas_tier += 1

func buy_style_ceiling() -> bool:
	var cur: int = canvas_config.style_current_ceiling
	if cur >= skill_tree.style_cap():
		return false
	var cost: BigNumber = BigNumber.from_float(CanvasConfig.style_ceiling_cost(cur))
	if not currency.spend("gold", cost):
		return false
	canvas_config.buy_style_ceiling(skill_tree.style_cap())
	return true

func buy_palette_ceiling() -> bool:
	var cur: int = canvas_config.palette_current_ceiling
	if cur >= skill_tree.palette_cap():
		return false
	var cost: BigNumber = BigNumber.from_float(CanvasConfig.palette_ceiling_cost(cur))
	if not currency.spend("gold", cost):
		return false
	canvas_config.buy_palette_ceiling(skill_tree.palette_cap())
	return true

func refresh_canvas_slot_count() -> void:
	var n: int = 1 + skill_tree.multi_canvas_slots_grant() + painter_office.worker_count
	n = clamp(n, 1, 8)  # spec §12 soft cap
	slots.set_slot_count(n)

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
		"canvas_tier":        _canvas_tier,
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
	_canvas_tier = int(data.get("canvas_tier", 1))
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
