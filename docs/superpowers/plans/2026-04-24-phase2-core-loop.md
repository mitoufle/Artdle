# Artdle Rebuild — Phase 2: Core Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core gameplay loop in headless logic: `InspirationTree` produces inspiration passively, `Canvas` produces gold + paint mastery on sale, `PaintMastery` tracks the permanent multiplier. All three systems wired through `GameState` signals and saved.

**Architecture:** Systems talk via `GameState` signals only (spec §9). Canvas emits `canvas_sold`; `GameState` routes to Currency (adds gold) and PaintMastery (adds PM, updates tree multiplier). InspirationTree ticks in `_process` and emits `stage_entered` / `possibility_unlocked` on milestones.

**Tech Stack:** Godot 4.4, GDScript, GUT 9.x.

**Spec reference:** `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md` §4 (tree), §5 (canvas), §7 (paint mastery), §9 (architecture).

**Prerequisites:** Phase 1 complete. `BigNumber`, `Formatter`, `Balance`, `Currency`, `Save`, `GameState` all exist and tested.

---

## Task 1: `CanvasTiers` config

**Files:**
- Create: `scripts/config/CanvasTiers.gd`, `test/test_canvas_tiers.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_canvas_tiers.gd`:

```gdscript
extends GutTest

func test_tier_1_exists():
    var t = CanvasTiers.get_tier(1)
    assert_ne(t, null)
    assert_eq(t["tier"], 1)

func test_tier_gold_value_increases():
    var t1 = CanvasTiers.get_tier(1)
    var t2 = CanvasTiers.get_tier(2)
    assert_gt(t2["gold_value"], t1["gold_value"])

func test_tier_paint_time_defined():
    var t = CanvasTiers.get_tier(1)
    assert_gt(t["paint_seconds"], 0.0)

func test_upgrade_cost_increases():
    var c1 = CanvasTiers.upgrade_cost(1).value
    var c2 = CanvasTiers.upgrade_cost(2).value
    assert_gt(c2, c1)

func test_max_tier_defined():
    assert_gte(CanvasTiers.MAX_TIER, 3)
```

- [ ] **Step 2: Run — expect fail**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/test_canvas_tiers.gd -gexit
```

- [ ] **Step 3: Implement**

Create `scripts/config/CanvasTiers.gd`:

```gdscript
class_name CanvasTiers
extends RefCounted

const MAX_TIER: int = 10

# tier -> {gold_value, paint_seconds}
const TIERS: Dictionary = {
    1:  {"gold_value": 10.0,       "paint_seconds": 2.0},
    2:  {"gold_value": 50.0,       "paint_seconds": 3.0},
    3:  {"gold_value": 250.0,      "paint_seconds": 4.0},
    4:  {"gold_value": 1_500.0,    "paint_seconds": 5.0},
    5:  {"gold_value": 10_000.0,   "paint_seconds": 7.0},
    6:  {"gold_value": 75_000.0,   "paint_seconds": 10.0},
    7:  {"gold_value": 500_000.0,  "paint_seconds": 15.0},
    8:  {"gold_value": 5_000_000.0,"paint_seconds": 20.0},
    9:  {"gold_value": 50_000_000.0,"paint_seconds": 30.0},
    10: {"gold_value": 500_000_000.0,"paint_seconds": 45.0},
}

static func get_tier(tier: int) -> Dictionary:
    return TIERS.get(tier, {"tier": tier, "gold_value": 0.0, "paint_seconds": 1.0})

static func upgrade_cost(from_tier: int) -> BigNumber:
    # Cost to go from `from_tier` to `from_tier + 1`
    var base = 100.0
    return BigNumber.from_float(base * pow(6.0, float(from_tier)))
