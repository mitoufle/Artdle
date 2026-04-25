# Artdle Rebuild — Session Handover

**Last session:** 2026-04-24
**Status:** **Phase 4 complete — MVP playable.** 140/140 GUT tests pass. Game verified in-editor: Accueil tree + Peinture canvas + Ascend + Skill Tree all wired, save/load round-trip works.

---

## Where the project stands

- **Branch:** `master`. **26 commits ahead of `Origin/master`** (10 Phase 3 + 15 Phase 4 + 1 indent normalize). Push when ready.
- **All 4 phases done** per the 2026-04-24 rebuild spec (`docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`). MVP satisfies spec §16 definition of done: 4 currencies, 5 tree stages, painting loop with gated sub-mechanics, ascend + skill tree, save/load, 140 tests.
- **Godot version:** 4.6.2. **Test framework:** GUT 9.x (editor panel; CLI still broken).

---

## What's done

### Phase 1 — Foundation (scripts/core/, scripts/systems/, autoloads)
BigNumber, Formatter, Balance, Currency, Save, GameState, SceneManager.

### Phase 2 — Core loop (scripts/config/, systems)
CanvasTiers (10 tiers), TreeStages (5 MVP stages), PaintMastery, Canvas, InspirationTree.

### Phase 3 — Systems
Workshop, Inventory, Craft (+CraftRecipes), PainterOffice, SkillTree (+SkillTreeNodes), Ascend. GameState aggregates 11 systems with `canvas_gold_multiplier()` / `canvas_speed_multiplier()` and sub-mechanic gating (`is_possible`/`is_active`/`try_activate_mechanic`).

### Phase 4 — UI (this session)

| Module | Role |
|---|---|
| `scripts/ui/views/BaseView.gd` | `_initialize_view` / `_connect_view_signals` / `_initialize_ui` hooks |
| `scripts/ui/widgets/CurrencyDisplay.gd` | auto-refresh on `Currency.changed` |
| `scripts/ui/widgets/BottomBar.gd` | 4 currency displays (inspiration/gold/fame/paint_mastery) |
| `scripts/ui/widgets/TreeVisual.gd` | placeholder circles per part (radius ~ level) |
| `scripts/ui/widgets/PartUpgradeButton.gd` | per-part gold upgrade |
| `scripts/ui/views/AccueilView.gd` | tree + parts + possibilities |
| `scripts/ui/views/PaintingView.gd` | canvas progress + 4 gated popup buttons |
| `scripts/ui/views/AscendancyView.gd` | palier, fame preview, ascend |
| `scripts/ui/views/SkillTreeView.gd` | node unlock buttons |
| `scripts/ui/popups/{Canvas,Inventory,Craft,PainterOffice}Popup.gd` | 4 sub-mechanic popups |
| `scripts/Main.gd` + `Main.tscn` | root scene: top nav, view stack, bottom bar, `tick(delta)` hub |

`project.godot` has `run/main_scene="res://Main.tscn"`. The workshop button currently opens `CanvasPopup` (plan note; dedicated workshop UI is a simple swap later).

**Bootstrap loop** (confirmed working): start at 0/0/0/0 → Peinture view → wait 2s → Vendre (+10 gold) → Accueil → upgrade Roots (5g) → inspi flows → upgrade toward stage advance.

### Info-panel infra (post-MVP)

The hover info-panel (spec `2026-04-25-info-panel-design.md`, plan `2026-04-25-info-panel.md`) shipped:

- Horizontal `InfoPanel` strip in `Main.tscn` between Content and BottomBar.
- `Hoverable` child-node helper for any Control to publish hover info via `GameState.push_hover_info(title, body, footer)`.
- `Icons` registry (`scripts/core/Icons.gd`) for inline currency/element BBCode icons.
- `GameState.hover_info_pushed` / `hover_info_cleared` signals.
- AscendButton wired with live palier + projected-fame content_provider as the §6 validation.
- Deprecated floating `Tooltip` and `CustomTooltip.tscn` deleted.

156 GUT tests pass (140 prior + 16 new for icons/hover-bus/info-panel/hoverable).

**Future gameplay specs reference §6 of the info-panel spec** (mandatory content authoring rule: numbers, live values, costs with icons, no narrative-only blurbs).

---

## What's next (post-MVP)

Spec §13 and §14 list post-MVP hooks — none of this is blocking MVP shipping:

