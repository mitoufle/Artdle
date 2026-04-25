# Info-panel — Hover Description Surface

**Date:** 2026-04-25
**Status:** Approved design, ready for plan.

## 1. Goal

A dedicated UI surface that fills with a description whenever the mouse hovers any explainable element of the game (items, recipes, parts, sub-mechanic buttons, skill nodes, ascend buttons, etc.). Replaces the floating-tooltip pattern. Cross-cutting infrastructure: every future gameplay spec (Atelier+Inventaire first) emits content into it via a single signal.

## 2. Layout

A new `InfoPanel` sits between the existing `Content` panel and the `BottomBar` in `Main.tscn`. Horizontal strip, full width, fixed height (~100 px). Slightly contrasted background to read as a separate UI region.

```
TopBar              (nav buttons + speed toggle)
Content             (current view, expand_fill)
InfoPanel           ← new, ~100px
BottomBar           (4 currencies)
```

Layout fixed across all views — info content is always read in the same screen location.

## 3. Components

### 3.1 `InfoPanel` widget

**File:** `scripts/ui/widgets/InfoPanel.gd`. Attached to the `InfoPanel` node in `Main.tscn`. Script `extends PanelContainer`.

**Node tree:**

```
InfoPanel (PanelContainer, ~100px tall, full width)
└── MarginContainer
    └── HBoxContainer
        ├── TitleLabel (RichTextLabel, bbcode_enabled, ~30% width)
        ├── BodyLabel (RichTextLabel, bbcode_enabled, expand)
        └── FooterLabel (RichTextLabel, bbcode_enabled, ~25% width, right-aligned)
```

All three labels support BBCode so any field can carry inline `[img]` icons or color tags.

**Public API (panel script):**

```gdscript
func set_content(title: String, body: String, footer: String) -> void
func clear() -> void
```

`set_content` writes the three texts. `clear` blanks all three. Internally the panel listens to GameState signals (see §4) — callers don't talk to the panel directly.

### 3.2 `Hoverable` helper

**File:** `scripts/ui/widgets/Hoverable.gd`. Script `extends Node`, used as a **child node** of any `Control`-derived node that should publish hover info. Adding hover info to any element = adding a `Hoverable` child and setting three strings (or a Callable). Works for both `.tscn`-defined Controls and dynamically built ones (`Button.new()` + `add_child(Hoverable.new())`).

**Exports:**

```gdscript
@export var title: String = ""
@export var body: String = ""
@export var footer: String = ""

# Optional: when set, called on each hover to produce dynamic content.
# Must return Array[String] of length 3 — [title, body, footer].
var content_provider: Callable = Callable()
```

`content_provider` is a regular var (not `@export` — Godot's editor cannot set Callables, and they're always wired from code). When set, it's called on each `mouse_entered` and its three returned strings override the static `@export`s. Used for content that changes (e.g., a cost that drops as a multiplier rises).

**Behavior:**

- On `_ready()`: walk to the parent `Control`. Error (`push_error`) if the parent is not a `Control`. Connect `parent.mouse_entered` and `parent.mouse_exited`.
- On `mouse_entered`: resolve content (provider if set, else static), call `GameState.push_hover_info(title, body, footer)`.
- On `mouse_exited`: call `GameState.clear_hover_info()`.

### 3.3 `Icons` registry

**File:** `scripts/core/Icons.gd` (RefCounted, all static).

**Contents:**

```gdscript
const ICONS: Dictionary = {
    "gold":           "res://artdleAsset/Currency/coin.png",
    "fame":           "res://artdleAsset/Currency/fame.png",
    "inspiration":    "res://artdleAsset/Inspiration.png",
    "paint_mastery":  "res://artdleAsset/Currency/Painting_mastery.png",
}

static func bbcode(id: String, height: int = 16) -> String
static func has(id: String) -> bool
```

`bbcode("gold")` returns `"[img height=16]res://artdleAsset/Currency/coin.png[/img]"`. Unknown id returns `""` and emits a `push_warning`. `height` argument lets callers ask for a larger icon in titles vs body.

The registry starts with the 4 MVP currencies. Future specs (items, parts, recipes) extend `ICONS` with their own ids — same lookup, no API change.

## 4. Data flow

Single signal hub on `GameState` (consistent with the existing pattern):

