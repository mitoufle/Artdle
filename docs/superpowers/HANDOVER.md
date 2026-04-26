# Artdle Rebuild — Session Handover

**Last session:** 2026-04-26
**Status:** Canvas redesign — backend complete, Phase F UI shipped (text-authored .tscn). 232/232 GUT tests pass. **Several UI bugs surfaced after first F5; many fixed in-session, more remain (user said "il y'a encore enormément de bug" — needs hands-on diagnosis next session).** Branch `feat/canvas` is 37 commits ahead of `master`.

---

## Where the project stands

- **Branch:** `feat/canvas`. NOT yet merged to `master` (master still at `d4bf992`, post-WIP-promotion).
- **Specs shipped on master** (`bb22d74`): `docs/superpowers/specs/2026-04-25-canvas-design.md` and `2026-04-25-atelier-design.md`.
- **Plan shipped on master** (`d6421d8`): `docs/superpowers/plans/2026-04-26-canvas-implementation.md` (30 tasks, phases A→G).
- **Phases A-G shipped** on `feat/canvas` (commits `a7deb6b` → `1c71d03`).
- **Godot 4.6.2**, GUT 9.x (editor panel; CLI broken).
- **Tests:** 232/232 passing.

---

## What's done (full session arc)

### Spec writing (start of session, on master)
Two WIPs promoted to final specs (`bb22d74`). Items-source resolved to canvas drops (was undefined in WIPs). Tuning values invented per "difficile, long, récompensant" north star, all flagged in §15.

### Plan writing (start of session, on master)
30 tasks across 7 phases A-G, written into `docs/superpowers/plans/2026-04-26-canvas-implementation.md` (`d6421d8`).

### Phase A — Data foundations (Tasks 1-7, on `feat/canvas`)
- `scripts/config/Subjects.gd` — 20 subjects + prereq graph (5 starters + 15 derived, all with `mastery_tier 5` prereqs)
- `scripts/systems/SubjectMastery.gd` — Node, exponential XP curve `200·2^(T-1)` to MAX_TIER 10, `is_unlocked`, `has_hint`
- `scripts/core/Balance.gd` — 9 new static methods covering quality, ideal, gold, PM, time, gamble (success/failure/with_mult)

### Phase B — Canvas core refactor (Tasks 8-10)
- `scripts/systems/CanvasConfig.gd` — sticky settings (style/palette/sujet/gamble + per-run ceilings)
- `scripts/systems/Canvas.gd` REWRITTEN — per-slot, `start(paint_time, quality)`, `tick(delta)`, `signal finished(payload)`. Old API (tier/sell/sold/upgrade_tier/is_ready_to_sell) removed
- `scripts/autoloads/GameState.gd` wires SubjectMastery + CanvasConfig

### Phase C — Multi-canvas + drops (Tasks 11-14)
- `scripts/systems/CanvasSlots.gd` — multi-slot orchestrator with `canvas_completed`, `canvas_starting`, `drop_rolled` signals
- `GameState` rewires from single Canvas to CanvasSlots. New helpers: `_canvas_tier`, `upgrade_canvas_tier()`, `_on_canvas_completed`. Ascend uses `on_reset: Callable`
- 4 broken pending tests un-stubbed with new API equivalents

### Phase D — Skill tree Canvas branch (Tasks 15-18)
- 17 new entries in `SkillTreeNodes.gd` with `branch: "canvas"`. MVP nodes tagged `branch: "mvp"`. Total Canvas-branch fame cost: **970** (plan said 935 — arithmetic error in plan, fixed in test)
- `SkillTree.unlock()` enforces `prereq` array BEFORE debiting fame
- 9 aggregator methods on `SkillTree`
- `GameState.tick()` pushes 9 aggregators into CanvasSlots; `refresh_canvas_slot_count()` triggers on `node_unlocked`. Slots clamped 1-8

### Phase E — Improvement panel + ceilings (Tasks 19-21)
- `CanvasConfig` static cost methods: `style_ceiling_cost(N) = 100·3^(N-1)`, palette same, `subject_hint_cost(N) = 1000·2^N`
- `GameState.buy_style_ceiling()` / `buy_palette_ceiling()` — atomic gold sinks
- `CanvasSlots.canvas_starting` signal + `GameState._on_canvas_starting` debits inspiration. Silent-skip on insufficient via `gamble_skipped` meta flag

