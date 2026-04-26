# Artdle Rebuild — Session Handover

**Last session:** 2026-04-26
**Status:** Canvas redesign — backend complete, UI deferred. **232/232 GUT tests pass** on branch `feat/canvas`. Phase F (UI rebuild, Tasks 22-27) is the only Canvas work remaining; user opted to do it manually in the Godot editor.

---

## Where the project stands

- **Branch:** `feat/canvas` (29 commits ahead of `master`). NOT yet merged. `master` still points at `d4bf992` (post-brainstorm WIPs).
- **Specs shipped:** `docs/superpowers/specs/2026-04-25-canvas-design.md` and `2026-04-25-atelier-design.md` (both promoted from WIPs in the previous session, committed on `master` at `bb22d74`).
- **Plan shipped:** `docs/superpowers/plans/2026-04-26-canvas-implementation.md` (30 tasks across 7 phases A→G).
- **Phases A-E + G shipped on `feat/canvas`:** data foundations, sticky configuration, multi-canvas slots, drops, skill tree Canvas branch (17 nodes), improvement panel sinks, gamble inspiration spend, integration tests.
- **Phase F (Tasks 22-27 — UI rebuild) deferred** to manual user work in the Godot editor. The plan has all the GD code; the user reproduces scene authoring in the editor for `CanvasSlotCard`, `DropFeed`, `PaintingView`, `CanvasPopup` (2-tab), and Hoverable wiring.
- **Godot version:** 4.6.2. **Test framework:** GUT 9.x (editor panel; CLI still broken).

---

## What's done

### Phases 1-4 (MVP) + info-panel
Unchanged from last session — see `git log master`. 156 prior tests still pass.

### Canvas + Atelier brainstorms → final specs (2026-04-25 → 2026-04-26)
- Both WIPs promoted to final specs at `bb22d74` on `master`.
- Items source resolved as canvas drops (was undefined in WIPs) — flagged in §15.3 of both specs as the #1 architectural assumption to validate.
- Tuning values invented per "difficile, long, récompensant" north star, all flagged for review in §15 of each spec.

### Canvas implementation plan written (2026-04-26)
30 tasks, phases A→G, on `feat/canvas` (commits `a7deb6b` → `bd448a4`).

### Phase A — Data foundations
- `scripts/config/Subjects.gd` — 20-subject prereq graph (5 starters + 15 derived, all with `mastery_tier 5` prereqs)
- `scripts/systems/SubjectMastery.gd` — Node, exponential XP curve `200·2^(T-1)` to MAX_TIER 10, carry-over on level-up, `is_unlocked` (AND-of-parents), `has_hint` (any-parent-at-half-tier)
- `scripts/core/Balance.gd` — 6 new static methods: `canvas_base_quality`, `canvas_ideal_quality`, `canvas_gold`, `canvas_pm_base`, `canvas_pm_burst_eligible`, `canvas_time` (with `STYLE_TIME_REDUCTION_CAP = 0.70` clamp), and 3 gamble methods using `log(x)/log(10.0)` (no `log10` builtin in GDScript)

### Phase B — Canvas core refactor
- `scripts/systems/CanvasConfig.gd` — Node holding sticky settings (style/palette/sujet/gamble + per-run ceilings)
- `scripts/systems/Canvas.gd` — REWRITTEN as per-slot. New API: `start(paint_time, quality)`, `tick(delta)`, `signal finished(payload: Dictionary)`. Old API (`tier`, `sell()`, `sold`, `is_ready_to_sell`, `upgrade_tier`) all removed
- `scripts/autoloads/GameState.gd` — wires `SubjectMastery` + `CanvasConfig` as autoload children

### Phase C — Multi-canvas + drops
- `scripts/systems/CanvasSlots.gd` — multi-slot orchestrator with `canvas_completed`, `canvas_starting`, `drop_rolled` signals. Gamble + chef d'œuvre resolution at finish. Auto-restart chain (spec §3.2)
- `GameState` rewires from single Canvas to CanvasSlots. New helpers: `_canvas_tier`, `upgrade_canvas_tier()`, `_on_canvas_completed`, `_current_canvas_tier()`. Ascend uses `on_reset: Callable` instead of holding a Canvas ref