```

Note: `get_tier` adds `tier` key to dict returned; update TIERS to include `tier` key per entry:

Replace TIERS body with:

```gdscript
const TIERS: Dictionary = {
    1:  {"tier": 1,  "gold_value": 10.0,          "paint_seconds": 2.0},
    2:  {"tier": 2,  "gold_value": 50.0,          "paint_seconds": 3.0},
    3:  {"tier": 3,  "gold_value": 250.0,         "paint_seconds": 4.0},
    4:  {"tier": 4,  "gold_value": 1_500.0,       "paint_seconds": 5.0},
    5:  {"tier": 5,  "gold_value": 10_000.0,      "paint_seconds": 7.0},
    6:  {"tier": 6,  "gold_value": 75_000.0,      "paint_seconds": 10.0},
    7:  {"tier": 7,  "gold_value": 500_000.0,     "paint_seconds": 15.0},
    8:  {"tier": 8,  "gold_value": 5_000_000.0,   "paint_seconds": 20.0},
    9:  {"tier": 9,  "gold_value": 50_000_000.0,  "paint_seconds": 30.0},
    10: {"tier": 10, "gold_value": 500_000_000.0, "paint_seconds": 45.0},
}
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/config/CanvasTiers.gd test/test_canvas_tiers.gd
git commit -m "add CanvasTiers config (10 tiers with gold/time/upgrade cost)"
```

---

## Task 2: `TreeStages` config

**Files:**
- Create: `scripts/config/TreeStages.gd`, `test/test_tree_stages.gd`

MVP defines 5 stages for now (expanded to 20-30 later). Each has parts (generator units) and optional `unlocks` (sub-mechanics the stage makes possible).

- [ ] **Step 1: Write failing test**

Create `test/test_tree_stages.gd`:

```gdscript
extends GutTest

func test_stage_0_is_seed():
    var s = TreeStages.get_stage(0)
    assert_ne(s, null)
    assert_eq(s["name"], "Pousse")

func test_stage_count_at_least_5():
    assert_gte(TreeStages.count(), 5)

func test_stage_0_has_roots_part():
    var s = TreeStages.get_stage(0)
    assert_true(s["parts"].has("roots"))

func test_later_stage_has_more_parts():
    var s0 = TreeStages.get_stage(0)
    var s3 = TreeStages.get_stage(3)
    assert_gt(s3["parts"].size(), s0["parts"].size())

func test_part_has_required_fields():
    var s = TreeStages.get_stage(0)
    var roots = s["parts"]["roots"]
    assert_true(roots.has("base_rate"))
    assert_true(roots.has("max_level"))
    assert_true(roots.has("upgrade_base_cost"))

func test_stage_3_unlocks_workshop():
    var s = TreeStages.get_stage(2)  # 0-indexed, stage 3 = index 2
    assert_true("workshop" in s.get("unlocks", []))

func test_unlock_cost_defined():
    assert_gt(TreeStages.unlock_cost("workshop").value, 0.0)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/config/TreeStages.gd`:

```gdscript
class_name TreeStages
extends RefCounted

# Stage definition:
#   name: display name
#   parts: dict of part_id -> {base_rate, max_level, upgrade_base_cost, upgrade_growth}
#   unlocks: list of mechanic_ids unlocked upon entering this stage
#
# Cost to upgrade part to level N (from N-1) = upgrade_base_cost * upgrade_growth^(N-1)

