# Artdle Rebuild — Phase 3: Systems Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build all sub-mechanics (Workshop, Inventory, Craft, PainterOffice), the Ascend orchestrator, and the SkillTree. Close the full game loop: a player can run → upgrade → sell canvases → ascend → spend fame on skill tree nodes.

**Architecture:** Sub-mechanics all feed into canvas as multipliers (spec §5). GameState aggregates modifiers and applies them when canvas sells. Ascend is the single orchestrator for resets. All systems save/load through GameState's payload.

**Tech Stack:** Godot 4.4, GDScript, GUT 9.x.

**Spec reference:** `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md` §5 (sub-mechanics), §6 (ascend), §8 (skill tree), §10 (save).

**Prerequisites:** Phase 2 complete. `Canvas`, `InspirationTree`, `PaintMastery` exist in GameState.

---

## Task 1: Refactor `Canvas.sell()` to emit base gold and route multipliers through GameState

**Files:**
- Modify: `scripts/systems/Canvas.gd`
- Modify: `scripts/autoloads/GameState.gd`
- Modify: `test/test_canvas.gd`
- Create: `test/test_modifier_aggregation.gd`

- [ ] **Step 1: Update `Canvas.gd` to emit base gold only**

The `sold` signal keeps the same shape; the emitted `gold_amount` is the base tier value (no modifiers applied). `GameState._on_canvas_sold` now multiplies.

No code change required in `Canvas.gd` — the current `sell()` already emits the base tier's `gold_value`. Just document that modifiers live in GameState.

- [ ] **Step 2: Add modifier aggregator methods to `GameState.gd`**

Add these methods to `scripts/autoloads/GameState.gd`:

```gdscript
# -- Modifier aggregation --
# Each sub-mechanic exposes its multiplier contribution; these methods sum them.

func canvas_gold_multiplier() -> float:
    var m: float = 1.0
    if workshop:       m *= workshop.canvas_gold_mult()
    if inventory:      m *= inventory.canvas_gold_mult()
    if skill_tree:     m *= skill_tree.canvas_gold_mult()
    return m

func canvas_speed_multiplier() -> float:
    var m: float = 1.0
    if workshop:       m *= workshop.canvas_speed_mult()
    if painter_office: m *= painter_office.canvas_speed_mult()
    if skill_tree:     m *= skill_tree.canvas_speed_mult()
    return m
```

Also declare the new member vars near the top of the file:

```gdscript
var workshop: Workshop
var inventory: Inventory
var craft: Craft
var painter_office: PainterOffice
var ascend: Ascend
var skill_tree: SkillTree
```

- [ ] **Step 3: Update `_on_canvas_sold` to apply modifiers**

Replace the existing `_on_canvas_sold` in `scripts/autoloads/GameState.gd`:

```gdscript
func _on_canvas_sold(tier: int, base_gold_amount: float) -> void:
    var mult: float = canvas_gold_multiplier()
    var final_gold: float = base_gold_amount * mult
    currency.add("gold", BigNumber.from_float(final_gold))
    paint_mastery.on_canvas_sold(tier, BigNumber.from_float(final_gold))
    canvas_sold.emit(tier, final_gold)
```

- [ ] **Step 4: Update `_process` to apply speed modifier**

Replace the existing `_process` in `scripts/autoloads/GameState.gd`:

```gdscript
func _process(delta: float) -> void:
    tree.tick(delta)
    canvas.tick(delta * canvas_speed_multiplier())
```

- [ ] **Step 5: Add placeholder aggregator test**

Create `test/test_modifier_aggregation.gd`:

```gdscript
extends GutTest

# Verifies that GameState.canvas_gold_multiplier and canvas_speed_multiplier
# return 1.0 when no sub-mechanics are registered yet. Further tests added
# per sub-mechanic.

func test_default_gold_multiplier_is_one_without_subsystems():
    # In current GameState, workshop/inventory/skill_tree are null at this point
    # in Phase 3 Task 1. Once registered, they each default to 1.0.
    assert_almost_eq(GameState.canvas_gold_multiplier(), 1.0, 0.0001)

func test_default_speed_multiplier_is_one_without_subsystems():
    assert_almost_eq(GameState.canvas_speed_multiplier(), 1.0, 0.0001)
```

- [ ] **Step 6: Run all tests — expect all pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

- [ ] **Step 7: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_modifier_aggregation.gd
git commit -m "route canvas gold/speed through GameState modifier aggregators"
```

---

## Task 2: `Workshop` system

**Files:**
- Create: `scripts/systems/Workshop.gd`, `test/test_workshop.gd`

Workshop owns a **tier** that gives passive bonuses (canvas gold + canvas speed). Upgrading the tier costs gold, cost scales exponentially.

- [ ] **Step 1: Write failing test**

Create `test/test_workshop.gd`:

```gdscript
extends GutTest

var currency: Currency
var workshop: Workshop

func before_each():
    currency = Currency.new()
    workshop = Workshop.new()
    workshop.currency = currency

