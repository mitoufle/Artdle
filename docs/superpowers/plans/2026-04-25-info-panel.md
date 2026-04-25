# Info-panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the dedicated hover info-panel (title + body + footer with BBCode icons) that fills with detailed quantitative descriptions whenever the mouse hovers an explainable element. Replaces the deprecated floating `Tooltip`. Validate by hovering the AscendButton and seeing live palier/fame numbers.

**Architecture:** A horizontal `PanelContainer` strip is inserted between `Content` and `BottomBar` in `Main.tscn`. Three `RichTextLabel`s render title/body/footer with BBCode-enabled icons. Emitters push content via two new GameState signals (`hover_info_pushed`, `hover_info_cleared`). A small `Hoverable` child-node helper wraps any `Control` to push static or dynamic content on mouse_entered/exited. A static `Icons` registry centralises currency icon paths.

**Tech Stack:** Godot 4.6, GDScript, GUT 9.x. Tests live in `test/`.

**Spec reference:** `docs/superpowers/specs/2026-04-25-info-panel-design.md`. §6 is the mandatory content authoring rule — keep it in mind for Task 6.

**Prerequisites:** All Phase 4 work merged on `master`. 140 GUT tests passing. Branch off a `info-panel` working branch before Task 1.

---

## Task 1: `Icons` registry + tests

**Files:**
- Create: `scripts/core/Icons.gd`
- Create: `test/test_icons.gd`

- [ ] **Step 1: Create the failing test**

Create `test/test_icons.gd`:

```gdscript
extends GutTest

func test_has_known_id():
    assert_true(Icons.has("gold"))
    assert_true(Icons.has("fame"))
    assert_true(Icons.has("inspiration"))
    assert_true(Icons.has("paint_mastery"))

func test_has_unknown_id():
    assert_false(Icons.has("nonexistent"))

func test_bbcode_known_id_default_height():
    var s: String = Icons.bbcode("gold")
    assert_eq(s, "[img height=16]res://artdleAsset/Currency/coin.png[/img]")

func test_bbcode_known_id_custom_height():
    var s: String = Icons.bbcode("inspiration", 32)
    assert_eq(s, "[img height=32]res://artdleAsset/Currency/Inspiration.png[/img]")

func test_bbcode_unknown_returns_empty():
    var s: String = Icons.bbcode("nope")
    assert_eq(s, "")
```

- [ ] **Step 2: Run test to verify it fails**

Open Godot → Project → Tools → GUT → run the `test_icons.gd` panel.
Expected: 5 fails with "Identifier 'Icons' not declared in the current scope."

- [ ] **Step 3: Create `Icons.gd`**

Create `scripts/core/Icons.gd`:

```gdscript
class_name Icons
extends RefCounted

# Registry: id → resource path. Extend as new game elements need icons.
const ICONS: Dictionary = {
    "gold":           "res://artdleAsset/Currency/coin.png",
    "fame":           "res://artdleAsset/Currency/fame.png",
    "inspiration":    "res://artdleAsset/Currency/Inspiration.png",
    "paint_mastery":  "res://artdleAsset/Currency/Painting_mastery.png",
}

static func has(id: String) -> bool:
    return ICONS.has(id)

static func bbcode(id: String, height: int = 16) -> String:
    if not ICONS.has(id):
        push_warning("Icons.bbcode: unknown id '%s'" % id)
        return ""
    return "[img height=%d]%s[/img]" % [height, ICONS[id]]
```

- [ ] **Step 4: Run tests to verify they pass**

Re-run `test_icons.gd` in the GUT panel.
Expected: 5 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/Icons.gd test/test_icons.gd
git commit -m "add Icons registry: bbcode helper for inline currency icons"
```

---

## Task 2: GameState hover signals + methods

**Files:**
- Modify: `scripts/autoloads/GameState.gd`
- Create: `test/test_gamestate_hover.gd`

- [ ] **Step 1: Create the failing test**

Create `test/test_gamestate_hover.gd`:

```gdscript
extends GutTest