const STAGES: Array = [
    {
        "name": "Pousse",
        "parts": {
            "roots": {"base_rate": 0.1, "max_level": 5, "upgrade_base_cost": 5.0, "upgrade_growth": 1.8},
        },
        "unlocks": [],
    },
    {
        "name": "Jeune",
        "parts": {
            "roots":  {"base_rate": 0.3, "max_level": 5, "upgrade_base_cost": 20.0, "upgrade_growth": 1.8},
            "leaves": {"base_rate": 0.2, "max_level": 5, "upgrade_base_cost": 30.0, "upgrade_growth": 1.8},
        },
        "unlocks": [],
    },
    {
        "name": "Rameaux",
        "parts": {
            "roots":    {"base_rate": 1.0, "max_level": 5, "upgrade_base_cost": 100.0,  "upgrade_growth": 1.9},
            "leaves":   {"base_rate": 0.8, "max_level": 5, "upgrade_base_cost": 150.0,  "upgrade_growth": 1.9},
            "branches": {"base_rate": 1.5, "max_level": 5, "upgrade_base_cost": 250.0,  "upgrade_growth": 1.9},
        },
        "unlocks": ["workshop"],
    },
    {
        "name": "Mature",
        "parts": {
            "roots":    {"base_rate": 3.0, "max_level": 5, "upgrade_base_cost": 1_000.0, "upgrade_growth": 2.0},
            "leaves":   {"base_rate": 2.5, "max_level": 5, "upgrade_base_cost": 1_500.0, "upgrade_growth": 2.0},
            "branches": {"base_rate": 4.0, "max_level": 5, "upgrade_base_cost": 2_500.0, "upgrade_growth": 2.0},
            "flowers":  {"base_rate": 5.0, "max_level": 5, "upgrade_base_cost": 5_000.0, "upgrade_growth": 2.0},
        },
        "unlocks": ["inventory"],
    },
    {
        "name": "Ancien",
        "parts": {
            "roots":    {"base_rate": 8.0,  "max_level": 5, "upgrade_base_cost": 20_000.0,  "upgrade_growth": 2.1},
            "leaves":   {"base_rate": 7.0,  "max_level": 5, "upgrade_base_cost": 30_000.0,  "upgrade_growth": 2.1},
            "branches": {"base_rate": 12.0, "max_level": 5, "upgrade_base_cost": 50_000.0,  "upgrade_growth": 2.1},
            "flowers":  {"base_rate": 18.0, "max_level": 5, "upgrade_base_cost": 80_000.0,  "upgrade_growth": 2.1},
            "fruits":   {"base_rate": 25.0, "max_level": 5, "upgrade_base_cost": 150_000.0, "upgrade_growth": 2.1},
        },
        "unlocks": ["painter_office"],
    },
]

const UNLOCK_COSTS: Dictionary = {
    "workshop":       500.0,
    "inventory":      2500.0,
    "painter_office": 10000.0,
}

static func count() -> int:
    return STAGES.size()

static func get_stage(index: int) -> Dictionary:
    if index < 0 or index >= STAGES.size():
        return {}
    return STAGES[index]

static func unlock_cost(mechanic_id: String) -> BigNumber:
    return BigNumber.from_float(UNLOCK_COSTS.get(mechanic_id, 0.0))

static func upgrade_cost(stage_index: int, part_id: String, current_level: int) -> BigNumber:
    var s = get_stage(stage_index)
    if s.is_empty() or not s["parts"].has(part_id):
        return BigNumber.from_float(0.0)
    var p = s["parts"][part_id]
    var cost: float = p["upgrade_base_cost"] * pow(p["upgrade_growth"], float(current_level))
    return BigNumber.from_float(cost)
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/config/TreeStages.gd test/test_tree_stages.gd
git commit -m "add TreeStages config with 5 MVP stages, parts, unlocks"
```

---

## Task 3: `PaintMastery` system

**Files:**
- Create: `scripts/systems/PaintMastery.gd`, `test/test_paint_mastery.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_paint_mastery.gd`:

```gdscript
extends GutTest

var currency: Currency
var pm: PaintMastery

func before_each():
    currency = Currency.new()
    pm = PaintMastery.new()
    pm.currency = currency

func test_on_canvas_sold_adds_paint_mastery():
    pm.on_canvas_sold(1, BigNumber.from_float(10.0))
    var stored = currency.get_amount("paint_mastery")
    assert_gt(stored.value, 0.0)

func test_higher_tier_yields_more_pm():
    pm.on_canvas_sold(1, BigNumber.from_float(100.0))
    var low = currency.get_amount("paint_mastery").value
    currency.reset(["paint_mastery"])
    pm.on_canvas_sold(5, BigNumber.from_float(100.0))
    var high = currency.get_amount("paint_mastery").value
    assert_gt(high, low)

