# Atelier + Inventaire — Design Spec

**Status:** Draft for review. Promoted from `2026-04-25-atelier-design-WIP.md` on 2026-04-26.
**Implementation order:** Atelier ships **after** Canvas (Atelier affix pool depends on canvas dimensions). See `2026-04-25-canvas-design.md`.
**References:** §6 of `2026-04-25-info-panel-design.md` (mandatory hover-info content authoring rule).

---

## 1. Design intent

**Deep long-game axis** (option C from the original Q1). The Atelier+Inventaire is comparable in depth to the skill tree — the player crafts, equips, optimizes builds, hunts sets, and gambles for top-tier persistence. Not a passive multiplier; a mid-to-late-game system the player actively engages with.

This is **post-MVP scope.** Exceeds the MVP-rebuild spec on slot count, tier depth, and skill-tree expansion — intentional, because MVP shipped.

**Constraint:** every sub-mechanic of the Peinture view exists to make the central canvas mechanic more efficient. Atelier item affixes therefore must roll only **canvas-related stats** — never `inspiration_gain`, `fame_at_ascend`, or anything outside the canvas loop.

**Tuning north star:** *« difficile, long, récompensant »* — system designed to reward patient accumulation and intentional play. Hardcore ARPG philosophy. All numerical tuning (drop rates, stash sizes, success probabilities, level costs, fame costs) follows this principle.

---

## 2. Architecture

**Single merged interface.** Atelier + Inventaire = one panel (`AtelierPopup`). Craft → equip happens in one place. The MVP's separate `CraftPopup` and `InventoryPopup` are deprecated and replaced by this panel.

```
AtelierPopup
├── Top bar: Atelier level + XP + Persistence Vault toggle
├── Left col 25%: 8 equipment slots (with currently equipped item visible)
├── Center col 50%: Stash grid + filter row + sort + pagination
├── Right col 25%: Action panel (Craft / Reroll / Upgrade / Set Target / Persistence)
│                   + selected-item details + lock/pin toggles
└── Bottom: hover info bridge to InfoPanel (§6 of info-panel spec)
```

---

## 3. Slots and tiers

- **8 equippable slots.**
- **6 rarity tiers:** normal → rare → magique → épique → légendaire → masterpiece. Higher tiers gated by skill tree tier-ceiling unlocks.

### 3.1 Slot taxonomy

| Slot | Implicit affix | Build naturel |
|---|---|---|
| Brush | `canvas_speed_mult` | Speed |
| Palette | `palette_size_bonus` | (utility) |
| Chapeau | `subject_mastery_gain_mult` | Mastery |
| Blouse | `quality_floor_bonus` | Chef d'œuvre / PM |
| Gants | `style_time_reduction` | Speed hybride |
| Chevalet | `chef_doeuvre_chance_mult` | Chef d'œuvre |
| Couteau à peindre | `gamble_success_chance_mult` | Gamble |
| Broche | `pm_burst_chance_mult` | PM |

Implicit affixes always present; ranges scale with tier (see §7.4).

---

## 4. Sets

### 4.1 Set system

- Each item carries a set tag (or none for normal/rare items above a small probability — see §11.2).
- **4-piece bonus per set.** No 2-piece tier.
- Player can have **up to 2 set bonuses active simultaneously** (4+4 across 8 slots).
- **6 launch sets** — one per build archetype. **No 7th set.**

### 4.2 Four-piece set bonuses

| Set | Build | 4-piece bonus |
|---|---|---|
| **Risque-tout** | Gamble | Gamble yield ×2 always **+** chance par gamble de "JACKPOT" — yield ×10 (proc rare). |
| **Maître** | Chef d'œuvre | Chef d'œuvre yield ×2 always **+** un chef d'œuvre déclenche une "streak créative" : les 3 prochains canvas ont ×3 chef d'œuvre chance. |
| **Rendement** | Speed + Gold | `canvas_speed_mult` ×1.5 + `canvas_gold_mult` ×1.5 always **+** chance par canvas d'un proc random : burst speed ×100 pendant 7 s, OU boost gold ×10 sur les 3 prochains canvas. |
| **Érudit** | Mastery | `subject_mastery_gain_mult` ×2 **+** révèle un sujet caché à chaque palier de mastery franchi (continu — pas de proc). |
| **Atelier prolifique** | Multi-canvas | **+1 slot canvas parallèle** (effet structural unique). |
| **Héritage** | PM | `pm_gain_mult` ×2 always **+** chance de "révélation" — un canvas accorde instantanément 5% du PM total gagné dans le run en cours (proc rare). |

