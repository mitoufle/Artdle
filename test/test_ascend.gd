extends GutTest

var currency: Currency
var canvas: Canvas
var tree: InspirationTree
var workshop: Workshop
var inventory: Inventory
var painter_office: PainterOffice
var ascend: Ascend

func before_each():
    currency = Currency.new()
    canvas = Canvas.new()
    tree = InspirationTree.new()
    tree.currency = currency
    workshop = Workshop.new()
    workshop.currency = currency
    inventory = Inventory.new()
    painter_office = PainterOffice.new()
    painter_office.currency = currency

    ascend = Ascend.new()
    ascend.currency = currency
    ascend.canvas = canvas
    ascend.tree = tree
    ascend.workshop = workshop
    ascend.inventory = inventory
    ascend.painter_office = painter_office

func after_each():
    for n in [currency, canvas, tree, workshop, inventory, painter_office, ascend]:
        if n != null:
            n.free()
    currency = null
    canvas = null
    tree = null
    workshop = null
    inventory = null
    painter_office = null
    ascend = null

func test_initial_ascend_count_zero():
    assert_eq(ascend.ascend_count, 0)

func test_can_ascend_false_below_palier():
    currency.add("inspiration", BigNumber.from_float(500.0))
    assert_false(ascend.can_ascend())

func test_can_ascend_true_at_palier():
    var palier = Balance.palier_ascend(0)
    currency.add("inspiration", palier)
    assert_true(ascend.can_ascend())

func test_perform_below_palier_is_noop():
    var count_before = ascend.ascend_count
    var ok = ascend.perform()
    assert_false(ok)
    assert_eq(ascend.ascend_count, count_before)

func test_perform_increments_ascend_count():
    currency.add("inspiration", Balance.palier_ascend(0))
    ascend.perform()
    assert_eq(ascend.ascend_count, 1)

func test_perform_converts_inspi_to_fame():
    currency.add("inspiration", BigNumber.from_float(5000.0))
    var expected = Balance.fame_conversion(BigNumber.from_float(5000.0)).value
    ascend.perform()
    assert_almost_eq(currency.get_amount("fame").value, expected, 0.0001)

func test_perform_resets_inspiration_gold():
    currency.add("inspiration", Balance.palier_ascend(0))
    currency.add("gold", BigNumber.from_float(10000.0))
    ascend.perform()
    assert_eq(currency.get_amount("inspiration").value, 0.0)
    assert_eq(currency.get_amount("gold").value, 0.0)

func test_perform_preserves_fame_and_paint_mastery():
    currency.add("inspiration", Balance.palier_ascend(0))
    currency.add("fame", BigNumber.from_float(3.0))
    currency.add("paint_mastery", BigNumber.from_float(50.0))
    ascend.perform()
    assert_gt(currency.get_amount("fame").value, 3.0)
    assert_eq(currency.get_amount("paint_mastery").value, 50.0)

func test_perform_resets_subsystems():
    pending("Canvas tier moved to GameState in Canvas plan; rewritten in Task 14")

func test_perform_palier_grows_with_count():
    var palier0 = Balance.palier_ascend(0)
    currency.add("inspiration", palier0)
    ascend.perform()
    assert_eq(ascend.ascend_count, 1)
    currency.add("inspiration", palier0)
    assert_false(ascend.can_ascend())
    currency.add("inspiration", palier0)
    assert_true(ascend.can_ascend())

func test_serialize_roundtrip():
    ascend.ascend_count = 3
    var data = ascend.serialize()
    var fresh = Ascend.new()
    fresh.deserialize(data)
    assert_eq(fresh.ascend_count, 3)
    fresh.free()
