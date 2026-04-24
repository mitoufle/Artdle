extends GutTest

func test_save_and_load_currency_roundtrip():
    GameState.save_system.save_path = "user://test_gamestate.save"
    GameState.currency.add("gold", BigNumber.from_float(500.0))
    GameState.currency.add("fame", BigNumber.from_float(3.0))
    var saved = GameState.save_game()
    assert_true(saved)
    GameState.currency.reset(["gold", "fame"])
    var loaded = GameState.load_game()
    assert_true(loaded)
    assert_eq(GameState.currency.get_amount("gold").value, 500.0)
    assert_eq(GameState.currency.get_amount("fame").value, 3.0)
    if FileAccess.file_exists(GameState.save_system.save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_system.save_path))