4 sets sur 6 ont un proc/burst (Risque-tout, Maître, Rendement, Héritage). 2 restent continus (Érudit, Atelier prolifique) — leur identité (apprentissage progressif / slot extra) résiste aux procs. Initial proc tuning in §11.5.

---

## 5. Loot model

**Hybrid C.** Players do not get items via "I want a brush" buy buttons. Items enter via:

1. **Canvas drops** (primary source — see Canvas spec §11). Slot, set, tier, affixes are RNG, weighted by atelier level + skill tree gates + active set targeting.
2. **Atelier paid actions** (secondary — see §6) modify existing items: reroll affixes, upgrade rarity, set targeting (next drop), persistence craft.

There is **no** direct "I want a légendaire chevalet Maître" button. Players gather drops, then refine via paid actions. This is the difficile-long-récompensant philosophy in mechanism form.

---

## 6. Cost model — items-as-materials, strict B+C

**No new currency.** Reroll, upgrade rarity, set targeting, and persistence craft consume **other items** as input.

### 6.1 Strict B+C constraint

Input items must match BOTH **slot type** AND **set affiliation** of the action target.

- Reroll a brush Maître → exigé : 2 brushes Maître same-tier. Sinon action impossible.
- Stash management = puzzle exigeant. C'est l'intention, en ligne avec « difficile, long, récompensant ».
- Conséquence : **set targeting** est le moteur central du système. Doit être unlocked tôt et fiable.

### 6.2 Quantities by action

| Action | Input requis | Note |
|---|---|---|
| **Craft** | n/a — items come from canvas drops | The "Craft" terminology is reserved for canvas drops + reroll/upgrade. The Atelier panel exposes drop targeting (set) but not direct creation. |
| **Reroll affixes** | 2 items same-tier same-slot same-set | Rerolls all random affixes; implicit unchanged. |
| **Upgrade rarity** | 3 items du tier courant same-slot same-set | Output item one tier higher (e.g., 3 magique brushes Maître → 1 épique brush Maître with rerolled affixes). |
| **Set targeting** | 1 item du set visé (consommé) | Active for the next 10 canvas drops; raises set-affiliation odds. See §11.3. |
| **Persistence craft** | 5 items same-tier same-slot (any sets) — or fewer with tier overshoot | Bound to one specific item; success makes that item permanent. See §10. |

**Persistence craft excess sacrifice:** input `n ≥ 5` items same tier (same slot only — set affiliation not required). Each item beyond 5 adds a success bonus. See §10 for tuning.

---

## 7. Affixes

### 7.1 Roll model (PoE-style hybrid)

Each item has:
- **1 implicit affix** — always present, fixed range per tier, specific to slot type (§3.1).
- **2–4 random affixes** drawn from the universal pool (count by tier — §7.4).
- **0–1 set affix** — present iff the item carries a set tag (§4.1).

### 7.2 Universal affix pool

**Existing (MVP):**
- `canvas_speed_mult`
- `canvas_gold_mult`
- `paint_mastery_gain_mult`

**Canvas-derived (from canvas spec §14):**
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

### 7.3 Excluded from items

Atelier-internal stats live in skill tree nodes or atelier-level bonuses — never on items:
- `set_targeting_odds`
- `salvage_yield`
- `craft_cost_reduction`
- (any future internal-economy lever)

### 7.4 Affix counts by tier

| Tier | Implicit | Random | Set | Total |
|---|---|---|---|---|
| Normal | 1 | 2 | 0 | 3 |
| Rare | 1 | 3 | 0 | 4 |
| Magique | 1 | 3 | 0–1 | 4–5 |
| Épique | 1 | 4 | 1 | 6 |
| Légendaire | 1 | 4 | 1 | 6 |
| Masterpiece | 1 | 4 | 1 + 1 unique | 7 |

### 7.5 Affix value ranges

Every affix rolls within a tier-scaled range. Initial values flagged for tuning (§15).

