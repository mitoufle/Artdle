class_name Subjects
extends RefCounted

# All 20 subjects per spec §7.3 + §7.4. id -> {name, parents}
# parents: array of {subject_id, mastery_tier} required to unlock.
# Starter subjects have empty `parents`.
const SUBJECTS: Dictionary = {
    # Starters (5)
    "nature":     {"name": "Nature",     "parents": []},
    "vie":        {"name": "Vie",        "parents": []},
    "geometrie":  {"name": "Géométrie",  "parents": []},
    "emotion":    {"name": "Émotion",    "parents": []},
    "mythe":      {"name": "Mythe",      "parents": []},
    # Tier 1 derived (5)
    "animaliere":   {"name": "Animalière",   "parents": [{"subject_id": "nature",    "mastery_tier": 5}, {"subject_id": "vie",       "mastery_tier": 5}]},
    "architecture": {"name": "Architecture", "parents": [{"subject_id": "nature",    "mastery_tier": 5}, {"subject_id": "geometrie", "mastery_tier": 5}]},
    "portrait":     {"name": "Portrait",     "parents": [{"subject_id": "vie",       "mastery_tier": 5}, {"subject_id": "emotion",   "mastery_tier": 5}]},
    "religieuse":   {"name": "Religieuse",   "parents": [{"subject_id": "emotion",   "mastery_tier": 5}, {"subject_id": "mythe",     "mastery_tier": 5}]},
    "cosmique":     {"name": "Cosmique",     "parents": [{"subject_id": "mythe",     "mastery_tier": 5}, {"subject_id": "geometrie", "mastery_tier": 5}]},
    # Tier 2 derived (5)
    "bestiaire_mythique": {"name": "Bestiaire mythique", "parents": [{"subject_id": "animaliere",   "mastery_tier": 5}, {"subject_id": "mythe",        "mastery_tier": 5}]},
    "jardin_classique":   {"name": "Jardin classique",   "parents": [{"subject_id": "architecture", "mastery_tier": 5}, {"subject_id": "nature",       "mastery_tier": 5}]},
    "allegorie":          {"name": "Allégorie",          "parents": [{"subject_id": "portrait",     "mastery_tier": 5}, {"subject_id": "mythe",        "mastery_tier": 5}]},
    "cathedrale":         {"name": "Cathédrale",         "parents": [{"subject_id": "religieuse",   "mastery_tier": 5}, {"subject_id": "architecture", "mastery_tier": 5}]},
    "surrealiste":        {"name": "Surréaliste",        "parents": [{"subject_id": "cosmique",     "mastery_tier": 5}, {"subject_id": "nature",       "mastery_tier": 5}]},
    # Tier 3 derived (5)
    "apocalypse":      {"name": "Apocalypse",      "parents": [{"subject_id": "bestiaire_mythique", "mastery_tier": 5}, {"subject_id": "religieuse",       "mastery_tier": 5}]},
    "pastorale":       {"name": "Pastorale",       "parents": [{"subject_id": "jardin_classique",   "mastery_tier": 5}, {"subject_id": "allegorie",        "mastery_tier": 5}]},
    "triomphe":        {"name": "Triomphe",        "parents": [{"subject_id": "cathedrale",         "mastery_tier": 5}, {"subject_id": "allegorie",        "mastery_tier": 5}]},
    "onirique":        {"name": "Onirique",        "parents": [{"subject_id": "surrealiste",        "mastery_tier": 5}, {"subject_id": "portrait",         "mastery_tier": 5}]},
    "eschatologique":  {"name": "Eschatologique",  "parents": [{"subject_id": "apocalypse",         "mastery_tier": 5}, {"subject_id": "cosmique",         "mastery_tier": 5}]},
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
