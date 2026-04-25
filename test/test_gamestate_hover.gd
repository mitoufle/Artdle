extends GutTest

func test_push_hover_info_emits_with_args():
    watch_signals(GameState)
    GameState.push_hover_info("Title", "Body text", "Footer line")
    assert_signal_emitted_with_parameters(
        GameState, "hover_info_pushed", ["Title", "Body text", "Footer line"]
    )

func test_clear_hover_info_emits():
    watch_signals(GameState)
    GameState.clear_hover_info()
    assert_signal_emitted(GameState, "hover_info_cleared")
