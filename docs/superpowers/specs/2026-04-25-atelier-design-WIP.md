# Atelier + Inventaire — Brainstorm WIP (closed)

**Status:** Brainstorm closed 2026-04-25. Decisions locked. Ready for promotion to final spec at `docs/superpowers/specs/2026-04-25-atelier-design.md`.

**Source:** brainstorming across sessions `fc1df13a` (crashed 2026-04-25) and the resumption session of the same date.

---

## Design intent

**Deep long-game axis** (option C from the original Q1). The Atelier+Inventaire is meant to be comparable in depth to the skill tree — the player crafts, equips, optimizes builds, hunts sets, and gambles for top-tier persistence. Not a passive multiplier; a mid-to-late-game system the player actively engages with.

This is **post-MVP scope.** Exceeds the MVP-rebuild spec on slot count, tier depth, and skill-tree expansion — intentional, because MVP shipped.

**Constraint inherited from the project:** *every sub-mechanic of the Peinture view exists to make the central canvas mechanic more efficient.* Atelier item affixes therefore must roll only **canvas-related stats** — never `inspiration_gain`, `fame_at_ascend`, or anything outside the canvas loop.

**Tuning north star:** *"difficile, long, récompensant"* — system designed to reward patient accumulation and intentional play. Hardcore ARPG philosophy. All numerical tuning (drop rates, stash sizes, success probabilities, level costs, fame costs) follows this principle.

---

## Locked decisions

### Architecture

1. **Single merged interface.** Atelier + Inventaire = one panel. Craft → equip happens in one place. The MVP's separate `CraftPopup` and `InventoryPopup` go away.

### Slots & tiers

2. **8 equippable slots.**
3. **6 rarity tiers:** normal → rare → magique → épique → légendaire → masterpiece. Higher tiers gated by Atelier level + slow progression.

### Slot taxonomy (finalized)

| Slot | Implicit affix | Build naturel |
|---|---|---|
| Brush | `canvas_speed_mult` | Speed |
| Palette | `palette_size_bonus` | (utility) |
| Chapeau | `subject_mastery_gain_mult` | Mastery |
| Blouse | `quality_floor_bonus` | Chef d'œuvre / PM |
| Gants | `style_time_reduction` | Speed hybride |
| **Chevalet** | `chef_doeuvre_chance_mult` | Chef d'œuvre |
| **Couteau à peindre** | `gamble_success_chance_mult` | Gamble |
| **Broche** | `pm_burst_chance_mult` | PM |

### Sets

4. **Set system.** Each item carries a set tag. **4-piece bonus per set** (no 2-piece tier). Player can have **up to 2 set bonuses active simultaneously** (4+4 across 8 slots).
5. **6 launch sets** — one per build archetype. **No 7th set.**

### 4-piece set bonuses (finalized)

| Set | Build | 4-piece bonus |
|---|---|---|
| **Risque-tout** | Gamble | Gamble yield ×2 always **+** chance par gamble de "JACKPOT" — yield ×10 (proc rare) |
| **Maître** | Chef d'œuvre | Chef d'œuvre yield ×2 always **+** un chef d'œuvre déclenche une "streak créative" : les 3 prochains canvas ont ×3 chef d'œuvre chance |
| **Rendement** | Speed + Gold | `canvas_speed_mult` ×1.5 + `canvas_gold_mult` ×1.5 always **+** chance par canvas d'un proc random : burst speed ×100 pendant 7s, OU boost gold ×10 sur les 3 prochains canvas |
| **Érudit** | Mastery | `subject_mastery_gain_mult` ×2 **+** révèle un sujet caché à chaque palier de mastery franchi (continu — pas de proc) |
| **Atelier prolifique** | Multi-canvas | **+1 slot canvas parallèle** (effet structural unique) |
| **Héritage** | PM | `pm_gain_mult` ×2 always **+** chance de "révélation" — un canvas accorde instantanément 5% du PM total gagné dans le run en cours (proc rare) |

