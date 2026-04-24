extends GutTest

func test_stage_0_is_seed():
    var s = TreeStages.get_stage(0)
    assert_true(not s.is_empty())
    assert_eq(s["name"], "Pousse")

func test_stage_count_at_least_5():
    assert_gte(TreeStages.count(), 5)

func test_stage_0_has_roots_part():
    var s = TreeStages.get_stage(0)
    assert_true(s["parts"].has("roots"))

func test_later_stage_has_more_parts():
    var s0 = TreeStages.get_stage(0)
    var s3 = TreeStages.get_stage(3)
    assert_gt(s3["parts"].size(), s0["parts"].size())

func test_part_has_required_fields():
    var s = TreeStages.get_stage(0)
    var roots = s["parts"]["roots"]
    assert_true(roots.has("base_rate"))
    assert_true(roots.has("max_level"))
    assert_true(roots.has("upgrade_base_cost"))

func test_stage_3_unlocks_workshop():
    var s = TreeStages.get_stage(2)
    assert_true("workshop" in s.get("unlocks", []))

func test_unlock_cost_defined():
    assert_gt(TreeStages.unlock_cost("workshop").value, 0.0)