### Phase G — Integration tests (Tasks 28-30)
- `test/test_gamestate_canvas_loop.gd` — 10 tests: slot count expansion, quality floor propagation, buy_ceiling sinks (3), gamble spend (2), save/load roundtrip, end-to-end loop, chef d'œuvre override

### Phase F — UI rebuild (Tasks 22-27, originally deferred but completed in-session)
- `scripts/ui/widgets/CanvasSlotCard.gd` + `Scenes/Widgets/CanvasSlotCard.tscn` — per-slot card showing "Subject — Tier N — Q X.X" + ProgressBar (max_value 1.0)
- `scripts/ui/widgets/DropFeed.gd` + `Scenes/Widgets/DropFeed.tscn` — last-5 drops with full English names ("Knife T1 (Legacy)")
- `views/PaintingView.tscn` + `scripts/ui/views/PaintingView.gd` rebuilt — slot list (in ScrollContainer) + drop feed + 3 buttons: Canvas / Workshop / Painter Office
- `Scenes/CanvasPopup.tscn` + `scripts/ui/popups/CanvasPopup.gd` rebuilt — TabContainer with **Configuration** (style + palette HSliders, subject OptionButton with hint placeholders, gamble OptionButton) and **Improvement** (Upgrade Canvas Tier + Buy Style Ceiling + Buy Palette Ceiling buttons with live cost labels)
- `Scenes/WorkshopPopup.tscn` + `scripts/ui/popups/WorkshopPopup.gd` (new) — minimal Workshop tier upgrade popup
- 11 Hoverable child nodes wired across CanvasPopup (6), CanvasSlotCard (1), PaintingView buttons (3), Workshop placeholder (none yet — could add). All single-line English bodies, player-facing
- Inventory + Craft buttons REMOVED from PaintingView per spec §2 ("Atelier is one merged mechanic"). The Atelier plan will add a single "Atelier" button when shipped

---

## Bugs surfaced after F5 in this session — fixed

| Bug | Cause | Fix commit |
|---|---|---|
| `_ready` crash: `canvas.sold` not found | Phase B removed signal; Phase C didn't fix until Task 14 | `484431a` (interim comment-out, then `002e66e` did proper rewire) |
| Test `test_ascend.gd:89` runtime error: `canvas.tier = 5` | Same Canvas API removal | `f2a9845` (stub 4 tests as `pending()`, un-stubbed in `002e66e`) |
| Cross-test leak: `slots.quality_floor_bonus` stuck at 2.0 | Test order: `test_quality_floor_propagates_to_slots_on_tick` ran before `test_canvas_sale_with_modifiers` | `8a209e5` (added `tick(0.0)` to `before_each` to refresh aggregators) |
| `paint_time_override` set after canvas already started → tick(1.5) doesn't finish | The override applies on `_start_slot`, not on running canvases | `9cc4a8f` (test pattern: `set_slot_count(0); set_slot_count(1)` to force restart with override) |
| GDScript lambda captures primitive bool by value | `on_reset_called: bool` flag never mutated by callback | `9cc4a8f` (changed to `Array = [false]`, mutated as `[0] = true`) |
| Gamble test got 30 inspi instead of 40 | `tick(0.01)` finished + auto-restarted canvas → `canvas_starting` fired twice → double-spend | `5dc541d` (use long `paint_time = 1.0`, no auto-restart in tick) |
| Gold test got 82.5 / 66 / 40 instead of 49.5 / 49.5 / 30 | `subject_mastery` not reset between tests; previous test's nature mastery=1 leaked, raising quality from 3 to 4 | `bd448a4` (added `subject_mastery.reset()` to `before_each` in 2 test files) |
| `chef_doeuvre_chance = 1.0` overridden back to 0.005 by `GameState.tick()` aggregator pass | Test set chance directly then called full `GameState.tick`, which re-derives chance from skill_tree state | `bd448a4` (use `slots.tick()` directly, bypass GameState aggregator pass) |
| ProgressBar showing full at 1% | ProgressBar default `max_value = 100`, script wrote 0..1 ratio | `b5c7972` (set `max_value = 1.0` in .tscn) |
| Stray `Q:3.0` floating below progress bar | Separate QualityLabel below SubjectLabel | `b5c7972` (merged into SubjectLabel as `Nature — Tier 1 — Q 3.0`, removed QualityLabel) |
| DropFeed garbled `cou/T1 her bru/T1 ate` | 3-char abbreviations + HBox concat | `b5c7972` (full names: `Knife T1 (Legacy)` via SLOT_NAMES + SET_NAMES dicts) |
| Mixed French/English UI text | Initial Phase F bodies in French | `b5c7972` (full English translation of all 11 Hoverable bodies + UI labels) |
| 3 buttons (Inventory/Craft/Office) for what should be one Atelier | Conflict with spec §2 | `b5c7972` (removed Inventory + Craft; Atelier plan will replace with one button) |
| No Workshop button | Removed in cleanup based on misreading of spec ("Atelier+Inventory merged") — actually Workshop IS the English name for Atelier | `1c71d03` (restored + new minimal `WorkshopPopup.tscn`/`.gd` as placeholder for future Atelier panel) |
| Workshop UI was aliased to old CanvasPopup; new CanvasPopup has no Canvas tier upgrade | Plan §10 said tier upgrade goes in Improvement tab; rewrite forgot to port the OLD popup's upgrade button | `1c71d03` (added "Upgrade Canvas Tier" button to Improvement tab) |
| Hoverable bodies too verbose, perceived as "random info appearing" | Multi-clause paragraphs | `1c71d03` (trimmed to single-line, focused) |