func test_multiplier_scales_with_pm():
    var m0 = pm.current_multiplier()
    pm.on_canvas_sold(5, BigNumber.from_float(1_000_000.0))
    var m1 = pm.current_multiplier()
    assert_gt(m1, m0)
    assert_almost_eq(m0, 1.0, 0.001)

func test_multiplier_log_curve_bounded():
    currency.add("paint_mastery", BigNumber.from_float(1.0e10))
    var m = pm.current_multiplier()
    assert_lt(m, 10.0)  # log curve stays bounded

func test_persists_through_reset():
    pm.on_canvas_sold(3, BigNumber.from_float(1000.0))
    var before = currency.get_amount("paint_mastery").value
    currency.reset(["inspiration", "gold"])  # mimic ascend reset
    assert_eq(currency.get_amount("paint_mastery").value, before)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/PaintMastery.gd`:

```gdscript
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
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/PaintMastery.gd test/test_paint_mastery.gd
git commit -m "add PaintMastery accumulator + log-curve multiplier"
```

---

## Task 4: `Canvas` system

**Files:**
- Create: `scripts/systems/Canvas.gd`, `test/test_canvas.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_canvas.gd`:

```gdscript
extends GutTest

var canvas: Canvas

func before_each():
    canvas = Canvas.new()

func test_initial_tier_1():
    assert_eq(canvas.tier, 1)

func test_initial_progress_zero():
    assert_eq(canvas.progress_seconds, 0.0)

func test_tick_accumulates_progress():
    canvas.tick(1.0)
    assert_eq(canvas.progress_seconds, 1.0)

func test_ready_to_sell_when_progress_complete():
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time + 0.5)
    assert_true(canvas.is_ready_to_sell())

func test_not_ready_before_paint_time():
    canvas.tick(0.5)
    assert_false(canvas.is_ready_to_sell())

func test_sell_emits_canvas_sold():
    watch_signals(canvas)
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time)
    canvas.sell()
    assert_signal_emitted(canvas, "sold")

func test_sell_resets_progress():
    var paint_time = CanvasTiers.get_tier(canvas.tier)["paint_seconds"]
    canvas.tick(paint_time)
    canvas.sell()
    assert_eq(canvas.progress_seconds, 0.0)
    assert_false(canvas.is_ready_to_sell())

func test_sell_when_not_ready_does_nothing():
    watch_signals(canvas)
    canvas.sell()
    assert_signal_not_emitted(canvas, "sold")

func test_upgrade_tier_increases_tier():
    canvas.tier = 1
    canvas.upgrade_tier()
    assert_eq(canvas.tier, 2)

func test_upgrade_tier_caps_at_max():
    canvas.tier = CanvasTiers.MAX_TIER
    canvas.upgrade_tier()
    assert_eq(canvas.tier, CanvasTiers.MAX_TIER)

func test_reset_sets_tier_1_and_progress_zero():
    canvas.tier = 5
    canvas.tick(1.0)
    canvas.reset()
    assert_eq(canvas.tier, 1)
    assert_eq(canvas.progress_seconds, 0.0)

func test_serialize_roundtrip():
    canvas.tier = 4
    canvas.tick(2.5)
    var data = canvas.serialize()
    var fresh = Canvas.new()
    fresh.deserialize(data)
    assert_eq(fresh.tier, 4)
    assert_eq(fresh.progress_seconds, 2.5)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Canvas.gd`:

```gdscript
class_name Canvas
extends Node

signal sold(tier: int, gold_amount: float)

var tier: int = 1
var progress_seconds: float = 0.0

func tick(delta: float) -> void:
    progress_seconds += delta

func is_ready_to_sell() -> bool:
    var needed: float = CanvasTiers.get_tier(tier)["paint_seconds"]
    return progress_seconds >= needed

func sell() -> void:
    if not is_ready_to_sell():
        return
    var gold_value: float = CanvasTiers.get_tier(tier)["gold_value"]
    progress_seconds = 0.0
    sold.emit(tier, gold_value)

func upgrade_tier() -> void:
    if tier < CanvasTiers.MAX_TIER:
        tier += 1

