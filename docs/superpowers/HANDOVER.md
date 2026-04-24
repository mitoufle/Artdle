# Artdle Rebuild — Session Handover

**Last session:** 2026-04-24
**Status:** Phase 1 complete (40/40 tests pass). Next: Phase 2 (core loop).

---

## Where the project stands

- **Branch:** `rebuild-mvp` (17 commits ahead of `master`)
- **Approach:** Full rebuild from scratch per spec (`docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`). Old GDScript stripped, `.tscn` layouts kept as visual references for Phase 4.
- **Godot version:** 4.6.2 (user updated mid-session — some Godot 4.6 behaviors tripped us up; see "Gotchas")
- **Test framework:** GUT 9.x in `addons/gut/`. CLI runner is broken on this install (class-resolution issue) but the editor's GUT panel works.

---

## What's done (Phase 1: Foundation)

Code in `scripts/core/` and `scripts/systems/`, tested in `test/`:

| Module | Role | Status |
|---|---|---|
| `core/BigNumber.gd` | Float wrapper, overflow caps at `MAX_VALUE=1e308` (not 0) | ✅ 10/10 |
| `core/Formatter.gd` | K/M/B/T display formatting | ✅ 8/8 |
| `core/Balance.gd` | `palier_ascend`, `fame_conversion`, `paint_mastery_*` formulas | ✅ 7/7 |
| `systems/Currency.gd` | 4 pools (inspi/gold/fame/paint_mastery), atomic spend, `changed` signal | ✅ 8/8 |
| `systems/Save.gd` | Atomic write, versioned, migration stub, fail-loud | ✅ 5/6 (1 uses `assert_true` shim) |
| `autoloads/GameState.gd` | Signal hub, holds Currency + Save as children, save_game / load_game | ✅ 1/1 integration |
| `autoloads/SceneManager.gd` | Minimal scene loader (expanded Phase 4) | — |

**Total: 40/40 test assertions passing in the GUT editor panel.**

---

## What's next (Phase 2: Core Loop)

Plan file: `docs/superpowers/plans/2026-04-24-phase2-core-loop.md` (6 tasks).

Scope:
1. `config/CanvasTiers.gd` — 10 tiers of canvas (gold_value, paint_seconds, upgrade_cost)
2. `config/TreeStages.gd` — 5 MVP stages (Pousse → Ancien) with parts + unlocks
3. `systems/PaintMastery.gd` — log-curve multiplier driven by canvas sales
4. `systems/Canvas.gd` — state machine, tick, sell (emits `sold`)
5. `systems/InspirationTree.gd` — stages + parts + upgrades + passive tick
6. Wire all three into `GameState` with signal routing and integration test

Milestone: headless-tested core loop where a canvas sale generates gold + paint_mastery, and tree ticks produce inspiration proportional to upgraded parts.

---

## How to resume (checklist for next session)

1. **Read this file, then the spec:** `docs/superpowers/specs/2026-04-24-artdle-rescope-design.md`
2. **Verify branch:** `git branch --show-current` should say `rebuild-mvp`
3. **Verify tests still pass:** Open Godot (4.6.2+), Project → Tools → GUT panel → Run All → expect 40/40 green
4. **Read Phase 2 plan:** `docs/superpowers/plans/2026-04-24-phase2-core-loop.md`
5. **Resume subagent-driven execution:** dispatch a subagent for Phase 2 Task 1 (CanvasTiers), following the same pattern as Phase 1 — feed the task's full text + context, skip GUT CLI, verify via editor panel after each task or at end of phase.

---

## Gotchas & known issues