func test_push_hover_info_emits_with_args():
    watch_signals(GameState)
    GameState.push_hover_info("Title", "Body text", "Footer line")
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["Title", "Body text", "Footer line"]
    )

func test_clear_hover_info_emits():
    watch_signals(GameState)
    GameState.clear_hover_info()
    assert_signal_emitted(GameState, "hover_info_cleared")
```

- [ ] **Step 2: Run test to verify it fails**

Run `test_gamestate_hover.gd` in the GUT panel.
Expected: 2 fails — `push_hover_info` / `clear_hover_info` undefined.

- [ ] **Step 3: Add signals + methods to GameState**

Edit `scripts/autoloads/GameState.gd`. Find the `# -- Signals --` block (around line 19-24) and add the two new signals at the end of that block. Keep tabs (this file is tab-indented):

```gdscript
signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)
signal hover_info_pushed(title: String, body: String, footer: String)
signal hover_info_cleared()
```

Then add two methods at the bottom of the file (after `load_game()`):

```gdscript
# -- Hover info bus --

func push_hover_info(title: String, body: String, footer: String) -> void:
	hover_info_pushed.emit(title, body, footer)

func clear_hover_info() -> void:
	hover_info_cleared.emit()
```

- [ ] **Step 4: Run tests to verify they pass**

Re-run `test_gamestate_hover.gd`.
Expected: 2 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoloads/GameState.gd test/test_gamestate_hover.gd
git commit -m "GameState: add hover_info_pushed/cleared signals + push/clear helpers"
```

---

## Task 3: `InfoPanel` widget + scene

**Files:**
- Create: `scripts/ui/widgets/InfoPanel.gd`
- Create: `Scenes/InfoPanel.tscn`
- Create: `test/test_info_panel.gd`

- [ ] **Step 1: Create the failing test**

Create `test/test_info_panel.gd`:

```gdscript
extends GutTest

const InfoPanelScene = preload("res://Scenes/InfoPanel.tscn")
var panel

func before_each():
    panel = InfoPanelScene.instantiate()
    add_child_autofree(panel)

func test_initial_state_blank():
    assert_eq(panel.title_label.text, "")
    assert_eq(panel.body_label.text, "")
    assert_eq(panel.footer_label.text, "")

func test_set_content_writes_three_labels():
    panel.set_content("Hello", "World", "Footer")
    assert_eq(panel.title_label.text, "Hello")
    assert_eq(panel.body_label.text, "World")
    assert_eq(panel.footer_label.text, "Footer")

func test_clear_blanks_all_three():
    panel.set_content("a", "b", "c")
    panel.clear()
    assert_eq(panel.title_label.text, "")
    assert_eq(panel.body_label.text, "")
    assert_eq(panel.footer_label.text, "")

func test_responds_to_gamestate_push_signal():
    GameState.push_hover_info("X", "Y", "Z")
    await get_tree().process_frame
    assert_eq(panel.title_label.text, "X")
    assert_eq(panel.body_label.text, "Y")
    assert_eq(panel.footer_label.text, "Z")

func test_responds_to_gamestate_clear_signal():
    panel.set_content("a", "b", "c")
    GameState.clear_hover_info()
    await get_tree().process_frame
    assert_eq(panel.title_label.text, "")
```

- [ ] **Step 2: Run test to verify it fails**

Run `test_info_panel.gd`.
Expected: fails on `preload("res://Scenes/InfoPanel.tscn")` — file does not exist.

- [ ] **Step 3: Create the scene**

Create `Scenes/InfoPanel.tscn` (text-write — no UID, Godot will regenerate):

```
[gd_scene load_steps=2 format=3 uid="uid://binfopanelartdl0"]

[ext_resource type="Script" path="res://scripts/ui/widgets/InfoPanel.gd" id="1_infopanel"]

[node name="InfoPanel" type="PanelContainer"]
custom_minimum_size = Vector2(0, 100)
script = ExtResource("1_infopanel")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 12
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 12
theme_override_constants/margin_bottom = 8