func reset() -> void:
    tier = 1
    progress_seconds = 0.0

func serialize() -> Dictionary:
    return {"tier": tier, "progress_seconds": progress_seconds}

func deserialize(data: Dictionary) -> void:
    tier = int(data.get("tier", 1))
    progress_seconds = float(data.get("progress_seconds", 0.0))
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Canvas.gd test/test_canvas.gd
git commit -m "add Canvas system: state machine, tick, sell, upgrade tier"
```

---

## Task 5: `InspirationTree` system

**Files:**
- Create: `scripts/systems/InspirationTree.gd`, `test/test_inspiration_tree.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_inspiration_tree.gd`:

```gdscript
extends GutTest

var currency: Currency
var tree: InspirationTree

func before_each():
    currency = Currency.new()
    tree = InspirationTree.new()
    tree.currency = currency

func test_initial_stage_zero():
    assert_eq(tree.stage_index, 0)

func test_initial_parts_empty_levels():
    assert_eq(tree.get_part_level("roots"), 0)

func test_tick_zero_rate_at_start():
    var inspi_before = currency.get_amount("inspiration").value
    tree.tick(1.0)
    assert_eq(currency.get_amount("inspiration").value, inspi_before)  # all parts at level 0

func test_upgrade_part_success_spends_gold():
    currency.add("gold", BigNumber.from_float(100.0))
    var cost_before = TreeStages.upgrade_cost(0, "roots", 0).value
    var ok = tree.upgrade_part("roots")
    assert_true(ok)
    assert_eq(tree.get_part_level("roots"), 1)
    assert_eq(currency.get_amount("gold").value, 100.0 - cost_before)

func test_upgrade_part_insufficient_gold_fails():
    var ok = tree.upgrade_part("roots")
    assert_false(ok)
    assert_eq(tree.get_part_level("roots"), 0)

func test_upgrade_part_capped_at_max():
    currency.add("gold", BigNumber.from_float(1.0e9))
    for i in range(10):
        tree.upgrade_part("roots")
    var max_lvl = TreeStages.get_stage(0)["parts"]["roots"]["max_level"]
    assert_eq(tree.get_part_level("roots"), max_lvl)

func test_tick_produces_inspi_after_upgrade():
    currency.add("gold", BigNumber.from_float(1000.0))
    tree.upgrade_part("roots")
    tree.tick(1.0)
    var inspi = currency.get_amount("inspiration").value
    assert_gt(inspi, 0.0)

func test_stage_advances_when_all_parts_maxed():
    watch_signals(tree)
    currency.add("gold", BigNumber.from_float(1.0e6))
    var s0 = TreeStages.get_stage(0)
    var max_lvl = s0["parts"]["roots"]["max_level"]
    for i in range(max_lvl):
        tree.upgrade_part("roots")
    assert_eq(tree.stage_index, 1)
    assert_signal_emitted(tree, "stage_entered")

func test_stage_advance_emits_possibility_unlocked():
    watch_signals(tree)
    currency.add("gold", BigNumber.from_float(1.0e9))
    # Advance through stages 0, 1 (neither unlocks), reach stage 2 (unlocks workshop)
    _max_all_parts_of_current_stage(tree)  # stage 0 -> 1
    _max_all_parts_of_current_stage(tree)  # stage 1 -> 2
    _max_all_parts_of_current_stage(tree)  # stage 2 -> 3 (stage 2 unlocks workshop)
    assert_signal_emitted_with_parameters(tree, "possibility_unlocked", ["workshop"])

func test_reset_returns_to_stage_zero():
    currency.add("gold", BigNumber.from_float(1.0e6))
    tree.upgrade_part("roots")
    tree.reset()
    assert_eq(tree.stage_index, 0)
    assert_eq(tree.get_part_level("roots"), 0)

func test_serialize_roundtrip():
    currency.add("gold", BigNumber.from_float(1000.0))
    tree.upgrade_part("roots")
    var data = tree.serialize()
    var fresh = InspirationTree.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.stage_index, tree.stage_index)
    assert_eq(fresh.get_part_level("roots"), tree.get_part_level("roots"))