- **Visual polish:** replace `TreeVisual` circles with sprites/SVG; add icons to BottomBar (the widget doesn't support `icon_texture` yet); theme the popups.
- **Dedicated WorkshopPopup:** currently aliased to CanvasPopup. Split once workshop gains its own controls (tier, separate gold mult ladder).
- **More stages / parts / recipes / nodes:** all data-driven via `config/` — just extend dictionaries.
- **Offline progress:** save timestamp + compute on load.
- **Hoverables on every interactive element:** the `InfoPanel` infra ships, but only `AscendButton` is currently wired. Add `Hoverable` children with `content_provider` lambdas (per spec §6) to every PartUpgradeButton, every popup recipe/item button, every sub-mechanic activation button, every Skill Tree node, etc.
- **Sound:** `floating_text.tscn` still sits unused from the pre-rebuild era.
- **Pre-rebuild assets cleanup:** `Scenes/{Ascendancy2DView,ClickerPopup,paintingscreen,Animated_Plant,UpgradeButton,tooltipedbtn,floating_text}.tscn` + `Scenes/views/` + `Scenes/controls/ExperienceBar.tscn` are orphaned. Remove in a cleanup PR.

---

## How to resume (checklist for next session)

1. **Read this file.**
2. **Verify branch:** `master`, clean working tree.
3. **Verify tests:** GUT editor panel → Run All → 140 pass.
4. **Launch project** (`Main.tscn` = main scene) → walk the bootstrap loop to confirm nothing regressed.
5. **Decide next scope:** polish (visual), extension (content), or cleanup (orphaned legacy files).
6. **Push to origin** when ready (`git push Origin master` — 26 commits pending).

---

## Gotchas (carried forward)

### Test execution
- **GUT CLI broken.** Editor panel only.

### Godot 4.6 strictness
1. **`class_name` + autoload typing breaks.** Use `const FooClass = preload(...)` in autoloads (GameState has 11). Non-autoload `Control`/`Node` scripts can keep `class_name`.
2. **`to_string()` collides with native `Object.to_string`** — use `_to_string()`.
3. **`.gdignore` in a directory makes Godot skip it** — don't leave it in dirs with real scripts.

### Save system
- `JSON.new().parse()` (not `JSON.parse_string`) — avoids GUT false failures.
- `push_warning` for non-fatal messages; `push_error` triggers GUT failure.

### Indentation
Per-file consistency only. Godot's editor auto-converts on save; expect incidental diffs. Project convention trends toward tabs (GameState, Main normalized to tabs).

### `.tscn` files written by hand in Phase 4
- Many Phase 4 `.tscn` files were written as plain text (UIDs stripped from new ext_resource lines). Godot regenerates UIDs on first editor load and rewrites the scene file. **Expect incidental `.tscn` diffs after first open of the MVP in the editor** — commit them as a tidy-up.
- `AccueilView.tscn`, `AscendancyView.tscn`, and `SkillTreeView.tscn` were **completely rewritten** (legacy layouts ejected). Don't search for old nodes — they're gone.

### Architecture invariants (keep)
- `GameState.tick(delta)` called from `Main._process` (not `GameState._process`). Keeps tests deterministic.
- All autoload subsystem types are `const XClass = preload(...)`, not `class_name`-typed vars.

### Orphan nodes in tests
Any `Node`-based system `.new()` in a test needs `after_each { node.free() }` to keep GUT orphan count at 0.

### Files not part of the rebuild
`default_bus_layout.tres` is user work — don't touch.

### Pre-rebuild `.tscn` orphans
The following still exist on disk but are not wired anywhere in the MVP:
- `Scenes/{Ascendancy2DView,ClickerPopup,paintingscreen,Animated_Plant,UpgradeButton,tooltipedbtn,floating_text}.tscn`
- `Scenes/views/` (entire directory)
- `Scenes/controls/ExperienceBar.tscn`
- `views/` had legacy contents but all four view `.tscn`s in use were overwritten

These reference deleted scripts; safe to delete in a cleanup pass.

---

## Phase 4 commits (on `master`, fast-forward-merged from `phase4-ui`)

```
ce079bb normalize Main.gd indentation to tabs (Godot editor auto-format)
6ea9c9b harmonize closure capture pattern in AccueilView
f6be900 wire all views and popups in Main.tscn — MVP playable
f55c635 add SkillTreeView with node unlocks and fame display
74bea46 add AscendancyView with palier, fame preview, ascend button
492ffd0 add PainterOfficePopup with hire button
256a90a add CraftPopup with recipe buttons
baeb980 add InventoryPopup with equip/unequip
392ca32 add CanvasPopup with tier upgrade
9e40ba9 add PaintingView with canvas progress and sub-mechanic buttons
1955299 add AccueilView with tree visual, parts upgrades, possibilities
ed4a267 add Main root scene with top bar and view switcher
0773ae6 add minimal Tooltip widget
0fa2a95 rebuild BottomBar with 4 currency displays (no XP bar)
ba03781 add CurrencyDisplay widget — live refresh on Currency.changed
1669be6 add BaseView parent with lifecycle hooks
```

16 commits on branch `phase4-ui`, fast-forward-merged into `master`, branch deleted.

---

## Skill chain followed (all 4 phases)

`superpowers:brainstorming` → `superpowers:writing-plans` (×4) → `superpowers:executing-plans` (×4) → `superpowers:finishing-a-development-branch` (×4)

All 4 phase plans archived in `docs/superpowers/plans/`. Rebuild done.

---

## Quick status commands

```bash
cd /c/Users/mitoufle/Documents/artdle
git branch --show-current
git status --short
git log --oneline Origin/master..HEAD

# Launch Godot (user's install)
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All  (or F5 to play)
```
