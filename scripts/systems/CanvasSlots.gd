class_name CanvasSlots
extends Node

signal canvas_completed(payload: Dictionary)
# payload keys: slot_index (int), quality (float), tier (int),
#               subject_id (String), gambled (bool), chef_doeuvre (bool)

signal canvas_starting(slot_index: int)
# Fired immediately before each canvas's start() call. GameState listens to
# debit inspiration for gamble and stamps the actual amount paid (0 if not
# gambled, >0 if paid) onto the canvas as `gamble_amount` meta. The slot
# manager reads that on finish to resolve the gamble outcome.

# Items source = crafting only (design call 2026-04-26). No drops on canvas finish.

# External refs (set by GameState during boot).
var config: CanvasConfig = null
var mastery: SubjectMastery = null

# Provider for current canvas tier (auto-max). GameState supplies a Callable.
var tier_provider: Callable = Callable()

# Aggregated multipliers (set each tick by GameState before calling tick(delta)).
var canvas_speed_mult: float = 1.0
var style_time_reduction: float = 0.0
var quality_floor_bonus: float = 0.0
var chef_doeuvre_chance: float = 0.0  # 0..1, e.g. 0.005 baseline if unlocked
var gamble_yield_mult: float = 1.0
var gamble_success_chance: float = 0.5

# Skill-tree caps (used by ideal_quality and CanvasConfig.buy_*_ceiling).
var style_skill_cap: int = 10
var palette_skill_cap: int = 10

# Test/dev override — when > 0, replaces computed paint_time.
var paint_time_override: float = -1.0

# Internal: list of Canvas children.
var _slots: Array = []

func slot_count() -> int:
    return _slots.size()

func get_canvas(idx: int) -> Canvas:
    return _slots[idx] as Canvas

func set_slot_count(n: int) -> void:
    while _slots.size() < n:
        var c := Canvas.new()
        c.name = "Slot_%d" % _slots.size()
        var idx: int = _slots.size()
        c.finished.connect(func(payload: Dictionary): _on_slot_finished(idx, payload))
        add_child(c)
        _slots.append(c)
        _start_slot(c)
    while _slots.size() > n:
        var dropped: Canvas = _slots.pop_back()
        dropped.queue_free()

func tick(delta: float) -> void:
    var scaled: float = delta * canvas_speed_mult
    for c in _slots:
        if not (c as Canvas).is_running:
            _start_slot(c)
        (c as Canvas).tick(scaled)

func _start_slot(c: Canvas) -> void:
    if config == null or mastery == null:
        return
    var tier: int = 1
    if tier_provider.is_valid():
        tier = int(tier_provider.call())
    var subject_id: String = config.current_subject
    var mastery_tier: int = mastery.tier_of(subject_id)
    var base_q: float = Balance.canvas_base_quality(tier, config.style, config.palette, mastery_tier, quality_floor_bonus)
    # Gamble (resolution captured here; success/fail materialised on finish payload).
    # Chef d'œuvre roll happens at finish to keep tests deterministic via stubs.
    var paint_time: float = paint_time_override if paint_time_override > 0.0 \
        else Balance.canvas_time(tier, config.style, style_time_reduction, 1.0)  # speed_mult applied via tick scaling
    canvas_starting.emit(_slots.find(c))
    c.start(paint_time, base_q)
    c.set_meta("tier", tier)
    c.set_meta("subject_id", subject_id)

func _on_slot_finished(idx: int, payload: Dictionary) -> void:
    var c: Canvas = _slots[idx] as Canvas
    var base_q: float = float(payload["quality"])
    var tier: int = int(c.get_meta("tier", 1))
    var subject_id: String = String(c.get_meta("subject_id", "nature"))
    # Gamble resolution. The amount actually paid is stamped on the canvas at start
    # (per-slot, not shared via config), so it's stable even if config changes mid-canvas
    # or another slot started since.
    var gambled: bool = false
    var gamble_succeeded: bool = false
    var gambled_q: float = base_q
    var gamble_amount: int = int(c.get_meta("gamble_amount", 0))
    if gamble_amount > 0:
        gambled = true
        if randf() < gamble_success_chance:
            gamble_succeeded = true
            gambled_q = Balance.gamble_success_quality_with_mult(base_q, gamble_amount, gamble_yield_mult)
        else:
            gambled_q = Balance.gamble_failure_quality(base_q)
    # Chef d'œuvre roll
    var is_chef: bool = false
    var final_q: float = gambled_q
    if randf() < chef_doeuvre_chance:
        is_chef = true
        var ideal: float = Balance.canvas_ideal_quality(tier, style_skill_cap, palette_skill_cap, quality_floor_bonus)
        final_q = max(gambled_q, ideal)
    canvas_completed.emit({
        "slot_index":         idx,
        "quality":            final_q,
        "tier":               tier,
        "subject_id":         subject_id,
        "gambled":            gambled,
        "gamble_succeeded":   gamble_succeeded,
        "gamble_inspi_spent": (gamble_amount if gambled else 0),
        "chef_doeuvre":       is_chef,
    })
    # Auto-restart immediately (auto-sale state machine, spec §3.2).
    _start_slot(c)
