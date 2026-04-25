extends GutTest

const InfoPanelScene = preload("res://Scenes/InfoPanel.tscn")
var panel

func before_each():
    panel = InfoPanelScene.instantiate()
    add_child_autofree(panel)

func test_initial_state_blank():
    assert_eq(panel.title_label.text, "")
    assert_eq(panel.body_label.text, "")
    assert_eq(panel.footer_label.text, "")

func test_set_content_writes_three_labels():
    panel.set_content("Hello", "World", "Footer")
    assert_eq(panel.title_label.text, "Hello")
    assert_eq(panel.body_label.text, "World")
    assert_eq(panel.footer_label.text, "Footer")

func test_clear_blanks_all_three():
    panel.set_content("a", "b", "c")
    panel.clear()
    assert_eq(panel.title_label.text, "")
    assert_eq(panel.body_label.text, "")
    assert_eq(panel.footer_label.text, "")

func test_responds_to_gamestate_push_signal():
    GameState.push_hover_info("X", "Y", "Z")
    await get_tree().process_frame
    assert_eq(panel.title_label.text, "X")
    assert_eq(panel.body_label.text, "Y")
    assert_eq(panel.footer_label.text, "Z")

func test_responds_to_gamestate_clear_signal():
    panel.set_content("a", "b", "c")
    GameState.clear_hover_info()
    await get_tree().process_frame
    assert_eq(panel.title_label.text, "")
