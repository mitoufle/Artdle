# Canvas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the MVP single-multiplier canvas with the multi-axis system from `docs/superpowers/specs/2026-04-25-canvas-design.md` — sticky configuration, 12 dimensions, 20-subject discovery graph, gamble + chef d'œuvre, multi-canvas slots, item drops, 17 new skill tree nodes, 2-tab improvement/configuration popup.

**Architecture:** Bottom-up. Build immutable data layer first (subjects, balance formulas), then per-slot canvas behaviour (sticky config, formulas, gamble, chef d'œuvre, auto-sale, drop event), then multi-slot orchestration, then skill tree gating + improvement currency sinks, then UI rebuild. Atelier consumes the drop event later via its own plan; this plan emits the event but does not store items.

**Tech Stack:** Godot 4.6.2, GDScript, GUT 9.x. All persistent systems are `Node`-based and held as children of `GameState` autoload. Pure-data config classes are `class_name Foo extends RefCounted` with static methods. Tests run via Godot editor → Project → Tools → GUT → Run All (CLI broken per HANDOVER).

---

## File structure

### New files

| Path | Responsibility |
|---|---|
| `scripts/config/Subjects.gd` | 20-subject registry + prereq graph (RefCounted, static). |
| `scripts/systems/SubjectMastery.gd` | Per-subject mastery tier + XP tracking. Node, child of GameState. |
| `scripts/systems/CanvasConfig.gd` | Sticky configuration (current style, palette, sujet, gamble setting, current ceilings). Node. |
| `scripts/systems/CanvasSlots.gd` | Multi-canvas slot manager. Owns a list of Canvas instances; ticks them in parallel; aggregates drop events. Node. |
| `scripts/ui/widgets/CanvasSlotCard.gd` + `.tscn` | One slot's progress bar + subject label + live quality preview. |
| `scripts/ui/widgets/DropFeed.gd` + `.tscn` | Last 5 drop events as small badges. |
| `test/test_subjects.gd` | Subjects registry + prereq evaluator. |
| `test/test_subject_mastery.gd` | Mastery curve, gain, prereq edges. |
| `test/test_canvas_config.gd` | Sticky config + ceilings clamp. |
| `test/test_canvas_formulas.gd` | New Balance.gd formulas (quality, ideal, gold, PM, time, gamble). |
| `test/test_canvas_drop.gd` | Drop event roll. |
| `test/test_canvas_slots.gd` | Multi-canvas tick + slot count source. |
| `test/test_gamestate_canvas_loop.gd` | Full sticky-config loop, gamble outcomes, chef d'œuvre. |

### Modified files

| Path | What changes |
|---|---|
| `scripts/core/Balance.gd` | Add quality formula constants + 6 new static methods (quality, ideal, gold, PM, time, gamble). |
| `scripts/systems/Canvas.gd` | Per-slot state (no longer holds tier itself; receives sticky_config + ceilings + tier-source on tick); new signals (`finished` carrying quality, `drop_rolled` carrying slot/set/tier). |
| `scripts/systems/SkillTree.gd` | Add 9 new aggregator methods (style_cap, palette_cap, multi_canvas_slots, quality_floor, chef_doeuvre_unlocked, hint_reveals, gamble_safety_net, always_gamble_unlocked, auto_mastery). |
| `scripts/config/SkillTreeNodes.gd` | Add 17 Canvas branch entries. |
| `scripts/autoloads/GameState.gd` | Wire Subjects/SubjectMastery/CanvasConfig/CanvasSlots into autoload. Replace direct `canvas` ref with `slots`. Update `tick(delta)` to fan out to `slots.tick(delta)`. New aggregators `canvas_quality_floor()` etc. Update `_on_canvas_sold` to consume new payload. |
| `scripts/systems/Save.gd` | No code change — schema is just dict keys; updates are in GameState.save_game/load_game. |
| `scripts/systems/PainterOffice.gd` | Expose `worker_count()` for the slot-count source (likely already exists; verify). |
| `scripts/ui/popups/CanvasPopup.gd` + `.tscn` | Rebuild as TabContainer with `Configuration` and `Improvement` tabs. |
| `scripts/ui/views/PaintingView.gd` + `.tscn` | Replace single canvas progress with slot list + drop feed. |
| `scripts/Main.gd` | If multi-canvas changes the autoload tick wiring, reflect here. (Likely no-op since GameState.tick stays the entry point.) |

### Files to delete

None in this plan. (Pre-rebuild orphans listed in HANDOVER are out of scope.)

---

## Phase A — Data foundations

### Task 1: Subjects registry — starter list

**Files:**
- Create: `scripts/config/Subjects.gd`
- Create: `test/test_subjects.gd`

- [ ] **Step 1: Write failing test** (`test/test_subjects.gd`)

```gdscript
extends GutTest

func test_starter_subjects_count():
    assert_eq(Subjects.starter_ids().size(), 5)

func test_starter_subjects_contain_nature():
    assert_true(Subjects.starter_ids().has("nature"))

func test_subject_name_localised():
    assert_eq(Subjects.get_subject("nature")["name"], "Nature")

func test_unknown_subject_returns_empty_dict():
    assert_true(Subjects.get_subject("does_not_exist").is_empty())
```

- [ ] **Step 2: Run test, verify it fails**

Open Godot → Project → Tools → GUT → filter `test_subjects` → Run. Expected: parse error or all asserts fail (`Subjects` not defined).

- [ ] **Step 3: Implement Subjects with starter list**

```gdscript
class_name Subjects
extends RefCounted

# All 20 subjects per spec §7.3 + §7.4. id -> {name, parents}
# parents: array of {subject_id, mastery_tier} required to unlock.
# Starter subjects have empty `parents`.
const SUBJECTS: Dictionary = {
    "nature":     {"name": "Nature",     "parents": []},
    "vie":        {"name": "Vie",        "parents": []},
    "geometrie":  {"name": "Géométrie",  "parents": []},
    "emotion":    {"name": "Émotion",    "parents": []},
    "mythe":      {"name": "Mythe",      "parents": []},
}

const PREREQ_TIER: int = 5  # spec §7.2

static func starter_ids() -> Array:
    var out: Array = []
    for id in SUBJECTS.keys():
        if (SUBJECTS[id] as Dictionary)["parents"].is_empty():
            out.append(id)
    return out

static func get_subject(id: String) -> Dictionary:
    return SUBJECTS.get(id, {})

static func all_ids() -> Array:
    return SUBJECTS.keys()
```

- [ ] **Step 4: Run, verify pass**

Run in editor: 4/4 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/config/Subjects.gd test/test_subjects.gd
git commit -m "Subjects: starter registry (5 subjects)"
```

---

### Task 2: Subjects derived graph — full 20

**Files:**
- Modify: `scripts/config/Subjects.gd`
- Modify: `test/test_subjects.gd`

- [ ] **Step 1: Add failing tests for derived subjects**

Append to `test/test_subjects.gd`:

```gdscript
func test_total_subject_count_20():
    assert_eq(Subjects.all_ids().size(), 20)

func test_animaliere_requires_nature_and_vie():
    var s = Subjects.get_subject("animaliere")
    var parents = s["parents"]
    assert_eq(parents.size(), 2)
    var ids = []
    for p in parents:
        ids.append(p["subject_id"])
    assert_true(ids.has("nature"))
    assert_true(ids.has("vie"))
    for p in parents:
        assert_eq(p["mastery_tier"], Subjects.PREREQ_TIER)

func test_eschatologique_chains_two_levels_deep():
    var s = Subjects.get_subject("eschatologique")
    assert_false(s.is_empty())
    var parent_ids = []
    for p in s["parents"]:
        parent_ids.append(p["subject_id"])
    assert_true(parent_ids.has("apocalypse"))
    assert_true(parent_ids.has("cosmique"))

func test_no_starter_has_parents():
    for id in Subjects.starter_ids():
        assert_true((Subjects.get_subject(id)["parents"] as Array).is_empty())
```

- [ ] **Step 2: Run, verify fail**

Filter `test_subjects` → Run. Expected: 4 fails.

- [ ] **Step 3: Add 15 derived entries to `SUBJECTS`**

Replace the const with the full registry:

```gdscript
const SUBJECTS: Dictionary = {
    # Starters (5)
    "nature":     {"name": "Nature",     "parents": []},
    "vie":        {"name": "Vie",        "parents": []},
    "geometrie":  {"name": "Géométrie",  "parents": []},
    "emotion":    {"name": "Émotion",    "parents": []},
    "mythe":      {"name": "Mythe",      "parents": []},
    # Tier 1 derived (5)
    "animaliere":   {"name": "Animalière",   "parents": [{"subject_id": "nature",    "mastery_tier": 5}, {"subject_id": "vie",       "mastery_tier": 5}]},
    "architecture": {"name": "Architecture", "parents": [{"subject_id": "nature",    "mastery_tier": 5}, {"subject_id": "geometrie", "mastery_tier": 5}]},
    "portrait":     {"name": "Portrait",     "parents": [{"subject_id": "vie",       "mastery_tier": 5}, {"subject_id": "emotion",   "mastery_tier": 5}]},
    "religieuse":   {"name": "Religieuse",   "parents": [{"subject_id": "emotion",   "mastery_tier": 5}, {"subject_id": "mythe",     "mastery_tier": 5}]},
    "cosmique":     {"name": "Cosmique",     "parents": [{"subject_id": "mythe",     "mastery_tier": 5}, {"subject_id": "geometrie", "mastery_tier": 5}]},
    # Tier 2 derived (5)
    "bestiaire_mythique": {"name": "Bestiaire mythique", "parents": [{"subject_id": "animaliere",   "mastery_tier": 5}, {"subject_id": "mythe",        "mastery_tier": 5}]},
    "jardin_classique":   {"name": "Jardin classique",   "parents": [{"subject_id": "architecture", "mastery_tier": 5}, {"subject_id": "nature",       "mastery_tier": 5}]},
    "allegorie":          {"name": "Allégorie",          "parents": [{"subject_id": "portrait",     "mastery_tier": 5}, {"subject_id": "mythe",        "mastery_tier": 5}]},
    "cathedrale":         {"name": "Cathédrale",         "parents": [{"subject_id": "religieuse",   "mastery_tier": 5}, {"subject_id": "architecture", "mastery_tier": 5}]},
    "surrealiste":        {"name": "Surréaliste",        "parents": [{"subject_id": "cosmique",     "mastery_tier": 5}, {"subject_id": "nature",       "mastery_tier": 5}]},
    # Tier 3 derived (5)
    "apocalypse":      {"name": "Apocalypse",      "parents": [{"subject_id": "bestiaire_mythique", "mastery_tier": 5}, {"subject_id": "religieuse",       "mastery_tier": 5}]},
    "pastorale":       {"name": "Pastorale",       "parents": [{"subject_id": "jardin_classique",   "mastery_tier": 5}, {"subject_id": "allegorie",        "mastery_tier": 5}]},
    "triomphe":        {"name": "Triomphe",        "parents": [{"subject_id": "cathedrale",         "mastery_tier": 5}, {"subject_id": "allegorie",        "mastery_tier": 5}]},
    "onirique":        {"name": "Onirique",        "parents": [{"subject_id": "surrealiste",        "mastery_tier": 5}, {"subject_id": "portrait",         "mastery_tier": 5}]},
    "eschatologique":  {"name": "Eschatologique",  "parents": [{"subject_id": "apocalypse",         "mastery_tier": 5}, {"subject_id": "cosmique",         "mastery_tier": 5}]},
}
```

- [ ] **Step 4: Run, verify pass (8/8 in test_subjects)**

- [ ] **Step 5: Commit**

```bash
git add scripts/config/Subjects.gd test/test_subjects.gd
git commit -m "Subjects: derived 15 + prereq tier 5"
```

---

### Task 3: SubjectMastery system — XP curve and gain

**Files:**
- Create: `scripts/systems/SubjectMastery.gd`
- Create: `test/test_subject_mastery.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

var mastery: SubjectMastery

func before_each():
    mastery = SubjectMastery.new()

func after_each():
    if mastery != null:
        mastery.free()

func test_initial_tier_zero_for_starter():
    assert_eq(mastery.tier_of("nature"), 0)

func test_xp_threshold_tier_1_is_200():
    # spec §7.2: tier T requires 200 * 2^(T-1) XP. Tier 1 = 200.
    assert_eq(SubjectMastery.xp_threshold(1), 200)

func test_xp_threshold_tier_5_is_3200():
    assert_eq(SubjectMastery.xp_threshold(5), 3200)

func test_xp_threshold_tier_10_is_102400():
    assert_eq(SubjectMastery.xp_threshold(10), 102400)

func test_gain_under_threshold_does_not_advance_tier():
    mastery.gain("nature", 100)
    assert_eq(mastery.tier_of("nature"), 0)
    assert_eq(mastery.xp_of("nature"), 100)

func test_gain_at_threshold_advances_tier():
    mastery.gain("nature", 200)
    assert_eq(mastery.tier_of("nature"), 1)
    # Spec semantics: XP carries over across tier boundary.
    assert_eq(mastery.xp_of("nature"), 0)

func test_gain_can_advance_multiple_tiers():
    # tier 1 = 200, tier 2 = 400. Total 600.
    mastery.gain("nature", 600)
    assert_eq(mastery.tier_of("nature"), 2)

func test_gain_caps_at_tier_10():
    mastery.gain("nature", 1_000_000)
    assert_eq(mastery.tier_of("nature"), 10)

func test_serialize_roundtrip():
    mastery.gain("nature", 250)
    mastery.gain("vie", 100)
    var data = mastery.serialize()
    var fresh = SubjectMastery.new()
    fresh.deserialize(data)
    assert_eq(fresh.tier_of("nature"), 1)
    assert_eq(fresh.xp_of("vie"), 100)
    fresh.free()
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement SubjectMastery**

```gdscript
class_name SubjectMastery
extends Node

# subject_id -> {tier: int, xp_in_tier: int}
var _state: Dictionary = {}

const MAX_TIER: int = 10

static func xp_threshold(tier: int) -> int:
    if tier <= 0:
        return 0
    return 200 * int(pow(2.0, float(tier - 1)))

func tier_of(subject_id: String) -> int:
    return int((_state.get(subject_id, {}) as Dictionary).get("tier", 0))

func xp_of(subject_id: String) -> int:
    return int((_state.get(subject_id, {}) as Dictionary).get("xp_in_tier", 0))

func gain(subject_id: String, amount: int) -> void:
    if amount <= 0:
        return
    var entry: Dictionary = _state.get(subject_id, {"tier": 0, "xp_in_tier": 0})
    var tier: int = int(entry["tier"])
    var xp: int = int(entry["xp_in_tier"]) + amount
    while tier < MAX_TIER:
        var threshold: int = xp_threshold(tier + 1)
        if xp >= threshold:
            xp -= threshold
            tier += 1
        else:
            break
    if tier >= MAX_TIER:
        xp = 0
    _state[subject_id] = {"tier": tier, "xp_in_tier": xp}

func reset() -> void:
    _state.clear()

func serialize() -> Dictionary:
    return {"state": _state.duplicate(true)}

func deserialize(data: Dictionary) -> void:
    _state = (data.get("state", {}) as Dictionary).duplicate(true)
```

- [ ] **Step 4: Run, verify all pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/SubjectMastery.gd test/test_subject_mastery.gd
git commit -m "SubjectMastery: tier curve + gain + serialize"
```

---

### Task 4: SubjectMastery — derived-subject discovery

**Files:**
- Modify: `scripts/systems/SubjectMastery.gd`
- Modify: `test/test_subject_mastery.gd`

- [ ] **Step 1: Add failing tests**

```gdscript
func test_starter_subjects_unlocked_from_start():
    assert_true(mastery.is_unlocked("nature"))
    assert_true(mastery.is_unlocked("vie"))

func test_derived_subject_locked_until_both_parents_at_tier_5():
    assert_false(mastery.is_unlocked("animaliere"))
    mastery.gain("nature", SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3) + SubjectMastery.xp_threshold(4) + SubjectMastery.xp_threshold(5))
    assert_false(mastery.is_unlocked("animaliere"))  # one parent at tier 5, second still 0
    mastery.gain("vie", SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3) + SubjectMastery.xp_threshold(4) + SubjectMastery.xp_threshold(5))
    assert_true(mastery.is_unlocked("animaliere"))