func test_initial_tier_zero():
    assert_eq(workshop.tier, 0)

func test_initial_multipliers_are_one():
    assert_almost_eq(workshop.canvas_gold_mult(), 1.0, 0.0001)
    assert_almost_eq(workshop.canvas_speed_mult(), 1.0, 0.0001)

func test_upgrade_tier_success_spends_gold():
    currency.add("gold", BigNumber.from_float(1000.0))
    var cost = Workshop.tier_upgrade_cost(0).value
    var ok = workshop.upgrade_tier()
    assert_true(ok)
    assert_eq(workshop.tier, 1)
    assert_eq(currency.get_amount("gold").value, 1000.0 - cost)

func test_upgrade_tier_insufficient_fails():
    var ok = workshop.upgrade_tier()
    assert_false(ok)
    assert_eq(workshop.tier, 0)

func test_higher_tier_gives_higher_multipliers():
    workshop.tier = 3
    assert_gt(workshop.canvas_gold_mult(), 1.0)
    assert_gt(workshop.canvas_speed_mult(), 1.0)

func test_reset_returns_tier_zero():
    workshop.tier = 5
    workshop.reset()
    assert_eq(workshop.tier, 0)

func test_serialize_roundtrip():
    workshop.tier = 4
    var data = workshop.serialize()
    var fresh = Workshop.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.tier, 4)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Workshop.gd`:

```gdscript
class_name Workshop
extends Node

signal tier_upgraded(new_tier: int)

const GOLD_MULT_PER_TIER: float = 0.25   # +25% canvas gold per tier
const SPEED_MULT_PER_TIER: float = 0.10  # +10% canvas speed per tier
const MAX_TIER: int = 20
const UPGRADE_COST_BASE: float = 1000.0
const UPGRADE_COST_GROWTH: float = 3.0

var currency: Currency
var tier: int = 0

static func tier_upgrade_cost(from_tier: int) -> BigNumber:
    return BigNumber.from_float(UPGRADE_COST_BASE * pow(UPGRADE_COST_GROWTH, float(from_tier)))

func upgrade_tier() -> bool:
    if currency == null:
        return false
    if tier >= MAX_TIER:
        return false
    var cost = Workshop.tier_upgrade_cost(tier)
    if not currency.spend("gold", cost):
        return false
    tier += 1
    tier_upgraded.emit(tier)
    return true

func canvas_gold_mult() -> float:
    return 1.0 + GOLD_MULT_PER_TIER * float(tier)

func canvas_speed_mult() -> float:
    return 1.0 + SPEED_MULT_PER_TIER * float(tier)

func reset() -> void:
    tier = 0

func serialize() -> Dictionary:
    return {"tier": tier}

func deserialize(data: Dictionary) -> void:
    tier = int(data.get("tier", 0))
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Workshop.gd test/test_workshop.gd
git commit -m "add Workshop system: tier upgrade, canvas gold+speed mults"
```

---

## Task 3: `Inventory` system

**Files:**
- Create: `scripts/systems/Inventory.gd`, `test/test_inventory.gd`

Inventory holds a list of owned items and tracks equipped ones per slot. Equipped items contribute multipliers to canvas gold.

Slots for MVP: `"brush"` and `"palette"`. Exactly one item per slot.

- [ ] **Step 1: Write failing test**

Create `test/test_inventory.gd`:

```gdscript
extends GutTest

var inventory: Inventory

func before_each():
    inventory = Inventory.new()

func test_initial_empty():
    assert_eq(inventory.owned_items.size(), 0)
    assert_eq(inventory.equipped["brush"], null)

func test_add_item():
    var item = {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1}
    inventory.add_item(item)
    assert_eq(inventory.owned_items.size(), 1)

func test_equip_success():
    var item = {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1}
    inventory.add_item(item)
    var ok = inventory.equip("basic_brush")
    assert_true(ok)
    assert_eq(inventory.equipped["brush"]["id"], "basic_brush")

func test_equip_unknown_fails():
    var ok = inventory.equip("nonexistent")
    assert_false(ok)

func test_equip_replaces_existing_in_slot():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.add_item({"id": "b", "slot": "brush", "gold_mult": 0.2})
    inventory.equip("a")
    inventory.equip("b")
    assert_eq(inventory.equipped["brush"]["id"], "b")

func test_unequip():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    inventory.unequip("brush")
    assert_eq(inventory.equipped["brush"], null)

func test_canvas_gold_mult_sums_equipped():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.2})
    inventory.add_item({"id": "b", "slot": "palette", "gold_mult": 0.3})
    inventory.equip("a")
    inventory.equip("b")
    assert_almost_eq(inventory.canvas_gold_mult(), 1.5, 0.0001)

func test_reset_clears_items_and_slots():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    inventory.reset()
    assert_eq(inventory.owned_items.size(), 0)
    assert_eq(inventory.equipped["brush"], null)

