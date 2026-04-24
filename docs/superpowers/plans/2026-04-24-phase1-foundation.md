# Artdle Rebuild — Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip the existing GDScript, install the test framework, and build the core primitives (`BigNumber`, `Formatter`, `Balance`), the `Currency` system, the `Save` system, and the `GameState` / `SceneManager` autoloads. All with unit tests that pass.

**Architecture:** Approach 3 (strip-down rebuild) per spec §13. Delete all existing `.gd` scripts and `.uid` files; keep `.tscn` layouts as visual references (their scripts are re-attached in Phase 4). Create the new folder structure under `scripts/` per spec §9. Build primitives first, then systems that depend on them.

**Tech Stack:** Godot 4.4, GDScript, GUT (Godot Unit Test) 9.x.

**Spec reference:** `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md` §3 (currencies), §9 (architecture), §10 (save), §12 (testing).

---

## Task 1: Install GUT (manual step)

**Files:**
- Create: `addons/gut/` (from Godot AssetLib)

- [ ] **Step 1: Install GUT via Godot AssetLib**

Open the Godot editor → AssetLib tab → search "Gut" → install "Gut - Godot Unit Testing" by bitwes. Install into `addons/gut/`.

- [ ] **Step 2: Enable plugin**

Project → Project Settings → Plugins → check GUT "Enable".

- [ ] **Step 3: Verify installation**

Run in bash: `ls addons/gut/` — expected: non-empty directory listing.

- [ ] **Step 4: Commit**

```bash
git add addons/ project.godot
git commit -m "add GUT test framework"
```

---

## Task 2: Strip-down existing GDScript

**Files:**
- Delete: `scripts/*.gd`, `scripts/*.gd.uid`, all subdirectories of `scripts/` (`UI/`, `controls/`, `tooling/`, `views/`)
- Delete: `Main.tscn`, `accueil_2d_view.tscn`, `alternateGuidingSpirit2d.tscn`
- Modify: `project.godot` (remove autoload entries, remove main_scene temporarily)

- [ ] **Step 1: Delete all existing scripts**

```bash
rm -rf scripts/*
rm -f Main.tscn accueil_2d_view.tscn alternateGuidingSpirit2d.tscn
```

Expected: `scripts/` is empty. Scene files at root gone.

- [ ] **Step 2: Strip `project.godot` autoloads and main_scene**

Open `project.godot` and replace the `[autoload]` section and the `run/main_scene` line:

```ini
[application]

config/name="artdle"
config/features=PackedStringArray("4.4", "GL Compatibility")
config/icon="res://icon.svg"
```