func test_hint_revealed_when_half_progress_on_a_parent():
    # Half progress = parent at tier 3 (half of prereq tier 5).
    var xp_to_tier_3 = SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3)
    mastery.gain("nature", xp_to_tier_3)
    # animaliere requires nature(5) + vie(5); half = nature(3) reached.
    assert_true(mastery.has_hint("animaliere"))
    assert_false(mastery.is_unlocked("animaliere"))

func test_no_hint_when_no_progress():
    assert_false(mastery.has_hint("animaliere"))
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement is_unlocked + has_hint**

Append:

```gdscript
const HINT_HALF_TIER: int = 3  # half of Subjects.PREREQ_TIER

func is_unlocked(subject_id: String) -> bool:
    var s: Dictionary = Subjects.get_subject(subject_id)
    if s.is_empty():
        return false
    if (s["parents"] as Array).is_empty():
        return true
    for p in (s["parents"] as Array):
        if tier_of(p["subject_id"]) < int(p["mastery_tier"]):
            return false
    return true

func has_hint(subject_id: String) -> bool:
    if is_unlocked(subject_id):
        return false
    var s: Dictionary = Subjects.get_subject(subject_id)
    if s.is_empty() or (s["parents"] as Array).is_empty():
        return false
    for p in (s["parents"] as Array):
        if tier_of(p["subject_id"]) >= HINT_HALF_TIER:
            return true
    return false
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/SubjectMastery.gd test/test_subject_mastery.gd
git commit -m "SubjectMastery: is_unlocked + half-progress hint"
```

---

### Task 5: Balance.gd — quality and ideal-quality formulas

**Files:**
- Modify: `scripts/core/Balance.gd`
- Create: `test/test_canvas_formulas.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

func test_base_quality_simple():
    # spec §6.1: base_quality = taille + style + palette + mastery + floor_bonus
    assert_eq(Balance.canvas_base_quality(5, 5, 5, 3, 0.0), 18.0)

func test_base_quality_late_game():
    assert_eq(Balance.canvas_base_quality(10, 25, 25, 10, 5.0), 75.0)

func test_base_quality_floor_bonus_added():
    assert_eq(Balance.canvas_base_quality(1, 1, 1, 0, 7.0), 10.0)

func test_ideal_quality_uses_skill_caps_not_current():
    # spec §6.2: ideal = taille + style_cap + palette_cap + 10 + floor_bonus
    # player at tier 5, current style 5 (cap 10), current palette 5 (cap 10)
    assert_eq(Balance.canvas_ideal_quality(5, 10, 10, 0.0), 35.0)

func test_ideal_quality_with_floor_bonus():
    assert_eq(Balance.canvas_ideal_quality(10, 25, 25, 5.0), 75.0)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add formulas to Balance.gd**

Append to `scripts/core/Balance.gd`:

```gdscript
# -- Canvas formulas (spec 2026-04-25-canvas-design §6) --

static func canvas_base_quality(taille: int, style: int, palette: int, mastery_tier: int, floor_bonus: float) -> float:
    return float(taille) + float(style) + float(palette) + float(mastery_tier) + floor_bonus

static func canvas_ideal_quality(taille: int, style_cap: int, palette_cap: int, floor_bonus: float) -> float:
    return float(taille) + float(style_cap) + float(palette_cap) + 10.0 + floor_bonus
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Balance.gd test/test_canvas_formulas.gd
git commit -m "Balance: canvas base + ideal quality formulas"
```

---

### Task 6: Balance.gd — gold + PM + time formulas

**Files:**
- Modify: `scripts/core/Balance.gd`
- Modify: `test/test_canvas_formulas.gd`

- [ ] **Step 1: Add failing tests**

Append to `test/test_canvas_formulas.gd`:

```gdscript
func test_canvas_gold_formula():
    # spec §6.3: gold = quality * tier * 10 * gold_mult
    assert_eq(Balance.canvas_gold(5.0, 1, 1.0), 50.0)
    assert_eq(Balance.canvas_gold(75.0, 10, 1.0), 7500.0)
    assert_eq(Balance.canvas_gold(100.0, 10, 5.0), 50000.0)

func test_canvas_pm_base_floor_div_10():
    assert_eq(Balance.canvas_pm_base(75.0), 7)
    assert_eq(Balance.canvas_pm_base(5.0), 0)
    assert_eq(Balance.canvas_pm_base(10.0), 1)

func test_canvas_pm_burst_eligible_at_quality_31():
    # spec §6.4: pm_burst_eligible = final_quality > 30
    assert_true(Balance.canvas_pm_burst_eligible(31.0))
    assert_false(Balance.canvas_pm_burst_eligible(30.0))

func test_canvas_time_formula():
    # spec §6.5: time = (tier*2 + style*1) * (1 - reduction) / speed_mult
    assert_eq(Balance.canvas_time(1, 1, 0.0, 1.0), 3.0)
    assert_eq(Balance.canvas_time(5, 10, 0.0, 1.0), 20.0)
    # 30% reduction + 2x speed
    assert_almost_eq(Balance.canvas_time(10, 25, 0.30, 2.0), (45.0 * 0.70) / 2.0, 0.001)

func test_canvas_time_reduction_capped_at_70_percent():
    # spec §15.1 implies cap, but direct test: 0.95 reduction must be clamped to 0.70
    assert_almost_eq(Balance.canvas_time(1, 1, 0.95, 1.0), 3.0 * 0.30, 0.001)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add formulas**

Append to `Balance.gd`:

```gdscript
const STYLE_TIME_REDUCTION_CAP: float = 0.70
const PM_BURST_THRESHOLD: float = 30.0

static func canvas_gold(final_quality: float, tier: int, gold_mult: float) -> float:
    return final_quality * float(tier) * 10.0 * gold_mult

static func canvas_pm_base(final_quality: float) -> int:
    return int(floor(final_quality / 10.0))

static func canvas_pm_burst_eligible(final_quality: float) -> bool:
    return final_quality > PM_BURST_THRESHOLD

static func canvas_time(tier: int, style: int, time_reduction: float, speed_mult: float) -> float:
    var clamped_reduction: float = clamp(time_reduction, 0.0, STYLE_TIME_REDUCTION_CAP)
    var raw: float = (float(tier) * 2.0 + float(style) * 1.0)
    var divisor: float = max(speed_mult, 0.0001)  # guard div-by-zero
    return raw * (1.0 - clamped_reduction) / divisor
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Balance.gd test/test_canvas_formulas.gd
git commit -m "Balance: canvas gold + PM + time formulas"
```

---

### Task 7: Balance.gd — gamble formula

**Files:**
- Modify: `scripts/core/Balance.gd`
- Modify: `test/test_canvas_formulas.gd`

- [ ] **Step 1: Add failing tests**