func test_serialize_roundtrip():
    inventory.add_item({"id": "a", "slot": "brush", "gold_mult": 0.1})
    inventory.equip("a")
    var data = inventory.serialize()
    var fresh = Inventory.new()
    fresh.deserialize(data)
    assert_eq(fresh.owned_items.size(), 1)
    assert_eq(fresh.equipped["brush"]["id"], "a")
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Inventory.gd`:

```gdscript
class_name Inventory
extends Node

signal item_added(item_id: String)
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)

const SLOTS: Array[String] = ["brush", "palette"]

var owned_items: Array = []  # list of item dicts
var equipped: Dictionary = {}

func _init() -> void:
    for s in SLOTS:
        equipped[s] = null

func add_item(item: Dictionary) -> void:
    owned_items.append(item)
    item_added.emit(item.get("id", ""))

func _find_item(item_id: String) -> Variant:
    for it in owned_items:
        if it.get("id") == item_id:
            return it
    return null

func equip(item_id: String) -> bool:
    var item = _find_item(item_id)
    if item == null:
        return false
    var slot: String = item.get("slot", "")
    if not SLOTS.has(slot):
        return false
    equipped[slot] = item
    item_equipped.emit(slot, item_id)
    return true

func unequip(slot: String) -> void:
    if equipped.get(slot) != null:
        equipped[slot] = null
        item_unequipped.emit(slot)

func canvas_gold_mult() -> float:
    var m: float = 1.0
    for s in SLOTS:
        var it = equipped.get(s)
        if it != null:
            m += float(it.get("gold_mult", 0.0))
    return m

func reset() -> void:
    owned_items = []
    for s in SLOTS:
        equipped[s] = null

func serialize() -> Dictionary:
    var eq_ids: Dictionary = {}
    for s in SLOTS:
        eq_ids[s] = null if equipped[s] == null else equipped[s].get("id", null)
    return {
        "owned": owned_items.duplicate(true),
        "equipped_ids": eq_ids,
    }

func deserialize(data: Dictionary) -> void:
    owned_items = data.get("owned", []).duplicate(true)
    var eq_ids: Dictionary = data.get("equipped_ids", {})
    for s in SLOTS:
        var id = eq_ids.get(s, null)
        equipped[s] = null if id == null else _find_item(id)
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Inventory.gd test/test_inventory.gd
git commit -m "add Inventory: owned items, slot equip, canvas_gold_mult"
```

---

## Task 4: `Craft` system + recipes config

**Files:**
- Create: `scripts/config/CraftRecipes.gd`, `scripts/systems/Craft.gd`, `test/test_craft.gd`

- [ ] **Step 1: Define recipes config**

Create `scripts/config/CraftRecipes.gd`:

```gdscript
class_name CraftRecipes
extends RefCounted

# recipe_id -> {name, gold_cost, produces_item (dict added to Inventory)}
const RECIPES: Dictionary = {
    "basic_brush": {
        "name":       "Pinceau basique",
        "gold_cost":  500.0,
        "produces":   {"id": "basic_brush", "slot": "brush", "gold_mult": 0.1},
    },
    "fine_brush": {
        "name":       "Pinceau fin",
        "gold_cost":  5000.0,
        "produces":   {"id": "fine_brush", "slot": "brush", "gold_mult": 0.25},
    },
    "basic_palette": {
        "name":       "Palette basique",
        "gold_cost":  1000.0,
        "produces":   {"id": "basic_palette", "slot": "palette", "gold_mult": 0.1},
    },
    "fine_palette": {
        "name":       "Palette fine",
        "gold_cost":  10000.0,
        "produces":   {"id": "fine_palette", "slot": "palette", "gold_mult": 0.3},
    },
}

static func get_recipe(recipe_id: String) -> Dictionary:
    return RECIPES.get(recipe_id, {})

static func all_recipes() -> Array:
    return RECIPES.keys()
```

- [ ] **Step 2: Write failing test**

Create `test/test_craft.gd`:

```gdscript
extends GutTest

var currency: Currency
var inventory: Inventory
var craft: Craft

func before_each():
    currency = Currency.new()
    inventory = Inventory.new()
    craft = Craft.new()
    craft.currency = currency
    craft.inventory = inventory

func test_craft_success_adds_item():
    currency.add("gold", BigNumber.from_float(1000.0))
    var ok = craft.craft("basic_brush")
    assert_true(ok)
    assert_eq(inventory.owned_items.size(), 1)
    assert_eq(inventory.owned_items[0]["id"], "basic_brush")

func test_craft_spends_gold():
    currency.add("gold", BigNumber.from_float(1000.0))
    var cost = CraftRecipes.get_recipe("basic_brush")["gold_cost"]
    craft.craft("basic_brush")
    assert_eq(currency.get_amount("gold").value, 1000.0 - cost)

func test_craft_insufficient_gold_fails():
    var ok = craft.craft("basic_brush")
    assert_false(ok)
    assert_eq(inventory.owned_items.size(), 0)

