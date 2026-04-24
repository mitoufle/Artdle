class_name PartUpgradeButton
extends Button

var part_id: String = ""

func setup(p_id: String) -> void:
    part_id = p_id
    pressed.connect(_on_pressed)
    GameState.currency.changed.connect(_on_currency_changed)
    GameState.tree.part_upgraded.connect(_on_part_upgraded)
    _refresh()

func _on_pressed() -> void:
    GameState.tree.upgrade_part(part_id)

func _on_currency_changed(_kind: String, _val: float) -> void:
    _refresh()

func _on_part_upgraded(_id: String, _lvl: int) -> void:
    _refresh()

func _refresh() -> void:
    var lvl: int = GameState.tree.get_part_level(part_id)
    var cost: BigNumber = TreeStages.upgrade_cost(GameState.tree.stage_index, part_id, lvl)
    text = "%s (Lv.%d) — %s gold" % [part_id.capitalize(), lvl, Formatter.short(cost)]
    disabled = not GameState.currency.get_amount("gold").gte(cost)