```gdscript
signal hover_info_pushed(title: String, body: String, footer: String)
signal hover_info_cleared()

func push_hover_info(title: String, body: String, footer: String) -> void:
    hover_info_pushed.emit(title, body, footer)

func clear_hover_info() -> void:
    hover_info_cleared.emit()
```

`InfoPanel._ready` connects:

- `GameState.hover_info_pushed` → `set_content`
- `GameState.hover_info_cleared` → `clear`

The panel exposes only its public methods — emitters never reference it directly. This keeps the panel decoupled from popups, views, dynamic widgets, etc.

## 5. Default and exit behavior

- **Boot:** panel reads empty (three blank labels).
- **Mouse exit:** `Hoverable` emits `clear_hover_info` → panel blanks. No placeholder, no transition.
- **Mouse enter on another element:** the new push overwrites (no prior clear required), so moving directly between elements doesn't blink to empty.

This is auto-clear without placeholder.

## 6. Usage example

**Static content (`.tscn`-defined button):** add a `Hoverable` child node in the editor and set the three strings on it.

```
[node name="AscendButton" type="Button" parent="VBoxContainer"]
text = "Ascend"

[node name="Hoverable" type="Node" parent="VBoxContainer/AscendButton"]
script = ExtResource("hoverable_script")
title = "Ascendance"
body = "Réinitialise le run en cours et te donne de la fame proportionnelle à l'inspiration accumulée."
footer = "Palier requis : 1000 [img]res://artdleAsset/Inspiration.png[/img]"
```

**Dynamic content (button created at runtime, e.g., a `PartUpgradeButton`):**

```gdscript
const HoverableScript = preload("res://scripts/ui/widgets/Hoverable.gd")

func setup(p_id: String) -> void:
    part_id = p_id
    # ... existing wiring ...

    var hov = HoverableScript.new()
    hov.content_provider = func() -> Array:
        var lvl = GameState.tree.get_part_level(part_id)
        var cost = TreeStages.upgrade_cost(GameState.tree.stage_index, part_id, lvl)
        return [
            "%s (Lv.%d)" % [part_id.capitalize(), lvl],
            "Augmente la production d'inspiration de cette partie de l'arbre.",
            "Coût : %s %s" % [Formatter.short(cost), Icons.bbcode("gold")]
        ]
    add_child(hov)
```

## 7. Tests

- `test_icons.gd`: known id → expected BBCode string ; unknown id → empty + warning.
- `test_game_state_hover.gd`: `push_hover_info` emits `hover_info_pushed` with the right args ; `clear_hover_info` emits `hover_info_cleared`.
- `test_info_panel.gd` (integration): instantiate `InfoPanel`, emit `GameState.hover_info_pushed`, assert `TitleLabel.text` etc. updated ; emit `clear`, assert blanks.
- `test_hoverable.gd`: instantiate parent `Control` + `Hoverable`, emit `mouse_entered` / `mouse_exited` on parent, assert `GameState` signals fire with the right payload (static and dynamic provider variants).

Tests live in `tests/` next to existing unit tests. Any test that creates a `Node` follows the existing `after_each { node.free() }` orphan-cleanup pattern.

## 8. Migration

The current `Tooltip` widget (`scripts/ui/widgets/Tooltip.gd`, `Scenes/CustomTooltip.tscn`) was a placeholder for the floating model and is no longer used. Delete both files in the implementation pass.

The Phase 4 plan referenced a dedicated workshop popup and instead reused `CanvasPopup`. The info-panel is unrelated — no impact on that decision.

## 9. Out of scope

- Animation (fade-in/out, slide, etc.).
- Custom theming / colors / fonts beyond BBCode tags inside content strings.
- Auto-discovery of hover info on dynamically built `Control`s without a `Hoverable` attached. Each emitter must opt in.
- Internationalization. Strings are French-only for now ; i18n will be a separate spec.
- Hover content for elements outside `Main.tscn`'s view stack (e.g., the `TopBar` nav buttons themselves, the speed toggle).

## 10. Definition of done

- `InfoPanel` is visible in `Main.tscn` between Content and BottomBar.
- `Hoverable.gd` attached to at least one element (validation target: the `AscendButton` in `AscendancyView`) populates the panel on hover and blanks it on exit.
- BBCode `[img]` for `gold` renders the coin icon inline.
- All four test files above pass via the GUT editor panel.
- `Tooltip.gd` and `CustomTooltip.tscn` are deleted from the repo.
