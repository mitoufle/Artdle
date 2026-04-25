class_name Subjects
extends RefCounted

# All 20 subjects per spec §7.3 + §7.4. id -> {name, parents}
# parents: array of {subject_id, mastery_tier} required to unlock.
# Starter subjects have empty `parents`.
const SUBJECTS: Dictionary = {
    "nature":     {"name": "Nature",     "parents": []},
    "vie":        {"name": "Vie",        "parents": []},
    "geometrie":  {"name": "Géométrie",  "parents": []},
    "emotion":    {"name": "Émotion",    "parents": []},
    "mythe":      {"name": "Mythe",      "parents": []},
}

const PREREQ_TIER: int = 5  # spec §7.2

static func starter_ids() -> Array:
    var out: Array = []
    for id in SUBJECTS.keys():
        if (SUBJECTS[id] as Dictionary)["parents"].is_empty():
            out.append(id)
    return out

static func get_subject(id: String) -> Dictionary:
    return SUBJECTS.get(id, {})

static func all_ids() -> Array:
    return SUBJECTS.keys()
