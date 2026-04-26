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
