# Artdle Rebuild — Session Handover

**Last session:** 2026-04-24
**Status:** Phase 2 complete (84/84 tests pass on master). Next: Phase 3 (systems — workshop, inventory, craft, painter office, skill tree, ascend).

---

## Where the project stands

- **Branch:** `phase3-systems` (branched off `master` after Phase 2 merge/push). `master` was pushed to GitHub at the end of the Phase 2 session — remote is current.
- **Approach:** Full rebuild per spec (`docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`). Phase 1 (foundation) and Phase 2 (core loop) merged to `master`. Old GDScript was stripped; `.tscn` layouts stay as references for Phase 4.
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
| `autoloads/GameState.gd` | now wires Canvas + PaintMastery + InspirationTree; preload for all 5 subclasses; explicit `tick(delta)` instead of `_process` (deterministic tests) |

**Totals: 84 tests / 131 assertions, all passing in the GUT editor panel.**

---

## What's next (Phase 3: Systems)

Plan file: `docs/superpowers/plans/2026-04-24-phase3-systems.md` (8 tasks).

Scope:
1. `systems/Workshop.gd` — tier upgrade, canvas gold+speed mults
2. `systems/Inventory.gd` — owned items, slot equip, canvas_gold_mult
3. `systems/Craft.gd` + `config/CraftRecipes.gd` — gold → items
4. `systems/PainterOffice.gd` — hire workers, canvas speed bonus
5. `systems/SkillTree.gd` + `config/SkillTreeNodes.gd` — fame → permanent effects
6. `systems/Ascend.gd` — palier check, fame conversion, reset orchestration
7. `autoloads/GameState.gd` — rewire with modifier aggregators, sub-mechanic gating, full save/load

**Recommended order deviation from the plan:** Plan's Task 1 introduces `var workshop: Workshop` (etc.) in GameState *before* the Workshop class exists. That parse-errors the autoload and breaks all tests. Build all 6 systems standalone first (plan Tasks 2→7), then merge plan Tasks 1 + 8 into a single final GameState rewrite. This mirrors the Phase 2 pattern.

Milestone: full run cycle (earn inspiration → spend gold on upgrades → sell canvases with modifier stack → ascend → spend fame on skill tree → start next run).

---

## How to resume (checklist for next session)

1. **Read this file.** Spec at `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md` for the full design context.
2. **Verify branch:** `git branch --show-current` should say `phase3-systems` (or `master` if the branch was merged and deleted).
3. **Verify Phase 1+2 still pass:** Open Godot, GUT panel → Run All → expect 84/84.
4. **Read Phase 3 plan:** `docs/superpowers/plans/2026-04-24-phase3-systems.md`.
5. **Execute tasks:** build all 6 sub-mechanic systems first, then do the GameState rewrite + integration test last.

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

## Phase 3 plan deviations to carry through

When executing the Phase 3 plan:
- **Skip plan Task 1 as written.** Its declarations reference classes that don't exist yet. Do Tasks 2-7 first.
- **When writing the final GameState (plan Task 8) — use `const FooClass = preload(...)` for all 11 systems**, including the 5 already loaded. Type member vars against the consts, not `class_name`s.
- **Keep `tick(delta)` pattern.** Apply `canvas_speed_multiplier()` there (`canvas.tick(delta * canvas_speed_multiplier())`).
- **Skip `godot --headless -s addons/gut/gut_cmdln.gd` commands in the plan** — the CLI is broken. Batch-verify the whole suite via editor panel at the end.
- **Every new `Node`-based system needs `after_each { system.free() }` in its test file.**

---

## Commits since master on `phase3-systems`

*(Empty at the start of Phase 3. Fill in as tasks complete.)*

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