4 sets sur 6 ont un proc/burst (Risque-tout, Maître, Rendement, Héritage). 2 restent continus (Érudit, Atelier prolifique) — leur identité (apprentissage progressif / slot extra) résiste aux procs. Tuning des fréquences/durées dans `Balance.gd`.

### Affixes

6. **Hybrid PoE-style roll model.** Each slot has:
   - **1 implicit affix** — always present, fixed range per tier, specific to slot type (see slot taxonomy table above)
   - **2-4 random affixes** drawn from the universal pool

7. **Affix pool (derived from Canvas brainstorm)** — see `2026-04-25-canvas-design-WIP.md` for the full derivation:
   - **Existing:** `canvas_speed_mult`, `canvas_gold_mult`, `paint_mastery_gain_mult`
   - **Canvas-derived:** `quality_floor_bonus`, `style_time_reduction`, `palette_size_bonus`, `subject_mastery_gain_mult`, `chef_doeuvre_chance_mult`, `gamble_success_chance_mult`, `gamble_yield_mult`, `parallel_canvas_efficiency`, `pm_burst_chance_mult`
   - **Atelier-meta (very rare on items):** `+1 pin slot`, `+1 stash slot`
   - **Excluded** (atelier-internal stats — live in skill tree Atelier branch or Atelier level bonuses, NOT on items): `set_targeting_odds`, `salvage_yield`, `craft_cost_reduction`, etc.

### Loot model

8. **Hybrid C.** Player picks item type. Tier + affixes are RNG, gated by Atelier level. Three paid sub-actions:
   - **Target a set** — raise odds the next roll lands in set X.
   - **Reroll affixes** on an existing item.
   - **Upgrade rarity** — normal → rare → … (per step).

### Cost model

9. **Items-as-materials.** No new currency. Reroll, upgrade, set-targeting, and persistence-craft consume **other items** as input.

### Items-as-materials specifics — STRICT B+C

10. **Strict B+C combined.** Input items must match BOTH **slot type** AND **set affiliation** of the action target.
    - Reroll a brush Maître → exigé : 2 brushes Maître same-tier. Sinon action impossible.
    - Stash management = puzzle exigeant. *C'est l'intention*, en ligne avec la philosophie "difficile, long, récompensant".
    - Conséquence : **set targeting** devient le moteur central du système. Doit être unlocked tôt et fiable.

### Quantities by action

| Action | Input requis |
|---|---|
| **Craft** | 1 item seed (tier ≥ tier visé) |
| **Reroll affixes** | 2 items same-tier same-slot same-set |
| **Upgrade rarity** | 3 items du tier courant same-slot same-set |
| **Set targeting** | 1 item du set visé (oriente le prochain craft) |
| **Persistence craft** | 5 items same-tier same-slot (ou moins si tier supérieur — ex. 3 items tier+1 = équivalent) ; proba de succès = base + bonus par excédent |

### Skill tree gating

11. **New "Atelier" branch** on the global (fame) skill tree. Permanent across ascends. Sister to the new "Canvas" branch.

### Atelier branch — final structure

12. **22 nodes total, themed sub-branches:**

| Catégorie | Nb nodes | Détail |
|---|---|---|
| **Capabilities** | 4 | reroll, upgrade rarity, set targeting, persistence craft |
| **Tier ceilings** | 5 | rare → magique → épique → légendaire → masterpiece (chain prereq) |
| **Slot unlocks** | 6 | chapeau, blouse, gants, chevalet, couteau, broche |
| **Pin slots** | 4 | +1 pin slot par node, jusqu'au cap de 4 |
| **QoL / power** | 3 | stash expansion, atelier level cap +N, cost reduction per action |

13. **Topology:** themed sub-branches with internal prereqs (ex. tier ceilings chain). Between categories, free purchase order, except structural prereqs (ex. *persistence capability* requires *masterpiece tier* déjà unlocked).

14. **Coûts en fame:** progressifs. Slots/capabilities/lower tiers = 1-10 fame. Hauts tiers / pin slots / persistence = 50-500+ fame. Calibrage in `Balance.gd`.

### Atelier level vs skill tree

