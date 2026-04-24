extends GutTest

var currency: Currency
var tree: InspirationTree

func before_each():
    currency = Currency.new()
    tree = InspirationTree.new()
    tree.currency = currency

func after_each():
    if currency != null:
        currency.free()
    if tree != null:
        tree.free()

func test_initial_stage_zero():
    assert_eq(tree.stage_index, 0)

func test_initial_parts_empty_levels():
    assert_eq(tree.get_part_level("roots"), 0)

func test_tick_zero_rate_at_start():
    var inspi_before = currency.get_amount("inspiration").value
    tree.tick(1.0)
    assert_eq(currency.get_amount("inspiration").value, inspi_before)

func test_upgrade_part_success_spends_gold():
    currency.add("gold", BigNumber.from_float(100.0))
    var cost_before = TreeStages.upgrade_cost(0, "roots", 0).value
    var ok = tree.upgrade_part("roots")
    assert_true(ok)
    assert_eq(tree.get_part_level("roots"), 1)
    assert_eq(currency.get_amount("gold").value, 100.0 - cost_before)

func test_upgrade_part_insufficient_gold_fails():
    var ok = tree.upgrade_part("roots")
    assert_false(ok)
    assert_eq(tree.get_part_level("roots"), 0)

func test_upgrade_part_capped_at_max():
    currency.add("gold", BigNumber.from_float(1.0e9))
    for i in range(10):
        tree.upgrade_part("roots")
    var max_lvl = TreeStages.get_stage(0)["parts"]["roots"]["max_level"]
    assert_eq(tree.get_part_level("roots"), max_lvl)

func test_tick_produces_inspi_after_upgrade():
    currency.add("gold", BigNumber.from_float(1000.0))
    tree.upgrade_part("roots")
    tree.tick(1.0)
    var inspi = currency.get_amount("inspiration").value
    assert_gt(inspi, 0.0)

func test_stage_advances_when_all_parts_maxed():
    watch_signals(tree)
    currency.add("gold", BigNumber.from_float(1.0e6))
    var s0 = TreeStages.get_stage(0)
    var max_lvl = s0["parts"]["roots"]["max_level"]
    for i in range(max_lvl):
        tree.upgrade_part("roots")
    assert_eq(tree.stage_index, 1)
    assert_signal_emitted(tree, "stage_entered")

func test_stage_advance_emits_possibility_unlocked():
    watch_signals(tree)
    currency.add("gold", BigNumber.from_float(1.0e9))
    _max_all_parts_of_current_stage(tree)  # 0 -> 1
    _max_all_parts_of_current_stage(tree)  # 1 -> 2 (entering stage 2 "Rameaux" emits workshop)
    assert_signal_emitted_with_parameters(tree, "possibility_unlocked", ["workshop"])

func test_reset_returns_to_stage_zero():
    currency.add("gold", BigNumber.from_float(1.0e6))
    tree.upgrade_part("roots")
    tree.reset()
    assert_eq(tree.stage_index, 0)
    assert_eq(tree.get_part_level("roots"), 0)

func test_serialize_roundtrip():
    currency.add("gold", BigNumber.from_float(1000.0))
    tree.upgrade_part("roots")
    var data = tree.serialize()
    var fresh = InspirationTree.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_eq(fresh.stage_index, tree.stage_index)
    assert_eq(fresh.get_part_level("roots"), tree.get_part_level("roots"))
    fresh.free()

func _max_all_parts_of_current_stage(t: InspirationTree) -> void:
    var s = TreeStages.get_stage(t.stage_index)
    for part_id in s["parts"].keys():
        var max_lvl = s["parts"][part_id]["max_level"]
        while t.get_part_level(part_id) < max_lvl:
            if not t.upgrade_part(part_id):
                break