func test_craft_unknown_recipe_fails():
    currency.add("gold", BigNumber.from_float(1.0e6))
    var ok = craft.craft("nonexistent_recipe")
    assert_false(ok)
```

- [ ] **Step 3: Run — expect fail**

- [ ] **Step 4: Implement**

Create `scripts/systems/Craft.gd`:

```gdscript
class_name Craft
extends Node

signal item_crafted(recipe_id: String, item: Dictionary)

var currency: Currency
var inventory: Inventory

func craft(recipe_id: String) -> bool:
    if currency == null or inventory == null:
        return false
    var recipe = CraftRecipes.get_recipe(recipe_id)
    if recipe.is_empty():
        return false
    var cost = BigNumber.from_float(float(recipe["gold_cost"]))
    if not currency.spend("gold", cost):
        return false
    var item: Dictionary = recipe["produces"].duplicate(true)
    inventory.add_item(item)
    item_crafted.emit(recipe_id, item)
    return true

func reset() -> void:
    pass  # Craft has no per-run state; recipes + inventory reset handle it
```

- [ ] **Step 5: Run — expect pass**

- [ ] **Step 6: Commit**

```bash
git add scripts/config/CraftRecipes.gd scripts/systems/Craft.gd test/test_craft.gd
git commit -m "add Craft system and recipes config"
```

---

## Task 5: `PainterOffice` system

**Files:**
- Create: `scripts/systems/PainterOffice.gd`, `test/test_painter_office.gd`

Workers are hired for gold, each adds a fixed canvas speed bonus. MVP: one worker type.

- [ ] **Step 1: Write failing test**

Create `test/test_painter_office.gd`:

```gdscript
extends GutTest

var currency: Currency
var office: PainterOffice

func before_each():
    currency = Currency.new()
    office = PainterOffice.new()
    office.currency = currency

func test_initial_zero_workers():
    assert_eq(office.worker_count, 0)

func test_initial_speed_mult_one():
    assert_almost_eq(office.canvas_speed_mult(), 1.0, 0.0001)

func test_hire_worker_success():
    currency.add("gold", BigNumber.from_float(1.0e6))
    var cost_first = PainterOffice.hire_cost(0).value
    var ok = office.hire_worker()
    assert_true(ok)
    assert_eq(office.worker_count, 1)
    assert_eq(currency.get_amount("gold").value, 1.0e6 - cost_first)

func test_hire_cost_increases():
    var c0 = PainterOffice.hire_cost(0).value
    var c1 = PainterOffice.hire_cost(1).value
    var c2 = PainterOffice.hire_cost(2).value
    assert_gt(c1, c0)
    assert_gt(c2, c1)

func test_more_workers_higher_speed():
    currency.add("gold", BigNumber.from_float(1.0e9))
    office.hire_worker()
    office.hire_worker()
    office.hire_worker()
    assert_gt(office.canvas_speed_mult(), 1.0)

func test_hire_insufficient_fails():
    var ok = office.hire_worker()
    assert_false(ok)
    assert_eq(office.worker_count, 0)

func test_reset_clears_workers():
    currency.add("gold", BigNumber.from_float(1.0e6))
    office.hire_worker()
    office.reset()
    assert_eq(office.worker_count, 0)

func test_serialize_roundtrip():
    currency.add("gold", BigNumber.from_float(1.0e9))
    office.hire_worker()
    office.hire_worker()
    var data = office.serialize()
    var fresh = PainterOffice.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.worker_count, 2)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/PainterOffice.gd`:

```gdscript
class_name PainterOffice
extends Node

signal worker_hired(new_count: int)

const HIRE_COST_BASE: float = 10_000.0
const HIRE_COST_GROWTH: float = 2.5
const SPEED_PER_WORKER: float = 0.20  # +20% canvas speed per worker

var currency: Currency
var worker_count: int = 0

static func hire_cost(from_count: int) -> BigNumber:
    return BigNumber.from_float(HIRE_COST_BASE * pow(HIRE_COST_GROWTH, float(from_count)))

func hire_worker() -> bool:
    if currency == null:
        return false
    var cost = PainterOffice.hire_cost(worker_count)
    if not currency.spend("gold", cost):
        return false
    worker_count += 1
    worker_hired.emit(worker_count)
    return true

func canvas_speed_mult() -> float:
    return 1.0 + SPEED_PER_WORKER * float(worker_count)

func reset() -> void:
    worker_count = 0

func serialize() -> Dictionary:
    return {"worker_count": worker_count}

func deserialize(data: Dictionary) -> void:
    worker_count = int(data.get("worker_count", 0))
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/PainterOffice.gd test/test_painter_office.gd
git commit -m "add PainterOffice: hire workers, canvas speed bonus"
```

---

## Task 6: `SkillTree` system + nodes config

**Files:**
- Create: `scripts/config/SkillTreeNodes.gd`, `scripts/systems/SkillTree.gd`, `test/test_skill_tree.gd`

- [ ] **Step 1: Define nodes config**

Create `scripts/config/SkillTreeNodes.gd`:

```gdscript
class_name SkillTreeNodes
extends RefCounted

