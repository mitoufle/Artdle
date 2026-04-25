extends GutTest

func test_starter_subjects_count():
    assert_eq(Subjects.starter_ids().size(), 5)

func test_starter_subjects_contain_nature():
    assert_true(Subjects.starter_ids().has("nature"))

func test_subject_name_localised():
    assert_eq(Subjects.get_subject("nature")["name"], "Nature")

func test_unknown_subject_returns_empty_dict():
    assert_true(Subjects.get_subject("does_not_exist").is_empty())
