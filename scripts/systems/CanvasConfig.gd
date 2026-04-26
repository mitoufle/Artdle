class_name CanvasConfig
extends Node

const VALID_GAMBLE_LEVELS: Array = [0, 10, 100, 1000, 10000]
const SKILL_CAP_DEFAULT: int = 10  # spec §5 baseline

# Sticky settings
var style: int = 1
var palette: int = 1
var current_subject: String = "nature"
var gamble_n_inspi: int = 0  # 0 = off; ignored when auto_gamble is true
var auto_gamble: bool = false  # spec §8.3 Always-gamble toggle (skill-tree gated)

# Per-run improvement-tab ceilings (within skill cap)
var style_current_ceiling: int = 1
var palette_current_ceiling: int = 1

# External ref (set by GameState during boot)
var subject_mastery: SubjectMastery = null

func set_style(v: int) -> void:
    style = clamp(v, 1, style_current_ceiling)

func set_palette(v: int) -> void:
    palette = clamp(v, 1, palette_current_ceiling)

func set_subject(subject_id: String) -> bool:
    if subject_mastery == null:
        return false
    if not subject_mastery.is_unlocked(subject_id):
        return false
    current_subject = subject_id
    return true

func set_gamble(n: int) -> void:
    if VALID_GAMBLE_LEVELS.has(n):
        gamble_n_inspi = n
        auto_gamble = false

func set_auto_gamble() -> void:
    auto_gamble = true
    gamble_n_inspi = 0

func buy_style_ceiling(skill_cap: int = SKILL_CAP_DEFAULT) -> void:
    if style_current_ceiling < skill_cap:
        style_current_ceiling += 1

func buy_palette_ceiling(skill_cap: int = SKILL_CAP_DEFAULT) -> void:
    if palette_current_ceiling < skill_cap:
        palette_current_ceiling += 1

func reset() -> void:
    style = 1
    palette = 1
    current_subject = "nature"
    gamble_n_inspi = 0
    auto_gamble = false
    style_current_ceiling = 1
    palette_current_ceiling = 1

func serialize() -> Dictionary:
    return {
        "style": style,
        "palette": palette,
        "current_subject": current_subject,
        "gamble_n_inspi": gamble_n_inspi,
        "auto_gamble": auto_gamble,
        "style_current_ceiling": style_current_ceiling,
        "palette_current_ceiling": palette_current_ceiling,
    }

func deserialize(data: Dictionary) -> void:
    style = int(data.get("style", 1))
    palette = int(data.get("palette", 1))
    current_subject = String(data.get("current_subject", "nature"))
    gamble_n_inspi = int(data.get("gamble_n_inspi", 0))
    auto_gamble = bool(data.get("auto_gamble", false))
    style_current_ceiling = int(data.get("style_current_ceiling", 1))
    palette_current_ceiling = int(data.get("palette_current_ceiling", 1))

static func style_ceiling_cost(current_level: int) -> float:
    return 100.0 * pow(3.0, float(current_level - 1))

static func palette_ceiling_cost(current_level: int) -> float:
    return 100.0 * pow(3.0, float(current_level - 1))

# Spec §10 inspiration sink for explicit hint reveal action — formula reserved.
# Buy action (UI button + GameState handler + reveals_used counter) lands with
# the Atelier plan; current builds rely on the skill-tree Subject Hint nodes
# (CanvasPopup._hint_threshold) for reveal control.
static func subject_hint_cost(reveals_used: int) -> float:
    return 1000.0 * pow(2.0, float(reveals_used))
