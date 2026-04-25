extends GutTest

func test_has_known_id():
    assert_true(Icons.has("gold"))
    assert_true(Icons.has("fame"))
    assert_true(Icons.has("inspiration"))
    assert_true(Icons.has("paint_mastery"))

func test_has_unknown_id():
    assert_false(Icons.has("nonexistent"))

func test_bbcode_known_id_default_height():
    var s: String = Icons.bbcode("gold")
    assert_eq(s, "[img height=16]res://artdleAsset/Currency/coin.png[/img]")

func test_bbcode_known_id_custom_height():
    var s: String = Icons.bbcode("inspiration", 32)
    assert_eq(s, "[img height=32]res://artdleAsset/Inspiration.png[/img]")

func test_bbcode_unknown_returns_empty():
    var s: String = Icons.bbcode("nope")
    assert_eq(s, "")
