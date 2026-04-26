class_name Balance
extends RefCounted

const ASCEND_PALIER_BASE: float = 1000.0
const ASCEND_PALIER_GROWTH: float = 2.0

const FAME_CONVERSION_THRESHOLD: float = 1000.0
const FAME_CONVERSION_LOG_FACTOR: float = 1.0

const PM_GAIN_TIER_FACTOR: float = 0.1
const PM_LOG_FACTOR: float = 0.2

static func palier_ascend(ascend_count: int) -> BigNumber:
    var v = ASCEND_PALIER_BASE * pow(ASCEND_PALIER_GROWTH, float(ascend_count))
    return BigNumber.from_float(v)

static func fame_conversion(inspi: BigNumber) -> BigNumber:
    if inspi.value < FAME_CONVERSION_THRESHOLD:
        return BigNumber.zero()
    var fame = floor(log(inspi.value / FAME_CONVERSION_THRESHOLD + 1.0) * FAME_CONVERSION_LOG_FACTOR + 1.0)
    return BigNumber.from_float(fame)

static func paint_mastery_gain(canvas_tier: int, gold_earned: BigNumber) -> BigNumber:
    var gain = gold_earned.value * PM_GAIN_TIER_FACTOR * float(canvas_tier)
    return BigNumber.from_float(gain)

static func paint_mastery_multiplier(paint_mastery: BigNumber) -> float:
    return 1.0 + PM_LOG_FACTOR * log(paint_mastery.value + 1.0)

# -- Canvas formulas (spec 2026-04-25-canvas-design §6) --

static func canvas_base_quality(taille: int, style: int, palette: int, mastery_tier: int, floor_bonus: float) -> float:
    return float(taille) + float(style) + float(palette) + float(mastery_tier) + floor_bonus

static func canvas_ideal_quality(taille: int, style_cap: int, palette_cap: int, floor_bonus: float) -> float:
    return float(taille) + float(style_cap) + float(palette_cap) + 10.0 + floor_bonus