15. **Two parallel axes.**
    - **Skill tree (fame, permanent)** sets the *ceiling* — what is possible at all.
    - **Atelier level (gold, per-run)** is the *per-run progress toward that ceiling.* Reset on ascend; re-grind from 0 each run, within the unlocked ceiling.

### End-game persistence — TWO-TIER

16. **Étage 1 — Pin déterministe.** Skill tree unlocks up to **4 pin slots maximum**. Player chooses items to pin before ascend. No risk. Secures 1 complete set (4/4).
17. **Étage 2 — Permanence craft.** For the other 4 slots: sacrifice 5 items same-tier (or fewer if higher tier) → probability roll → success = item permanent, failure = item destroyed.

### Stash management

18. **Capacity = B.** 200 slots base + 50 par node QoL skill tree (cap théorique ~500). Donne du sens aux QoL nodes du skill tree.
19. **Organisation = a.** Single grid + filtres/tri par slot, set, tier, affixe. Filtres et tri sont UI-critical pour naviguer dans les ~288 sous-catégories (8 slots × 6 sets × 6 tiers).
20. **Disposal = iii.** Lock items + auto-clean des unlocked au cap. Le joueur protège ses pépites, le reste se nettoie. Critère exact d'auto-clean (oldest first / lowest "value" / user-configurable) à nailer dans la spec.

---

## Build archetypes & sets (validated)

| Build | Set name | Core affixes | Cross-system dep |
|---|---|---|---|
| Gamble | **Set du Risque-tout** | `gamble_success_chance_mult`, `gamble_yield_mult` | Tree (inspi income) |
| Chef d'œuvre | **Set du Maître** | `chef_doeuvre_chance_mult`, `quality_floor_bonus` | Skill tree (chef d'œuvre unlock node) |
| Speed + Gold | **Set du Rendement** | `canvas_speed_mult`, `canvas_gold_mult` | — |
| Mastery / exploration | **Set de l'Érudit** | `subject_mastery_gain_mult` | Subject system pacing |
| Multi-canvas | **Set de l'Atelier prolifique** | `parallel_canvas_efficiency` | Painter Office (slots) |
| PM accumulator | **Set de l'Héritage** | `pm_gain_mult`, `pm_burst_chance_mult` | — |

Player can run **2 sets simultaneously** (4+4 split). Combos create distinct strategic identities (Risque-tout + Maître = "lucky gambler" ; Rendement + Érudit = "speed-runner mastery" ; Atelier prolifique + Maître = "masterpiece factory" ; etc.).

---

## Cross-system depth (validated)

Several builds depend on other systems to shine:
- Gamble ↔ Tree (income inspi)
- Multi-canvas ↔ Painter Office (slots)
- Mastery ↔ Subject system progression

This is good ARPG design — depth via cross-system synergy. The Atelier alone does not determine builds — it **amplifies** broader strategic choices.

---

## To nail in spec writing (deferred tuning)

These are tuning / UX, not design fundamentals. Initial values to be in spec, adjustable later. North star : *"difficile, long, récompensant"*.

1. **Atelier level economy.** How many levels total ? Cost curve (gold) ? What does each level unlock per-run beyond skill-tree gating (slot type access in current run, tier access within gated max, drop rate distribution, etc.) ?
2. **Persistence-craft tuning.** Base success probability per tier ; bonus per excess sacrifice item ; bonus per tier overshoot ; pin reversibility (mid-run swap or definitive until ascend) ; equipment slot vs separate vault for pinned/permanent items.
3. **UI structure of merged Atelier+Inventaire panel.** Slot grid layout, stash grid, action buttons, affix display, hover info per spec §6 of `2026-04-25-info-panel-design.md`. Filter/sort UI (slot, set, tier, affixe — multi-select). Lock indicator + auto-clean criteria definition (oldest first / lowest value / user-configurable).

---

## Skill tree growing pains (méta-note)

Between this Atelier branch (~22 nodes), the new Canvas branch (nodes TBD in canvas spec), and the existing MVP skill tree, the global skill tree is becoming a substantial system. Worth its own design pass after the Canvas + Atelier specs are written. Note for later, not blocking.
