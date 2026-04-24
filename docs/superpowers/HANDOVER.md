# Artdle Rebuild — Session Handover

**Last session:** 2026-04-24
**Status:** Phase 3 complete (140/140 tests pass on master). Next: Phase 4 (UI — `Main.tscn`, views, popups, widgets).

---

## Where the project stands

- **Branch:** `master` (Phase 3 branch merged and deleted). Master is **ahead of `Origin/master` by 9 commits** — unpushed Phase 3 work. Push when ready.
- **Approach:** Full rebuild per spec (`docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`). Phases 1 (foundation), 2 (core loop), and 3 (systems) all merged to `master`. Old GDScript was stripped; existing `.tscn` layouts in `Scenes/` and `views/` stay as references — Phase 4 attaches new scripts to them.
- **Godot version:** 4.6.2.
- **Test framework:** GUT 9.x. CLI runner remains broken — verify via editor panel only (Project → Tools → GUT → Run All).

---

## What's done

### Phase 1 (Foundation) — `scripts/core/`, `scripts/systems/`, Phase 1 autoloads

| Module | Role |
|---|---|
| `core/BigNumber.gd` | Float wrapper, overflow caps at `MAX_VALUE=1e308` |
| `core/Formatter.gd` | K/M/B/T display formatting |
| `core/Balance.gd` | `palier_ascend`, `fame_conversion`, `paint_mastery_*` formulas |
| `systems/Currency.gd` | 4 pools (inspiration/gold/fame/paint_mastery), atomic spend, `changed` signal |
| `systems/Save.gd` | Atomic write, versioned, migration stub, fail-loud |
| `autoloads/GameState.gd` | Signal hub, preload-pattern for Currency + Save children |
| `autoloads/SceneManager.gd` | Minimal scene loader (expanded Phase 4) |

### Phase 2 (Core Loop) — `scripts/config/`, plus new systems

| Module | Role |
|---|---|
| `config/CanvasTiers.gd` | 10 tiers of canvas (gold_value, paint_seconds, upgrade_cost) |
| `config/TreeStages.gd` | 5 MVP stages (Pousse → Ancien) with parts + unlocks |
| `systems/PaintMastery.gd` | log-curve multiplier driven by canvas sales |
| `systems/Canvas.gd` | state machine, tick, sell (emits `sold`) |
| `systems/InspirationTree.gd` | stages + parts + upgrades + passive tick |
| `autoloads/GameState.gd` | wires Canvas + PaintMastery + InspirationTree; preload for all subclasses; explicit `tick(delta)` instead of `_process` (deterministic tests) |

### Phase 3 (Systems)

| Module | Role |
|---|---|
| `systems/Workshop.gd` | tier upgrade, contributes canvas gold + speed mults |
| `systems/Inventory.gd` | owned items, per-slot equip, contributes canvas_gold_mult |
| `config/CraftRecipes.gd` + `systems/Craft.gd` | gold → item crafting |
| `systems/PainterOffice.gd` | hire workers, contributes canvas speed mult |
| `config/SkillTreeNodes.gd` + `systems/SkillTree.gd` | fame spend → permanent effects (never resets) |
| `systems/Ascend.gd` | palier check, fame conversion, orchestrates subsystem reset |
| `autoloads/GameState.gd` (final form) | 11 preload consts, modifier aggregators (`canvas_gold_multiplier()`, `canvas_speed_multiplier()`), sub-mechanic gating (`_possible_mechanics`/`_active_mechanics` + `try_activate_mechanic`), full save/load |

**Totals: 140 tests passing in the GUT editor panel (Phase 1 + 2 + 3).**

---

## What's next (Phase 4: UI)

Plan file: `docs/superpowers/plans/2026-04-24-phase4-ui.md` (~25 tasks, 1045 lines).

Scope:
1. `BaseView` parent class with 3-hook lifecycle (`_initialize_view`, `_connect_view_signals`, `_initialize_ui`)
2. Widgets: `CurrencyDisplay`, `BottomBar`, `TreeVisual`, `Tooltip`
3. Four views: `AccueilView` (tree), `PaintingView`, `AscendancyView`, `SkillTreeView`
4. Four popups: Canvas, Inventory, Craft, PainterOffice
5. Root `Main.tscn` with view stack + `SceneManager` routing
6. Wire `GameState.tick(delta)` from `Main._process`
7. Manual-test checklist (spec §12)

Milestone: runnable game — open `Main.tscn`, see inspiration accumulate on the tree, upgrade parts with gold, sell canvases, ascend, spend fame. All of Phase 3's backend visible and interactive.

**Note:** Phase 4 is UI-heavy. Views attach scripts to existing `.tscn` files (`Scenes/`, `views/`) where possible; `AccueilView` layout is built fresh. See the plan for per-task guidance on "open existing scene and attach" vs "build from scratch in editor".

---

## How to resume (checklist for next session)

