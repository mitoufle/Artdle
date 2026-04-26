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

const STYLE_TIME_REDUCTION_CAP: float = 0.70
const PM_BURST_THRESHOLD: float = 30.0

static func canvas_gold(final_quality: float, tier: int, gold_mult: float) -> float:
    return final_quality * float(tier) * 10.0 * gold_mult

static func canvas_pm_base(final_quality: float) -> int:
    return int(floor(final_quality / 10.0))

static func canvas_pm_burst_eligible(final_quality: float) -> bool:
    return final_quality > PM_BURST_THRESHOLD

static func canvas_time(tier: int, style: int, time_reduction: float, speed_mult: float) -> float:
    var clamped_reduction: float = clamp(time_reduction, 0.0, STYLE_TIME_REDUCTION_CAP)
    var raw: float = (float(tier) * 2.0 + float(style) * 1.0)
    var divisor: float = max(speed_mult, 0.0001)  # guard div-by-zero
    return raw * (1.0 - clamped_reduction) / divisor

static func gamble_success_quality(base_quality: float, n_inspi: int) -> float:
    if n_inspi < 1:
        return base_quality
    var bonus: float = log(float(n_inspi)) / log(10.0) * 0.5
    return base_quality * (1.0 + bonus)

static func gamble_success_quality_with_mult(base_quality: float, n_inspi: int, yield_mult: float) -> float:
    if n_inspi < 1:
        return base_quality
    var bonus: float = log(float(n_inspi)) / log(10.0) * 0.5 * yield_mult
    return base_quality * (1.0 + bonus)

static func gamble_failure_quality(base_quality: float) -> float:
    return max(1.0, floor(base_quality / 2.0))