[node name="HBoxContainer" type="HBoxContainer" parent="MarginContainer"]
layout_mode = 2
theme_override_constants/separation = 16

[node name="TitleLabel" type="RichTextLabel" parent="MarginContainer/HBoxContainer"]
custom_minimum_size = Vector2(180, 0)
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 0.3
bbcode_enabled = true
fit_content = true

[node name="BodyLabel" type="RichTextLabel" parent="MarginContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.0
bbcode_enabled = true
fit_content = true

[node name="FooterLabel" type="RichTextLabel" parent="MarginContainer/HBoxContainer"]
custom_minimum_size = Vector2(160, 0)
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 0.25
bbcode_enabled = true
fit_content = true
```

- [ ] **Step 4: Create the script**

Create `scripts/ui/widgets/InfoPanel.gd`:

```gdscript
extends PanelContainer

@onready var title_label: RichTextLabel = $MarginContainer/HBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $MarginContainer/HBoxContainer/BodyLabel
@onready var footer_label: RichTextLabel = $MarginContainer/HBoxContainer/FooterLabel

func _ready() -> void:
    GameState.hover_info_pushed.connect(set_content)
    GameState.hover_info_cleared.connect(clear)
    clear()

func set_content(title: String, body: String, footer: String) -> void:
    if title_label == null:
        return
    title_label.text = title
    body_label.text = body
    footer_label.text = footer

func clear() -> void:
    if title_label == null:
        return
    title_label.text = ""
    body_label.text = ""
    footer_label.text = ""
```

- [ ] **Step 5: Run tests to verify they pass**

Re-run `test_info_panel.gd`.
Expected: 5 pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/widgets/InfoPanel.gd Scenes/InfoPanel.tscn test/test_info_panel.gd
git commit -m "add InfoPanel widget — RichTextLabel triplet listening to GameState hover signals"
```

---

## Task 4: `Hoverable` helper + tests

**Files:**
- Create: `scripts/ui/widgets/Hoverable.gd`
- Create: `test/test_hoverable.gd`

- [ ] **Step 1: Create the failing test**

Create `test/test_hoverable.gd`:

```gdscript
extends GutTest

const HoverableScript = preload("res://scripts/ui/widgets/Hoverable.gd")

var parent_ctrl: Control
var hov

func before_each():
    parent_ctrl = Control.new()
    add_child_autofree(parent_ctrl)
    hov = HoverableScript.new()
    hov.title = "T"
    hov.body = "B"
    hov.footer = "F"
    parent_ctrl.add_child(hov)

func test_static_strings_pushed_on_mouse_entered():
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["T", "B", "F"]
    )

func test_clear_emitted_on_mouse_exited():
    watch_signals(GameState)
    parent_ctrl.mouse_exited.emit()
    assert_signal_emitted(GameState, "hover_info_cleared")

func test_content_provider_overrides_static():
    hov.content_provider = func() -> Array: return ["DT", "DB", "DF"]
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["DT", "DB", "DF"]
    )

func test_provider_short_array_falls_back_to_empty():
    hov.content_provider = func() -> Array: return ["only-title"]
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["only-title", "", ""]
    )
```

- [ ] **Step 2: Run test to verify it fails**

Run `test_hoverable.gd`.
Expected: fails on `preload(...)` — script doesn't exist.

- [ ] **Step 3: Create `Hoverable.gd`**

Create `scripts/ui/widgets/Hoverable.gd`:

```gdscript
extends Node

@export var title: String = ""
@export var body: String = ""
@export var footer: String = ""

# Optional. Must return Array of length 3 — [title, body, footer].
# Set from code after instantiating; not @export because Callables aren't editable in the inspector.
var content_provider: Callable = Callable()

func _ready() -> void:
    var p = get_parent()
    if not (p is Control):
        push_error("Hoverable: parent is not a Control (got %s)" % p)
        return
    p.mouse_entered.connect(_on_mouse_entered)
    p.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
    var t: String = title
    var b: String = body
    var f: String = footer
    if content_provider.is_valid():
        var arr: Array = content_provider.call()
        t = arr[0] if arr.size() > 0 else ""
        b = arr[1] if arr.size() > 1 else ""
        f = arr[2] if arr.size() > 2 else ""
    GameState.push_hover_info(t, b, f)

func _on_mouse_exited() -> void:
    GameState.clear_hover_info()
```

- [ ] **Step 4: Run tests to verify they pass**

Re-run `test_hoverable.gd`.
Expected: 4 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/widgets/Hoverable.gd test/test_hoverable.gd
git commit -m "add Hoverable helper: child-node that pushes hover info on parent's mouse signals"
```

---

## Task 5: Wire `InfoPanel` into `Main.tscn`

**Files:**
- Modify: `Main.tscn`

No tests — visual integration only. Verify in Godot editor by launching the game.

- [ ] **Step 1: Edit `Main.tscn`**

Open `Main.tscn` (text editor). Find the `[gd_scene load_steps=...]` header at the top:

```
[gd_scene load_steps=7 format=3 uid="uid://bcdmain8artdl0"]
```

Bump `load_steps` from `7` to `8`. Add an ext_resource line for the InfoPanel scene right after the BottomBar one:

```
[ext_resource type="PackedScene" uid="uid://dpskjp8x1i7x" path="res://Scenes/BottomBar.tscn" id="2_bottombar"]
[ext_resource type="PackedScene" path="res://Scenes/InfoPanel.tscn" id="7_infopanel"]
[ext_resource type="PackedScene" path="res://views/AccueilView.tscn" id="3_accueil"]
```

Then find the `Content` node and the `BottomBar` instance node. Insert a new `[node name="InfoPanel" parent="MainLayout/VBoxContainer" instance=ExtResource("7_infopanel")]` block **between** them. After the edit, that section should read:

```
[node name="Content" type="PanelContainer" parent="MainLayout/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="InfoPanel" parent="MainLayout/VBoxContainer" instance=ExtResource("7_infopanel")]
layout_mode = 2

[node name="BottomBar" parent="MainLayout/VBoxContainer" instance=ExtResource("2_bottombar")]
layout_mode = 2
```

- [ ] **Step 2: Verify in editor**

Launch Godot, open `Main.tscn`, check there are no parse errors in the Output panel. Run the project (F5). Confirm a ~100px horizontal strip appears between the canvas content and the bottom currencies, empty.

- [ ] **Step 3: Commit**

```bash
git add Main.tscn
git commit -m "wire InfoPanel into Main.tscn between Content and BottomBar"
```

---

## Task 6: Validation — hover info on AscendButton (live values per §6)

**Files:**
- Modify: `scripts/ui/views/AscendancyView.gd`

This is the §6 / §11 Definition-of-Done validation. The AscendButton must push **live** palier and projected fame on hover, not a static blurb.

- [ ] **Step 1: Edit `AscendancyView.gd`**

Open `scripts/ui/views/AscendancyView.gd`. Add a preload at the top of the script (after `extends BaseView`):

```gdscript
extends BaseView

const HoverableScript = preload("res://scripts/ui/widgets/Hoverable.gd")
```

Then extend `_initialize_view` (currently empty / inherited) to attach a Hoverable child to `AscendButton`:

```gdscript
func _initialize_view() -> void:
    var hov = HoverableScript.new()
    hov.content_provider = func() -> Array:
        var palier: BigNumber  = Balance.palier_ascend(GameState.ascend.ascend_count)
        var current: BigNumber = GameState.currency.get_amount("inspiration")
        var preview: BigNumber = Balance.fame_conversion(current)
        return [
            "Ascendance",
            "Réinitialise le run et donne de la fame permanente. Gagne actuellement %s %s." % [
                Formatter.short(preview), Icons.bbcode("fame")
            ],
            "Palier : %s / %s %s" % [
                Formatter.short(current), Formatter.short(palier), Icons.bbcode("inspiration")
            ]
        ]
    ascend_btn.add_child(hov)
```

The handler is wired *before* `_connect_view_signals` runs, but that's fine — `Hoverable._ready` connects on its own when added to the tree.

- [ ] **Step 2: Manual verify**

Launch the game (F5). Switch to the Ascend view. Hover the **Ascend** button. The InfoPanel should fill with:

- Title: `Ascendance`
- Body: `Réinitialise le run et donne de la fame permanente. Gagne actuellement <preview> [fame icon].`
- Footer: `Palier : <current_inspi> / <palier> [inspi icon]`

Move the cursor off the button — panel blanks. Move it back on — panel re-fills with the *current* values (e.g., increasing as inspi grows).

- [ ] **Step 3: Commit**

```bash
git add scripts/ui/views/AscendancyView.gd
git commit -m "AscendancyView: hoverable on AscendButton with live palier and fame preview"
```

---

## Task 7: Cleanup — delete deprecated `Tooltip`

**Files:**
- Delete: `scripts/ui/widgets/Tooltip.gd`
- Delete: `scripts/ui/widgets/Tooltip.gd.uid`
- Delete: `Scenes/CustomTooltip.tscn`

- [ ] **Step 1: Delete files**

```bash
git rm scripts/ui/widgets/Tooltip.gd
git rm scripts/ui/widgets/Tooltip.gd.uid
git rm Scenes/CustomTooltip.tscn
```

- [ ] **Step 2: Confirm nothing references them**

Run a search to verify no remaining references:

```bash
grep -rn "Tooltip" scripts/ Scenes/ views/ 2>/dev/null
grep -rn "CustomTooltip" scripts/ Scenes/ views/ 2>/dev/null
```

Expected: no output (the only matches in the project should now be in deleted files, which are gone).

- [ ] **Step 3: Commit**

```bash
git commit -m "remove deprecated floating Tooltip widget (replaced by InfoPanel)"
```

---

## Task 8: Final test run + handover

- [ ] **Step 1: Run full GUT panel**

Open Godot → Project → Tools → GUT → Run All.
Expected: previous 140 tests + the 4 new test files pass. No orphan nodes flagged.

If any pre-existing test fails, the most likely cause is a missed `Tooltip`/`CustomTooltip` reference. Investigate before continuing.

- [ ] **Step 2: Manual smoke**

Launch the project. Confirm:

- InfoPanel strip is present and empty at boot.
- Ascend view → hover the Ascend button → panel fills with live values per Task 6.
- Move off the button → panel blanks immediately.

- [ ] **Step 3: Commit any incidental cleanup**

If the GUT panel run regenerated `.uid` files for the new scripts, stage and commit them:

```bash
git add scripts/core/Icons.gd.uid scripts/ui/widgets/InfoPanel.gd.uid scripts/ui/widgets/Hoverable.gd.uid Scenes/InfoPanel.tscn.uid 2>/dev/null
git commit -m "add Godot-generated .uid files for info-panel scripts" --allow-empty
```

(If there's nothing to add, skip this step — `--allow-empty` not needed when there's no diff.)

- [ ] **Step 4: Update HANDOVER**

Append a short section to `docs/superpowers/HANDOVER.md` under "What's done" (or replace if reorganising) noting:

- Info-panel infra shipped (spec at `2026-04-25-info-panel-design.md`, plan at `2026-04-25-info-panel.md`).
- Available for future gameplay specs to consume — every hoverable element from now on uses §6 content rules.

Commit:

```bash
git add docs/superpowers/HANDOVER.md
git commit -m "HANDOVER: info-panel infra shipped"
```

---

## Done criteria

- All 4 new test files pass alongside the prior 140 in the GUT panel.
- `Main.tscn` has the `InfoPanel` strip wired between Content and BottomBar.
- Hovering the Ascend button shows live values matching the spec §6 example.
- `Tooltip.gd` / `CustomTooltip.tscn` removed and unreferenced.
- HANDOVER updated.