# node_id -> {name, cost (fame), effects (dict of modifier_key -> value)}
# Effect keys map to SkillTree query methods (canvas_gold_mult, canvas_speed_mult, etc.)

const NODES: Dictionary = {
    "gilded_frame": {
        "name":    "Cadre doré",
        "cost":    1.0,
        "effects": {"canvas_gold_mult_add": 0.10},
    },
    "quick_strokes": {
        "name":    "Coups rapides",
        "cost":    2.0,
        "effects": {"canvas_speed_mult_add": 0.15},
    },
    "master_palette": {
        "name":    "Palette de maître",
        "cost":    5.0,
        "effects": {"canvas_gold_mult_add": 0.25},
    },
    "tireless_hand": {
        "name":    "Main infatigable",
        "cost":    10.0,
        "effects": {"canvas_speed_mult_add": 0.30},
    },
    "golden_touch": {
        "name":    "Touche d'or",
        "cost":    25.0,
        "effects": {"canvas_gold_mult_add": 0.75},
    },
}

static func get_node(node_id: String) -> Dictionary:
    return NODES.get(node_id, {})

static func all_node_ids() -> Array:
    return NODES.keys()
```

- [ ] **Step 2: Write failing test**

Create `test/test_skill_tree.gd`:

```gdscript
extends GutTest

var currency: Currency
var st: SkillTree

func before_each():
    currency = Currency.new()
    st = SkillTree.new()
    st.currency = currency

func test_initial_no_unlocked():
    assert_eq(st.unlocked_nodes.size(), 0)

func test_initial_multipliers_are_one():
    assert_almost_eq(st.canvas_gold_mult(), 1.0, 0.0001)
    assert_almost_eq(st.canvas_speed_mult(), 1.0, 0.0001)

func test_unlock_success_spends_fame():
    currency.add("fame", BigNumber.from_float(5.0))
    var ok = st.unlock("gilded_frame")
    assert_true(ok)
    assert_true(st.unlocked_nodes.has("gilded_frame"))
    assert_eq(currency.get_amount("fame").value, 4.0)

func test_unlock_insufficient_fails():
    var ok = st.unlock("gilded_frame")
    assert_false(ok)
    assert_false(st.unlocked_nodes.has("gilded_frame"))

func test_unlock_twice_fails_second_time():
    currency.add("fame", BigNumber.from_float(10.0))
    assert_true(st.unlock("gilded_frame"))
    assert_false(st.unlock("gilded_frame"))
    assert_eq(currency.get_amount("fame").value, 10.0 - 1.0)

func test_canvas_gold_mult_applies_unlocked_effects():
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")      # +0.10
    st.unlock("master_palette")    # +0.25
    assert_almost_eq(st.canvas_gold_mult(), 1.35, 0.0001)

func test_canvas_speed_mult_applies_unlocked_effects():
    currency.add("fame", BigNumber.from_float(20.0))
    st.unlock("quick_strokes")     # +0.15
    st.unlock("tireless_hand")     # +0.30
    assert_almost_eq(st.canvas_speed_mult(), 1.45, 0.0001)

func test_persists_through_reset():
    # SkillTree has NO reset method — it's permanent
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")
    # Simulate an "ascend" by resetting currency pools but not skill_tree
    currency.reset(["inspiration", "gold"])
    assert_true(st.unlocked_nodes.has("gilded_frame"))

func test_serialize_roundtrip():
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")
    var data = st.serialize()
    var fresh = SkillTree.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_true(fresh.unlocked_nodes.has("gilded_frame"))
```

- [ ] **Step 3: Run — expect fail**

- [ ] **Step 4: Implement**

Create `scripts/systems/SkillTree.gd`:

```gdscript
class_name SkillTree
extends Node

signal node_unlocked(node_id: String)

var currency: Currency
var unlocked_nodes: Dictionary = {}  # node_id -> true

func unlock(node_id: String) -> bool:
    if currency == null:
        return false
    if unlocked_nodes.has(node_id):
        return false
    var node = SkillTreeNodes.get_node(node_id)
    if node.is_empty():
        return false
    var cost = BigNumber.from_float(float(node["cost"]))
    if not currency.spend("fame", cost):
        return false
    unlocked_nodes[node_id] = true
    node_unlocked.emit(node_id)
    return true

func _sum_effect(effect_key: String) -> float:
    var total: float = 0.0
    for node_id in unlocked_nodes.keys():
        var node = SkillTreeNodes.get_node(node_id)
        total += float(node.get("effects", {}).get(effect_key, 0.0))
    return total

func canvas_gold_mult() -> float:
    return 1.0 + _sum_effect("canvas_gold_mult_add")

func canvas_speed_mult() -> float:
    return 1.0 + _sum_effect("canvas_speed_mult_add")

# No reset() method — skill tree is permanent by design.

func serialize() -> Dictionary:
    return {"unlocked": unlocked_nodes.keys()}

