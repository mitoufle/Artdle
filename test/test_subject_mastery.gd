extends GutTest

var mastery: SubjectMastery

func before_each():
    mastery = SubjectMastery.new()

func after_each():
    if mastery != null:
        mastery.free()

func test_initial_tier_zero_for_starter():
    assert_eq(mastery.tier_of("nature"), 0)

func test_xp_threshold_tier_1_is_200():
    # spec §7.2: tier T requires 200 * 2^(T-1) XP. Tier 1 = 200.
    assert_eq(SubjectMastery.xp_threshold(1), 200)

func test_xp_threshold_tier_5_is_3200():
    assert_eq(SubjectMastery.xp_threshold(5), 3200)

func test_xp_threshold_tier_10_is_102400():
    assert_eq(SubjectMastery.xp_threshold(10), 102400)

func test_gain_under_threshold_does_not_advance_tier():
    mastery.gain("nature", 100)
    assert_eq(mastery.tier_of("nature"), 0)
    assert_eq(mastery.xp_of("nature"), 100)

func test_gain_at_threshold_advances_tier():
    mastery.gain("nature", 200)
    assert_eq(mastery.tier_of("nature"), 1)
    # Spec semantics: XP carries over across tier boundary.
    assert_eq(mastery.xp_of("nature"), 0)

func test_gain_can_advance_multiple_tiers():
    # tier 1 = 200, tier 2 = 400. Total 600.
    mastery.gain("nature", 600)
    assert_eq(mastery.tier_of("nature"), 2)

func test_gain_caps_at_tier_10():
    mastery.gain("nature", 1_000_000)
    assert_eq(mastery.tier_of("nature"), 10)

func test_serialize_roundtrip():
    mastery.gain("nature", 250)
    mastery.gain("vie", 100)
    var data = mastery.serialize()
    var fresh = SubjectMastery.new()
    fresh.deserialize(data)
    assert_eq(fresh.tier_of("nature"), 1)
    assert_eq(fresh.xp_of("vie"), 100)
    fresh.free()

func test_starter_subjects_unlocked_from_start():
    assert_true(mastery.is_unlocked("nature"))
    assert_true(mastery.is_unlocked("vie"))

func test_derived_subject_locked_until_both_parents_at_tier_5():
    assert_false(mastery.is_unlocked("animaliere"))
    mastery.gain("nature", SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3) + SubjectMastery.xp_threshold(4) + SubjectMastery.xp_threshold(5))
    assert_false(mastery.is_unlocked("animaliere"))  # one parent at tier 5, second still 0
    mastery.gain("vie", SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3) + SubjectMastery.xp_threshold(4) + SubjectMastery.xp_threshold(5))
    assert_true(mastery.is_unlocked("animaliere"))

func test_hint_revealed_when_half_progress_on_a_parent():
    # Half progress = parent at tier 3 (half of prereq tier 5).
    var xp_to_tier_3 = SubjectMastery.xp_threshold(1) + SubjectMastery.xp_threshold(2) + SubjectMastery.xp_threshold(3)
    mastery.gain("nature", xp_to_tier_3)
    # animaliere requires nature(5) + vie(5); half = nature(3) reached.
    assert_true(mastery.has_hint("animaliere"))
    assert_false(mastery.is_unlocked("animaliere"))

func test_no_hint_when_no_progress():
    assert_false(mastery.has_hint("animaliere"))
