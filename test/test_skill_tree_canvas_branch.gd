extends GutTest

func test_chef_doeuvre_unlock_node_exists():
    var n = SkillTreeNodes.get_node("chef_doeuvre_unlock")
    assert_false(n.is_empty())
    assert_eq(int(n["cost"]), 10)
    assert_eq(float(n["effects"].get("chef_doeuvre_unlocked", 0.0)), 1.0)

func test_style_ceiling_chain_exists():
    for id in ["style_cap_1", "style_cap_2", "style_cap_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_palette_ceiling_chain_exists():
    for id in ["palette_cap_1", "palette_cap_2", "palette_cap_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_multi_canvas_slots_exist():
    for id in ["multi_canvas_1", "multi_canvas_2", "multi_canvas_3"]:
        assert_false(SkillTreeNodes.get_node(id).is_empty(), id)

func test_total_canvas_branch_count_17():
    var ids = SkillTreeNodes.all_node_ids()
    var canvas_branch = []
    for id in ids:
        var n = SkillTreeNodes.get_node(id)
        if n.get("branch", "") == "canvas":
            canvas_branch.append(id)
    assert_eq(canvas_branch.size(), 17)

func test_canvas_branch_costs_total_in_range():
    # Sanity: 10 (chef) + 120 (3 style + 3 palette caps) + 45 (2 hints) +
    #         600 (3 multi-canvas) + 25 (safety) + 15 (always-gamble) +
    #         80 (2 quality floor) + 75 (auto-mastery) = 970
    var total: float = 0.0
    for id in SkillTreeNodes.all_node_ids():
        var n = SkillTreeNodes.get_node(id)
        if n.get("branch", "") == "canvas":
            total += float(n["cost"])
    assert_eq(total, 970.0)