(Delete the `run/main_scene=...` line and the entire `[autoload]` section for now — we'll re-add them in Task 9.)

- [ ] **Step 3: Verify project still opens**

Open the project in Godot. Expected: project opens without fatal errors. Warnings about missing scripts/scenes are expected and OK.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "strip all GDScript for rescope rebuild"
```

---

## Task 3: Create directory structure

**Files:**
- Create: `scripts/autoloads/.gdignore`, `scripts/core/.gdignore`, `scripts/systems/.gdignore`, `scripts/config/.gdignore`, `scripts/ui/.gdignore`, `test/.gdignore`

(`.gdignore` files are empty placeholders that allow Godot to track otherwise-empty dirs without error.)

- [ ] **Step 1: Create all dirs**

```bash
mkdir -p scripts/autoloads scripts/core scripts/systems scripts/config scripts/ui/views scripts/ui/popups scripts/ui/widgets test
```

- [ ] **Step 2: Commit**

```bash
git add scripts/ test/
git commit -m "create new scripts/ and test/ directory structure"
```

---

## Task 4: `BigNumber` primitive — failing test first

**Files:**
- Create: `test/test_big_number.gd`

- [ ] **Step 1: Write the failing test**

Create `test/test_big_number.gd`:

```gdscript
extends GutTest

func test_zero():
    var n = BigNumber.new()
    assert_eq(n.value, 0.0)
    assert_eq(n.to_string(), "0")

func test_add_positive():
    var a = BigNumber.from_float(5.0)
    var b = BigNumber.from_float(3.0)
    var c = a.add(b)
    assert_eq(c.value, 8.0)

func test_subtract():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.from_float(3.0)
    assert_eq(a.subtract(b).value, 7.0)

func test_multiply():
    var a = BigNumber.from_float(4.0)
    var b = BigNumber.from_float(2.5)
    assert_eq(a.multiply(b).value, 10.0)

func test_divide():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.from_float(4.0)
    assert_eq(a.divide(b).value, 2.5)

func test_divide_by_zero_returns_zero():
    var a = BigNumber.from_float(10.0)
    var b = BigNumber.zero()
    assert_eq(a.divide(b).value, 0.0)

func test_overflow_caps_at_max_float():
    var huge = BigNumber.from_float(1.0e308)
    var result = huge.multiply(BigNumber.from_float(10.0))
    assert_eq(result.value, BigNumber.MAX_VALUE)
    assert_true(result.is_at_cap())

func test_overflow_does_not_return_zero():
    var huge = BigNumber.from_float(1.0e308)
    var result = huge.add(huge)
    assert_gt(result.value, 1.0e307)
    assert_eq(result.value, BigNumber.MAX_VALUE)

func test_compare_greater_equal():
    assert_true(BigNumber.from_float(5.0).gte(BigNumber.from_float(5.0)))
    assert_true(BigNumber.from_float(5.0).gte(BigNumber.from_float(3.0)))
    assert_false(BigNumber.from_float(2.0).gte(BigNumber.from_float(3.0)))

func test_serialize_roundtrip():
    var a = BigNumber.from_float(123.45)
    var data = a.serialize()
    var b = BigNumber.deserialize(data)
    assert_eq(b.value, 123.45)
```

- [ ] **Step 2: Run tests — expect fail**

Run GUT from Godot editor panel, or via CLI:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/test_big_number.gd -gexit
```
Expected: all tests FAIL with "Class BigNumber not found" or similar.

- [ ] **Step 3: Implement `BigNumber`**

Create `scripts/core/BigNumber.gd`:

```gdscript
class_name BigNumber
extends RefCounted

const MAX_VALUE: float = 1.0e308

var value: float = 0.0

static func zero() -> BigNumber:
    var n = BigNumber.new()
    n.value = 0.0
    return n

static func from_float(v: float) -> BigNumber:
    var n = BigNumber.new()
    n.value = clamp(v, 0.0, MAX_VALUE)
    return n

func add(other: BigNumber) -> BigNumber:
    var r = value + other.value
    if is_inf(r) or r > MAX_VALUE:
        r = MAX_VALUE
    return BigNumber.from_float(r)

func subtract(other: BigNumber) -> BigNumber:
    return BigNumber.from_float(max(0.0, value - other.value))

func multiply(other: BigNumber) -> BigNumber:
    var r = value * other.value
    if is_inf(r) or r > MAX_VALUE:
        r = MAX_VALUE
    return BigNumber.from_float(r)

func divide(other: BigNumber) -> BigNumber:
    if other.value == 0.0:
        return BigNumber.zero()
    return BigNumber.from_float(value / other.value)

func gte(other: BigNumber) -> bool:
    return value >= other.value

func gt(other: BigNumber) -> bool:
    return value > other.value

func is_at_cap() -> bool:
    return value >= MAX_VALUE

func to_string() -> String:
    return str(value)

func serialize() -> float:
    return value

static func deserialize(data) -> BigNumber:
    return BigNumber.from_float(float(data))
```

- [ ] **Step 4: Run tests — expect pass**

Same command as step 2. Expected: all 10 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/BigNumber.gd test/test_big_number.gd
git commit -m "add BigNumber primitive with overflow cap and roundtrip"
```

---

## Task 5: `Formatter` primitive

**Files:**
- Create: `scripts/core/Formatter.gd`, `test/test_formatter.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_formatter.gd`:

```gdscript
extends GutTest

func test_small_integer():
    assert_eq(Formatter.short(BigNumber.from_float(42.0)), "42")

func test_thousand():
    assert_eq(Formatter.short(BigNumber.from_float(1500.0)), "1.50K")

func test_million():
    assert_eq(Formatter.short(BigNumber.from_float(2_500_000.0)), "2.50M")

func test_billion():
    assert_eq(Formatter.short(BigNumber.from_float(3_750_000_000.0)), "3.75B")

func test_trillion():
    assert_eq(Formatter.short(BigNumber.from_float(1.0e12)), "1.00T")

func test_very_large():
    assert_eq(Formatter.short(BigNumber.from_float(1.0e18)), "1.00Qi")

func test_zero():
    assert_eq(Formatter.short(BigNumber.zero()), "0")

func test_precision_integer_under_thousand():
    assert_eq(Formatter.short(BigNumber.from_float(999.0)), "999")
```

- [ ] **Step 2: Run — expect fail**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/test_formatter.gd -gexit
```

- [ ] **Step 3: Implement**

Create `scripts/core/Formatter.gd`:

```gdscript
class_name Formatter
extends RefCounted

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func short(n: BigNumber) -> String:
    var v: float = n.value
    if v < 1000.0:
        return str(int(v))
    var tier: int = 0
    while v >= 1000.0 and tier < SUFFIXES.size() - 1:
        v /= 1000.0
        tier += 1
    return "%.2f%s" % [v, SUFFIXES[tier]]
```

- [ ] **Step 4: Run — expect pass**

Same command as step 2. Expected: all 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Formatter.gd test/test_formatter.gd
git commit -m "add Formatter with K/M/B/T suffixes"
```

---

## Task 6: `Balance` constants + formulas

**Files:**
- Create: `scripts/core/Balance.gd`, `test/test_balance.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_balance.gd`:

```gdscript
extends GutTest

func test_palier_ascend_first():
    var p = Balance.palier_ascend(0)
    assert_eq(p.value, 1000.0)

func test_palier_ascend_doubles():
    var p0 = Balance.palier_ascend(0).value
    var p1 = Balance.palier_ascend(1).value
    assert_eq(p1, p0 * 2.0)
    var p2 = Balance.palier_ascend(2).value
    assert_eq(p2, p0 * 4.0)

func test_fame_conversion_below_threshold_zero():
    var fame = Balance.fame_conversion(BigNumber.from_float(500.0))
    assert_eq(fame.value, 0.0)

func test_fame_conversion_at_palier_gives_one():
    var fame = Balance.fame_conversion(BigNumber.from_float(1000.0))
    assert_gte(fame.value, 1.0)

func test_fame_conversion_monotonic():
    var low = Balance.fame_conversion(BigNumber.from_float(1000.0)).value
    var high = Balance.fame_conversion(BigNumber.from_float(100000.0)).value
    assert_gt(high, low)

func test_pm_gain_scales_with_tier():
    var t1 = Balance.paint_mastery_gain(1, BigNumber.from_float(10.0)).value
    var t5 = Balance.paint_mastery_gain(5, BigNumber.from_float(10.0)).value
    assert_gt(t5, t1)

func test_pm_multiplier_log_curve():
    var low = Balance.paint_mastery_multiplier(BigNumber.from_float(10.0))
    var mid = Balance.paint_mastery_multiplier(BigNumber.from_float(10_000.0))
    var high = Balance.paint_mastery_multiplier(BigNumber.from_float(10_000_000.0))
    assert_almost_eq(low, 1.0, 0.5)
    assert_gt(mid, low)
    assert_gt(high, mid)
    assert_lt(high, 10.0)  # log curve doesn't explode
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/core/Balance.gd`:

```gdscript
class_name Balance
extends RefCounted

const ASCEND_PALIER_BASE: float = 1000.0
const ASCEND_PALIER_GROWTH: float = 2.0

const FAME_CONVERSION_THRESHOLD: float = 1000.0
const FAME_CONVERSION_LOG_FACTOR: float = 1.0

const PM_GAIN_TIER_FACTOR: float = 0.1
const PM_LOG_FACTOR: float = 0.2

static func palier_ascend(ascend_count: int) -> BigNumber:
    var v = ASCEND_PALIER_BASE * pow(ASCEND_PALIER_GROWTH, float(ascend_count))
    return BigNumber.from_float(v)

static func fame_conversion(inspi: BigNumber) -> BigNumber:
    if inspi.value < FAME_CONVERSION_THRESHOLD:
        return BigNumber.zero()
    var fame = floor(log(inspi.value / FAME_CONVERSION_THRESHOLD + 1.0) * FAME_CONVERSION_LOG_FACTOR + 1.0)
    return BigNumber.from_float(fame)

static func paint_mastery_gain(canvas_tier: int, gold_earned: BigNumber) -> BigNumber:
    var gain = gold_earned.value * PM_GAIN_TIER_FACTOR * float(canvas_tier)
    return BigNumber.from_float(gain)

static func paint_mastery_multiplier(paint_mastery: BigNumber) -> float:
    return 1.0 + PM_LOG_FACTOR * log(paint_mastery.value + 1.0)
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Balance.gd test/test_balance.gd
git commit -m "add Balance with ascend, fame, paint_mastery formulas"
```

---

## Task 7: `Currency` system

**Files:**
- Create: `scripts/systems/Currency.gd`, `test/test_currency.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_currency.gd`:

```gdscript
extends GutTest

var currency: Currency

func before_each():
    currency = Currency.new()

func test_initial_zero():
    assert_eq(currency.get_amount("inspiration").value, 0.0)
    assert_eq(currency.get_amount("gold").value, 0.0)
    assert_eq(currency.get_amount("fame").value, 0.0)
    assert_eq(currency.get_amount("paint_mastery").value, 0.0)

func test_add():
    currency.add("gold", BigNumber.from_float(100.0))
    assert_eq(currency.get_amount("gold").value, 100.0)

func test_spend_success_returns_true():
    currency.add("gold", BigNumber.from_float(100.0))
    var ok = currency.spend("gold", BigNumber.from_float(30.0))
    assert_true(ok)
    assert_eq(currency.get_amount("gold").value, 70.0)

func test_spend_insufficient_returns_false_and_no_debit():
    currency.add("gold", BigNumber.from_float(50.0))
    var ok = currency.spend("gold", BigNumber.from_float(100.0))
    assert_false(ok)
    assert_eq(currency.get_amount("gold").value, 50.0)

func test_reset_preserves_permanents():
    currency.add("inspiration", BigNumber.from_float(500.0))
    currency.add("gold", BigNumber.from_float(200.0))
    currency.add("fame", BigNumber.from_float(10.0))
    currency.add("paint_mastery", BigNumber.from_float(42.0))
    currency.reset(["inspiration", "gold"])
    assert_eq(currency.get_amount("inspiration").value, 0.0)
    assert_eq(currency.get_amount("gold").value, 0.0)
    assert_eq(currency.get_amount("fame").value, 10.0)
    assert_eq(currency.get_amount("paint_mastery").value, 42.0)

func test_changed_signal_emitted_on_add():
    watch_signals(currency)
    currency.add("gold", BigNumber.from_float(5.0))
    assert_signal_emitted(currency, "changed")
    assert_signal_emitted_with_parameters(currency, "changed", ["gold", BigNumber.from_float(5.0).value], 0)

func test_unknown_kind_does_nothing():
    currency.add("unobtainium", BigNumber.from_float(100.0))
    assert_eq(currency.get_amount("unobtainium").value, 0.0)

func test_serialize_roundtrip():
    currency.add("gold", BigNumber.from_float(1234.0))
    currency.add("fame", BigNumber.from_float(5.0))
    var data = currency.serialize()
    var fresh = Currency.new()
    fresh.deserialize(data)
    assert_eq(fresh.get_amount("gold").value, 1234.0)
    assert_eq(fresh.get_amount("fame").value, 5.0)
```

Note: `assert_signal_emitted_with_parameters` in GUT takes raw values. We pass `BigNumber.value` since signals can't compare custom RefCounted objects cleanly. Our implementation emits the float value, not the BigNumber object.

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Currency.gd`:

```gdscript
class_name Currency
extends Node

signal changed(kind: String, new_value: float)

const KINDS: Array[String] = ["inspiration", "gold", "fame", "paint_mastery"]

var _pools: Dictionary = {}

func _init() -> void:
    for k in KINDS:
        _pools[k] = BigNumber.zero()

func get_amount(kind: String) -> BigNumber:
    if not _pools.has(kind):
        return BigNumber.zero()
    return _pools[kind]

func add(kind: String, amount: BigNumber) -> void:
    if not _pools.has(kind):
        return
    _pools[kind] = _pools[kind].add(amount)
    changed.emit(kind, _pools[kind].value)

func spend(kind: String, amount: BigNumber) -> bool:
    if not _pools.has(kind):
        return false
    if not _pools[kind].gte(amount):
        return false
    _pools[kind] = _pools[kind].subtract(amount)
    changed.emit(kind, _pools[kind].value)
    return true

func reset(kinds: Array) -> void:
    for k in kinds:
        if _pools.has(k):
            _pools[k] = BigNumber.zero()
            changed.emit(k, 0.0)

func serialize() -> Dictionary:
    var out: Dictionary = {}
    for k in KINDS:
        out[k] = _pools[k].serialize()
    return out

func deserialize(data: Dictionary) -> void:
    for k in KINDS:
        if data.has(k):
            _pools[k] = BigNumber.deserialize(data[k])
        else:
            _pools[k] = BigNumber.zero()
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Currency.gd test/test_currency.gd
git commit -m "add Currency system with 4 pools, atomic spend, reset, signals"
```

---

## Task 8: `Save` system

**Files:**
- Create: `scripts/systems/Save.gd`, `test/test_save.gd`

- [ ] **Step 1: Write failing test**

Create `test/test_save.gd`:

```gdscript
extends GutTest

const TEST_PATH: String = "user://test_artdle.save"

func before_each():
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func after_each():
    if FileAccess.file_exists(TEST_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func test_write_and_read_roundtrip():
    var save = Save.new()
    save.save_path = TEST_PATH
    var payload = {"currency": {"gold": 123.0, "fame": 5.0}}
    var ok = save.write(payload)
    assert_true(ok)
    var loaded = save.read()
    assert_ne(loaded, null)
    assert_eq(loaded["version"], Save.SAVE_VERSION)
    assert_eq(loaded["currency"]["gold"], 123.0)

func test_read_missing_returns_null():
    var save = Save.new()
    save.save_path = TEST_PATH
    assert_eq(save.read(), null)

func test_read_corrupt_returns_null():
    var save = Save.new()
    save.save_path = TEST_PATH
    var f = FileAccess.open(TEST_PATH, FileAccess.WRITE)
    f.store_string("{not valid json")
    f.close()
    assert_eq(save.read(), null)

func test_version_newer_refused():
    var save = Save.new()
    save.save_path = TEST_PATH
    var f = FileAccess.open(TEST_PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify({"version": 999, "currency": {}}))
    f.close()
    assert_eq(save.read(), null)

func test_atomic_write_no_partial_on_failure():
    # We can't easily simulate a write failure, but we can verify the tmp
    # file doesn't linger after a successful write.
    var save = Save.new()
    save.save_path = TEST_PATH
    save.write({"currency": {}})
    var tmp = TEST_PATH + ".tmp"
    assert_false(FileAccess.file_exists(tmp))

func test_migrate_same_version_is_identity():
    var save = Save.new()
    var data = {"version": Save.SAVE_VERSION, "currency": {"gold": 1.0}}
    var migrated = save._migrate(data, Save.SAVE_VERSION, Save.SAVE_VERSION)
    assert_eq(migrated, data)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Implement**

Create `scripts/systems/Save.gd`:

```gdscript
class_name Save
extends Node

const SAVE_VERSION: int = 1
var save_path: String = "user://artdle.save"

func write(payload: Dictionary) -> bool:
    var full: Dictionary = payload.duplicate(true)
    full["version"] = SAVE_VERSION
    var tmp_path: String = save_path + ".tmp"
    var f = FileAccess.open(tmp_path, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(full))
    f.close()
    var err = DirAccess.rename_absolute(
        ProjectSettings.globalize_path(tmp_path),
        ProjectSettings.globalize_path(save_path)
    )
    return err == OK

func read() -> Variant:
    if not FileAccess.file_exists(save_path):
        return null
    var f = FileAccess.open(save_path, FileAccess.READ)
    if f == null:
        return null
    var text = f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(text)
    if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
        return null
    var version: int = int(parsed.get("version", 0))
    if version > SAVE_VERSION:
        push_error("Save from newer version (%d > %d) — refusing to load" % [version, SAVE_VERSION])
        return null
    if version < SAVE_VERSION:
        parsed = _migrate(parsed, version, SAVE_VERSION)
    return parsed

func _migrate(data: Dictionary, from_v: int, to_v: int) -> Dictionary:
    # MVP: v1 is the first version, no migrations yet. Stub kept for future.
    if from_v == to_v:
        return data
    push_error("No migration path from v%d to v%d" % [from_v, to_v])
    return data
```

- [ ] **Step 4: Run — expect pass**

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/Save.gd test/test_save.gd
git commit -m "add Save with atomic write, versioning, migration stub"
```

---

## Task 9: `GameState` + `SceneManager` autoloads

**Files:**
- Create: `scripts/autoloads/GameState.gd`, `scripts/autoloads/SceneManager.gd`
- Modify: `project.godot` (re-add autoloads)

- [ ] **Step 1: Implement `GameState`**

Create `scripts/autoloads/GameState.gd`:

```gdscript
extends Node

# Signal hub. Systems emit here; UI and other systems listen here.
# Currency + Save are held as children so they participate in the scene tree.

signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)

var currency: Currency
var save_system: Save

func _ready() -> void:
    currency = Currency.new()
    currency.name = "Currency"
    add_child(currency)
    save_system = Save.new()
    save_system.name = "Save"
    add_child(save_system)

func save_game() -> bool:
    var payload: Dictionary = {
        "currency": currency.serialize(),
    }
    return save_system.write(payload)

func load_game() -> bool:
    var data = save_system.read()
    if data == null:
        return false
    if data.has("currency"):
        currency.deserialize(data["currency"])
    return true
```

- [ ] **Step 2: Implement `SceneManager` (minimal)**

Create `scripts/autoloads/SceneManager.gd`:

```gdscript
extends Node

# Minimal scene loader. Expanded in Phase 4 when UI views exist.

func load_scene(scene_path: String) -> void:
    var err = get_tree().change_scene_to_file(scene_path)
    if err != OK:
        push_error("Failed to load scene: %s (err %d)" % [scene_path, err])
```

- [ ] **Step 3: Re-add autoloads in `project.godot`**

Add this section back to `project.godot` (after the `[application]` block):

```ini
[autoload]

GameState="*res://scripts/autoloads/GameState.gd"
SceneManager="*res://scripts/autoloads/SceneManager.gd"
```

- [ ] **Step 4: Verify project opens cleanly**

Open Godot. Expected: no parse errors in the Output panel.

- [ ] **Step 5: Write integration test for GameState save/load**

Create `test/test_gamestate.gd`:

```gdscript
extends GutTest

func test_save_and_load_currency_roundtrip():
    GameState.save_system.save_path = "user://test_gamestate.save"
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    GameState.currency.add("fame", BigNumber.from_float(3.0))
    var saved = GameState.save_game()
    assert_true(saved)
    GameState.currency.reset(["gold", "fame"])
    var loaded = GameState.load_game()
    assert_true(loaded)
    assert_eq(GameState.currency.get_amount("gold").value, 500.0)
    assert_eq(GameState.currency.get_amount("fame").value, 3.0)
    # Cleanup
    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
```

- [ ] **Step 6: Run all tests — expect all pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

Expected: all tests from `test_big_number.gd`, `test_formatter.gd`, `test_balance.gd`, `test_currency.gd`, `test_save.gd`, `test_gamestate.gd` PASS.

- [ ] **Step 7: Commit**

```bash
git add scripts/autoloads/ project.godot test/test_gamestate.gd
git commit -m "add GameState + SceneManager autoloads with save/load integration"
```

---

## Phase 1 Complete Criteria

- [ ] All unit tests pass (6 test files, ~45+ assertions).
- [ ] Project opens in Godot without errors.
- [ ] `GameState` autoload accessible from any script.
- [ ] Save round-trip works: add currency → save → reset → load → values restored.
- [ ] Folder structure matches spec §9.

**Next:** Phase 2 (Core loop — Inspiration Tree, Canvas, PaintMastery).