| Affix | Normal range | Légendaire range | Masterpiece range |
|---|---|---|---|
| `*_mult` style affixes (gold, speed, mastery, gamble yield, parallel efficiency, pm gain, …) | +1% to +5% | +20% to +35% | +35% to +50% |
| `*_chance_mult` style affixes (chef d'œuvre, gamble success, pm burst) | +5% to +10% | +50% to +80% | +80% to +120% |
| `quality_floor_bonus` (flat) | +1 to +2 | +5 to +8 | +9 to +12 |
| `style_time_reduction` (additive %) | +1% to +2% | +6% to +9% | +10% to +14% |
| `palette_size_bonus` (flat) | +1 | +3 | +5 |
| `+1 pin slot` (very rare) | n/a | one possible roll on légendaire+ | rolls in masterpiece-only pool |
| `+1 stash slot` (very rare) | n/a | one possible roll on légendaire+ | rolls in masterpiece-only pool |

Linear interpolation between normal and légendaire for rare/magique/épique.

---

## 8. Skill tree — Atelier branch

New "Atelier" branch on the global (fame) skill tree. Permanent across ascends. Sister to the new "Canvas" branch.

### 8.1 22 nodes total, themed sub-branches

| Catégorie | Nb nodes | Détail |
|---|---|---|
| Capabilities | 4 | reroll, upgrade rarity, set targeting, persistence craft |
| Tier ceilings | 5 | rare → magique → épique → légendaire → masterpiece (chain prereq) |
| Slot unlocks | 6 | chapeau, blouse, gants, chevalet, couteau, broche |
| Pin slots | 4 | +1 pin slot par node, jusqu'au cap de 4 |
| QoL / power | 3 | stash expansion, atelier level cap +N, cost reduction per action |

Brush + palette are unlocked from game start (Phase 1 MVP). The 6 slot-unlock nodes cover the post-MVP slots.

### 8.2 Topology

Themed sub-branches with internal prereqs (ex. tier ceilings chain). Between categories, free purchase order, except structural prereqs:
- **Persistence capability** requires **masterpiece tier** déjà unlocked.
- **Set targeting** requires **rare tier** unlocked.
- **Reroll** + **upgrade rarity** have no prereq beyond the branch root.

### 8.3 Node fame costs

| Catégorie | Cost range |
|---|---|
| Capability nodes (reroll, upgrade) | 5–25 |
| Set targeting | 30 |
| Persistence craft | 200 |
| Tier ceiling: rare | 5 |
| Tier ceiling: magique | 25 |
| Tier ceiling: épique | 75 |
| Tier ceiling: légendaire | 200 |
| Tier ceiling: masterpiece | 500 |
| Slot unlock (each) | 10 |
| Pin slot 1 / 2 / 3 / 4 | 50 / 150 / 350 / 700 |
| Stash expansion (each) | 30 |
| Atelier level cap +N (each) | 50 |
| Cost reduction per action (each) | 75 |

Calibrated against fame-per-ascend rates from MVP. **Flagged for tuning** — see §15.

---

## 9. Atelier level vs skill tree

**Two parallel axes.**
- **Skill tree (fame, permanent)** sets the *ceiling* — what is possible at all (which tiers, which slots, which capabilities).
- **Atelier level (gold-spent, per-run)** is the *per-run progress toward that ceiling.* Reset on ascend.

### 9.1 Atelier level economy

- **100 levels max.**
- **XP source:** gold spent in atelier actions (reroll, upgrade, set targeting, persistence craft) accumulates as atelier XP, 1:1.
- **Cost curve:** level N → level N+1 requires `100 * 1.15^N` gold spent. Level 1 = 115 g cumulative. Level 50 = ~108 k cumulative. Level 100 = ~1.2 M cumulative.
- **Level cap:** raised by skill tree QoL "atelier level cap +N" nodes (each +10 levels above the base 100, up to 130 with all 3).

### 9.2 Per-level effects

Each atelier level shifts the canvas drop tier distribution toward higher tiers, capped by skill tree tier-ceiling unlocks:

| Atelier level range | Drop tier weights (within unlocked ceiling) |
|---|---|
| 1–10 | 100% Normal |
| 11–25 | Normal 80–95%, Rare 5–20% (linear ramp) |
| 26–50 | Normal 60–80%, Rare 25–35%, Magique 0–8% |
| 51–75 | Normal 30–60%, Rare 30–40%, Magique 8–18%, Épique 0–4% |
| 76–95 | Normal 10–30%, Rare 25–35%, Magique 18–30%, Épique 4–10%, Légendaire 0–1.5% |
| 96–100 | Normal 5–10%, Rare 20–25%, Magique 30%, Épique 10–15%, Légendaire 1.5–5%, Masterpiece 0–0.3% |

Tiers above the player's skill-tree-unlocked ceiling are clamped to 0 and reweighted into lower tiers.

### 9.3 Cost reduction skill nodes

The 3 "cost reduction per action" QoL nodes each shave 10% off action gold costs (additive — full 30% with all 3). Affects atelier-XP-accrual rate inversely (less spend = slower level), so the nodes accelerate efficiency at the cost of slower atelier levelling. Intentional tradeoff.

---

## 10. End-game persistence — TWO-TIER

### 10.1 Étage 1 — Pin déterministe

- Skill tree unlocks up to **4 pin slots** total.
- Player chooses items to pin. **No risk.** Pinned items survive ascend (kept equipped at the start of the next run).
- Pin slot reversibility: **mid-run swap allowed** — the player can re-assign pin slots to different equipped items at any point during a run. Pin assignments lock at ascend.
- Secures up to one complete set (4/4) deterministically.

### 10.2 Étage 2 — Permanence craft

For the 4 non-pinned slots: sacrifice 5 items same-tier (same slot) → probability roll → success = item permanent (lives in the **Persistence Vault** UI tab and is auto-equipped each run), failure = target item destroyed.

### 10.3 Persistence-craft tuning

**Base success probability (5 sacrifice items, all same tier as target):**

| Target tier | Base success |
|---|---|
| Normal | 60% |
| Rare | 40% |
| Magique | 25% |
| Épique | 12% |
| Légendaire | 5% |
| Masterpiece | 1.5% |

**Bonuses:**
- Each excess sacrifice item beyond 5 (same tier): **+5%** chance, capped at **+20%** (so 9 items = max bonus).
- Each sacrifice item one tier above target: **+12%** chance, capped at **+24%** (so 2 tiers above = max bonus).

**Failure mode:** the targeted item is destroyed; sacrifices are also consumed (always — success or fail). No partial refund.

**Pin vs persistence resource trade:** pinned items occupy 1 of 4 pin slots. Persistence-crafted items live in the Persistence Vault and have no slot count limit (only the cost of crafting them limits them). Both modes can coexist for the same player.

### 10.4 Persistence Vault

Separate UI tab in `AtelierPopup` (toggled from the top bar). Contains all persistence-crafted items. Each persistence-vaulted item auto-equips at run start. If the vault holds multiple items eligible for the same equipment slot (e.g. two persistence-crafted brushes), the player chooses one as **primary** for that slot via the vault UI; non-primary items remain in the vault and can be manually swapped in mid-run. Pinned items override the vault primary if both target the same slot.

---

## 11. Drop mechanics in detail

(Owns the policy that the canvas-spec drop event implements.)

### 11.1 Drop chance trigger

See canvas spec §11.1 — `0.05 + 0.001 * quality` per canvas auto-sale.

### 11.2 Set affiliation roll

When a drop succeeds:
- 40% no-set (only valid for normal / rare / magique items)
- 60% set tag, with each of the 6 sets at 10%
- For épique+ tiers, the no-set 40% is reweighted onto the 6 sets (each → 16.67%)

Set affiliation is **rolled before tier**. Set targeting (§11.3) modifies these probabilities.

### 11.3 Set targeting effect

Set targeting (paid action, requires 1 item of target set as input) raises odds for the next 10 canvas drops:

- Target set probability: 60% (vs 10% baseline) for the duration.
- Other 5 sets: 8% each (40% remaining redistributed).
- No-set: same 40% / 0% rule by tier.

Stacking: re-targeting the same set within an active window resets the count to 10 (does NOT additively boost). Targeting a different set replaces the prior target.

### 11.4 Tier roll

After set affiliation, tier is drawn from the atelier-level distribution (§9.2), clamped to skill-tree-unlocked ceiling.

### 11.5 Set 4-piece proc tuning

Initial procs for the 4 burst sets (flagged §15):

- **Risque-tout JACKPOT:** 2% per gamble. Yield ×10 on success.
- **Maître creative streak:** triggered on every chef d'œuvre. Buff: ×3 chef d'œuvre chance for the next 3 canvases. If a chef d'œuvre triggers during an active streak, the streak counter is reset to 3 (does not stack the multiplier).
- **Rendement burst:** 1% per canvas → 50% speed-burst (×100 for 7 s), 50% gold-burst (×10 next 3 canvases). If a second proc occurs during an active burst, it replaces the active buff (does not stack).
- **Héritage révélation:** 0.5% per canvas. Grants 5% of run's total accumulated PM instantly. Cooldown: 5 canvases minimum between procs.

---

## 12. Stash management

### 12.1 Capacity

- **Base = 200 slots.**
- Skill tree QoL "stash expansion" nodes (3 nodes total) → +50 slots each. Theoretical cap **350**.
- Affix `+1 stash slot` on items — very rare, additive. Realistic effective cap ~360–380 with full investment.

(The previous WIP mentioned ~500 cap; the lower 350 cap is more in line with the strict-B+C puzzle intent — too much room undermines the constraint. Flagged for tuning.)

### 12.2 Organisation

Single grid + filters/sort:
- **Filters (multi-select dropdowns):** slot, set, tier, affix.
- **Sort (single dropdown):** newest, oldest, tier ↓, value ↓.
- Filter+sort combine. Active filters are summarized at the top of the grid for clarity.
- Total subcategory space: 8 slots × 6 sets × 6 tiers = 288 buckets (plus no-set variants for low tiers). Filters are UI-critical.

### 12.3 Disposal — lock + auto-clean

- Items are **locked** by the player (toggle on item details panel) to protect them. Locked items are never consumed by actions or auto-clean.
- When the stash hits cap, **auto-clean** removes unlocked items to make room for new drops.
- **Auto-clean criterion:** lowest **value** first, ties broken by oldest first.
  - `value = sum(affix_score) + (50 if set else 0)`
  - `affix_score = tier_weight^2 * affix_quality_pct` where `affix_quality_pct` is the affix's roll within its tier range (0..1) and `tier_weight = {normal: 1, rare: 2, magique: 3, épique: 5, légendaire: 8, masterpiece: 13}`
- Player can override per-item via lock. Auto-clean **never** removes locked items — if all items are locked at cap, new drops are silently discarded with a UI warning.

---

## 13. UI structure of merged Atelier+Inventaire panel

### 13.1 Layout

`AtelierPopup` is a Control with three columns and a top/bottom strip:

```
┌────────────────────────────────────────────────────────────────┐
│  Atelier Lv 47 [████████░░] 47/100      [Stash | Vault]   ⚙   │  Top bar
├──────────────┬──────────────────────────────────┬──────────────┤
│  EQUIPMENT   │  STASH GRID                      │  ACTION      │
│              │  [Slot ▾][Set ▾][Tier ▾][Aff ▾]  │  ┌────────┐  │
│  Brush       │  [Sort ▾]      [Search…]         │  │ Reroll │  │
│  Palette     │                                  │  │Upgrade │  │
│  Chapeau     │  ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐    │  │ Target │  │
│  Blouse      │  │  │  │  │  │  │  │  │  │  │    │  │Persist │  │
│  Gants       │  ├──┼──┼──┼──┼──┼──┼──┼──┼──┤    │  └────────┘  │
│  Chevalet    │  │  │  │  │  │  │  │  │  │  │    │              │
│  Couteau     │  …  …  …  …  …  …  …  …  …       │  [Selected   │
│  Broche      │  ◀ Page 1 / 4 ▶                  │   Item       │
│              │                                  │   Details    │
│              │                                  │   + 🔒 + 📌] │
└──────────────┴──────────────────────────────────┴──────────────┘
            (InfoPanel hover-info bridge below — outside this popup, on Main.tscn)
```

Approximate column widths: 25% / 50% / 25%.

### 13.2 Top bar elements

- **Atelier level + XP bar** (live updating).
- **Stash | Vault tabs** (Stash = full grid; Vault = persistence-crafted items, list view).
- **⚙** opens stash settings (auto-clean toggle, filter defaults).

### 13.3 Equipment column

- 8 vertical slot frames in canonical order (Brush, Palette, Chapeau, Blouse, Gants, Chevalet, Couteau, Broche).
- Each shows: sprite + tier-color border + set tag overlay + currently active set bonus indicators (count of pieces equipped per set).
- Drag-drop targets: drop a stash item onto a slot to equip; drop equipped onto stash to un-equip.

### 13.4 Center stash grid

- Filter row (multi-select dropdowns) + sort dropdown + search text field at top.
- Grid: 9 columns × variable rows, paginated at 90 items/page. Per-cell tile shows tier-color border, slot icon, set badge, lock indicator.
- Click an item → it becomes the **selected item** (right column populates).
- Right-click → context menu: equip, lock, mark for action input.

### 13.5 Action panel

- **4 action buttons** stacked: **Reroll**, **Upgrade**, **Set Target**, **Persistence**. (No "Craft" button — items enter the inventory via canvas drops, see §5.)
- Below buttons: selected-item details — full affix list with value, tier, set badge, lock + pin toggles.
- Action buttons are gated: disabled if the strict B+C input requirements are unmet, with a hover-info explanation per §6 of info-panel spec.

### 13.6 Hover info — InfoPanel bridge

Per `2026-04-25-info-panel-design.md` §6, every interactive element in `AtelierPopup` gets a `Hoverable` child publishing structured info: numbers, live values, costs with icons, no narrative-only blurbs. Coverage required for: every slot, every action button, every filter dropdown, every selected-item affix line, lock + pin toggles, atelier level bar.

---

## 14. Cross-system depth

Several builds depend on other systems to shine — Atelier alone does not determine builds; it amplifies broader strategic choices.

| Build | Atelier slot synergy | Cross-system dep |
|---|---|---|
| Gamble (Risque-tout) | Couteau implicit + 4-piece | Tree (inspiration income to gamble at high N) |
| Chef d'œuvre (Maître) | Chevalet implicit + Blouse floor | Skill tree (chef d'œuvre unlock node) + Subject mastery |
| Speed + Gold (Rendement) | Brush + Gants implicits | — |
| Mastery (Érudit) | Chapeau implicit | Subject system progression pacing |
| Multi-canvas (Atelier prolifique) | 4-piece slot grant | Painter Office (worker count) + Canvas skill tree multi-canvas nodes |
| PM accumulator (Héritage) | Broche implicit | — |