```gdscript
func test_gamble_success_yield_formula():
    # spec §8.2: gambled = base * (1 + log10(N) * 0.5)
    # N=10 → ×1.5
    assert_almost_eq(Balance.gamble_success_quality(10.0, 10), 15.0, 0.001)
    # N=100 → ×2.0
    assert_almost_eq(Balance.gamble_success_quality(10.0, 100), 20.0, 0.001)
    # N=10_000 → ×3.0
    assert_almost_eq(Balance.gamble_success_quality(10.0, 10000), 30.0, 0.001)

func test_gamble_failure_halves_quality_floor_1():
    assert_eq(Balance.gamble_failure_quality(10.0), 5.0)
    assert_eq(Balance.gamble_failure_quality(1.0), 1.0)
    assert_eq(Balance.gamble_failure_quality(0.5), 1.0)

func test_gamble_yield_mult_applies():
    # gamble_yield_mult ×2 doubles the bonus portion (not the base)
    # base 10, N=100, yield_mult 2.0: bonus = log10(100)*0.5*2 = 2.0 → quality = 10 * (1 + 2.0) = 30
    assert_almost_eq(Balance.gamble_success_quality_with_mult(10.0, 100, 2.0), 30.0, 0.001)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement**

```gdscript
static func gamble_success_quality(base_quality: float, n_inspi: int) -> float:
    if n_inspi < 1:
        return base_quality
    var bonus: float = log(float(n_inspi)) / log(10.0) * 0.5
    return base_quality * (1.0 + bonus)

static func gamble_success_quality_with_mult(base_quality: float, n_inspi: int, yield_mult: float) -> float:
    if n_inspi < 1:
        return base_quality
    var bonus: float = log(float(n_inspi)) / log(10.0) * 0.5 * yield_mult
    return base_quality * (1.0 + bonus)

static func gamble_failure_quality(base_quality: float) -> float:
    return max(1.0, floor(base_quality / 2.0))
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Balance.gd test/test_canvas_formulas.gd
git commit -m "Balance: gamble success/failure quality formulas"
```

---

## Phase B — Canvas core refactor

### Task 8: CanvasConfig system — sticky configuration

**Files:**
- Create: `scripts/systems/CanvasConfig.gd`
- Create: `test/test_canvas_config.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

var cfg: CanvasConfig

func before_each():
    cfg = CanvasConfig.new()

func after_each():
    if cfg != null:
        cfg.free()

func test_initial_style_1_palette_1():
    assert_eq(cfg.style, 1)
    assert_eq(cfg.palette, 1)

func test_initial_subject_is_first_starter():
    assert_eq(cfg.current_subject, "nature")

func test_initial_gamble_off():
    assert_eq(cfg.gamble_n_inspi, 0)

func test_initial_ceilings_are_one():
    assert_eq(cfg.style_current_ceiling, 1)
    assert_eq(cfg.palette_current_ceiling, 1)

func test_set_style_clamps_to_current_ceiling():
    cfg.style_current_ceiling = 5
    cfg.set_style(10)
    assert_eq(cfg.style, 5)

func test_set_palette_clamps_to_current_ceiling():
    cfg.palette_current_ceiling = 3
    cfg.set_palette(7)
    assert_eq(cfg.palette, 3)

func test_set_subject_only_if_unlocked():
    var mastery := SubjectMastery.new()
    add_child(mastery)
    cfg.subject_mastery = mastery
    assert_true(cfg.set_subject("nature"))
    assert_eq(cfg.current_subject, "nature")
    assert_false(cfg.set_subject("animaliere"))  # locked, no mastery
    assert_eq(cfg.current_subject, "nature")
    mastery.queue_free()

func test_set_gamble_to_valid_levels():
    for n in [0, 10, 100, 1000, 10000]:
        cfg.set_gamble(n)
        assert_eq(cfg.gamble_n_inspi, n)

func test_set_gamble_rejects_invalid():
    cfg.set_gamble(50)  # not a valid level
    assert_eq(cfg.gamble_n_inspi, 0)

func test_buy_style_ceiling_increments():
    cfg.style_current_ceiling = 1
    cfg.buy_style_ceiling()
    assert_eq(cfg.style_current_ceiling, 2)

func test_buy_style_ceiling_clamps_to_skill_cap():
    cfg.style_current_ceiling = 10
    cfg.buy_style_ceiling(10)  # explicit cap
    assert_eq(cfg.style_current_ceiling, 10)

func test_serialize_roundtrip():
    cfg.style_current_ceiling = 5
    cfg.set_style(3)
    cfg.set_gamble(100)
    var data = cfg.serialize()
    var fresh = CanvasConfig.new()
    fresh.deserialize(data)
    assert_eq(fresh.style, 3)
    assert_eq(fresh.style_current_ceiling, 5)
    assert_eq(fresh.gamble_n_inspi, 100)
    fresh.free()
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement CanvasConfig**

```gdscript
class_name CanvasConfig
extends Node

const VALID_GAMBLE_LEVELS: Array = [0, 10, 100, 1000, 10000]
const SKILL_CAP_DEFAULT: int = 10  # spec §5 baseline

# Sticky settings
var style: int = 1
var palette: int = 1
var current_subject: String = "nature"
var gamble_n_inspi: int = 0  # 0 = off

# Per-run improvement-tab ceilings (within skill cap)
var style_current_ceiling: int = 1
var palette_current_ceiling: int = 1

# External ref (set by GameState during boot)
var subject_mastery: SubjectMastery = null

func set_style(v: int) -> void:
    style = clamp(v, 1, style_current_ceiling)

func set_palette(v: int) -> void:
    palette = clamp(v, 1, palette_current_ceiling)

func set_subject(subject_id: String) -> bool:
    if subject_mastery == null:
        return false
    if not subject_mastery.is_unlocked(subject_id):
        return false
    current_subject = subject_id
    return true

func set_gamble(n: int) -> void:
    if VALID_GAMBLE_LEVELS.has(n):
        gamble_n_inspi = n

func buy_style_ceiling(skill_cap: int = SKILL_CAP_DEFAULT) -> void:
    if style_current_ceiling < skill_cap:
        style_current_ceiling += 1

func buy_palette_ceiling(skill_cap: int = SKILL_CAP_DEFAULT) -> void:
    if palette_current_ceiling < skill_cap:
        palette_current_ceiling += 1

func reset() -> void:
    style = 1
    palette = 1
    current_subject = "nature"
    gamble_n_inspi = 0
    style_current_ceiling = 1
    palette_current_ceiling = 1

func serialize() -> Dictionary:
    return {
        "style": style,
        "palette": palette,
        "current_subject": current_subject,
        "gamble_n_inspi": gamble_n_inspi,
        "style_current_ceiling": style_current_ceiling,
        "palette_current_ceiling": palette_current_ceiling,
    }

func deserialize(data: Dictionary) -> void:
    style = int(data.get("style", 1))
    palette = int(data.get("palette", 1))
    current_subject = String(data.get("current_subject", "nature"))
    gamble_n_inspi = int(data.get("gamble_n_inspi", 0))
    style_current_ceiling = int(data.get("style_current_ceiling", 1))
    palette_current_ceiling = int(data.get("palette_current_ceiling", 1))
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/CanvasConfig.gd test/test_canvas_config.gd
git commit -m "CanvasConfig: sticky settings + ceilings + serialize"
```

---

### Task 9: Canvas refactor — accept config + emit `finished` with payload

**Files:**
- Modify: `scripts/systems/Canvas.gd`
- Modify: `test/test_canvas.gd`

- [ ] **Step 1: Replace existing test_canvas.gd with new shape**

Note: the previous `Canvas.tier`, `Canvas.sell()`, and `is_ready_to_sell()` API is being replaced. The new Canvas is per-slot, ticks against a configured paint-time, and emits `finished` with quality/gold/pm payload. Auto-sale: no idle ready-to-sell state; emit `finished` immediately when progress completes.

Replace `test/test_canvas.gd`:

```gdscript
extends GutTest

var canvas: Canvas
var stub_quality: float = 18.0
var stub_paint_time: float = 5.0

func before_each():
    canvas = Canvas.new()

func after_each():
    if canvas != null:
        canvas.free()

func test_initial_progress_zero():
    assert_eq(canvas.progress_seconds, 0.0)

func test_tick_accumulates_progress():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(1.0)
    assert_eq(canvas.progress_seconds, 1.0)

func test_finishes_immediately_when_tick_exceeds_paint_time():
    watch_signals(canvas)
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time + 0.1)
    assert_signal_emitted(canvas, "finished")

func test_finished_payload_carries_quality():
    var captured: Array = []
    canvas.finished.connect(func(payload: Dictionary): captured.append(payload))
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time)
    assert_eq(captured.size(), 1)
    assert_eq(captured[0]["quality"], stub_quality)

func test_progress_resets_after_finish():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(stub_paint_time + 0.5)
    # The slot manager re-starts immediately (auto-sale chain). Until then progress is 0.
    assert_eq(canvas.progress_seconds, 0.0)

func test_serialize_roundtrip():
    canvas.start(stub_paint_time, stub_quality)
    canvas.tick(2.5)
    var data = canvas.serialize()
    var fresh = Canvas.new()
    fresh.deserialize(data)
    assert_eq(fresh.progress_seconds, 2.5)
    assert_eq(fresh.paint_time, stub_paint_time)
    assert_eq(fresh.quality, stub_quality)
    fresh.free()
```

(Old tests for `tier`, `sell()`, `upgrade_tier()`, `reset()` to MAX_TIER, `is_ready_to_sell()` are gone — those concepts move to CanvasSlots/CanvasConfig.)

- [ ] **Step 2: Run, verify fail (Canvas.start does not exist)**

- [ ] **Step 3: Rewrite Canvas.gd**

```gdscript
class_name Canvas
extends Node

# Per-slot canvas. Holds only progress + the snapshot of paint_time/quality
# that was active at canvas-start. Reconfiguration of sticky config does NOT
# affect a canvas already in flight — it only affects subsequent canvases
# (see spec §3 "sticky configuration + observed loop").

signal finished(payload: Dictionary)
# payload keys: quality (float), tier (int), subject_id (String), gambled (bool),
#               chef_doeuvre (bool). Slot manager fills tier/subject/gambled/chef before emit.

var paint_time: float = 0.0
var quality: float = 0.0
var progress_seconds: float = 0.0
var is_running: bool = false

func start(p_paint_time: float, p_quality: float) -> void:
    paint_time = p_paint_time
    quality = p_quality
    progress_seconds = 0.0
    is_running = true

func tick(delta: float) -> void:
    if not is_running:
        return
    progress_seconds += delta
    if progress_seconds >= paint_time:
        is_running = false
        progress_seconds = 0.0
        finished.emit({"quality": quality})

func reset() -> void:
    paint_time = 0.0
    quality = 0.0
    progress_seconds = 0.0
    is_running = false

func serialize() -> Dictionary:
    return {
        "paint_time": paint_time,
        "quality": quality,
        "progress_seconds": progress_seconds,
        "is_running": is_running,
    }

func deserialize(data: Dictionary) -> void:
    paint_time = float(data.get("paint_time", 0.0))
    quality = float(data.get("quality", 0.0))
    progress_seconds = float(data.get("progress_seconds", 0.0))
    is_running = bool(data.get("is_running", false))
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Canvas.gd test/test_canvas.gd
git commit -m "Canvas: refactor to per-slot with finished payload"
```

---

### Task 10: Wire SubjectMastery + CanvasConfig into GameState (without slot manager yet)

**Files:**
- Modify: `scripts/autoloads/GameState.gd`

- [ ] **Step 1: Note context — this task changes wiring without a test of its own**

GameState wiring is integration plumbing. The `test_gamestate_*` tests (existing) will exercise it. We add new constants + members + boot wiring, then verify ALL existing tests still pass (156).

- [ ] **Step 2: Add preloads + members + boot lines**

Edit `scripts/autoloads/GameState.gd`:

After the existing `const AscendClass` line, add:

```gdscript
const SubjectMasteryClass = preload("res://scripts/systems/SubjectMastery.gd")
const CanvasConfigClass   = preload("res://scripts/systems/CanvasConfig.gd")
```

After the existing `var ascend: AscendClass` line, add:

```gdscript
var subject_mastery: SubjectMasteryClass
var canvas_config: CanvasConfigClass
```

In `_ready()`, after the existing `add_child(canvas)` line, add (using tab indents per autoload convention):

```gdscript
	subject_mastery = SubjectMasteryClass.new()
	subject_mastery.name = "SubjectMastery"
	add_child(subject_mastery)

	canvas_config = CanvasConfigClass.new()
	canvas_config.name = "CanvasConfig"
	canvas_config.subject_mastery = subject_mastery
	add_child(canvas_config)
```

In `save_game()`, add to the payload Dictionary literal:

```gdscript
		"subject_mastery": subject_mastery.serialize(),
		"canvas_config":   canvas_config.serialize(),
```

In `load_game()`, after the existing `if data.has("ascend")` line, add:

```gdscript
	if data.has("subject_mastery"): subject_mastery.deserialize(data["subject_mastery"])
	if data.has("canvas_config"):   canvas_config.deserialize(data["canvas_config"])
```

- [ ] **Step 3: Run all tests, verify 156 still pass**

Editor → GUT → Run All. Expected: 156 pass (no new tests this task).

- [ ] **Step 4: Commit**

```bash
git add scripts/autoloads/GameState.gd
git commit -m "GameState: wire SubjectMastery + CanvasConfig autoloads"
```

---

## Phase C — Multi-canvas slot orchestrator

### Task 11: CanvasSlots — single-slot tick path and finish handling

**Files:**
- Create: `scripts/systems/CanvasSlots.gd`
- Create: `test/test_canvas_slots.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

var slots: CanvasSlots
var cfg: CanvasConfig
var mastery: SubjectMastery

func before_each():
    mastery = SubjectMastery.new()
    cfg = CanvasConfig.new()
    cfg.subject_mastery = mastery
    slots = CanvasSlots.new()
    slots.config = cfg
    slots.mastery = mastery
    slots.tier_provider = func(): return 1
    slots.style_skill_cap = 10
    slots.palette_skill_cap = 10
    slots.canvas_speed_mult = 1.0
    slots.style_time_reduction = 0.0
    slots.quality_floor_bonus = 0.0
    slots.chef_doeuvre_chance = 0.0
    slots.gamble_yield_mult = 1.0
    slots.gamble_success_chance = 0.5
    slots.add_child(mastery)  # parented for cleanup; slots will not own
    slots.set_slot_count(1)

func after_each():
    if slots != null:
        slots.free()

func test_default_slot_count_zero_until_set():
    var fresh = CanvasSlots.new()
    assert_eq(fresh.slot_count(), 0)
    fresh.free()

func test_set_slot_count_creates_canvas_children():
    assert_eq(slots.slot_count(), 1)

func test_tick_drives_canvas_to_finish_and_restarts():
    # Stub paint time low for fast finish.
    slots.paint_time_override = 1.0
    slots.tick(1.5)
    # After finishing, slot auto-restarts; progress should be > 0 again.
    var c: Canvas = slots.get_canvas(0)
    assert_true(c.is_running)
    assert_true(c.progress_seconds > 0.0)

func test_finish_emits_canvas_completed():
    watch_signals(slots)
    slots.paint_time_override = 1.0
    slots.tick(1.5)
    assert_signal_emitted(slots, "canvas_completed")
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement CanvasSlots (single-slot path)**

```gdscript
class_name CanvasSlots
extends Node

signal canvas_completed(payload: Dictionary)
# payload keys: slot_index (int), quality (float), tier (int),
#               subject_id (String), gambled (bool), chef_doeuvre (bool)

# External refs (set by GameState during boot).
var config: CanvasConfig = null
var mastery: SubjectMastery = null

# Provider for current canvas tier (auto-max). GameState supplies a Callable.
var tier_provider: Callable = Callable()

# Aggregated multipliers (set each tick by GameState before calling tick(delta)).
var canvas_speed_mult: float = 1.0
var style_time_reduction: float = 0.0
var quality_floor_bonus: float = 0.0
var chef_doeuvre_chance: float = 0.0  # 0..1, e.g. 0.005 baseline if unlocked
var gamble_yield_mult: float = 1.0
var gamble_success_chance: float = 0.5

# Skill-tree caps (used by ideal_quality and CanvasConfig.buy_*_ceiling).
var style_skill_cap: int = 10
var palette_skill_cap: int = 10

# Test/dev override — when > 0, replaces computed paint_time.
var paint_time_override: float = -1.0

# Internal: list of Canvas children.
var _slots: Array = []

func slot_count() -> int:
    return _slots.size()

func get_canvas(idx: int) -> Canvas:
    return _slots[idx] as Canvas

func set_slot_count(n: int) -> void:
    while _slots.size() < n:
        var c := Canvas.new()
        c.name = "Slot_%d" % _slots.size()
        var idx: int = _slots.size()
        c.finished.connect(func(payload: Dictionary): _on_slot_finished(idx, payload))
        add_child(c)
        _slots.append(c)
        _start_slot(c)
    while _slots.size() > n:
        var dropped: Canvas = _slots.pop_back()
        dropped.queue_free()

func tick(delta: float) -> void:
    var scaled: float = delta * canvas_speed_mult
    for c in _slots:
        if not (c as Canvas).is_running:
            _start_slot(c)
        (c as Canvas).tick(scaled)

func _start_slot(c: Canvas) -> void:
    if config == null or mastery == null:
        return
    var tier: int = 1
    if tier_provider.is_valid():
        tier = int(tier_provider.call())
    var subject_id: String = config.current_subject
    var mastery_tier: int = mastery.tier_of(subject_id)
    var base_q: float = Balance.canvas_base_quality(tier, config.style, config.palette, mastery_tier, quality_floor_bonus)
    # Gamble (resolution captured here; success/fail materialised on finish payload).
    # Chef d'œuvre roll happens at finish to keep tests deterministic via stubs.
    var paint_time: float = paint_time_override if paint_time_override > 0.0 \
        else Balance.canvas_time(tier, config.style, style_time_reduction, 1.0)  # speed_mult applied via tick scaling
    c.start(paint_time, base_q)
    c.set_meta("tier", tier)
    c.set_meta("subject_id", subject_id)

func _on_slot_finished(idx: int, payload: Dictionary) -> void:
    var c: Canvas = _slots[idx] as Canvas
    var base_q: float = float(payload["quality"])
    var tier: int = int(c.get_meta("tier", 1))
    var subject_id: String = String(c.get_meta("subject_id", "nature"))
    # Gamble resolution
    var gambled: bool = false
    var gambled_q: float = base_q
    if config != null and config.gamble_n_inspi > 0:
        gambled = true
        if randf() < gamble_success_chance:
            gambled_q = Balance.gamble_success_quality_with_mult(base_q, config.gamble_n_inspi, gamble_yield_mult)
        else:
            gambled_q = Balance.gamble_failure_quality(base_q)
    # Chef d'œuvre roll
    var is_chef: bool = false
    var final_q: float = gambled_q
    if randf() < chef_doeuvre_chance:
        is_chef = true
        var ideal: float = Balance.canvas_ideal_quality(tier, style_skill_cap, palette_skill_cap, quality_floor_bonus)
        final_q = max(gambled_q, ideal)
    canvas_completed.emit({
        "slot_index":   idx,
        "quality":      final_q,
        "tier":         tier,
        "subject_id":   subject_id,
        "gambled":      gambled,
        "chef_doeuvre": is_chef,
    })
    # Auto-restart immediately (auto-sale state machine, spec §3.2).
    _start_slot(c)
```

Note: `mastery` is parented in the test setup to keep GUT orphan count zero. `CanvasSlots` does NOT own it; cleanup is the test's responsibility.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/CanvasSlots.gd test/test_canvas_slots.gd
git commit -m "CanvasSlots: single-slot tick + auto-restart"
```

---

### Task 12: CanvasSlots — multi-slot tick

**Files:**
- Modify: `test/test_canvas_slots.gd`

- [ ] **Step 1: Add failing test**

```gdscript
func test_three_slots_each_finish_independently():
    slots.paint_time_override = 1.0
    slots.set_slot_count(3)
    var captured: Array = []
    slots.canvas_completed.connect(func(p: Dictionary): captured.append(p))
    slots.tick(1.5)
    # All 3 slots finished one canvas each.
    assert_eq(captured.size(), 3)
    var indices: Array = []
    for p in captured:
        indices.append(p["slot_index"])
    indices.sort()
    assert_eq(indices, [0, 1, 2])

func test_set_slot_count_decreases_frees_excess():
    slots.set_slot_count(3)
    slots.set_slot_count(1)
    assert_eq(slots.slot_count(), 1)
```

- [ ] **Step 2: Run, verify pass (no impl change needed — already supported)**

If a test fails, debug; expected to pass since `set_slot_count` already loops.

- [ ] **Step 3: Commit**

```bash
git add test/test_canvas_slots.gd
git commit -m "CanvasSlots: cover multi-slot independence"
```

---

### Task 13: CanvasSlots — drop event

**Files:**
- Modify: `scripts/systems/CanvasSlots.gd`
- Create: `test/test_canvas_drop.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

var slots: CanvasSlots
var cfg: CanvasConfig
var mastery: SubjectMastery

func before_each():
    mastery = SubjectMastery.new()
    cfg = CanvasConfig.new()
    cfg.subject_mastery = mastery
    slots = CanvasSlots.new()
    slots.config = cfg
    slots.mastery = mastery
    slots.tier_provider = func(): return 1
    slots.style_skill_cap = 10
    slots.palette_skill_cap = 10
    slots.add_child(mastery)
    slots.set_slot_count(1)

func after_each():
    if slots != null:
        slots.free()

func test_drop_chance_at_quality_zero():
    # spec §11.1: 0.05 + 0.001 * quality
    assert_almost_eq(CanvasSlots.drop_chance(0.0), 0.05, 0.0001)

func test_drop_chance_at_quality_30():
    assert_almost_eq(CanvasSlots.drop_chance(30.0), 0.08, 0.0001)

func test_drop_chance_at_quality_75():
    assert_almost_eq(CanvasSlots.drop_chance(75.0), 0.125, 0.0001)

func test_drop_event_emitted_when_force_drop():
    slots.force_drop = true  # test-only deterministic switch
    slots.paint_time_override = 1.0
    var captured: Array = []
    slots.drop_rolled.connect(func(p: Dictionary): captured.append(p))
    slots.tick(1.5)
    assert_eq(captured.size(), 1)
    assert_true(captured[0].has("slot_type"))
    assert_true(captured[0].has("set_id"))
    assert_true(captured[0].has("tier"))
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add drop logic to CanvasSlots**

Append to `CanvasSlots.gd`:

```gdscript
signal drop_rolled(payload: Dictionary)
# payload: slot_type (String), set_id (String — empty for no-set), tier (int)

# Test-only: force every canvas to drop. False in production.
var force_drop: bool = false

# Atelier-level provided by GameState; -1 means no atelier yet (drop tier always 1).
var atelier_level: int = 0

const SLOT_TYPES: Array = ["brush", "palette_item", "chapeau", "blouse", "gants", "chevalet", "couteau", "broche"]
const SET_IDS:    Array = ["risque_tout", "maitre", "rendement", "erudit", "atelier_prolifique", "heritage"]

static func drop_chance(quality: float) -> float:
    return 0.05 + 0.001 * quality
