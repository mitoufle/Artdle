extends GutTest

var currency: Currency
var st: SkillTree

func before_each():
    currency = Currency.new()
    st = SkillTree.new()
    st.currency = currency

func after_each():
    if currency != null:
        currency.free()
        currency = null
    if st != null:
        st.free()
        st = null

func test_initial_no_unlocked():
    assert_eq(st.unlocked_nodes.size(), 0)

func test_initial_multipliers_are_one():
    assert_almost_eq(st.canvas_gold_mult(), 1.0, 0.0001)
    assert_almost_eq(st.canvas_speed_mult(), 1.0, 0.0001)

func test_unlock_success_spends_fame():
    currency.add("fame", BigNumber.from_float(5.0))
    var ok = st.unlock("gilded_frame")
    assert_true(ok)
    assert_true(st.unlocked_nodes.has("gilded_frame"))
    assert_eq(currency.get_amount("fame").value, 4.0)

func test_unlock_insufficient_fails():
    var ok = st.unlock("gilded_frame")
    assert_false(ok)
    assert_false(st.unlocked_nodes.has("gilded_frame"))

func test_unlock_twice_fails_second_time():
    currency.add("fame", BigNumber.from_float(10.0))
    assert_true(st.unlock("gilded_frame"))
    assert_false(st.unlock("gilded_frame"))
    assert_eq(currency.get_amount("fame").value, 10.0 - 1.0)

func test_canvas_gold_mult_applies_unlocked_effects():
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")
    st.unlock("master_palette")
    assert_almost_eq(st.canvas_gold_mult(), 1.35, 0.0001)

func test_canvas_speed_mult_applies_unlocked_effects():
    currency.add("fame", BigNumber.from_float(20.0))
    st.unlock("quick_strokes")
    st.unlock("tireless_hand")
    assert_almost_eq(st.canvas_speed_mult(), 1.45, 0.0001)

func test_persists_through_reset():
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")
    currency.reset(["inspiration", "gold"])
    assert_true(st.unlocked_nodes.has("gilded_frame"))

func test_serialize_roundtrip():
    currency.add("fame", BigNumber.from_float(10.0))
    st.unlock("gilded_frame")
    var data = st.serialize()
    var fresh = SkillTree.new()
    fresh.currency = currency
    fresh.deserialize(data)
    assert_true(fresh.unlocked_nodes.has("gilded_frame"))
    fresh.free()

func test_unlock_blocked_when_prereq_unmet():
    # style_cap_2 requires style_cap_1
    currency.add("fame", BigNumber.from_float(50.0))
    assert_false(st.unlock("style_cap_2"))
    assert_eq(currency.get_amount("fame").value, 50.0)  # fame not spent

func test_unlock_succeeds_when_prereq_met():
    currency.add("fame", BigNumber.from_float(50.0))
    assert_true(st.unlock("style_cap_1"))
    assert_true(st.unlock("style_cap_2"))
