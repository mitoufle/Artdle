extends GutTest

func test_base_quality_simple():
    # spec §6.1: base_quality = taille + style + palette + mastery + floor_bonus
    assert_eq(Balance.canvas_base_quality(5, 5, 5, 3, 0.0), 18.0)

func test_base_quality_late_game():
    assert_eq(Balance.canvas_base_quality(10, 25, 25, 10, 5.0), 75.0)

func test_base_quality_floor_bonus_added():
    assert_eq(Balance.canvas_base_quality(1, 1, 1, 0, 7.0), 10.0)

func test_ideal_quality_uses_skill_caps_not_current():
    # spec §6.2: ideal = taille + style_cap + palette_cap + 10 + floor_bonus
    # player at tier 5, current style 5 (cap 10), current palette 5 (cap 10)
    assert_eq(Balance.canvas_ideal_quality(5, 10, 10, 0.0), 35.0)

func test_ideal_quality_with_floor_bonus():
    assert_eq(Balance.canvas_ideal_quality(10, 25, 25, 5.0), 75.0)

func test_canvas_gold_formula():
    # spec §6.3: gold = quality * tier * 10 * gold_mult
    assert_eq(Balance.canvas_gold(5.0, 1, 1.0), 50.0)
    assert_eq(Balance.canvas_gold(75.0, 10, 1.0), 7500.0)
    assert_eq(Balance.canvas_gold(100.0, 10, 5.0), 50000.0)

func test_canvas_pm_base_floor_div_10():
    assert_eq(Balance.canvas_pm_base(75.0), 7)
    assert_eq(Balance.canvas_pm_base(5.0), 0)
    assert_eq(Balance.canvas_pm_base(10.0), 1)

func test_canvas_pm_burst_eligible_at_quality_31():
    # spec §6.4: pm_burst_eligible = final_quality > 30
    assert_true(Balance.canvas_pm_burst_eligible(31.0))
    assert_false(Balance.canvas_pm_burst_eligible(30.0))

func test_canvas_time_formula():
    # spec §6.5: time = (tier*2 + style*1) * (1 - reduction) / speed_mult
    assert_eq(Balance.canvas_time(1, 1, 0.0, 1.0), 3.0)
    assert_eq(Balance.canvas_time(5, 10, 0.0, 1.0), 20.0)
    # 30% reduction + 2x speed
    assert_almost_eq(Balance.canvas_time(10, 25, 0.30, 2.0), (45.0 * 0.70) / 2.0, 0.001)

func test_canvas_time_reduction_capped_at_70_percent():
    # spec §15.1 implies cap, but direct test: 0.95 reduction must be clamped to 0.70
    assert_almost_eq(Balance.canvas_time(1, 1, 0.95, 1.0), 3.0 * 0.30, 0.001)
