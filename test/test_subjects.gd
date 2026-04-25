extends GutTest

func test_starter_subjects_count():
    assert_eq(Subjects.starter_ids().size(), 5)

func test_starter_subjects_contain_nature():
    assert_true(Subjects.starter_ids().has("nature"))

func test_subject_name_localised():
    assert_eq(Subjects.get_subject("nature")["name"], "Nature")

func test_unknown_subject_returns_empty_dict():
    assert_true(Subjects.get_subject("does_not_exist").is_empty())

func test_total_subject_count_20():
    assert_eq(Subjects.all_ids().size(), 20)

func test_animaliere_requires_nature_and_vie():
    var s = Subjects.get_subject("animaliere")
    var parents = s["parents"]
    assert_eq(parents.size(), 2)
    var ids = []
    for p in parents:
        ids.append(p["subject_id"])
    assert_true(ids.has("nature"))
    assert_true(ids.has("vie"))
    for p in parents:
        assert_eq(p["mastery_tier"], Subjects.PREREQ_TIER)

func test_eschatologique_chains_two_levels_deep():
    var s = Subjects.get_subject("eschatologique")
    assert_false(s.is_empty())
    var parent_ids = []
    for p in s["parents"]:
        parent_ids.append(p["subject_id"])
    assert_true(parent_ids.has("apocalypse"))
    assert_true(parent_ids.has("cosmique"))

func test_no_starter_has_parents():
    for id in Subjects.starter_ids():
        assert_true((Subjects.get_subject(id)["parents"] as Array).is_empty())
