# Artdle Rebuild — Session Handover

**Last session:** 2026-04-26 (afternoon — code review + merge)
**Status:** `feat/canvas` MERGED to master. 238 GUT tests pass. Save/load DISABLED in production during rebuild churn (every launch is a fresh run; functions still callable from tests). Item drops REMOVED per design call — items will be crafted only. **The Atelier brainstorm needs rework** to define the new items source before the Atelier plan can be written.

---

## Where the project stands

- **Branch:** `master` (post-merge). HEAD = `3786e6b` (merge commit). Local only — NOT pushed to origin.
- **`feat/canvas` branch still exists** as a marker; safe to delete with `git branch -d feat/canvas` once you're confident.
- **Specs on master:** `docs/superpowers/specs/2026-04-25-canvas-design.md` (§11 marked obsolete in-file — drops removed) and `2026-04-25-atelier-design.md` (still references canvas drops as items source — must be revisited).
- **Plans on master:** `docs/superpowers/plans/2026-04-26-canvas-implementation.md` (canvas implementation, fully shipped).
- **Godot 4.6.2**, GUT 9.x (editor panel only; CLI broken).
- **Tests:** 238/238 passing.
- **Save/load:** disabled in `scripts/Main.gd` (`load_game()` and `save_game()` calls commented). `GameState.save_game/load_game` functions intact for test roundtrip.

---

## What this session did (3 commits on master)

### Code review (full multi-agent code-reviewer pass)
The reviewer found **5 Critical + 5 Important + 8 Minor** issues against the canvas spec. Five of the worst shared a signature: "module unit-tested in isolation, never wired into production." All 5 Critical + 4 Important fixed; the remaining ones were obviated by save-disable.

### Commit `113de83` — tidy
- Tracked 13 Godot-generated `.uid` files for new Phase F scripts.
- Reverted `Hoverable.gd` to tab indentation (editor had auto-converted to spaces locally).