func deserialize(data: Dictionary) -> void:
    unlocked_nodes = {}
    for id in data.get("unlocked", []):
        unlocked_nodes[id] = true
```

- [ ] **Step 5: Run — expect pass**

- [ ] **Step 6: Commit**

```bash
git add scripts/config/SkillTreeNodes.gd scripts/systems/SkillTree.gd test/test_skill_tree.gd
git commit -m "add SkillTree: fame spend, permanent effects, gold/speed mults"
```

---

## Task 7: `Ascend` orchestrator

**Files:**
- Create: `scripts/systems/Ascend.gd`, `test/test_ascend.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_ascend.gd`:

```gdscript
extends GutTest

var currency: Currency
var canvas: Canvas
var tree: InspirationTree
var workshop: Workshop
var inventory: Inventory
var painter_office: PainterOffice
var ascend: Ascend

func before_each():
    currency = Currency.new()
    canvas = Canvas.new()
    tree = InspirationTree.new()
    tree.currency = currency
    workshop = Workshop.new()
    workshop.currency = currency
    inventory = Inventory.new()
    painter_office = PainterOffice.new()
    painter_office.currency = currency

    ascend = Ascend.new()
    ascend.currency = currency
    ascend.canvas = canvas
    ascend.tree = tree
    ascend.workshop = workshop
    ascend.inventory = inventory
    ascend.painter_office = painter_office

func test_initial_ascend_count_zero():
    assert_eq(ascend.ascend_count, 0)

func test_can_ascend_false_below_palier():
    currency.add("inspiration", BigNumber.from_float(500.0))
    assert_false(ascend.can_ascend())

func test_can_ascend_true_at_palier():
    var palier = Balance.palier_ascend(0)
    currency.add("inspiration", palier)
    assert_true(ascend.can_ascend())

func test_perform_below_palier_is_noop():
    var count_before = ascend.ascend_count
    var ok = ascend.perform()
    assert_false(ok)
    assert_eq(ascend.ascend_count, count_before)

func test_perform_increments_ascend_count():
    currency.add("inspiration", Balance.palier_ascend(0))
    ascend.perform()
    assert_eq(ascend.ascend_count, 1)

func test_perform_converts_inspi_to_fame():
    currency.add("inspiration", BigNumber.from_float(5000.0))
    var expected = Balance.fame_conversion(BigNumber.from_float(5000.0)).value
    ascend.perform()
    assert_almost_eq(currency.get_amount("fame").value, expected, 0.0001)

func test_perform_resets_inspiration_gold():
    currency.add("inspiration", Balance.palier_ascend(0))
    currency.add("gold", BigNumber.from_float(10000.0))
    ascend.perform()
    assert_eq(currency.get_amount("inspiration").value, 0.0)
    assert_eq(currency.get_amount("gold").value, 0.0)

func test_perform_preserves_fame_and_paint_mastery():
    currency.add("inspiration", Balance.palier_ascend(0))
    currency.add("fame", BigNumber.from_float(3.0))
    currency.add("paint_mastery", BigNumber.from_float(50.0))
    ascend.perform()
    assert_gt(currency.get_amount("fame").value, 3.0)  # got more from conversion
    assert_eq(currency.get_amount("paint_mastery").value, 50.0)

func test_perform_resets_subsystems():
    currency.add("inspiration", Balance.palier_ascend(0))
    currency.add("gold", BigNumber.from_float(1.0e9))
    canvas.tier = 5
    canvas.tick(1.0)
    tree.stage_index = 2
    tree._part_levels = {"roots": 3}
    workshop.tier = 4
    inventory.add_item({"id": "x", "slot": "brush", "gold_mult": 0.1})
    painter_office.worker_count = 5

    ascend.perform()

    assert_eq(canvas.tier, 1)
    assert_eq(canvas.progress_seconds, 0.0)
    assert_eq(tree.stage_index, 0)
    assert_eq(tree.get_part_level("roots"), 0)
    assert_eq(workshop.tier, 0)
    assert_eq(inventory.owned_items.size(), 0)
    assert_eq(painter_office.worker_count, 0)

func test_perform_palier_grows_with_count():
    var palier0 = Balance.palier_ascend(0)
    currency.add("inspiration", palier0)
    ascend.perform()
    assert_eq(ascend.ascend_count, 1)
    # Now palier should be palier0 * 2
    currency.add("inspiration", palier0)
    assert_false(ascend.can_ascend())
    currency.add("inspiration", palier0)  # now we have 2 * palier0
    assert_true(ascend.can_ascend())

func test_serialize_roundtrip():
    ascend.ascend_count = 3
    var data = ascend.serialize()
    var fresh = Ascend.new()
    fresh.deserialize(data)
    assert_eq(fresh.ascend_count, 3)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Ascend.gd`:

```gdscript
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
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Ascend.gd test/test_ascend.gd
git commit -m "add Ascend orchestrator: palier, conversion, reset"
```

---

## Task 8: Wire all systems into `GameState` + sub-mechanic gating

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Create: `test/test_gamestate_full_loop.gd`

- [ ] **Step 1: Update `GameState.gd`**

Replace the entirety of `scripts/autoloads/GameState.gd` with:

```gdscript
extends Node