1. **Read this file.** Spec at `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md` for the full design context.
2. **Verify branch:** `git branch --show-current` → `master`. Decide if you want a `phase4-ui` branch before touching code.
3. **Verify Phase 1+2+3 still pass:** Open Godot, GUT panel → Run All → expect 140 pass.
4. **Read Phase 4 plan:** `docs/superpowers/plans/2026-04-24-phase4-ui.md`.
5. **Push master if you haven't** (`git push Origin master`) — 9 Phase-3 commits are local only.
6. **Execute tasks:** UI is a lot of small scenes/widgets. Phase 4 will require manual Godot-editor work for `.tscn` scene building — script-only changes can still follow the TDD pattern, but `.tscn` edits need the editor.

---

## Gotchas (carried forward — re-verify each phase)

### Test execution
- **GUT CLI is broken.** Always verify via the editor's GUT panel, not CLI.

### Godot 4.6 strictness
1. **`class_name` + autoload typing breaks.** Autoloads that type vars against `class_name` may fail to parse. **Workaround:** `const FooClass = preload("res://path/to/Foo.gd")` in the autoload, then `var foo: FooClass`. Applied in Phase 1 + Phase 2 GameState. Phase 3's final GameState will need 11 preload constants (all systems).
2. **`to_string()` collides with native `Object.to_string`** — becomes an error. Use `_to_string()` (proper virtual).
3. **`.gdignore` in a directory makes Godot skip it entirely.** Don't leave `.gdignore` in dirs containing real scripts.

### Save system
- `JSON.new().parse()` (not `JSON.parse_string`) avoids engine-level error noise that GUT reports as failures.
- Use `push_warning` for non-fatal informational messages — `push_error` triggers GUT failure.

### Indentation
Files are internally consistent per-file (some tabs, some 4-space); Godot's editor may auto-convert on save. Don't force-convert, just keep each file consistent with itself. Plan markdown uses 4 spaces — paste as-is.

### Architecture deviations from the plans (applied)
- **`GameState` exposes explicit `tick(delta)` instead of `_process`** — the main scene in Phase 4 will call it each frame. Keeps integration tests deterministic (no engine frames firing between `before_each` and assertions). Phase 3's plan still shows `_process`; keep the `tick(delta)` pattern.
- **All autoload subsystem types are `const XClass = preload(...)`**, not `class_name`-typed vars. Apply the same treatment to every new system added in Phase 3.

### Orphan nodes in tests
Phase 1 tests (`test_currency.gd`, `test_save.gd`) now have `after_each` that frees leaked Nodes. Phase 2 tests also free. Keep the pattern in Phase 3: any test that does `SystemName.new()` on a `Node`-based system needs `after_each { .free() }`.

### Files not part of the rebuild
`default_bus_layout.tres` is user work — don't touch it.

---

## Phase 4 plan deviations to expect

Based on Phase 2+3 patterns, expect to apply these when executing Phase 4:
- **`Main._process` calls `GameState.tick(delta)`.** The plan may call this out; if not, wire it. That's where backend ticks now live (Phase 2 moved it off `GameState._process`).
- **If any view/widget becomes an autoload, preload its class dependencies.** Non-autoload `Control`/`Node` scripts can keep `class_name` typing. Only autoloads need the `const FooClass = preload(...)` pattern.
- **Skip `godot --headless ...` commands in the plan** — the CLI is broken. Manual UI verification + GUT panel for any new test files.
- **`.tscn` work:** Godot's editor rewrites the file on save (normalizes node ordering, property keys). Expect whitespace/ordering diffs after opening a scene even with no intentional edits. Commit those if they're incidental to real work.
- **Orphan node cleanup** — any new `Node.new()`-based test needs `after_each { node.free() }` to keep GUT orphan count at 0.

---

## Commits on Phase 3 (merged into master)

```
9c7c046 normalize GameState indentation to tabs, add Godot .uid files
434f386 wire all 11 systems into GameState with modifiers and gating
48f1bdc add Ascend orchestrator: palier, conversion, reset
49da9e8 add SkillTree: fame spend, permanent effects, gold/speed mults
1a8bd86 add PainterOffice: hire workers, canvas speed bonus
14a08e4 add Craft system and recipes config
f6ba7ca add Inventory: owned items, slot equip, canvas_gold_mult
f322afe add Workshop system: tier upgrade, canvas gold+speed mults
eeaa80e update HANDOVER for Phase 2 complete, Phase 3 kickoff
```

9 commits on branch `phase3-systems`, fast-forward-merged into `master`, branch deleted.

---

## Skill chain being followed

`superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:executing-plans` → `superpowers:finishing-a-development-branch`

All 4 phase plans are in `docs/superpowers/plans/`. Phase 4 (UI) still pending after Phase 3.

---

## Quick status commands

```bash
cd /c/Users/mitoufle/Documents/artdle
git branch --show-current
git status --short
git log --oneline master..HEAD   # commits on current phase branch

# Launch Godot (user's install)
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All
```