### Commit `e5473d7` — disable save/load during rebuild
- `Main.gd`: `load_game()` and `save_game()` calls commented.
- Side effect: review issues C2 (load doesn't refresh slot count) and I4 (no schema migration v1→v2) are obviated.

### Commit `ea85d03` — canvas: code review fixes + remove item drops per design call

Critical fixes:
- **C1 — Multi-slot gamble race.** `gamble_skipped` flag was on the shared `CanvasSlots` Node; slot B's start clobbered slot A's. Replaced with per-canvas `gamble_amount` meta stamped at start; the slot manager reads it on finish. Also fixes a latent bug where mid-canvas config changes corrupted the gamble outcome.
- **C3 — PM formula tested but never called.** `_on_canvas_completed` now applies spec §6.4: `floor(quality/10) * (2 if burst else 1) * pm_gain_mult`. Old `paint_mastery.on_canvas_sold(tier, gold)` call removed from production. New `pm_gain_multiplier()` hook returns 1.0 (skill-tree/inventory aggregators land with the Atelier plan).
- **C4a — `gamble_safety_net` no effect.** Now refunds 50% of inspi spent on gamble failure when unlocked. Payload extended with `gamble_succeeded` + `gamble_inspi_spent`.
- **C4b — `always_gamble_toggle` no UI.** `CanvasPopup` appends "Always (auto)" to the gamble picker when unlocked. `CanvasConfig.auto_gamble` flag + `set_auto_gamble()`. `GameState._resolve_gamble_amount()` picks the largest affordable preset at canvas start.
- **C4c — `auto_mastery_passive` no effect.** `_on_canvas_completed` grants `rate * mastery_gain` to every other unlocked subject when unlocked.
- **C5 — Subject hint mechanism incoherent.** Skill-tree `subject_hint_*` nodes now lower the parent-mastery threshold for revealing `?` subjects (default 3 → 2 → 1). `SubjectMastery.has_hint(threshold)` accepts an optional override. `CanvasPopup._hint_threshold()` derives from `skill_tree.subject_hint_count()`. `CanvasConfig.subject_hint_cost` static kept (deferred to Atelier plan's per-run reveal action).

Important fixes:
- **I1 — `CanvasSlotCard` hover dead zones.** `Progress` and `SubjectLabel` had `MouseFilter=STOP`; set to `MOUSE_FILTER_PASS` so the parent `PanelContainer.mouse_entered` fires across the whole card. Hover body trimmed to single line.
- **I2 — First canvas at boot.** Removed eager `set_slot_count(1)` from `_ready` (fired before `canvas_starting` was connected). The `connect`-then-`refresh_canvas_slot_count` flow at end of `_ready` covers it.
- **I3 — `CanvasPopup` picker thrash.** Was rebuilding the 20-item Subject `OptionButton` on every gold tick. Split refresh: `currency.changed` → improvement-tab buttons only; `subject_mastery.mastery_changed` (new signal) → picker only; `skill_tree.node_unlocked` → full refresh.

### Subject mastery persistence
`Ascend.perform()` does not reset `subject_mastery` (verified — no change needed). New test locks in the behavior.

### Items-source design call (drop removal)
- Removed `drop_rolled` signal, `force_drop` field, `SLOT_TYPES`/`SET_IDS` constants, `drop_chance()` static, the entire drop block in `CanvasSlots._on_slot_finished`.
- Deleted `Scenes/Widgets/DropFeed.tscn`, `scripts/ui/widgets/DropFeed.gd` + `.uid`, `views/PaintingView.tscn`'s Drops node, `PaintingView.gd._drops` field + connection.
- Deleted `test/test_canvas_drop.gd` + `.uid` (4 tests).
- Annotated canvas spec §11 obsolete in-file.

### Tests
- **+11 new tests:** C1 (per-slot meta), C3 (3 cases: sub-threshold/linear/burst), C4a (refund + no-refund), C4b (auto picks max + no-debit below smallest), C4c (passive + no-passive-without-node), C5 (threshold param), mastery persists on ascend.
- **−4 deleted:** drop_chance ×3 + force_drop emit ×1.
- Net: 232 → 238 passing.

---

## What's next

### Immediate priority — Atelier brainstorm rework
The Atelier spec (`2026-04-25-atelier-design.md`) and the canvas spec (§11) both rest on canvas drops as the items source. With drops removed, the Atelier brainstorm must redefine **where items come from**. Open questions:

1. **Recipe inputs.** What do you spend to craft an item — gold? inspiration? a new mastery-currency? combinations?
2. **Tier control.** How does the player escalate item tier — recipe upgrades? Atelier-level gating? a per-craft "fame burn" akin to gamble?
3. **Affix rolling.** Does the affix pool stay the same (rolled at craft time)? Or is it deterministic by recipe?
4. **Set affiliation.** Are sets craftable by name (player chooses), or rolled? Spec §11.2-11.4 RNG-rolled set tags; the new system needs a substitute mechanism.
5. **Throughput.** Drops were quality-driven (∼5-12% chance per canvas). What's the new pacing — 1 craft per N canvases? gated on mastery tiers?

Once the brainstorm closes, promote to a revised spec, then write the Atelier plan, then execute. The current `WorkshopPopup.tscn`/`.gd` is a minimal placeholder (tier upgrade only) — the plan will expand it into the full panel (8 slots, 6 sets, persistence vault, craft action UI). Do NOT add a separate "Atelier" button — the existing Workshop button IS the Atelier entry point.

### Carried-over UI items, NOT YET diagnosed

1. **Inspiration production stops abruptly when advancing to a new tree stage.** `InspirationTree._check_stage_advance` resets `_part_levels = {}` on stage advance. By design (each stage has its own parts) but user finds it jarring. Options: carry-over levels for parts that persist across stages, auto-purchase L1 on advance, clearer feedback, or accept design.
2. **Painting view layout has a large empty area** between the slot card (top of `ScrollContainer`) and the Canvas/Workshop/Office buttons row. With only 1 slot, the expanding `ScrollContainer` leaves a void. Cosmetic, not broken; could tighten by setting `size_flags_vertical = 0` on `ScrollContainer` and giving it a `custom_minimum_size` for ≥4 slot cases.

### Background polish (not blocking)
- Hoverable wiring on the rest of the UI (Accueil, Ascendancy, SkillTree, BottomBar) — Canvas UI + AscendButton are the only wired surfaces.
- `TreeVisual` placeholder circles → sprites.
- `BottomBar` icons via `Icons.bbcode`.
- Workshop UI polish (currently minimal — placeholder for the merged Atelier panel).
- Live `content_provider` callbacks on hovers showing numbers (e.g., BuyStyle's exact current cost).
- Sound effects (`floating_text.tscn` still unused).

---

## Architecture decisions worth knowing (carry-forward)

- **Items source = crafting only (decision 2026-04-26).** No drops on canvas completion. Atelier brainstorm must redefine items source before the plan can be written. Affixes/sets/8-slot equipping (Atelier spec §13) remain valid; only the input source changes.
- **Save/load disabled in production during rebuild.** `Main.gd` calls commented; `GameState.save_game/load_game` intact for test roundtrip. Re-enable with the next stable schema (probably after the Atelier ships).
- **Atelier-coupled affixes are NOT pre-coupled to Canvas.** `GameState.tick()` guards them with `inventory.has_method(...)` checks that return safe defaults. The Atelier plan replaces `Inventory` with the rolled-affix system later.
- **CanvasSlots.canvas_starting fires on EVERY canvas start, including auto-restart.** In tests, `paint_time_override = 0.001 + tick(0.01)` causes one finish + one auto-restart per tick → 2 `canvas_starting` fires. Real production with `paint_time` = 3s doesn't see this.
- **Per-canvas `gamble_amount` meta is the source of truth for gamble resolution.** Set on the Canvas instance in `GameState._on_canvas_starting` (via `slots.get_canvas(idx).set_meta`). Read in `CanvasSlots._on_slot_finished` (via `c.get_meta`). NOT shared on the slots Node — that was the C1 race bug.
- **`subject_mastery` MUST be reset in `before_each`** of integration test files. Without it, prior tests' mastery state leaks.
- **`GameState.tick()` overrides per-slot aggregator fields every frame.** Tests that need to force `chef_doeuvre_chance = 1.0` etc. must call `slots.tick()` directly to bypass.
- **Path conventions:** `Scenes/Widgets/` (capital W), `views/PaintingView.tscn` (root, not `Scenes/views/`), `Scenes/CanvasPopup.tscn` (root, not `Scenes/popups/`). Scene `res://` paths match disk casing for cross-platform safety.
- **Atelier (French) = Workshop (English) — same single mechanic.** The "Workshop" button in PaintingView IS the Atelier entry point. Current `WorkshopPopup.tscn` is a placeholder (tier upgrade only); the Atelier plan will expand it.
- **MVP `Workshop.gd` system maps to the future Atelier level.** Its `tier` field is conceptually the per-run Atelier-level progression. The cost curve and effect outputs will migrate to affix-driven items, but the "grind a level up per run" mechanism is preserved.
- **Canvas tier upgrade lives in CanvasPopup Improvement tab.** Not in WorkshopPopup despite naming confusion in MVP.

---

## How to resume (next session)

1. **Read this file.**
2. **Verify state:**
   ```bash
   git branch --show-current     # master
   git log --oneline -5          # 3786e6b merge on top
   git status --short            # clean
   ```
3. **Verify tests:** Godot editor → Project → Tools → GUT → Run All → 238 pass.
4. **Open the Atelier brainstorm:** `superpowers:brainstorming` on `2026-04-25-atelier-design.md` to rework the items source. Or, if you want to F5 first and pile up more UI feedback, do that and address before brainstorm.

---

## Gotchas (carried forward)

### Test execution
- **GUT CLI broken.** Editor panel only.
- **Integration tests** in `test_gamestate_canvas_loop.gd` reset: currency, `_canvas_tier`, `paint_time_override`, `unlocked_nodes`, `canvas_config`, `subject_mastery`, `painter_office`, slot count.
- **`save_game()` / `load_game()` still callable from tests.** Tests use them for roundtrip. Production has them commented out.

### Godot 4.6 strictness
1. `class_name` + autoload typing → use `const FooClass = preload(...)`. `GameState` has 13.
2. `to_string()` collides with native — use `_to_string()`.
3. `.gdignore` in a directory makes Godot skip it.
4. `log()` is natural log; for log base 10 use `log(x) / log(10.0)`.
5. **Auto-restart in `_start_slot`** — `_on_slot_finished` calls `_start_slot(c)` synchronously. A single `tick(delta)` with `delta > paint_time` triggers ONE finish + ONE auto-restart in the same tick.
6. **GDScript lambdas capture primitives BY VALUE.** Mutating a captured `bool`/`int`/`float` inside a lambda is a no-op (silent in editor, warning in test runner: `CONFUSABLE_CAPTURE_REASSIGNMENT`). Use a 1-element `Array` or `Dictionary` instead.

### Save system (disabled in production but retained)
- `JSON.new().parse()` (not `JSON.parse_string`).
- Save schema keys: `subject_mastery`, `canvas_config`, `canvas_tier`, `auto_gamble` (inside canvas_config).

### Indentation
- `GameState.gd` uses TABS. Most other scripts use 4 spaces. Per-file consistency.
- `Hoverable.gd` uses tabs.
- New systems (`Subjects.gd`, `SubjectMastery.gd`, `CanvasConfig.gd`, `CanvasSlots.gd`) all use 4 spaces.

### Architecture invariants (keep)
- `GameState.tick(delta)` called from `Main._process` (not `GameState._process`).
- Autoload subsystem types are `const XClass = preload(...)`.
- **CanvasSlots is loosely coupled to GameState.** Multipliers pushed via plain field assignment in `GameState.tick()`. Tests can directly set fields on slots to bypass GameState's aggregator overrides.

### Path conventions
- `Scenes/` (root, no popups/ subdir) for popups: CanvasPopup, WorkshopPopup, InventoryPopup, CraftPopup, PainterOfficePopup, BottomBar, InfoPanel.
- `Scenes/Widgets/` (capital W) for new widgets: CanvasSlotCard.
- `views/` (root, no Scenes/ prefix) for views: AccueilView, PaintingView, AscendancyView, SkillTreeView.
- `scripts/ui/{views,widgets,popups}/` for scripts.

### Pre-rebuild orphans
Same list of `.tscn` files in `Scenes/` are still safe to delete: Animated_Plant, Ascendancy2DView, ClickerPopup, paintingscreen, UpgradeButton, tooltipedbtn, floating_text, plus `Scenes/views/CanvasView.tscn` (orphan from pre-rebuild). Plus `Scenes/controls/ExperienceBar.tscn`.

---

## Skill chain followed

- **Phases 1-4 (MVP rebuild):** brainstorming → writing-plans (×4) → executing-plans (×4) → finishing-a-development-branch (×4)
- **Info-panel infra:** brainstorming → writing-plans → executing-plans
- **Canvas + Atelier brainstorms:** brainstorming (closed)
- **Canvas spec → plan → backend (prior session):** brainstorming → writing-plans → subagent-driven-development (Phases A-E + G; ~30 dispatches)
- **Canvas Phase F (prior session):** Claude direct (text-authored .tscn).
- **Code review + drop removal (this session):** requesting-code-review → fixes → merge.
- **Pending:** Atelier brainstorm rework → spec revision → plan → execution.

All prior phase plans archived in `docs/superpowers/plans/`.

---

## Quick status commands

```bash
cd /c/Users/mitoufle/Documents/artdle
git branch --show-current                    # master
git log --oneline -5
git status --short

# Launch Godot
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All  (or F5 to play)
```