```

In `_on_slot_finished`, after `canvas_completed.emit(...)`, before `_start_slot(c)`, add:

```gdscript
    var should_drop: bool = force_drop or randf() < drop_chance(final_q)
    if should_drop:
        var slot_type: String = SLOT_TYPES[randi() % SLOT_TYPES.size()]
        var set_id: String = ""  # placeholder set roll; full set-affiliation logic lives in Atelier plan.
        if randf() < 0.6:
            set_id = SET_IDS[randi() % SET_IDS.size()]
        var tier_drop: int = 1  # placeholder; atelier-level distribution lives in Atelier plan.
        drop_rolled.emit({
            "slot_type": slot_type,
            "set_id":    set_id,
            "tier":      tier_drop,
        })
```

Note: this Canvas plan emits the drop event but uses placeholder weights for set affiliation (60% set vs 40% no-set, uniform across 6 sets) and tier 1 only. The Atelier plan replaces the set-affiliation roll with the §11.2-11.4 logic and the tier roll with the §9.2 distribution.

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/CanvasSlots.gd test/test_canvas_drop.gd
git commit -m "CanvasSlots: drop_rolled event with placeholder set/tier"
```

---

### Task 14: Wire CanvasSlots into GameState; replace single canvas

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Modify: existing `test_gamestate_*` files: search for any reference to `gamestate.canvas` and update.

- [ ] **Step 1: Discover gamestate.canvas references**

Run a grep before editing:

```bash
grep -rn "\.canvas\." test/ scripts/
```

Expected hits in: `Ascend.gd` (sets `ascend.canvas = canvas`), `test_gamestate_*` (calls `gs.canvas.tier`, `gs.canvas.tick`, `gs.canvas.sell`).

- [ ] **Step 2: Replace `canvas: CanvasClass` with `slots: CanvasSlotsClass`**

Edit `GameState.gd`. Add preload near top:

```gdscript
const CanvasSlotsClass = preload("res://scripts/systems/CanvasSlots.gd")
```

Remove `var canvas: CanvasClass`. Add:

```gdscript
var slots: CanvasSlotsClass
```

In `_ready()`, replace the existing `canvas = CanvasClass.new(); add_child(canvas)` block with:

```gdscript
	slots = CanvasSlotsClass.new()
	slots.name = "CanvasSlots"
	slots.config = canvas_config
	slots.mastery = subject_mastery
	slots.tier_provider = func(): return _current_canvas_tier()
	slots.set_slot_count(1)
	add_child(slots)
```

Add helper:

```gdscript
var _canvas_tier: int = 1

func _current_canvas_tier() -> int:
    return _canvas_tier

func upgrade_canvas_tier() -> void:
    if _canvas_tier < CanvasTiers.MAX_TIER:
        _canvas_tier += 1
```

Remove the `canvas.sold.connect(_on_canvas_sold)` line. Replace `_on_canvas_sold` with `_on_canvas_completed`:

```gdscript
func _on_canvas_completed(payload: Dictionary) -> void:
    var tier: int = int(payload["tier"])
    var quality: float = float(payload["quality"])
    var subject_id: String = String(payload["subject_id"])
    var gold_value: float = Balance.canvas_gold(quality, tier, canvas_gold_multiplier())
    currency.add("gold", BigNumber.from_float(gold_value))
    var pm_base: int = Balance.canvas_pm_base(quality)
    if pm_base > 0:
        paint_mastery.on_canvas_sold(tier, BigNumber.from_float(gold_value))
    # Mastery gain to current subject.
    var mastery_gain: int = 1 + int(quality / 20.0)
    subject_mastery.gain(subject_id, mastery_gain)
    canvas_sold.emit(tier, gold_value)
```

Connect in `_ready()`:

```gdscript
	slots.canvas_completed.connect(_on_canvas_completed)
```

Update `tick(delta)` to fan out to `slots`:

```gdscript
func tick(delta: float) -> void:
    tree.tick(delta)
    slots.canvas_speed_mult = canvas_speed_multiplier()
    slots.tick(delta)
```

Update `save_game()` payload: replace `"canvas": canvas.serialize()` with:

```gdscript
		"canvas_tier":  _canvas_tier,
```

Update `load_game()`: replace `if data.has("canvas"): canvas.deserialize(...)` with:

```gdscript
	_canvas_tier = int(data.get("canvas_tier", 1))
```

Update Ascend wiring: in the existing `ascend.canvas = canvas` line — Ascend uses canvas only for `reset()`. Replace by storing a callback:

```gdscript
	ascend.on_reset = func(): _canvas_tier = 1; canvas_config.reset()
```

(Ascend.gd needs a corresponding `on_reset: Callable` member that it calls during ascend reset; if Ascend currently calls `canvas.reset()`, replace that line with `if on_reset.is_valid(): on_reset.call()`.)

- [ ] **Step 3: Update Ascend.gd**

Edit `scripts/systems/Ascend.gd`:

Find the `var canvas` member (likely typed as `Canvas`). Remove. Add:

```gdscript
var on_reset: Callable = Callable()
```

In whichever method does the ascend reset (likely `ascend()`), replace `canvas.reset()` with:

```gdscript
    if on_reset.is_valid():
        on_reset.call()
```

- [ ] **Step 4: Update GameState/Ascend tests**

In `test/test_gamestate*` and `test/test_ascend.gd`, find any reference to `gs.canvas` or `canvas.tier`/`canvas.sell()`/`canvas.tick()` and update:

- `gs.canvas.tier` → `gs._canvas_tier` (or expose via `gs.current_canvas_tier()`)
- `gs.canvas.tick(...)` → `gs.tick(...)`
- `gs.canvas.sell()` → use `gs.slots.paint_time_override = 0.001; gs.tick(0.01)` to force a finish
- Tests that assert on the `canvas_sold` signal stay (signal is preserved)

For `test_ascend.gd`: any reference to canvas reset behavior should now stub `on_reset` or assert via `gs._canvas_tier == 1` after ascend.

(This task may take longer — work each failing test individually until 156 → 156 again.)

- [ ] **Step 5: Run all tests, verify pass count restored**

Editor → GUT → Run All. Target: 156 + new (subjects/mastery/config/formulas/canvas/slots/drop) all pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/autoloads/GameState.gd scripts/systems/Ascend.gd test/
git commit -m "GameState: replace single Canvas with CanvasSlots"
```

---

## Phase D — Skill tree Canvas branch

### Task 15: SkillTreeNodes — add 17 Canvas branch entries

**Files:**
- Modify: `scripts/config/SkillTreeNodes.gd`
- Create: `test/test_skill_tree_canvas_branch.gd`

- [ ] **Step 1: Write failing tests**

```gdscript
extends GutTest

func test_chef_doeuvre_unlock_node_exists():
    var n = SkillTreeNodes.get_node("chef_doeuvre_unlock")
    assert_false(n.is_empty())
    assert_eq(int(n["cost"]), 10)
    assert_eq(float(n["effects"].get("chef_doeuvre_unlocked", 0.0)), 1.0)

