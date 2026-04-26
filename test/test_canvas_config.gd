extends GutTest

var cfg: CanvasConfig

func before_each():
    cfg = CanvasConfig.new()

func after_each():
    if cfg != null:
        cfg.free()

func test_initial_style_1_palette_1():
    assert_eq(cfg.style, 1)
    assert_eq(cfg.palette, 1)

func test_initial_subject_is_first_starter():
    assert_eq(cfg.current_subject, "nature")

func test_initial_gamble_off():
    assert_eq(cfg.gamble_n_inspi, 0)

func test_initial_ceilings_are_one():
    assert_eq(cfg.style_current_ceiling, 1)
    assert_eq(cfg.palette_current_ceiling, 1)

func test_set_style_clamps_to_current_ceiling():
    cfg.style_current_ceiling = 5
    cfg.set_style(10)
    assert_eq(cfg.style, 5)

func test_set_palette_clamps_to_current_ceiling():
    cfg.palette_current_ceiling = 3
    cfg.set_palette(7)
    assert_eq(cfg.palette, 3)

func test_set_subject_only_if_unlocked():
    var mastery := SubjectMastery.new()
    add_child(mastery)
    cfg.subject_mastery = mastery
    assert_true(cfg.set_subject("nature"))
    assert_eq(cfg.current_subject, "nature")
    assert_false(cfg.set_subject("animaliere"))  # locked, no mastery
    assert_eq(cfg.current_subject, "nature")
    mastery.queue_free()

func test_set_gamble_to_valid_levels():
    for n in [0, 10, 100, 1000, 10000]:
        cfg.set_gamble(n)
        assert_eq(cfg.gamble_n_inspi, n)

func test_set_gamble_rejects_invalid():
    cfg.set_gamble(50)  # not a valid level
    assert_eq(cfg.gamble_n_inspi, 0)

func test_buy_style_ceiling_increments():
    cfg.style_current_ceiling = 1
    cfg.buy_style_ceiling()
    assert_eq(cfg.style_current_ceiling, 2)

func test_buy_style_ceiling_clamps_to_skill_cap():
    cfg.style_current_ceiling = 10
    cfg.buy_style_ceiling(10)  # explicit cap
    assert_eq(cfg.style_current_ceiling, 10)

func test_serialize_roundtrip():
    cfg.style_current_ceiling = 5
    cfg.set_style(3)
    cfg.set_gamble(100)
    var data = cfg.serialize()
    var fresh = CanvasConfig.new()
    fresh.deserialize(data)
    assert_eq(fresh.style, 3)
    assert_eq(fresh.style_current_ceiling, 5)
    assert_eq(fresh.gamble_n_inspi, 100)
    fresh.free()

func test_style_ceiling_buy_cost_curve():
    # spec §10: cost = 100 * 3^(level-1) for the +1 from current level
    assert_eq(CanvasConfig.style_ceiling_cost(1), 100.0)   # 1 → 2 costs 100
    assert_eq(CanvasConfig.style_ceiling_cost(2), 300.0)
    assert_eq(CanvasConfig.style_ceiling_cost(5), 8100.0)

func test_palette_ceiling_cost_curve_same():
    assert_eq(CanvasConfig.palette_ceiling_cost(3), 900.0)

func test_subject_hint_cost_curve():
    # spec §10: 1000 * 2^(reveals_used)
    assert_eq(CanvasConfig.subject_hint_cost(0), 1000.0)
    assert_eq(CanvasConfig.subject_hint_cost(2), 4000.0)