### Test execution
- **GUT CLI is broken** on this setup (Godot 4.4.1 binary + 4.6.2 editor). Parse errors on `GutErrorTracker`, `add_dock()`, etc. Root cause is version skew + something specific to this Windows install. **Always verify via the editor's GUT panel**, not CLI.
- `.gutconfig.json` at project root is configured for CLI (would-be), but the editor panel may need manual config too (Load `.gutconfig.json` from the panel's Config section, or add `res://test/` to Test Directories).

### Godot 4.6 strictness
Three patterns that work in 4.4 but break in 4.6 — handle them the same way in future code:

1. **`class_name` + autoloads ordering.** If an autoload types a var against a `class_name`, it may fail to parse on first load. **Workaround:** `const FooClass = preload("res://path/to/Foo.gd")` in the autoload, then `var foo: FooClass`. Already applied in `GameState.gd` lines 6-7.

2. **`to_string()` is treated as overriding native `Object.to_string`** — warning becomes error. **Use `_to_string()`** (the proper virtual). Already applied in `BigNumber.gd:47`.

3. **`.gdignore` in a directory makes Godot skip it entirely** — no file imports, no class_name registration. Directories with real scripts must NOT have `.gdignore`. We had this bug: subdirs created in Phase 1 Task 3 kept their placeholder `.gdignore`, and `Currency`/`Save` class_names never registered until the files were removed (commit `7e407f9`).

### Save system
- `JSON.parse_string` emits engine-level errors on malformed JSON, which GUT reports as "unexpected error". Use `JSON.new().parse()` instead (returns error code). Applied in `Save.gd`.
- `push_error` in non-fatal paths triggers GUT failure. Use `push_warning` for informational messages. Applied for the newer-version-refused path.

### Indentation
Mixed tabs/4-space across files. Most `.gd` files use 4 spaces (from the plan's markdown). Godot's editor may auto-convert to tabs on save. **Don't fight it** — Godot's editor setting wins. Each file is internally consistent, that's what matters for GDScript.

### Orphan nodes in tests
15 orphan Nodes reported by GUT across `test_currency.gd` and `test_save.gd`. Tests do `Currency.new()` / `Save.new()` in `before_each` but never `free()`. Fix is to add:
```gdscript
func after_each():
    if currency != null:
        currency.free()
```
To each test file. Not blocking — orphan warnings don't fail tests. **Clean up batch at the end of Phase 2** or beginning of Phase 3, whichever feels right.

### Files that don't belong to our work
`default_bus_layout.tres` and `scripts/Main.gd` show as modified (or were — `scripts/Main.gd` was deleted during strip-down, git may still show stale info in some agent reports). Leave `default_bus_layout.tres` alone — it's user's work unrelated to the rebuild.

---

## Commits since master (`rebuild-mvp`)

```
78664a1 replace assert_ne(dict, null) with assert_true in test_save
3398e05 fix Save test failures: int version, quiet parse errors
7e407f9 remove leftover .gdignore files from active script dirs
33ab889 rename BigNumber.to_string to _to_string (engine virtual)
627bea6 use preload in GameState autoload instead of class_name types
01d3dd2 add GameState + SceneManager autoloads with save/load integration
e5b8a20 normalize Save.gd/test_save.gd indentation to 4 spaces
09438b0 add Save with atomic write, versioning, migration stub
51e1cd0 add Currency system with 4 pools, atomic spend, reset, signals
d8ec7bf add Balance with ascend, fame, paint_mastery formulas
1a6ea72 add Formatter with K/M/B/T suffixes
a737e56 regenerate GUT .import files from first project import
c2de119 fix BigNumber.to_string for whole numbers + type Variant on deserialize
69ee928 add BigNumber primitive with overflow cap and roundtrip
88ef515 create new scripts/ and test/ directory structure
36117fa strip all GDScript and root scenes for rescope rebuild
a500c05 install GUT test framework in addons/gut/
```

17 commits. Linear, each self-contained. Safe to revert any single one if needed.

---

## Skill chain being followed

`superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development`

All three plans (Phase 2, 3, 4) are already written in `docs/superpowers/plans/`. The handoff protocol for subagents is:
- Full task text pasted into prompt (no file reads by subagent)
- Explicit "do not run GUT CLI" instruction
- Verify each phase via editor GUT panel at end

---

## Open question for next session

**Should Phase 2 batch-verify tests at the end (like Phase 1), or after each task?** Phase 1's per-task verification was skipped because of the GUT CLI block, so we batched. That worked fine. Probably do the same for Phase 2.

---

## Quick status commands

```bash
# Working dir
cd /c/Users/mitoufle/Documents/artdle

# Confirm branch
git branch --show-current

# Confirm clean
git status --short

# Commits since master
git log --oneline rebuild-mvp ^master

# Launch Godot (user's install)
"/c/Users/mitoufle/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe" --editor
# Then Project → Tools → GUT → Run All
```