# -- Signals --
signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)

# -- Systems --
var currency: Currency
var save_system: Save
var canvas: Canvas
var tree: InspirationTree
var paint_mastery: PaintMastery
var workshop: Workshop
var inventory: Inventory
var craft: Craft
var painter_office: PainterOffice
var ascend: Ascend
var skill_tree: SkillTree

# Sub-mechanics that are "active" this run (reset on ascend).
var _active_mechanics: Dictionary = {}

# Sub-mechanics that have been unlocked as possibilities by the tree (reset on ascend).
var _possible_mechanics: Dictionary = {}

func _ready() -> void:
    currency = Currency.new();       currency.name = "Currency";       add_child(currency)
    save_system = Save.new();        save_system.name = "Save";        add_child(save_system)
    canvas = Canvas.new();           canvas.name = "Canvas";           add_child(canvas)
    paint_mastery = PaintMastery.new(); paint_mastery.name = "PaintMastery"; add_child(paint_mastery)
    tree = InspirationTree.new();    tree.name = "InspirationTree";    add_child(tree)
    workshop = Workshop.new();       workshop.name = "Workshop";       add_child(workshop)
    inventory = Inventory.new();     inventory.name = "Inventory";     add_child(inventory)
    craft = Craft.new();             craft.name = "Craft";             add_child(craft)
    painter_office = PainterOffice.new(); painter_office.name = "PainterOffice"; add_child(painter_office)
    skill_tree = SkillTree.new();    skill_tree.name = "SkillTree";    add_child(skill_tree)
    ascend = Ascend.new();           ascend.name = "Ascend";           add_child(ascend)

    # Wire references
    paint_mastery.currency  = currency
    tree.currency           = currency
    workshop.currency       = currency
    craft.currency          = currency
    craft.inventory         = inventory
    painter_office.currency = currency
    skill_tree.currency     = currency

    ascend.currency         = currency
    ascend.canvas           = canvas
    ascend.tree             = tree
    ascend.workshop         = workshop
    ascend.inventory        = inventory
    ascend.painter_office   = painter_office

    # Wire signals
    canvas.sold.connect(_on_canvas_sold)
    tree.stage_entered.connect(_on_stage_entered)
    tree.possibility_unlocked.connect(_on_possibility_unlocked)
    ascend.ascended.connect(_on_ascended)
    currency.changed.connect(_on_currency_changed)

func _process(delta: float) -> void:
    tree.tick(delta)
    canvas.tick(delta * canvas_speed_multiplier())

# -- Modifier aggregation --

func canvas_gold_multiplier() -> float:
    return workshop.canvas_gold_mult() * inventory.canvas_gold_mult() * skill_tree.canvas_gold_mult()

func canvas_speed_multiplier() -> float:
    return workshop.canvas_speed_mult() * painter_office.canvas_speed_mult() * skill_tree.canvas_speed_mult()

# -- Signal handlers --

func _on_canvas_sold(tier: int, base_gold: float) -> void:
    var mult: float = canvas_gold_multiplier()
    var final_gold: float = base_gold * mult
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

func _on_ascended(fame: float, count: int) -> void:
    _active_mechanics.clear()
    _possible_mechanics.clear()
    ascended.emit(fame, count)

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
        "currency":         currency.serialize(),
        "canvas":           canvas.serialize(),
        "inspi_tree":       tree.serialize(),
        "workshop":         workshop.serialize(),
        "inventory":        inventory.serialize(),
        "painter_office":   painter_office.serialize(),
        "skill_tree":       skill_tree.serialize(),
        "ascend":           ascend.serialize(),
        "active_mechanics": _active_mechanics.keys(),
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
    _active_mechanics.clear()
    for id in data.get("active_mechanics", []):
        _active_mechanics[id] = true
    _possible_mechanics.clear()
    for id in data.get("possible_mechanics", []):
        _possible_mechanics[id] = true
    tree.external_multiplier = paint_mastery.current_multiplier()
    return true
```

- [ ] **Step 2: Write full-loop integration test**

Create `test/test_gamestate_full_loop.gd`:

```gdscript
extends GutTest

func before_each():
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState.canvas.reset()
    GameState.tree.reset()
    GameState.workshop.reset()
    GameState.inventory.reset()
    GameState.painter_office.reset()
    GameState.ascend.ascend_count = 0
    GameState._active_mechanics.clear()
    GameState._possible_mechanics.clear()