func _max_all_parts_of_current_stage(t: InspirationTree) -> void:
    var s = TreeStages.get_stage(t.stage_index)
    for part_id in s["parts"].keys():
        var max_lvl = s["parts"][part_id]["max_level"]
        while t.get_part_level(part_id) < max_lvl:
            if not t.upgrade_part(part_id):
                break
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/InspirationTree.gd`:

```gdscript
class_name InspirationTree
extends Node

signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal part_upgraded(part_id: String, new_level: int)

var currency: Currency
var stage_index: int = 0

# part_id -> level (applies to current stage's parts)
var _part_levels: Dictionary = {}

# External multiplier applied to inspi production (e.g., from PaintMastery)
var external_multiplier: float = 1.0

func get_part_level(part_id: String) -> int:
    return int(_part_levels.get(part_id, 0))

func upgrade_part(part_id: String) -> bool:
    if currency == null:
        return false
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty() or not stage["parts"].has(part_id):
        return false
    var current_lvl: int = get_part_level(part_id)
    var max_lvl: int = int(stage["parts"][part_id]["max_level"])
    if current_lvl >= max_lvl:
        return false
    var cost = TreeStages.upgrade_cost(stage_index, part_id, current_lvl)
    if not currency.spend("gold", cost):
        return false
    _part_levels[part_id] = current_lvl + 1
    part_upgraded.emit(part_id, current_lvl + 1)
    _check_stage_advance()
    return true

func tick(delta: float) -> void:
    if currency == null:
        return
    var rate = _compute_rate()
    if rate <= 0.0:
        return
    currency.add("inspiration", BigNumber.from_float(rate * delta))

func _compute_rate() -> float:
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty():
        return 0.0
    var rate: float = 0.0
    for part_id in stage["parts"].keys():
        var lvl: int = get_part_level(part_id)
        var base: float = float(stage["parts"][part_id]["base_rate"])
        rate += base * float(lvl)
    return rate * external_multiplier

func _check_stage_advance() -> void:
    var stage = TreeStages.get_stage(stage_index)
    if stage.is_empty():
        return
    for part_id in stage["parts"].keys():
        var max_lvl = int(stage["parts"][part_id]["max_level"])
        if get_part_level(part_id) < max_lvl:
            return
    # All parts maxed — advance
    if stage_index + 1 < TreeStages.count():
        stage_index += 1
        _part_levels = {}
        stage_entered.emit(stage_index)
        for unlock_id in TreeStages.get_stage(stage_index).get("unlocks", []):
            possibility_unlocked.emit(unlock_id)

func reset() -> void:
    stage_index = 0
    _part_levels = {}
    external_multiplier = 1.0

func serialize() -> Dictionary:
    return {
        "stage_index": stage_index,
        "part_levels": _part_levels.duplicate(),
    }

func deserialize(data: Dictionary) -> void:
    stage_index = int(data.get("stage_index", 0))
    _part_levels = data.get("part_levels", {}).duplicate()
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/InspirationTree.gd test/test_inspiration_tree.gd
git commit -m "add InspirationTree: stages, parts, upgrades, tick, unlock emit"
```

---

## Task 6: Wire everything into `GameState`

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Create: `test/test_gamestate_core_loop.gd`

- [ ] **Step 1: Update `GameState.gd`**

Replace the contents of `scripts/autoloads/GameState.gd` with:

```gdscript
extends Node

signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)

var currency: Currency
var save_system: Save
var canvas: Canvas
var tree: InspirationTree
var paint_mastery: PaintMastery

