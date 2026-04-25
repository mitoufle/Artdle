# Artdle Rebuild — Session Handover

**Last session:** 2026-04-25
**Status:** MVP shipped + info-panel infra shipped + **Canvas + Atelier post-MVP brainstorms closed**. Two WIP design docs ready for promotion to final specs. 156/156 GUT tests pass.

---

## Where the project stands

- **Branch:** `master`. Pushed to `Origin/master`.
- **All 4 phases done** per the 2026-04-24 rebuild spec (`docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`). MVP satisfies spec §16 definition of done: 4 currencies, 5 tree stages, painting loop with gated sub-mechanics, ascend + skill tree, save/load, 140 tests.
- **Info-panel infra** shipped on top (`docs/superpowers/specs/2026-04-25-info-panel-design.md`).
- **Canvas + Atelier post-MVP brainstorms closed** (this session). WIPs at `docs/superpowers/specs/2026-04-25-canvas-design-WIP.md` and `2026-04-25-atelier-design-WIP.md`.
- **Godot version:** 4.6.2. **Test framework:** GUT 9.x (editor panel; CLI still broken).

---

## What's done

### Phase 1 — Foundation (scripts/core/, scripts/systems/, autoloads)
BigNumber, Formatter, Balance, Currency, Save, GameState, SceneManager.

### Phase 2 — Core loop (scripts/config/, systems)
CanvasTiers (10 tiers), TreeStages (5 MVP stages), PaintMastery, Canvas, InspirationTree.

### Phase 3 — Systems
Workshop, Inventory, Craft (+CraftRecipes), PainterOffice, SkillTree (+SkillTreeNodes), Ascend. GameState aggregates 11 systems with `canvas_gold_multiplier()` / `canvas_speed_multiplier()` and sub-mechanic gating (`is_possible`/`is_active`/`try_activate_mechanic`).

### Phase 4 — UI

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

- Horizontal `InfoPanel` strip in `Main.tscn` between Content and BottomBar.
- `Hoverable` child-node helper for any Control to publish hover info via `GameState.push_hover_info(title, body, footer)`.
- `Icons` registry (`scripts/core/Icons.gd`) for inline currency/element BBCode icons.
- `GameState.hover_info_pushed` / `hover_info_cleared` signals.
- AscendButton wired with live palier + projected-fame content_provider as the §6 validation.
- Deprecated floating `Tooltip` and `CustomTooltip.tscn` deleted.

156 GUT tests pass (140 prior + 16 new for icons/hover-bus/info-panel/hoverable).

**Future gameplay specs reference §6 of the info-panel spec** (mandatory content authoring rule: numbers, live values, costs with icons, no narrative-only blurbs).

### Canvas + Atelier post-MVP brainstorms (this session, 2026-04-25)

Closed brainstorms for the next two major systems. Two WIP design docs saved as crash-safe persistence (the previous session crashed mid-brainstorm — durable artefacts now exist):

- **`docs/superpowers/specs/2026-04-25-canvas-design-WIP.md`** — Canvas redesign. Sticky-config + observed-loop operating model. ~12 dimensions exposed (taille, style, palette, sujet, gamble, mastery, qualité, etc.). Hidden subject discovery graph (5 starters, all others derived via prereqs). Skill tree Canvas branch (sister to Atelier). Multi-canvas via Painter Office workers. Auto-sale.
- **`docs/superpowers/specs/2026-04-25-atelier-design-WIP.md`** — Atelier+Inventaire redesign. 8 slots (brush, palette, chapeau, blouse, gants, chevalet, couteau, broche), 6 sets with build archetypes (4 with procs/bursts, 2 continuous), strict B+C items-as-materials, 22-node skill tree Atelier branch (themed sub-branches), two-tier persistence (4 pin slots + 4 craft-permanence), stash management (200-500 cap + single grid + lock-and-auto-clean).

**Tuning north star (Atelier):** *"difficile, long, récompensant"* — hardcore patient ARPG philosophy. All numerical tuning (drop rates, success probabilities, costs) follows it.

The Canvas brainstorm was a forced pivot mid-Atelier-brainstorm — the Atelier affix pool depends on canvas stats. Both designs are coherent and validated. Affix pool fully derived. Build coverage validated (6 specialized + balanced default).

---

## What's next

**Immediate priority — promote WIPs to final specs:**

1. Read both WIP design docs (canvas + atelier).
2. Promote `2026-04-25-canvas-design-WIP.md` → `2026-04-25-canvas-design.md` (clean, organize, fill in initial values for the WIP's "Open questions" section).
3. Promote `2026-04-25-atelier-design-WIP.md` → `2026-04-25-atelier-design.md` (clean, organize, fill in initial values for the "To nail in spec writing" section using the *"difficile, long, récompensant"* north star).
4. Spec self-review (per brainstorming skill) on each promoted spec.
5. User reviews. Then `superpowers:writing-plans` for the implementation plan.
6. **Implementation order:** Canvas first (Atelier affix pool depends on canvas stats), Atelier second.

**Background follow-ups (not blocking, fold in opportunistically):**

- **Visual polish:** replace `TreeVisual` circles with sprites/SVG ; add icons to BottomBar ; theme the popups.
- **Dedicated WorkshopPopup:** currently aliased to CanvasPopup. Split once workshop gains its own controls.
- **Hoverables rollout:** only `AscendButton` is currently wired. Add `Hoverable` children to every interactive element per info-panel spec §6.
- **Offline progress.**
- **Sound:** `floating_text.tscn` still sits unused.
- **Pre-rebuild assets cleanup:** `Scenes/{Ascendancy2DView,ClickerPopup,paintingscreen,Animated_Plant,UpgradeButton,tooltipedbtn,floating_text}.tscn` + `Scenes/views/` + `Scenes/controls/ExperienceBar.tscn` are orphaned.

---

## How to resume (checklist for next session)

1. **Read this file.**
2. **Read the two WIP design docs** (`2026-04-25-canvas-design-WIP.md` + `2026-04-25-atelier-design-WIP.md`).
3. **Verify branch:** `master`, clean working tree, in sync with `Origin/master`.
4. **Verify tests:** GUT editor panel → Run All → 156 pass.
5. **Promote WIPs to final specs** (see "What's next" above).
6. **Then writing-plans → executing-plans** for implementation, Canvas first.

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

## Skill chain followed

- **Phases 1-4 (MVP rebuild):** `superpowers:brainstorming` → `superpowers:writing-plans` (×4) → `superpowers:executing-plans` (×4) → `superpowers:finishing-a-development-branch` (×4)
- **Info-panel infra:** brainstorming → writing-plans → executing-plans
- **Canvas + Atelier brainstorms (this session):** `superpowers:brainstorming` (closed). Next: spec writing → writing-plans → executing-plans.

All prior phase plans archived in `docs/superpowers/plans/`.

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
