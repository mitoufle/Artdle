class_name SubjectMastery
extends Node

# subject_id -> {tier: int, xp_in_tier: int}
var _state: Dictionary = {}

const MAX_TIER: int = 10

static func xp_threshold(tier: int) -> int:
    if tier <= 0:
        return 0
    return 200 * int(pow(2.0, float(tier - 1)))

func tier_of(subject_id: String) -> int:
    return int((_state.get(subject_id, {}) as Dictionary).get("tier", 0))

func xp_of(subject_id: String) -> int:
    return int((_state.get(subject_id, {}) as Dictionary).get("xp_in_tier", 0))

func gain(subject_id: String, amount: int) -> void:
    if amount <= 0:
        return
    var entry: Dictionary = _state.get(subject_id, {"tier": 0, "xp_in_tier": 0})
    var tier: int = int(entry["tier"])
    var xp: int = int(entry["xp_in_tier"]) + amount
    while tier < MAX_TIER:
        var threshold: int = xp_threshold(tier + 1)
        if xp >= threshold:
            xp -= threshold
            tier += 1
        else:
            break
    if tier >= MAX_TIER:
        xp = 0
    _state[subject_id] = {"tier": tier, "xp_in_tier": xp}

func reset() -> void:
    _state.clear()

func serialize() -> Dictionary:
    return {"state": _state.duplicate(true)}

func deserialize(data: Dictionary) -> void:
    _state = (data.get("state", {}) as Dictionary).duplicate(true)

const HINT_HALF_TIER: int = 3  # half of Subjects.PREREQ_TIER

func is_unlocked(subject_id: String) -> bool:
    var s: Dictionary = Subjects.get_subject(subject_id)
    if s.is_empty():
        return false
    if (s["parents"] as Array).is_empty():
        return true
    for p in (s["parents"] as Array):
        if tier_of(p["subject_id"]) < int(p["mastery_tier"]):
            return false
    return true

func has_hint(subject_id: String) -> bool:
    if is_unlocked(subject_id):
        return false
    var s: Dictionary = Subjects.get_subject(subject_id)
    if s.is_empty() or (s["parents"] as Array).is_empty():
        return false
    for p in (s["parents"] as Array):
        if tier_of(p["subject_id"]) >= HINT_HALF_TIER:
            return true
    return false