func _ready() -> void:
    currency = Currency.new()
    currency.name = "Currency"
    add_child(currency)

    save_system = Save.new()
    save_system.name = "Save"
    add_child(save_system)

    canvas = Canvas.new()
    canvas.name = "Canvas"
    add_child(canvas)
    canvas.sold.connect(_on_canvas_sold)

    paint_mastery = PaintMastery.new()
    paint_mastery.name = "PaintMastery"
    paint_mastery.currency = currency
    add_child(paint_mastery)

    tree = InspirationTree.new()
    tree.name = "InspirationTree"
    tree.currency = currency
    add_child(tree)
    tree.stage_entered.connect(_on_stage_entered)
    tree.possibility_unlocked.connect(_on_possibility_unlocked)

    # Currency change on paint_mastery updates tree multiplier
    currency.changed.connect(_on_currency_changed)

func _process(delta: float) -> void:
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
        "currency":      currency.serialize(),
        "canvas":        canvas.serialize(),
        "inspi_tree":    tree.serialize(),
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
    # Reapply multiplier after deserialize
    tree.external_multiplier = paint_mastery.current_multiplier()
    return true
```

- [ ] **Step 2: Write integration test**

Create `test/test_gamestate_core_loop.gd`:

```gdscript
extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState.canvas.reset()
    GameState.tree.reset()

func test_canvas_sell_adds_gold_and_paint_mastery():
    var paint_time = CanvasTiers.get_tier(GameState.canvas.tier)["paint_seconds"]
    GameState.canvas.tick(paint_time)
    GameState.canvas.sell()
    assert_gt(GameState.currency.get_amount("gold").value, 0.0)
    assert_gt(GameState.currency.get_amount("paint_mastery").value, 0.0)

func test_tree_upgrade_then_tick_produces_inspiration():
    GameState.currency.add("gold", BigNumber.from_float(1000.0))
    var ok = GameState.tree.upgrade_part("roots")
    assert_true(ok)
    GameState.tree.tick(1.0)
    assert_gt(GameState.currency.get_amount("inspiration").value, 0.0)

func test_paint_mastery_boosts_tree_rate():
    GameState.currency.add("gold", BigNumber.from_float(1000.0))
    GameState.tree.upgrade_part("roots")
    GameState.tree.tick(1.0)
    var inspi_unboosted = GameState.currency.get_amount("inspiration").value
    GameState.currency.reset(["inspiration"])

    GameState.currency.add("paint_mastery", BigNumber.from_float(1.0e6))
    # Force multiplier refresh
    GameState.tree.external_multiplier = GameState.paint_mastery.current_multiplier()
    GameState.tree.tick(1.0)
    var inspi_boosted = GameState.currency.get_amount("inspiration").value
    assert_gt(inspi_boosted, inspi_unboosted)

func test_save_and_load_core_loop_roundtrip():
    GameState.save_system.save_path = "user://test_core_loop.save"
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    GameState.canvas.tier = 3
    GameState.canvas.tick(1.5)
    GameState.tree.stage_index = 1
    GameState.tree._part_levels = {"roots": 2}

    assert_true(GameState.save_game())

    GameState.currency.reset(["gold"])
    GameState.canvas.reset()
    GameState.tree.reset()

    assert_true(GameState.load_game())
    assert_eq(GameState.currency.get_amount("gold").value, 500.0)
    assert_eq(GameState.canvas.tier, 3)
    assert_eq(GameState.canvas.progress_seconds, 1.5)
    assert_eq(GameState.tree.stage_index, 1)
    assert_eq(GameState.tree.get_part_level("roots"), 2)

    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
```

- [ ] **Step 3: Run all tests — expect all pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

- [ ] **Step 4: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_gamestate_core_loop.gd
git commit -m "wire Canvas + PaintMastery + InspirationTree into GameState"
```

---

## Phase 2 Complete Criteria

- [ ] All tests pass (old + 4 new test files).
- [ ] `GameState._process` ticks canvas and tree.
- [ ] Selling a canvas adds gold + paint mastery, triggers tree multiplier update.
- [ ] Upgrading a tree part spends gold atomically; maxing all parts of a stage advances the tree.
- [ ] Stage 3 emits `possibility_unlocked("workshop")`.
- [ ] Save round-trip preserves currency + canvas + tree state.

**Next:** Phase 3 (Workshop, Inventory, Craft, PainterOffice, Ascend, SkillTree).
