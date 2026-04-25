# Canvas — Brainstorm WIP (closed, spec pending)

**Status:** Brainstorm closed 2026-04-25. Decisions locked. Full spec to be written separately at `docs/superpowers/specs/2026-04-25-canvas-design.md`. This WIP exists as crash-safe persistence of the locked decisions.

**Source:** brainstorming session 2026-04-25 (continuation of `fc1df13a`). Pivoted out of the Atelier brainstorm — canvas had to be defined first to derive the Atelier affix pool. Resumes Atelier brainstorm afterward.

---

## Design intent

The canvas is the central production loop (gold faucet). All sub-mechanics of the painting view (Atelier, Workshop, Inventory, Painter Office) exist to make the canvas more efficient. The brainstorm goal was to enrich the canvas from its 2-multiplier MVP state into a multi-axis system the Atelier affix pool can hook into.

---

## Locked decisions

### Operating model

1. **Sticky configuration + observed loop.** Player opens the canvas panel, sets sliders/toggles (style, palette, gamble, sujet), closes. Config applies to **all subsequent canvases** until manually changed. No per-canvas re-decision. Player observes the canvas filling.
2. **Auto-sale.** Canvas auto-sells on completion. No "Vendre" button. Loop is fully passive on the canvas itself.
3. **Two panels for the canvas:**
   - **Improvement panel** — where the player spends to upgrade size, style ceiling, palette ceiling, etc.
   - **Interaction panel** — on the painting view, sibling to atelier / workshop / painter office popups.

### Dimensions exposed

| Axe | Type | Mode |
|---|---|---|
| **Taille (tier)** | int upgrade | Auto-max — always painted at the highest unlocked tier |
| **Style** | slider sticky | Player sets, capped by unlocked ceiling |
| **Palette** | slider sticky | Player sets, capped by unlocked ceiling |
| **Sujet courant** | choice sticky | Player picks among unlocked subjects |
| **Gamble inspi** | toggle + amount sticky | Player activates and calibrates |
| **Maîtrise sujet** | per-subject stat | Auto-accumulates with sales of that subject |
| **Qualité (output)** | derived | f(taille, style, palette, mastery sujet) |
| **Temps (output)** | derived | f(taille, style) |
| **Gold (output)** | derived | f(qualité, taille, multipliers) |
| **PM gain (output)** | derived | f(qualité, gold, contextual bonus) |
| **Chef d'œuvre** | RNG very low | Gated by skill tree node, overrides quality |
| **Multi-canvas** | infrastructure | Parallel slots, source = Painter Office workers (likely) |

### Quality + chef d'œuvre

`quality = f(taille, style, palette, subject_mastery)` — derived, not RNG. Higher size, style, palette, and mastery = higher quality. Quality drives gold output and triggers the PM contextual bonus.

**RNG exception:** unlocked via a node on the skill tree's new Canvas branch. Each canvas then has a very low chance to roll a "chef d'œuvre" — quality override to maximum. Boosted by Atelier affix `chef_doeuvre_chance_mult`.

### Subject system

4. **Hidden discovery graph.** 5 starting subjects. All other subjects derive from these 5 via prereqs. Player does not see the full subject list upfront — discovers by exploring.
5. **Per-subject mastery.** Each subject has its own progression curve (multi-tier, not binary). Mastering subjects at certain tiers unlocks new subjects via prereq edges. Example: `nature(thresh) + vie(thresh) → animalière`.
6. **Naming + topology TBD.** 5 starter subject names + the prereq graph for derived subjects to be designed in spec.

### Auto-sale state machine

- `peint en cours` → progress fills (auto, time = f(setup))
- `terminé` → auto-sold immediately (gold + PM credited)
- `nouveau canvas` starts immediately with same setup
- No "ready to sell" idle state — direct chain.

### Skill tree integration

- **New "Canvas" branch** on the global (fame) skill tree. Sister to the new "Atelier" branch.
- **Anchor node:** chef d'œuvre RNG unlock.
- **Other nodes TBD** — subject discovery hint reveals, palette ceiling extensions, multi-canvas slot grants, gamble safety nets, etc.

### Multi-canvas

- Source of additional slots: most likely **Painter Office workers** (already the throughput automation system). Each worker = 1 parallel canvas slot.
- Each slot runs the same sticky config independently.
- Atelier affix `parallel_canvas_efficiency` modifies multiplier per slot.

### Inspiration gamble

- Toggle + amount in the canvas config panel.
- Spends N inspiration before/at canvas start.
- On success: quality boost proportional to investment.
- On failure: inspiration lost; canvas may be downgraded or destroyed (TBD).
- Modified by Atelier affixes `gamble_success_chance_mult` and `gamble_yield_mult`.
- Sticky-toggleable "always gamble" or one-shot per manual trigger — exact mechanism TBD.

### Paint mastery contextual bonus

- High-quality canvases (above some threshold) trigger a PM bonus on top of the standard gain.
- Modified by Atelier affix `pm_burst_chance_mult`.
- Threshold + bonus amount TBD.

---

## Affix pool derived (canvas-related — used by Atelier items)

**Existing:**
- `canvas_speed_mult`
- `canvas_gold_mult`
- `paint_mastery_gain_mult`

**New (canvas-derived):**
- `quality_floor_bonus`
- `style_time_reduction`
- `palette_size_bonus`
- `subject_mastery_gain_mult`
- `chef_doeuvre_chance_mult`
- `gamble_success_chance_mult`
- `gamble_yield_mult`
- `parallel_canvas_efficiency`
- `pm_burst_chance_mult`

**Atelier-meta (very rare on items):**
- `+1 pin slot`
- `+1 stash slot`

---

## Build archetypes (validated, 6 specialized + 1 default)

| Build | Core affixes | Set thématique |
|---|---|---|
| Gamble | `gamble_success_chance_mult`, `gamble_yield_mult` | Set du Risque-tout |
| Chef d'œuvre | `chef_doeuvre_chance_mult`, `quality_floor_bonus` | Set du Maître |
| Speed + Gold | `canvas_speed_mult`, `canvas_gold_mult` | Set du Rendement |
| Mastery / exploration | `subject_mastery_gain_mult` | Set de l'Érudit |
| Multi-canvas | `parallel_canvas_efficiency` | Set de l'Atelier prolifique |
| PM accumulator | `pm_gain_mult`, `pm_burst_chance_mult` | Set de l'Héritage |
| Balanced | mix | (default, no set) |

**Cross-system depth (validated):** several builds depend on other systems to shine — gamble ↔ tree (inspi income), multi-canvas ↔ painter office (slots), mastery ↔ subject graph progression. Atelier amplifies broader strategic choices, doesn't determine builds alone.

---

## Open questions (to nail in spec writing)

- Mastery curve shape (linéaire / log / exp), per-subject ceiling, gain weighting (flat vs scaled by quality)
- Hidden discovery UX (placeholder "?", cryptic hints, none)
- Style: discrete (1-N) or continuous (1-100)
- Palette: representation (color count, named palettes, etc.)
- Gamble formula (success curve, yield formula, fail consequence)
- Multi-canvas source confirmed = Painter Office workers
- Quality formula exact weighting
- Canvas improvement panel content (which upgrades, which currencies, cost curves)
- Skill tree Canvas branch nodes (full list, fame costs, prereqs)
- Subject system: 5 starter names, derived subject names, full prereq graph
- Painting view layout impact (how does the canvas's interaction popup coexist with current painting view?)