func test_style_ceiling_chain_exists():
    for id in ["style_cap_1", "style_cap_2", "style_cap_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_palette_ceiling_chain_exists():
    for id in ["palette_cap_1", "palette_cap_2", "palette_cap_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_multi_canvas_slots_exist():
    for id in ["multi_canvas_1", "multi_canvas_2", "multi_canvas_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_total_canvas_branch_count_17():
    var ids = SkillTreeNodes.all_node_ids()
    var canvas_branch = []
    for id in ids:
        var n = SkillTreeNodes.get_node(id)
        if n.get("branch", "") == "canvas":
            canvas_branch.append(id)
    assert_eq(canvas_branch.size(), 17)

func test_canvas_branch_costs_total_in_range():
    # Sanity: 5+15+40 (×2 for style+palette) + 10 + 15+30 + 50+150+400 + 25 + 15 + 20+60 + 75 = 935
    var total: float = 0.0
    for id in SkillTreeNodes.all_node_ids():
        var n = SkillTreeNodes.get_node(id)
        if n.get("branch", "") == "canvas":
            total += float(n["cost"])
    assert_eq(total, 935.0)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add 17 entries to SkillTreeNodes.NODES**

Add to the `NODES` dictionary (preserve existing 5 entries):

```gdscript
    # -- Canvas branch (spec 2026-04-25-canvas-design §9) --
    "chef_doeuvre_unlock": {
        "name":    "Chef d'œuvre",
        "cost":    10.0,
        "branch":  "canvas",
        "effects": {"chef_doeuvre_unlocked": 1.0},
    },
    "style_cap_1": {
        "name":    "Plafond de style I",
        "cost":    5.0,
        "branch":  "canvas",
        "prereq":  [],
        "effects": {"style_cap_add": 5.0},
    },
    "style_cap_2": {
        "name":    "Plafond de style II",
        "cost":    15.0,
        "branch":  "canvas",
        "prereq":  ["style_cap_1"],
        "effects": {"style_cap_add": 5.0},
    },
    "style_cap_3": {
        "name":    "Plafond de style III",
        "cost":    40.0,
        "branch":  "canvas",
        "prereq":  ["style_cap_2"],
        "effects": {"style_cap_add": 5.0},
    },
    "palette_cap_1": {
        "name":    "Plafond de palette I",
        "cost":    5.0,
        "branch":  "canvas",
        "prereq":  [],
        "effects": {"palette_cap_add": 5.0},
    },
    "palette_cap_2": {
        "name":    "Plafond de palette II",
        "cost":    15.0,
        "branch":  "canvas",
        "prereq":  ["palette_cap_1"],
        "effects": {"palette_cap_add": 5.0},
    },
    "palette_cap_3": {
        "name":    "Plafond de palette III",
        "cost":    40.0,
        "branch":  "canvas",
        "prereq":  ["palette_cap_2"],
        "effects": {"palette_cap_add": 5.0},
    },
    "subject_hint_1": {
        "name":    "Indice de sujet I",
        "cost":    15.0,
        "branch":  "canvas",
        "effects": {"subject_hint_add": 1.0},
    },
    "subject_hint_2": {
        "name":    "Indice de sujet II",
        "cost":    30.0,
        "branch":  "canvas",
        "prereq":  ["subject_hint_1"],
        "effects": {"subject_hint_add": 1.0},
    },
    "multi_canvas_1": {
        "name":    "Toile parallèle I",
        "cost":    50.0,
        "branch":  "canvas",
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "multi_canvas_2": {
        "name":    "Toile parallèle II",
        "cost":    150.0,
        "branch":  "canvas",
        "prereq":  ["multi_canvas_1"],
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "multi_canvas_3": {
        "name":    "Toile parallèle III",
        "cost":    400.0,
        "branch":  "canvas",
        "prereq":  ["multi_canvas_2"],
        "effects": {"multi_canvas_slots_add": 1.0},
    },
    "gamble_safety_net": {
        "name":    "Filet du gambleur",
        "cost":    25.0,
        "branch":  "canvas",
        "effects": {"gamble_safety_net": 1.0},
    },
    "always_gamble_toggle": {
        "name":    "Mise automatique",
        "cost":    15.0,
        "branch":  "canvas",
        "effects": {"always_gamble_unlocked": 1.0},
    },
    "quality_floor_1": {
        "name":    "Seuil de qualité I",
        "cost":    20.0,
        "branch":  "canvas",
        "effects": {"quality_floor_add": 2.0},
    },
    "quality_floor_2": {
        "name":    "Seuil de qualité II",
        "cost":    60.0,
        "branch":  "canvas",
        "prereq":  ["quality_floor_1"],
        "effects": {"quality_floor_add": 2.0},
    },
    "auto_mastery_passive": {
        "name":    "Maîtrise passive",
        "cost":    75.0,
        "branch":  "canvas",
        "prereq":  ["subject_hint_2"],
        "effects": {"auto_mastery_rate": 0.25},
    },
```

Mark existing 5 MVP nodes with `"branch": "mvp"` for symmetry (so the test for canvas-branch count is unambiguous):

```gdscript
    "gilded_frame": { ... existing ..., "branch": "mvp" },
    # repeat for quick_strokes, master_palette, tireless_hand, golden_touch
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/config/SkillTreeNodes.gd test/test_skill_tree_canvas_branch.gd
git commit -m "SkillTreeNodes: 17 Canvas branch entries"
```

---

### Task 16: SkillTree — prereq enforcement

**Files:**
- Modify: `scripts/systems/SkillTree.gd`
- Modify: `test/test_skill_tree.gd`

- [ ] **Step 1: Add failing tests** to `test/test_skill_tree.gd`

```gdscript
func test_unlock_blocked_when_prereq_unmet():
    # style_cap_2 requires style_cap_1
    skill_tree.currency.add("fame", BigNumber.from_float(50.0))
    assert_false(skill_tree.unlock("style_cap_2"))

func test_unlock_succeeds_when_prereq_met():
    skill_tree.currency.add("fame", BigNumber.from_float(50.0))
    assert_true(skill_tree.unlock("style_cap_1"))
    assert_true(skill_tree.unlock("style_cap_2"))
```

(Test setup pattern follows the existing `test_skill_tree.gd` conventions — instantiate Currency + SkillTree.)

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Enforce prereq in `unlock()`**

Edit `scripts/systems/SkillTree.gd`. Replace `unlock()` body:

```gdscript
func unlock(node_id: String) -> bool:
    if currency == null:
        return false
    if unlocked_nodes.has(node_id):
        return false
    var node = SkillTreeNodes.get_node(node_id)
    if node.is_empty():
        return false
    for required in node.get("prereq", []):
        if not unlocked_nodes.has(required):
            return false
    var cost = BigNumber.from_float(float(node["cost"]))
    if not currency.spend("fame", cost):
        return false
    unlocked_nodes[node_id] = true
    node_unlocked.emit(node_id)
    return true
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/SkillTree.gd test/test_skill_tree.gd
git commit -m "SkillTree: enforce prereq nodes"
```

---

### Task 17: SkillTree — Canvas branch aggregators

**Files:**
- Modify: `scripts/systems/SkillTree.gd`
- Modify: `test/test_skill_tree.gd`

- [ ] **Step 1: Add failing tests**

```gdscript
func test_style_cap_aggregates_across_chain():
    skill_tree.currency.add("fame", BigNumber.from_float(100.0))
    skill_tree.unlock("style_cap_1")
    assert_eq(skill_tree.style_cap(), 15)
    skill_tree.unlock("style_cap_2")
    assert_eq(skill_tree.style_cap(), 20)

func test_multi_canvas_slots_aggregates():
    skill_tree.currency.add("fame", BigNumber.from_float(700.0))
    skill_tree.unlock("multi_canvas_1")
    assert_eq(skill_tree.multi_canvas_slots_grant(), 1)
    skill_tree.unlock("multi_canvas_2")
    assert_eq(skill_tree.multi_canvas_slots_grant(), 2)

func test_chef_doeuvre_unlocked_flag():
    assert_false(skill_tree.chef_doeuvre_unlocked())
    skill_tree.currency.add("fame", BigNumber.from_float(20.0))
    skill_tree.unlock("chef_doeuvre_unlock")
    assert_true(skill_tree.chef_doeuvre_unlocked())

func test_quality_floor_bonus_aggregates():
    skill_tree.currency.add("fame", BigNumber.from_float(100.0))
    skill_tree.unlock("quality_floor_1")
    assert_eq(skill_tree.quality_floor_bonus(), 2.0)
    skill_tree.unlock("quality_floor_2")
    assert_eq(skill_tree.quality_floor_bonus(), 4.0)

func test_subject_hint_count_aggregates():
    skill_tree.currency.add("fame", BigNumber.from_float(50.0))
    skill_tree.unlock("subject_hint_1")
    assert_eq(skill_tree.subject_hint_count(), 1)
    skill_tree.unlock("subject_hint_2")
    assert_eq(skill_tree.subject_hint_count(), 2)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add 9 aggregator methods to `SkillTree.gd`**

Append:

```gdscript
const STYLE_CAP_BASELINE: int = 10
const PALETTE_CAP_BASELINE: int = 10

func style_cap() -> int:
    return STYLE_CAP_BASELINE + int(_sum_effect("style_cap_add"))

func palette_cap() -> int:
    return PALETTE_CAP_BASELINE + int(_sum_effect("palette_cap_add"))

func multi_canvas_slots_grant() -> int:
    return int(_sum_effect("multi_canvas_slots_add"))

func quality_floor_bonus() -> float:
    return _sum_effect("quality_floor_add")

func subject_hint_count() -> int:
    return int(_sum_effect("subject_hint_add"))

func chef_doeuvre_unlocked() -> bool:
    return _sum_effect("chef_doeuvre_unlocked") > 0.0

func always_gamble_unlocked() -> bool:
    return _sum_effect("always_gamble_unlocked") > 0.0

func gamble_safety_net() -> bool:
    return _sum_effect("gamble_safety_net") > 0.0

func auto_mastery_rate() -> float:
    return _sum_effect("auto_mastery_rate")
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/SkillTree.gd test/test_skill_tree.gd
git commit -m "SkillTree: 9 Canvas branch aggregators"
```

---

### Task 18: GameState — wire skill tree aggregators into CanvasSlots tick

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Modify: `test/test_gamestate_canvas_loop.gd` (create)

- [ ] **Step 1: Create integration test**

```gdscript
extends GutTest

const GameStateClass = preload("res://scripts/autoloads/GameState.gd")

var gs: Node

func before_each():
    gs = GameStateClass.new()
    add_child_autofree(gs)

func test_canvas_slot_count_increases_when_multi_canvas_unlocked():
    # Player unlocks multi_canvas_1: slot count goes from 1 → 2
    gs.currency.add("fame", BigNumber.from_float(60.0))
    gs.skill_tree.unlock("multi_canvas_1")
    gs.refresh_canvas_slot_count()
    assert_eq(gs.slots.slot_count(), 2)

func test_quality_floor_propagates_to_slots_on_tick():
    gs.currency.add("fame", BigNumber.from_float(20.0))
    gs.skill_tree.unlock("quality_floor_1")
    gs.tick(0.0)
    assert_eq(gs.slots.quality_floor_bonus, 2.0)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add slot-count refresh + multiplier propagation in GameState**

Add to `GameState.gd`:

```gdscript
func refresh_canvas_slot_count() -> void:
    var n: int = 1 + skill_tree.multi_canvas_slots_grant() + painter_office.worker_count()
    n = clamp(n, 1, 8)  # spec §12 soft cap
    slots.set_slot_count(n)
```

Update `tick(delta)` to push aggregators into slots before tick:

```gdscript
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
```

(Note: the `inventory.has_method` checks are temporary — the Atelier plan replaces Inventory and provides these methods. Keep MVP Inventory.gd compatible by leaving the methods undefined; the `has_method` guard returns the safe default.)

Also add to `_ready()`, after the existing `add_child(slots)` block, an initial slot-count call:

```gdscript
	refresh_canvas_slot_count()
```

And connect skill tree unlocks + painter office worker changes to refresh:

```gdscript
	skill_tree.node_unlocked.connect(func(_id): refresh_canvas_slot_count())
	# If PainterOffice exposes a signal for worker_count changes, wire it here.
	# Otherwise, refresh_canvas_slot_count() is also safe to call after each Painter Office hire.
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_gamestate_canvas_loop.gd
git commit -m "GameState: aggregate skill tree into CanvasSlots tick"
```

---

## Phase E — Improvement panel + ceilings

### Task 19: CanvasConfig — improvement-tab ceiling buys with cost curve

**Files:**
- Modify: `scripts/systems/CanvasConfig.gd`
- Modify: `test/test_canvas_config.gd`

- [ ] **Step 1: Add failing tests**

```gdscript
func test_style_ceiling_buy_cost_curve():
    # spec §10: cost = 100 * 3^(level-1) for the +1 from current level
    assert_eq(CanvasConfig.style_ceiling_cost(1), 100.0)   # 1 → 2 costs 100
    assert_eq(CanvasConfig.style_ceiling_cost(2), 300.0)
    assert_eq(CanvasConfig.style_ceiling_cost(5), 8100.0)

func test_palette_ceiling_cost_curve_same():
    assert_eq(CanvasConfig.palette_ceiling_cost(3), 900.0)

func test_subject_hint_cost_curve():
    # spec §10: 1000 * 2^(reveals_used)
    assert_eq(CanvasConfig.subject_hint_cost(0), 1000.0)
    assert_eq(CanvasConfig.subject_hint_cost(2), 4000.0)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add static cost methods to `CanvasConfig.gd`**

```gdscript
static func style_ceiling_cost(current_level: int) -> float:
    return 100.0 * pow(3.0, float(current_level - 1))

static func palette_ceiling_cost(current_level: int) -> float:
    return 100.0 * pow(3.0, float(current_level - 1))

static func subject_hint_cost(reveals_used: int) -> float:
    return 1000.0 * pow(2.0, float(reveals_used))
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/CanvasConfig.gd test/test_canvas_config.gd
git commit -m "CanvasConfig: improvement-tab cost curves"
```

---

### Task 20: GameState — buy_style_ceiling / buy_palette_ceiling actions

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Modify: `test/test_gamestate_canvas_loop.gd`

- [ ] **Step 1: Add failing tests**

```gdscript
func test_buy_style_ceiling_costs_gold_and_increments():
    gs.currency.add("gold", BigNumber.from_float(500.0))
    assert_true(gs.buy_style_ceiling())
    assert_eq(gs.canvas_config.style_current_ceiling, 2)
    # Spent 100 g → 400 g remaining
    assert_almost_eq(gs.currency.balance("gold").value, 400.0, 0.01)

func test_buy_style_ceiling_blocked_when_insufficient_gold():
    assert_false(gs.buy_style_ceiling())
    assert_eq(gs.canvas_config.style_current_ceiling, 1)

func test_buy_style_ceiling_blocked_at_skill_cap():
    gs.currency.add("gold", BigNumber.from_float(100_000_000.0))
    # Buy until skill cap (10 default)
    while gs.canvas_config.style_current_ceiling < 10:
        assert_true(gs.buy_style_ceiling())
    assert_false(gs.buy_style_ceiling())
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Implement in `GameState.gd`**

```gdscript
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
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_gamestate_canvas_loop.gd
git commit -m "GameState: buy_style/palette_ceiling gold sinks"
```

---

### Task 21: GameState — gamble inspiration spend on canvas-start

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Modify: `scripts/systems/CanvasSlots.gd` — emit a "starting" signal we can hook
- Modify: `test/test_gamestate_canvas_loop.gd`

- [ ] **Step 1: Failing test**

```gdscript
func test_gamble_spends_inspiration_on_canvas_start():
    gs.currency.add("inspiration", BigNumber.from_float(50.0))
    gs.canvas_config.set_gamble(10)
    # Force a fast canvas to fire the start.
    gs.slots.paint_time_override = 0.001
    gs.tick(0.01)
    # After one canvas, 10 inspiration consumed.
    assert_almost_eq(gs.currency.balance("inspiration").value, 40.0, 0.01)

func test_gamble_silently_skipped_when_insufficient_inspiration():
    gs.canvas_config.set_gamble(100)
    gs.slots.paint_time_override = 0.001
    gs.tick(0.01)
    # No spend (would have gone negative); canvas still ran without gamble.
    assert_almost_eq(gs.currency.balance("inspiration").value, 0.0, 0.01)
```

- [ ] **Step 2: Run, verify fail**

- [ ] **Step 3: Add canvas_starting signal to CanvasSlots; wire spend in GameState**

In `CanvasSlots.gd`, add:

```gdscript
signal canvas_starting(slot_index: int)
```

In `_start_slot`, before `c.start(...)`:

```gdscript
    var idx: int = _slots.find(c)
    canvas_starting.emit(idx)
```

In `GameState._ready()`, after `slots.canvas_completed.connect(...)`:

```gdscript
	slots.canvas_starting.connect(_on_canvas_starting)
```

Add handler:

```gdscript
func _on_canvas_starting(_idx: int) -> void:
    var n: int = canvas_config.gamble_n_inspi
    if n <= 0:
        return
    var cost: BigNumber = BigNumber.from_float(float(n))
    if currency.balance("inspiration").value < float(n):
        # Silent skip — canvas runs without gamble. Toggle ephemeral flag for slots:
        slots.set_meta("gamble_skipped", true)
        return
    currency.spend("inspiration", cost)
    slots.set_meta("gamble_skipped", false)
```

In `CanvasSlots._on_slot_finished`, modify the gamble check:

```gdscript
    var skipped: bool = bool(get_meta("gamble_skipped", false))
    if config != null and config.gamble_n_inspi > 0 and not skipped:
        gambled = true
        ...
```

- [ ] **Step 4: Run, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/CanvasSlots.gd scripts/autoloads/GameState.gd test/test_gamestate_canvas_loop.gd
git commit -m "GameState: spend inspiration on gamble canvas start"
```

---

## Phase F — UI

### Task 22: CanvasSlotCard widget

**Files:**
- Create: `scripts/ui/widgets/CanvasSlotCard.gd`
- Create: `Scenes/widgets/CanvasSlotCard.tscn` (Godot editor)
- Existing scene location: confirm via `Scenes/` (use `Scenes/widgets/` if it exists; else create alongside CurrencyDisplay).

- [ ] **Step 1: Create scene**

In Godot editor: New Scene → root: `PanelContainer` → child `VBoxContainer`:
- `Label` (name: `SubjectLabel`) — shows current subject + tier
- `ProgressBar` (name: `Progress`) — 0..1
- `Label` (name: `QualityLabel`) — "Q: 18.0"

Save as `Scenes/widgets/CanvasSlotCard.tscn`. Attach `scripts/ui/widgets/CanvasSlotCard.gd` to root.

- [ ] **Step 2: Implement script**

```gdscript
class_name CanvasSlotCard
extends PanelContainer

@onready var _subject_label: Label = $VBoxContainer/SubjectLabel
@onready var _progress: ProgressBar = $VBoxContainer/Progress
@onready var _quality_label: Label = $VBoxContainer/QualityLabel

var slot_index: int = -1
var canvas: Canvas = null

func bind(idx: int, c: Canvas) -> void:
    slot_index = idx
    canvas = c

func _process(_delta: float) -> void:
    if canvas == null:
        return
    if canvas.paint_time > 0.0:
        _progress.value = canvas.progress_seconds / canvas.paint_time
    else:
        _progress.value = 0.0
    _quality_label.text = "Q: %.1f" % canvas.quality
    var subject_id: String = String(canvas.get_meta("subject_id", "—"))
    var subject_name: String = String(Subjects.get_subject(subject_id).get("name", subject_id))
    _subject_label.text = "%s • Tier %d" % [subject_name, int(canvas.get_meta("tier", 1))]
```

- [ ] **Step 3: No unit test for this widget** — verify visually. Document in commit message.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/widgets/CanvasSlotCard.gd Scenes/widgets/CanvasSlotCard.tscn
git commit -m "CanvasSlotCard widget: per-slot progress card"
```

---

### Task 23: DropFeed widget

**Files:**
- Create: `scripts/ui/widgets/DropFeed.gd`
- Create: `Scenes/widgets/DropFeed.tscn`

- [ ] **Step 1: Create scene**

Root: `HBoxContainer` (name: `DropFeed`). Children added at runtime.

Attach `scripts/ui/widgets/DropFeed.gd`.

- [ ] **Step 2: Implement script**

```gdscript
class_name DropFeed
extends HBoxContainer

const MAX_DROPS: int = 5

func add_drop(payload: Dictionary) -> void:
    var label := Label.new()
    var slot: String = String(payload.get("slot_type", "?"))
    var set_id: String = String(payload.get("set_id", ""))
    var tier: int = int(payload.get("tier", 1))
    label.text = "%s/T%d%s" % [slot.substr(0, 3), tier, " " + set_id.substr(0, 3) if set_id != "" else ""]
    add_child(label)
    while get_child_count() > MAX_DROPS:
        var oldest := get_child(0)
        remove_child(oldest)
        oldest.queue_free()
```

- [ ] **Step 3: Commit**

```bash
git add scripts/ui/widgets/DropFeed.gd Scenes/widgets/DropFeed.tscn
git commit -m "DropFeed widget: last 5 canvas drops"
```

---

### Task 24: PaintingView rebuild — slot list + drop feed

**Files:**
- Modify: `scripts/ui/views/PaintingView.gd`
- Modify: `Scenes/views/PaintingView.tscn`

- [ ] **Step 1: Rebuild scene**

In Godot editor: open `Scenes/views/PaintingView.tscn`. Replace existing single-canvas progress UI with:

- `VBoxContainer` (root content)
  - `VBoxContainer` (name: `SlotList`) — hosts CanvasSlotCard instances
  - `DropFeed` (name: `Drops`)
  - `HBoxContainer` (name: `PopupRow`) — keep existing 4 popup buttons

Save scene.

- [ ] **Step 2: Update PaintingView.gd**

Replace existing script body:

```gdscript
class_name PaintingView
extends BaseView

const CanvasSlotCardScene = preload("res://Scenes/widgets/CanvasSlotCard.tscn")

@onready var _slot_list: VBoxContainer = $VBoxContainer/SlotList
@onready var _drops: DropFeed = $VBoxContainer/Drops

var _cards: Array = []

func _initialize_view() -> void:
    pass

func _connect_view_signals() -> void:
    GameState.slots.tree_entered.connect(_refresh_cards)  # safety: when slot count changes
    GameState.slots.drop_rolled.connect(_drops.add_drop)
    GameState.skill_tree.node_unlocked.connect(_on_skill_node_unlocked)

func _initialize_ui() -> void:
    _refresh_cards()

func _on_skill_node_unlocked(_id: String) -> void:
    _refresh_cards()

func _refresh_cards() -> void:
    for card in _cards:
        (card as Node).queue_free()
    _cards.clear()
    for i in GameState.slots.slot_count():
        var card := CanvasSlotCardScene.instantiate() as CanvasSlotCard
        card.bind(i, GameState.slots.get_canvas(i))
        _slot_list.add_child(card)
        _cards.append(card)
```

- [ ] **Step 3: Manual smoke test**

Open project in Godot → F5 → Peinture view. Expected: 1 slot card visible, progress bar fills, subject + tier shown, drop feed populates as drops occur.

- [ ] **Step 4: Run all tests, verify 156 + new still pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/views/PaintingView.gd Scenes/views/PaintingView.tscn
git commit -m "PaintingView: slot list + drop feed"
```

---

### Task 25: CanvasPopup rebuild — Configuration tab

**Files:**
- Modify: `scripts/ui/popups/CanvasPopup.gd`
- Modify: `Scenes/popups/CanvasPopup.tscn`

- [ ] **Step 1: Rebuild scene**

Root: `Window` or existing `Popup` type. Add `TabContainer` named `Tabs`. Add child tabs:

- `Configuration` (Control) — children:
  - `HSlider` (name: `StyleSlider`) min=1, max=skill_cap, step=1
  - `Label` (name: `StyleLabel`)
  - `HSlider` (name: `PaletteSlider`) min=1, max=skill_cap, step=1
  - `Label` (name: `PaletteLabel`)
  - `OptionButton` (name: `SubjectPicker`) — populated at runtime from unlocked subjects
  - `OptionButton` (name: `GambleLevel`) — items: Off / 10 / 100 / 1000 / 10000
- `Improvement` (Control) — populated in Task 26.

Save scene.

- [ ] **Step 2: Update CanvasPopup.gd Configuration logic**

```gdscript
class_name CanvasPopup
extends Window

@onready var _style_slider: HSlider = $Tabs/Configuration/StyleSlider
@onready var _style_label: Label = $Tabs/Configuration/StyleLabel
@onready var _palette_slider: HSlider = $Tabs/Configuration/PaletteSlider
@onready var _palette_label: Label = $Tabs/Configuration/PaletteLabel
@onready var _subject_picker: OptionButton = $Tabs/Configuration/SubjectPicker
@onready var _gamble_level: OptionButton = $Tabs/Configuration/GambleLevel

const GAMBLE_LEVELS: Array = [0, 10, 100, 1000, 10000]
const GAMBLE_LABELS: Array = ["Off", "10", "100", "1k", "10k"]

func _ready() -> void:
    _gamble_level.clear()
    for label in GAMBLE_LABELS:
        _gamble_level.add_item(label)
    _refresh_from_state()
    _style_slider.value_changed.connect(_on_style_changed)
    _palette_slider.value_changed.connect(_on_palette_changed)
    _subject_picker.item_selected.connect(_on_subject_changed)
    _gamble_level.item_selected.connect(_on_gamble_changed)

func _refresh_from_state() -> void:
    var cfg: CanvasConfig = GameState.canvas_config
    _style_slider.max_value = cfg.style_current_ceiling
    _style_slider.value = cfg.style
    _style_label.text = "Style: %d / %d (cap %d)" % [cfg.style, cfg.style_current_ceiling, GameState.skill_tree.style_cap()]
    _palette_slider.max_value = cfg.palette_current_ceiling
    _palette_slider.value = cfg.palette
    _palette_label.text = "Palette: %d / %d (cap %d)" % [cfg.palette, cfg.palette_current_ceiling, GameState.skill_tree.palette_cap()]
    _subject_picker.clear()
    for sid in Subjects.all_ids():
        var name: String = Subjects.get_subject(sid)["name"]
        if GameState.subject_mastery.is_unlocked(sid):
            _subject_picker.add_item(name, _subject_picker.item_count)
            _subject_picker.set_item_metadata(_subject_picker.item_count - 1, sid)
            if sid == cfg.current_subject:
                _subject_picker.selected = _subject_picker.item_count - 1
        elif GameState.subject_mastery.has_hint(sid):
            _subject_picker.add_item("? (%s)" % _hint_text_for(sid))
            _subject_picker.set_item_disabled(_subject_picker.item_count - 1, true)
    _gamble_level.selected = GAMBLE_LEVELS.find(cfg.gamble_n_inspi)

func _hint_text_for(sid: String) -> String:
    var s = Subjects.get_subject(sid)
    var revealed_edges: Array = []
    for p in (s["parents"] as Array):
        if GameState.subject_mastery.tier_of(p["subject_id"]) >= SubjectMastery.HINT_HALF_TIER:
            revealed_edges.append(Subjects.get_subject(p["subject_id"])["name"])
    return ", ".join(revealed_edges)

func _on_style_changed(v: float) -> void:
    GameState.canvas_config.set_style(int(v))
    _refresh_from_state()

func _on_palette_changed(v: float) -> void:
    GameState.canvas_config.set_palette(int(v))
    _refresh_from_state()

func _on_subject_changed(idx: int) -> void:
    var sid: String = String(_subject_picker.get_item_metadata(idx))
    if sid != "":
        GameState.canvas_config.set_subject(sid)

func _on_gamble_changed(idx: int) -> void:
    GameState.canvas_config.set_gamble(GAMBLE_LEVELS[idx])
```

- [ ] **Step 3: Manual smoke test**

Open in Godot → open Peinture → Canvas popup → verify sliders, subject picker, gamble dropdown work.

- [ ] **Step 4: Run all tests, verify pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/popups/CanvasPopup.gd Scenes/popups/CanvasPopup.tscn
git commit -m "CanvasPopup: Configuration tab"
```

---

### Task 26: CanvasPopup — Improvement tab

**Files:**
- Modify: `scripts/ui/popups/CanvasPopup.gd`
- Modify: `Scenes/popups/CanvasPopup.tscn`

- [ ] **Step 1: Add Improvement tab UI**

Inside the `Improvement` Control, add `VBoxContainer`:
- `Button` (name: `BuyStyle`) — text dynamic
- `Button` (name: `BuyPalette`) — text dynamic
- `Button` (name: `RevealHint`) — text dynamic
- `Label` (name: `Hints`) — instructions

Save scene.

- [ ] **Step 2: Append wiring to CanvasPopup.gd**

```gdscript
@onready var _buy_style: Button = $Tabs/Improvement/VBoxContainer/BuyStyle
@onready var _buy_palette: Button = $Tabs/Improvement/VBoxContainer/BuyPalette
@onready var _reveal_hint: Button = $Tabs/Improvement/VBoxContainer/RevealHint

func _ready_improvement() -> void:
    _buy_style.pressed.connect(func():
        GameState.buy_style_ceiling()
        _refresh_improvement()
    )
    _buy_palette.pressed.connect(func():
        GameState.buy_palette_ceiling()
        _refresh_improvement()
    )
    _refresh_improvement()

func _refresh_improvement() -> void:
    var cfg: CanvasConfig = GameState.canvas_config
    _buy_style.text = "Style ceiling +1 (%.0f g)" % CanvasConfig.style_ceiling_cost(cfg.style_current_ceiling)
    _buy_style.disabled = cfg.style_current_ceiling >= GameState.skill_tree.style_cap()
    _buy_palette.text = "Palette ceiling +1 (%.0f g)" % CanvasConfig.palette_ceiling_cost(cfg.palette_current_ceiling)
    _buy_palette.disabled = cfg.palette_current_ceiling >= GameState.skill_tree.palette_cap()
```

Add `_ready_improvement()` to existing `_ready()` and call `_refresh_improvement()` from the action handlers in Task 25.

- [ ] **Step 3: Manual smoke test**

Open in Godot → Improvement tab → click Buy Style → verify ceiling rises and gold drops.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/popups/CanvasPopup.gd Scenes/popups/CanvasPopup.tscn
git commit -m "CanvasPopup: Improvement tab"
```

---

### Task 27: Hover info wiring (Hoverable per info-panel spec §6)

**Files:**
- Modify: `Scenes/popups/CanvasPopup.tscn`
- Modify: `Scenes/views/PaintingView.tscn`
- Modify: `Scenes/widgets/CanvasSlotCard.tscn`

- [ ] **Step 1: Add `Hoverable` child nodes via Godot editor**

For each interactive Control listed below, add a `Hoverable` child (use existing `scripts/ui/widgets/Hoverable.gd`) and set its content provider via the inspector (or in code with `set_content_provider`).

Targets:
- `StyleSlider` — title: "Style", body: live "Current X / cap Y, +Z time, +Z quality", footer: ""
- `PaletteSlider` — similar for palette
- `SubjectPicker` — title: "Subject", body: "Mastery: tier X / 10. Quality bonus +X."
- `GambleLevel` — title: "Gamble", body: "Spend N inspiration. Success ~50%, ×Y quality. Failure halves quality."
- `BuyStyle` / `BuyPalette` / `RevealHint` — cost + effect breakdown
- Each `CanvasSlotCard` root — title: "Slot N", body: "Subject X, Tier Y, Quality Z, ETA Wt"

Use `Icons.gd` BBCode for currency tokens per info-panel spec §6.

- [ ] **Step 2: Manual smoke test**

Hover each element; verify InfoPanel updates. Confirm content includes numbers and live values (no narrative-only blurbs per spec §6).

- [ ] **Step 3: Commit**

```bash
git add Scenes/
git commit -m "Hoverable: wire CanvasPopup + PaintingView per info-panel §6"
```

---

## Phase G — Final integration

### Task 28: Save/load round-trip integration test

**Files:**
- Modify: `test/test_gamestate_canvas_loop.gd`

- [ ] **Step 1: Add failing test**

```gdscript
func test_save_load_roundtrip_preserves_canvas_state():
    gs.currency.add("fame", BigNumber.from_float(50.0))
    gs.skill_tree.unlock("style_cap_1")
    gs.canvas_config.style_current_ceiling = 5
    gs.canvas_config.set_style(3)
    gs.canvas_config.set_gamble(100)
    gs.subject_mastery.gain("nature", 250)  # tier 1 + leftover 50
    gs._canvas_tier = 4
    gs.save_game()

    var fresh = preload("res://scripts/autoloads/GameState.gd").new()
    add_child_autofree(fresh)
    assert_true(fresh.load_game())
    assert_eq(fresh.canvas_config.style, 3)
    assert_eq(fresh.canvas_config.style_current_ceiling, 5)
    assert_eq(fresh.canvas_config.gamble_n_inspi, 100)
    assert_eq(fresh.subject_mastery.tier_of("nature"), 1)
    assert_eq(fresh._canvas_tier, 4)
    assert_true(fresh.skill_tree.unlocked_nodes.has("style_cap_1"))
```

- [ ] **Step 2: Run, verify pass (no impl change expected — wiring already done in Task 10/14)**

If fail, debug missing serialize/deserialize fields.

- [ ] **Step 3: Commit**

```bash
git add test/test_gamestate_canvas_loop.gd
git commit -m "Tests: save/load roundtrip for canvas state"
```

---

### Task 29: End-to-end loop integration test

**Files:**
- Modify: `test/test_gamestate_canvas_loop.gd`

- [ ] **Step 1: Add failing test**

```gdscript
func test_full_canvas_loop_yields_gold_and_pm_and_mastery():
    # Spec §4 bootstrap loop: tier 1, style 1, palette 1, mastery 0 → quality 3 → 30 gold per canvas.
    gs.slots.paint_time_override = 0.001
    gs.tick(0.01)
    # 1 canvas finished
    assert_almost_eq(gs.currency.balance("gold").value, 30.0, 0.5)
    assert_eq(gs.subject_mastery.tier_of("nature"), 0)  # quality 3 → 1 gain → still tier 0
    assert_eq(gs.subject_mastery.xp_of("nature"), 1)

func test_chef_doeuvre_overrides_quality_when_proc():
    gs.currency.add("fame", BigNumber.from_float(20.0))
    gs.skill_tree.unlock("chef_doeuvre_unlock")
    gs.tick(0.0)  # propagate aggregators
    # Force chef_doeuvre_chance = 1.0 for determinism
    gs.slots.chef_doeuvre_chance = 1.0
    gs.slots.paint_time_override = 0.001
    gs.tick(0.01)
    # ideal_quality at tier 1 / cap 10 / cap 10 / mastery floor 0 = 1+10+10+10+0 = 31
    var observed_gold = gs.currency.balance("gold").value
    # gold = quality * tier * 10 = 31 * 1 * 10 = 310
    assert_almost_eq(observed_gold, 310.0, 1.0)
```

- [ ] **Step 2: Run, verify pass**

- [ ] **Step 3: Commit**

```bash
git add test/test_gamestate_canvas_loop.gd
git commit -m "Tests: end-to-end canvas loop + chef d'œuvre override"
```

---

### Task 30: Final regression sweep + spec definition-of-done check

- [ ] **Step 1: Run all tests, count passes**

Editor → GUT → Run All. Target: 156 prior + ~30 new = ~186 pass.

- [ ] **Step 2: Walk the spec §17 Definition of done and tick each box**

Open `docs/superpowers/specs/2026-04-25-canvas-design.md` §17. For each line:
- 17 skill tree Canvas branch nodes added to `SkillTreeNodes.gd` and rendered → Task 15 + (manual SkillTreeView verify)
- Style and palette sliders functional, capped by ceiling → Task 25
- Subject system: 20 subjects, prereq graph, hidden-until-half, `?` placeholders → Tasks 1, 2, 3, 4, 25
- Quality / chef d'œuvre / gold / PM / time formulas in `Balance.gd`, all 9 canvas-derived affixes → Tasks 5, 6, 7 + Task 18 (placeholder affix accessors)
- Drop system on canvas completion → Task 13
- Auto-sale state machine confirmed → Task 9
- Multi-canvas: N slots tick independently, each rolls drops, hard cap 8 → Task 12, 18
- Gamble: 5 sticky levels, success/fail formulas, safety net + always-gamble nodes → Tasks 8, 21, 15
- All formulas covered by GUT tests → Phases A–G
- Hover info wired → Task 27
- 156 prior tests still pass → Task 14, 30

- [ ] **Step 3: Update HANDOVER.md**

Append a section under "What's done" naming this Canvas implementation phase. Update "What's next" to point to the Atelier plan.

- [ ] **Step 4: Final commit**

```bash
git add docs/superpowers/HANDOVER.md
git commit -m "HANDOVER: Canvas implementation shipped"
```

---

## Self-review

**Spec coverage check:**

| Spec section | Covered by task |
|---|---|
| §3 Operating model — sticky config + auto-sale + multi-canvas + auto-max | T8, T9, T11, T14, T18 |
| §4 Dimensions exposed | T8 (config), T11 (formulas integration) |
| §5 Style + palette discrete sliders | T8, T17, T19, T20, T25 |
| §6 Quality / chef d'œuvre / gold / PM / time formulas | T5, T6, T7, T11, T29 |
| §7 Subject system (5 starters + 15 derived + mastery + hidden discovery) | T1, T2, T3, T4 |
| §8 Inspiration gamble (5 levels, success/fail, safety net + always-gamble) | T8, T21, T15 (skill tree nodes) |
| §9 Skill tree Canvas branch (17 nodes) | T15, T16, T17, T18 |
| §10 Improvement panel content + cost curves | T19, T20, T26 |
| §11 Items source — drops on canvas completion | T13, T18 |
| §12 Multi-canvas (slot sources, soft cap 8) | T11, T12, T18 |
| §13 Painting view layout | T22, T24, T25, T26 |
| §14 Affix pool (canvas-derived) | T18 (placeholder accessors via `inventory.has_method` guards) |
| §17 Definition of done | T30 |

**Gaps to flag during execution (not blockers):**
- §14 affix pool accessors (`inventory.style_time_reduction()` etc.) are placeholder `has_method` guards. The Atelier plan replaces Inventory.gd and provides the real methods. This plan does NOT extend Inventory — that would couple Canvas + Atelier.
- The set 4-piece bonuses (spec §11.5 of Atelier spec / §6 of Canvas spec) are not wired in this plan; canvas-spec proc references (creative streak, JACKPOT, révélation) belong to the Atelier plan since they require equipped sets.
- Set-targeting and tier distribution in drop rolls (spec §11.2-11.4) are placeholders here; Atelier plan implements the full logic.

**Placeholder scan:** None of the "TBD / TODO / fill in details / handle edge cases" anti-patterns are present. All `has_method` guards are explicitly justified above.

**Type consistency:** Canvas.start(paint_time, quality), CanvasSlots.canvas_completed(payload), CanvasSlots.drop_rolled(payload), CanvasSlots.canvas_starting(slot_index) — used consistently across all tasks.

---

## Execution choice

Plan complete and saved to `docs/superpowers/plans/2026-04-26-canvas-implementation.md`. Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, two-stage review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session via executing-plans, batch with checkpoints for review.

Which approach?