func test_canvas_sale_with_modifiers_applies_all_of_them():
    GameState.workshop.tier = 2  # +50% gold
    GameState.currency.add("fame", BigNumber.from_float(5.0))
    GameState.skill_tree.unlock("gilded_frame")  # +10% gold
    var base = CanvasTiers.get_tier(GameState.canvas.tier)["gold_value"]
    var paint_time = CanvasTiers.get_tier(GameState.canvas.tier)["paint_seconds"]
    GameState.canvas.tick(paint_time)
    GameState.canvas.sell()
    var expected_mult = (1.0 + 2 * Workshop.GOLD_MULT_PER_TIER) * 1.0 * 1.10
    var expected_gold = base * expected_mult
    assert_almost_eq(GameState.currency.get_amount("gold").value, expected_gold, 0.001)

func test_try_activate_mechanic_requires_possibility():
    var ok = GameState.try_activate_mechanic("workshop")
    assert_false(ok)

func test_try_activate_mechanic_spends_inspi_and_activates():
    GameState._possible_mechanics["workshop"] = true
    GameState.currency.add("inspiration", BigNumber.from_float(1000.0))
    var cost = TreeStages.unlock_cost("workshop").value
    var ok = GameState.try_activate_mechanic("workshop")
    assert_true(ok)
    assert_true(GameState.is_active("workshop"))
    assert_eq(GameState.currency.get_amount("inspiration").value, 1000.0 - cost)

func test_full_loop_run_then_ascend():
    # Simulate a tiny run: earn some inspiration, then ascend
    GameState.currency.add("inspiration", Balance.palier_ascend(0))
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    var ok = GameState.ascend.perform()
    assert_true(ok)
    assert_eq(GameState.currency.get_amount("inspiration").value, 0.0)
    assert_eq(GameState.currency.get_amount("gold").value, 0.0)
    assert_gt(GameState.currency.get_amount("fame").value, 0.0)
    assert_eq(GameState.ascend.ascend_count, 1)

func test_ascend_resets_active_and_possible_mechanics():
    GameState._possible_mechanics["workshop"] = true
    GameState._active_mechanics["workshop"] = true
    GameState.currency.add("inspiration", Balance.palier_ascend(0))
    GameState.ascend.perform()
    assert_false(GameState.is_active("workshop"))
    assert_false(GameState.is_possible("workshop"))

func test_full_save_load_roundtrip():
    GameState.save_system.save_path = "user://test_full_loop.save"
    # Build up state
    GameState.currency.add("gold", BigNumber.from_float(1234.0))
    GameState.currency.add("fame", BigNumber.from_float(7.0))
    GameState.currency.add("paint_mastery", BigNumber.from_float(42.0))
    GameState.workshop.tier = 3
    GameState.inventory.add_item({"id": "basic_brush", "slot": "brush", "gold_mult": 0.1})
    GameState.inventory.equip("basic_brush")
    GameState.painter_office.worker_count = 2
    GameState.skill_tree.unlocked_nodes["gilded_frame"] = true
    GameState.ascend.ascend_count = 3
    GameState._possible_mechanics["workshop"] = true
    GameState._active_mechanics["workshop"] = true

    assert_true(GameState.save_game())

    # Reset state
    GameState.currency.reset(["inspiration", "gold", "fame", "paint_mastery"])
    GameState.workshop.reset()
    GameState.inventory.reset()
    GameState.painter_office.reset()
    GameState.skill_tree.unlocked_nodes = {}
    GameState.ascend.ascend_count = 0
    GameState._active_mechanics.clear()
    GameState._possible_mechanics.clear()

    assert_true(GameState.load_game())

    assert_eq(GameState.currency.get_amount("gold").value, 1234.0)
    assert_eq(GameState.currency.get_amount("fame").value, 7.0)
    assert_eq(GameState.currency.get_amount("paint_mastery").value, 42.0)
    assert_eq(GameState.workshop.tier, 3)
    assert_eq(GameState.inventory.owned_items.size(), 1)
    assert_eq(GameState.inventory.equipped["brush"]["id"], "basic_brush")
    assert_eq(GameState.painter_office.worker_count, 2)
    assert_true(GameState.skill_tree.unlocked_nodes.has("gilded_frame"))
    assert_eq(GameState.ascend.ascend_count, 3)
    assert_true(GameState.is_possible("workshop"))
    assert_true(GameState.is_active("workshop"))

    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
```

- [ ] **Step 3: Run all tests — expect all pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

Expected: all tests from Phase 1 + Phase 2 + Phase 3 pass.

- [ ] **Step 4: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_gamestate_full_loop.gd
git commit -m "wire all systems into GameState with modifier aggregation and gating"
```

---

## Phase 3 Complete Criteria

- [ ] All tests pass (Phase 1 + Phase 2 + Phase 3).
- [ ] Canvas sale applies workshop × inventory × skill_tree gold multiplier.
- [ ] Canvas tick speed applies workshop × painter_office × skill_tree speed multiplier.
- [ ] `try_activate_mechanic("workshop")` only succeeds when tree has made it possible AND inspiration is sufficient.
- [ ] `Ascend.perform()` resets only the listed systems, preserves fame + paint_mastery + skill_tree.
- [ ] Full save round-trip preserves all system states and sub-mechanic gating flags.

**Next:** Phase 4 (UI — views, popups, widgets).