---

## ⚠️ KNOWN BUGS NOT YET DIAGNOSED — START HERE NEXT SESSION

The user reports more UI bugs after the latest commit (`1c71d03`). Specifically reported in last messages:

1. **"Inspiration production stops abruptly when advancing to a new tree stage"** — Confirmed pre-existing in `InspirationTree._check_stage_advance` line 68: `_part_levels = {}` resets all parts on stage advance. By design (each stage has its own parts), but **user finds this jarring**. Possible fixes:
   - Carry over part levels for parts that exist in both old and new stage (`roots` exists in stages 0-4 — keep its level)
   - Auto-purchase the new stage's parts at level 1 on advance (safety floor)
   - Show clearer feedback ("New stage! Upgrade roots/leaves/branches to resume production")
   - Leave as-is and accept the design

2. **"Hover info appears randomly when hovering Canvas / Painter Office buttons"** — User claim, not yet diagnosed. After `1c71d03` (verbose-body trim), should be less noisy. **If still happening, need user to describe exactly what text appears unexpectedly.** Possible causes to investigate:
   - Multiple Hoverables firing in sequence as mouse traverses neighbor controls
   - InfoPanel layout overlap with the buttons row
   - A Hoverable on a parent container we forgot about

3. **User said "il y'a encore enormément de bug"** — open-ended. Need user to enumerate.

---

## Architecture decisions worth knowing (carry-forward)