### Phase D — Skill tree Canvas branch
- 17 new entries in `scripts/config/SkillTreeNodes.gd` (chef d'œuvre unlock, style/palette caps ×3 chained, subject hints ×2 chained, multi-canvas ×3 chained, gamble safety net, always-gamble, quality floor ×2 chained, auto-mastery passive). Existing 5 MVP nodes tagged `branch: "mvp"`. Total Canvas-branch fame cost: 970
- `SkillTree.unlock()` enforces `prereq` array BEFORE debiting fame
- 9 new aggregator methods on `SkillTree`: `style_cap`, `palette_cap`, `multi_canvas_slots_grant`, `quality_floor_bonus`, `subject_hint_count`, `chef_doeuvre_unlocked`, `always_gamble_unlocked`, `gamble_safety_net`, `auto_mastery_rate`
- `GameState.tick()` pushes 9 aggregators into `CanvasSlots` each frame; `refresh_canvas_slot_count()` triggered on `skill_tree.node_unlocked` (clamped 1-8 per spec §12)

### Phase E — Improvement panel + ceilings
- `CanvasConfig` static cost methods: `style_ceiling_cost(N) = 100·3^(N-1)`, palette same, `subject_hint_cost(N) = 1000·2^N`
- `GameState.buy_style_ceiling()` / `buy_palette_ceiling()` — atomic gold sinks gated by `skill_tree.style_cap()` / `palette_cap()`
- `CanvasSlots.canvas_starting` signal + `GameState._on_canvas_starting` debits inspiration when gamble is configured. Silent-skip on insufficient via `gamble_skipped` meta flag

### Phase G — Integration tests
- `test/test_gamestate_canvas_loop.gd` — 10 tests: slot count expansion, quality floor propagation, buy_ceiling sinks (3 tests), gamble spend (2 tests), save/load roundtrip, end-to-end loop, chef d'œuvre override
- 232 tests total across the project. All green

### Architectural decisions worth knowing
- **Atelier-coupled affixes are NOT pre-coupled to Canvas.** GameState.tick() guards them with `inventory.has_method(...)` checks that return safe defaults. The Atelier plan replaces Inventory with the rolled affix system later.
- **CanvasSlots.canvas_starting fires on EVERY canvas start, including auto-restart.** In tests, `paint_time_override = 0.001 + tick(0.01)` causes one finish + one auto-restart per tick → 2 canvas_starting fires. Real production with `paint_time` = 3 seconds doesn't see this.
- **`subject_mastery` MUST be reset in `before_each`** of integration test files. The save/load roundtrip test deliberately preserves nature mastery; without a reset, that state leaks into the next test (was 3 separate test failures during Phase G).
- **`GameState.tick()` overrides per-slot aggregator fields every frame.** Tests that need to force `chef_doeuvre_chance = 1.0` etc. must call `slots.tick()` directly to bypass the GameState pass.

---

## What's next

### Phase F — UI rebuild (Tasks 22-27 in the plan, USER-DRIVEN)

Plan reference: `docs/superpowers/plans/2026-04-26-canvas-implementation.md`. Each task has the GD script in full + the scene-tree description. User authors the `.tscn` files in the Godot editor.

| # | What to build |
|---|---|
| 22 | `Scenes/widgets/CanvasSlotCard.tscn` + `scripts/ui/widgets/CanvasSlotCard.gd` — per-slot progress card |
| 23 | `Scenes/widgets/DropFeed.tscn` + `scripts/ui/widgets/DropFeed.gd` — last-5-drops badges |
| 24 | Rebuild `Scenes/views/PaintingView.tscn` + script — slot list + drop feed (currently broken: references removed `GameState.canvas` API) |
| 25 | Rebuild `Scenes/popups/CanvasPopup.tscn` + script — Configuration tab (style/palette sliders, subject picker, gamble dropdown) |
| 26 | Add Improvement tab to CanvasPopup (BuyStyle/BuyPalette/RevealHint buttons) |
| 27 | Wire `Hoverable` children per info-panel spec §6 on every interactive element |

**`scripts/ui/popups/CanvasPopup.gd` and `scripts/ui/views/PaintingView.gd` still reference removed Canvas API** (`canvas.tier`, `canvas.sell()`, `canvas.is_ready_to_sell()`, `canvas.upgrade_tier()`). The Peinture view will throw runtime errors if opened before Phase F. Editor still loads (boot is fine since the emergency fix at `484431a` commented out the broken `canvas.sold.connect` line).

### After Phase F: merge `feat/canvas` to `master`, then start the Atelier plan

The Atelier spec is ready (`2026-04-25-atelier-design.md`) and depends on the Canvas affix pool. Atelier is a fresh plan-write → execution cycle.

### Background follow-ups (not blocking)
- **Visual polish** as in prior HANDOVER (TreeVisual sprites, BottomBar icons, popup theming).
- **Hoverables rollout** — Phase F adds them for Canvas; the rest of the UI (Accueil, Ascendancy, SkillTree) still has only `AscendButton` wired.
- **Offline progress.**
- **Sound:** `floating_text.tscn` still unused.
- **Pre-rebuild `.tscn` orphans** — see HANDOVER §Pre-rebuild orphans, unchanged.
- **Untracked `.uid` files** Godot generated when the editor opened during Phase A/B/C — not yet committed (`git status` shows them).

---

## How to resume (checklist for next session)

1. **Read this file.**
2. **Verify branch:** `git branch --show-current` should be `feat/canvas`. `git log --oneline master..HEAD` should show 29 commits.
3. **Verify tests:** Godot editor → Project → Tools → GUT → Run All → 232 pass.
4. **If continuing Phase F manually:** open `docs/superpowers/plans/2026-04-26-canvas-implementation.md` and start at Task 22.
5. **If skipping to Atelier:** finish Phase F first (PaintingView is currently broken if opened) OR comment out the broken UI files temporarily and start writing the Atelier plan via `superpowers:writing-plans`. Atelier's plan-write should reference the Canvas spec for affix pool details.
6. **When Phase F lands:** smoke test in F5 — the Peinture view should display 1-8 slot cards with progress bars + a drop feed. CanvasPopup should have 2 tabs.
7. **Then merge `feat/canvas` → `master`** with `git merge --no-ff feat/canvas` (or PR).

---

## Gotchas (carried forward + new)

### Test execution
- **GUT CLI broken.** Editor panel only.
- **Integration tests use the `GameState` autoload directly**, not a fresh-instance pattern. `before_each` in `test_gamestate_canvas_loop.gd` and `test_gamestate_full_loop.gd` resets currency, tree, workshop, inventory, painter_office, skill_tree, **canvas_config, subject_mastery**, and slot count. Plus a `tick(0.0)` to refresh aggregators.
- **`paint_time_override` only applies on `_start_slot`**, not on a running canvas. Tests that change override mid-test must call `slots.set_slot_count(0); slots.set_slot_count(1)` to force a fresh start.
- **GDScript captures primitives by value in lambdas.** Tests using callbacks to mutate flags must use a 1-element Array (or Dictionary) — see `test_perform_resets_subsystems` in `test_ascend.gd`.

### Godot 4.6 strictness
1. `class_name` + autoload typing breaks → use `const FooClass = preload(...)` (GameState has 14 now: Currency, Save, InspirationTree, PaintMastery, Workshop, Inventory, Craft, PainterOffice, SkillTree, Ascend, SubjectMastery, CanvasConfig, CanvasSlots).
2. `to_string()` collides with native — use `_to_string()`.
3. `.gdignore` in a directory makes Godot skip it.
4. `log()` is natural log; for log base 10 use `log(x) / log(10.0)`.
5. **Auto-restart in `_start_slot`** — when a canvas finishes, `_on_slot_finished` calls `_start_slot(c)` synchronously. A single `tick(delta)` with `delta > paint_time` triggers ONE finish + ONE auto-restart in the same tick. `canvas_starting` fires twice in that case.

### Save system
- `JSON.new().parse()` (not `JSON.parse_string`) — avoids GUT false failures.
- `push_warning` for non-fatal; `push_error` triggers GUT failure.
- New save schema keys: `subject_mastery`, `canvas_config`, `canvas_tier` (replaces old `canvas`).

### Indentation
- GameState.gd uses TABS. Most other scripts use 4 spaces. Per-file consistency. Godot's editor auto-converts on save.
- `Subjects.gd`, `SubjectMastery.gd`, `CanvasConfig.gd`, `CanvasSlots.gd` all use 4 spaces.

### Architecture invariants (keep)
- `GameState.tick(delta)` called from `Main._process` (not `GameState._process`).
- Autoload subsystem types are `const XClass = preload(...)`.
- **CanvasSlots is loosely coupled to GameState.** It receives multipliers via plain field assignment in GameState.tick. This lets CanvasSlots be tested in isolation (with the test directly setting fields).

### `.tscn` files written by hand
- Phase 4 `.tscn` files were written as plain text. Godot regenerates UIDs on first editor load. Expect incidental diffs.
- **Phase F will TOUCH these files**: `Scenes/views/PaintingView.tscn`, `Scenes/popups/CanvasPopup.tscn`. User does this in the editor.
- **Phase F creates new files**: `Scenes/widgets/CanvasSlotCard.tscn`, `Scenes/widgets/DropFeed.tscn`.

### Files broken in `feat/canvas` until Phase F lands
- `scripts/ui/popups/CanvasPopup.gd` lines 14, 16, 23 reference `GameState.canvas.tier` and `upgrade_tier()`.
- `scripts/ui/views/PaintingView.gd` lines 17, 30, 31, 34 reference `GameState.canvas.sell()`, `tier`, `is_ready_to_sell()`.

These are lazy errors — they only fire if the popup/view is actually opened. The project boots cleanly. Tests don't touch these files.

### Pre-rebuild orphans
Unchanged from prior HANDOVER — same list of `.tscn` files in `Scenes/` are still safe to delete.

---

## Skill chain followed

- **Phases 1-4 (MVP rebuild):** brainstorming → writing-plans (×4) → executing-plans (×4) → finishing-a-development-branch (×4)
- **Info-panel infra:** brainstorming → writing-plans → executing-plans
- **Canvas + Atelier brainstorms:** brainstorming (closed)
- **Canvas spec → plan → backend (this session):** brainstorming (continued, advisor consulted) → writing-plans → subagent-driven-development (Phases A-E + G; ~30 subagent dispatches)
- **Canvas Phase F:** to be done manually by user

All prior phase plans archived in `docs/superpowers/plans/`.

---

## Quick status commands

```bash
cd /c/Users/mitoufle/Documents/artdle
git branch --show-current                    # feat/canvas
git status --short
git log --oneline master..HEAD               # 29 commits
git log --oneline d4bf992..HEAD              # since pre-spec state

# Launch Godot (user's install)
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All  (or F5 to play)
```
