extends GutTest

const HoverableScript = preload("res://scripts/ui/widgets/Hoverable.gd")

var parent_ctrl: Control
var hov

func before_each():
    parent_ctrl = Control.new()
    add_child_autofree(parent_ctrl)
    hov = HoverableScript.new()
    hov.title = "T"
    hov.body = "B"
    hov.footer = "F"
    parent_ctrl.add_child(hov)

func test_static_strings_pushed_on_mouse_entered():
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["T", "B", "F"]
    )

func test_clear_emitted_on_mouse_exited():
    watch_signals(GameState)
    parent_ctrl.mouse_exited.emit()
    assert_signal_emitted(GameState, "hover_info_cleared")

func test_content_provider_overrides_static():
    hov.content_provider = func() -> Array: return ["DT", "DB", "DF"]
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["DT", "DB", "DF"]
    )

func test_provider_short_array_falls_back_to_empty():
    hov.content_provider = func() -> Array: return ["only-title"]
    watch_signals(GameState)
    parent_ctrl.mouse_entered.emit()
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["only-title", "", ""]
    )