- **Items source = crafting only (decision 2026-04-26).** No drops on canvas completion. CanvasSlots no longer rolls drops; the `drop_rolled` signal, `force_drop` field, `SLOT_TYPES`/`SET_IDS` constants, `drop_chance()` static, and the entire `DropFeed` widget were deleted. **Canvas spec §11 is now obsolete** (annotated in-file). The Atelier brainstorm needs to redefine the items source — likely a craft action consuming gold/inspiration/mastery — before the Atelier plan can be written. Affixes/sets/8-slot equipping (Atelier spec §13) remain valid; only the input source changes.
- **Atelier-coupled affixes are NOT pre-coupled to Canvas.** GameState.tick() guards them with `inventory.has_method(...)` checks that return safe defaults. The Atelier plan replaces Inventory with the rolled affix system later.
- **CanvasSlots.canvas_starting fires on EVERY canvas start, including auto-restart.** In tests, `paint_time_override = 0.001 + tick(0.01)` causes one finish + one auto-restart per tick → 2 canvas_starting fires. Real production with `paint_time` = 3 seconds doesn't see this.
- **`subject_mastery` MUST be reset in `before_each`** of integration test files. The save/load roundtrip test deliberately preserves nature mastery; without a reset, that state leaks.
- **`GameState.tick()` overrides per-slot aggregator fields every frame.** Tests that need to force `chef_doeuvre_chance = 1.0` etc. must call `slots.tick()` directly to bypass.
- **Path conventions discovered:** existing on-disk layout is `Scenes/Widgets/` (capital W), `views/PaintingView.tscn` (root, NOT `Scenes/views/`), `Scenes/CanvasPopup.tscn` (root, NOT `Scenes/popups/`). The plan's path assumptions were wrong; res:// paths now match disk casing for Linux/Mac portability.
- **Atelier (French) = Workshop (English) — same single mechanic.** The "Workshop" button in PaintingView IS the future Atelier button. Current `WorkshopPopup.tscn` is a minimal placeholder (tier upgrade only); the Atelier plan will expand it into the full merged panel (8 equippable slots, 6 sets, 6 tiers, craft actions, persistence vault, item drops). Do NOT add a separate "Atelier" button — the Workshop button IS it.
- **MVP `Workshop.gd` system maps to the future Atelier level.** Its `tier` field is conceptually the per-run Atelier-level progression (spec §9.1 "Atelier level"). The cost curve will change (`100·1.15^N` per spec vs MVP's `1000·3^N`) and the multiplier outputs (`canvas_gold_mult`, `canvas_speed_mult`) will migrate to affix-driven items, but the underlying "you grind a level up per run" mechanism is preserved.
- **Canvas tier upgrade lives in CanvasPopup Improvement tab.** Not in WorkshopPopup despite naming confusion in MVP.

---

## What's next

### Immediate priority for next session — UI bugfix sweep

1. **User runs F5, lists every UI bug observed, paste-by-paste.** I diagnose and fix each.
2. **Tree stage advance behavior** — decide: carry-over part levels, or accept the design.
3. **Hover info "random"** — once user describes specific repro, fix it.

### Follow-up after bug sweep

4. **Test in editor that everything works** — full smoke test (all views, all popups, save/load, ascend cycle).
5. **Commit Godot-generated `.uid` files** — `git status` shows ~13 untracked. Run `git add scripts/**/*.uid test/**/*.uid` then commit as a tidy-up.
6. **Merge `feat/canvas` → `master`** when stable. 37 commits to integrate. `git merge --no-ff feat/canvas`.
7. **Start Atelier plan** — `superpowers:writing-plans` on `2026-04-25-atelier-design.md`. ⚠️ **Atelier = Workshop in English** — the existing Workshop button in PaintingView IS the Atelier entry point. Do NOT add a separate "Atelier" button. The plan will:
   - Replace `Workshop.gd` (MVP tier-multiplier system), `Inventory.gd`, `Craft.gd`, `InventoryPopup`, `CraftPopup` with the merged Atelier/Workshop system
   - Replace `WorkshopPopup.tscn` (current minimal placeholder) with the full merged panel: 8 equippable slots, 6 tiers, 6 sets, craft actions, persistence vault per spec §13
   - Map Atelier "level" (per-run XP) onto the existing `Workshop.tier` field
   - Implement the affix pool + 8 slots + 6 sets + persistence + skill tree Atelier branch (22 nodes)
   - Replace placeholder set/tier weights in `CanvasSlots._on_slot_finished` drop block with real §11.2-11.4 logic
   - Items provide `canvas_gold_mult`, `canvas_speed_mult`, etc. via affixes — replacing Workshop.gd's flat per-tier bonuses

### Background polish (not blocking)
- Hoverable wiring on the rest of the UI (Accueil, Ascendancy, SkillTree, BottomBar) — only AscendButton + Canvas UI wired so far
- `TreeVisual` placeholder circles → sprites
- `BottomBar` icons via `Icons.bbcode`
- Workshop UI polish (currently very minimal — just tier label + upgrade button)
- Live `content_provider` callbacks on hovers that show numbers (e.g., BuyStyle's exact current cost)
- Sound effects (`floating_text.tscn` still unused)

---

## How to resume (next session)

1. **Read this file.**
2. **Verify state:**
   ```bash
   git branch --show-current     # feat/canvas
   git log --oneline master..HEAD | wc -l    # 37
   git status --short            # clean (or .uid files untracked)
   ```
3. **Verify tests:** Godot editor → Project → Tools → GUT → Run All → 232 pass.
4. **F5 the project. List every bug observed.** Paste them in chat.
5. **Decide on tree stage advance behavior** (item #1 in known bugs above).
6. After UI bugs are flushed: pick option from "What's next" Follow-up section.

---

## Gotchas (carried forward)

### Test execution
- **GUT CLI broken.** Editor panel only.
- **Integration tests** in `test_gamestate_canvas_loop.gd` and `test_gamestate_full_loop.gd` reset: currency, tree, workshop, inventory, painter_office, skill_tree, **canvas_config, subject_mastery**, slot count, plus `tick(0.0)` to refresh aggregators.

### Godot 4.6 strictness
1. `class_name` + autoload typing → use `const FooClass = preload(...)`. GameState has 13 (Currency, Save, InspirationTree, PaintMastery, Workshop, Inventory, Craft, PainterOffice, SkillTree, Ascend, SubjectMastery, CanvasConfig, CanvasSlots).
2. `to_string()` collides with native — use `_to_string()`.
3. `.gdignore` in a directory makes Godot skip it.
4. `log()` is natural log; for log base 10 use `log(x) / log(10.0)`.
5. **Auto-restart in `_start_slot`** — `_on_slot_finished` calls `_start_slot(c)` synchronously. A single `tick(delta)` with `delta > paint_time` triggers ONE finish + ONE auto-restart in the same tick. `canvas_starting` fires twice in that case.
6. **GDScript lambdas capture primitives BY VALUE.** Mutating a captured `bool`/`int`/`float` inside a lambda is a no-op (silent in editor, warning in test runner: `CONFUSABLE_CAPTURE_REASSIGNMENT`). Use a 1-element `Array` or `Dictionary` instead.

### Save system
- `JSON.new().parse()` (not `JSON.parse_string`) — avoids GUT false failures.
- New save schema keys: `subject_mastery`, `canvas_config`, `canvas_tier` (replaces old `canvas`).

### Indentation
- GameState.gd uses TABS. Most other scripts use 4 spaces. Per-file consistency.
- New systems (`Subjects.gd`, `SubjectMastery.gd`, `CanvasConfig.gd`, `CanvasSlots.gd`) all use 4 spaces.
- Hoverable script uses tabs (parent: existing `scripts/ui/widgets/Hoverable.gd`).

### Architecture invariants (keep)
- `GameState.tick(delta)` called from `Main._process` (not `GameState._process`).
- Autoload subsystem types are `const XClass = preload(...)`.
- **CanvasSlots is loosely coupled to GameState.** Multipliers pushed via plain field assignment in `GameState.tick()`. Tests can directly set fields on slots to bypass GameState's aggregator overrides.

### Path conventions
- `Scenes/` (root, no popups/ subdir) for popups: CanvasPopup, WorkshopPopup, InventoryPopup, CraftPopup, PainterOfficePopup, BottomBar, InfoPanel.
- `Scenes/Widgets/` (capital W) for new widgets: CanvasSlotCard, DropFeed.
- `views/` (root, no Scenes/ prefix) for views: AccueilView, PaintingView, AscendancyView, SkillTreeView.
- `scripts/ui/{views,widgets,popups}/` for scripts.

### Pre-rebuild orphans (unchanged from prior HANDOVER)
Same list of `.tscn` files in `Scenes/` are still safe to delete: Animated_Plant, Ascendancy2DView, ClickerPopup, paintingscreen, UpgradeButton, tooltipedbtn, floating_text, plus Scenes/views/CanvasView.tscn (orphan from pre-rebuild). Plus Scenes/controls/ExperienceBar.tscn.

---

## Skill chain followed

- **Phases 1-4 (MVP rebuild):** brainstorming → writing-plans (×4) → executing-plans (×4) → finishing-a-development-branch (×4)
- **Info-panel infra:** brainstorming → writing-plans → executing-plans
- **Canvas + Atelier brainstorms:** brainstorming (closed)
- **Canvas spec → plan → backend (this session):** brainstorming → writing-plans → subagent-driven-development (Phases A-E + G; ~30 subagent dispatches)
- **Canvas Phase F (this session):** done by Claude directly (text-authored .tscn) due to subagents' inability to author scenes interactively. UI polish ongoing.
- **Pending:** Atelier plan → execution.

All prior phase plans archived in `docs/superpowers/plans/`.

---

## Quick status commands

```bash
cd /c/Users/mitoufle/Documents/artdle
git branch --show-current                    # feat/canvas
git status --short
git log --oneline master..HEAD               # 37 commits
git log --oneline d4bf992..HEAD              # since pre-spec state

# Launch Godot
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All  (or F5 to play)
```