**Implication:** the Atelier system is meant to be played alongside the rest of the game, not in isolation. Sparring weak Atelier with strong tree/canvas is intentional — the Atelier is amplification, not the primary lever.

---

## 15. Flagged for review

Initial values invented in this draft. The user is the validation gate. Two flag categories:

### 15.1 Tuning numbers (math / feel check)

- **Atelier level cost curve (§9.1):** `100 * 1.15^N` gold spent. Total to level 100 = ~1.2 M. Verify against canvas gold output curves — at what stage of progression should level 100 be reachable?
- **Drop tier distribution (§9.2):** légendaire ramps to 1.5–5% at levels 76–100. **Walk-through (verify):** to persistence-craft 4 légendaire pieces of Set du Maître at a 5% legendary drop rate × 16.7% set affiliation × 60% set targeting × 1/8 slot = ~0.06% per canvas. 5 items same-slot same-set = ~8,500 canvases (with set targeting maintained). At ~30 s per canvas with 4 parallel slots = ~18 hours of canvas time per persistence attempt. ×7 attempts at 5% success rate = ~125 hours per single permanent légendaire Maître item. **Hardcore but plausible.** User to validate the philosophy at this scale.
- **Persistence base success (§10.3):** 60/40/25/12/5/1.5%. Excess sacrifice +5%/item (cap +20%). Tier overshoot +12% (cap +24%). Verify the math against the philosophy: a fully-resourced légendaire attempt = 5 + 5%×4 + 12%×2 = 49% chance (5 base + 20 excess + 24 overshoot). Light-touch légendaire attempt (5 légendaire only, no extras) = 5%. 1 in 20 attempts.
- **Affix value ranges (§7.5):** ×1–5% normal → ×35–50% masterpiece per `*_mult`. With 4 random affixes on légendaire+, a 4-piece Rendement player can easily reach +200% gold and +100% speed. Verify against canvas output curves to ensure the multipliers feel rewarding without overshooting the gold-faucet pacing.
- **Skill tree fame costs (§8.3):** persistence node = 200 fame, masterpiece tier = 500 fame, pin slot 4 = 700 fame. Worth recalibrating once we have fame-per-ascend data from MVP runs.
- **Set 4-piece proc rates (§11.5):** Risque-tout JACKPOT 2%, Rendement burst 1%, Héritage révélation 0.5%. Pure-vibes initial values.
- **Stash cap (§12.1):** 200 base + 150 from QoL. Reduced from WIP's ~500 to better support the strict-B+C puzzle intent. May need to climb back if filters prove to be insufficient. Actively flagged.
- **Implicit affix ranges across slots:** every implicit affix uses the same per-tier range as the random pool, but slots have different "feel" budgets. Probably needs slot-specific ranges later (e.g., chevalet implicit chef-d'œuvre-chance might want a tighter spread than brush speed).

### 15.2 Thematic / naming (taste check)

- **Set bonuses' flavour names** (`Risque-tout`, `Maître`, `Rendement`, `Érudit`, `Atelier prolifique`, `Héritage`) — taste calls.
- **Slot French names** (Chapeau, Blouse, Gants, Chevalet, Couteau à peindre, Broche) — taste calls.
- **JACKPOT, streak créative, révélation** — proc flavour names from set 4-piece bonuses; taste calls.
- **Tier names** (normal, rare, magique, épique, légendaire, masterpiece) — could rename "masterpiece" to a French equivalent (`chef-d'œuvre` is taken by the canvas mechanic; `magnum opus`?). Taste call.

### 15.3 Architectural assumption needing validation

- **Items source = canvas drops (Canvas spec §11).** The original WIPs did not specify where items enter the inventory. The Canvas spec defines this as canvas drops, with chance scaling on quality + atelier level. The Atelier spec's level economy and persistence-craft math depend on this assumption. **Alternative designs:** items produced by gold-cost atelier action (no seed), items via "raw material" sub-currency dropped from canvases, or hybrid. **#1 thing to validate before plan-writing.**

---

## 16. Open implementation questions for plan phase

Resolved during writing-plans, not needed in this spec:

- File layout: new `Atelier.gd` autoload? Replace existing `Inventory.gd` + `Craft.gd` + `CraftRecipes.gd`? Keep `Workshop.gd` separate?
- Persistence: `Save.gd` schema additions for atelier level, equipped items, stash items, pin slots, persistence vault, lock states.
- Drop generator: in canvas tick or in atelier system? Probably atelier (`Atelier.roll_drop(quality, slot_unlocks, tier_ceiling, atelier_level, set_target)`).
- Test surface: target ~50 GUT tests for the system (drop weights, action input validation, persistence-craft probabilities, set bonus activation, auto-clean priority, save/load round-trip).
- UI scenes: `AtelierPopup.tscn` rebuilt from scratch; `CraftPopup.tscn` + `InventoryPopup.tscn` deprecated.
- `Hoverable` rollout per §6 — every interactive element in `AtelierPopup` gets one.

---

## 17. Definition of done

- All 22 Atelier skill tree nodes added to `SkillTreeNodes.gd` and rendered.
- 8 equipment slots + 6 tiers + 6 sets implemented.
- Affix system: pool, tier ranges, count by tier, implicit per slot.
- Drop generator tied to canvas auto-sale (per Canvas §11).
- 5 Atelier actions implemented (craft = drop targeting only; reroll, upgrade, set target, persistence) with strict B+C gates.
- 4-piece set bonuses implemented for all 6 sets with proc/burst tuning.
- Two-tier persistence (4 pin slots + persistence vault crafting) with success math.
- Stash: 200 base + skill tree expansion + filters/sort/search + lock + auto-clean priority.
- Atelier level economy (gold-spent XP, 1:1) and tier distribution table.
- All formulas covered by GUT tests (target 50+ new tests).
- Hover info wired (§6 of info-panel spec) on every interactive element.
- 156 prior tests still pass.
