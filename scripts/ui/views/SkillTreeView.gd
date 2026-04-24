extends BaseView

@onready var fame_label: Label = $VBoxContainer/FameLabel
@onready var nodes_list: VBoxContainer = $VBoxContainer/NodesList

func _connect_view_signals() -> void:
    GameState.currency.changed.connect(_on_currency_changed)
    GameState.skill_tree.node_unlocked.connect(_on_node_unlocked)

func _initialize_ui() -> void:
    _rebuild()

func _on_currency_changed(_kind: String, _value: float) -> void:
    _refresh()

func _on_node_unlocked(_id: String) -> void:
    _refresh()

func _rebuild() -> void:
    for child in nodes_list.get_children():
        child.queue_free()
    for node_id in SkillTreeNodes.all_node_ids():
        var btn: Button = Button.new()
        btn.set_meta("node_id", node_id)
        var id_copy: String = node_id
        btn.pressed.connect(func(): GameState.skill_tree.unlock(id_copy))
        nodes_list.add_child(btn)
    _refresh()

func _refresh() -> void:
    fame_label.text = "Fame : %s" % Formatter.short(GameState.currency.get_amount("fame"))
    for btn in nodes_list.get_children():
        var id: String = btn.get_meta("node_id", "")
        var node: Dictionary = SkillTreeNodes.get_node(id)
        var cost: BigNumber = BigNumber.from_float(float(node.get("cost", 0.0)))
        var owned: bool = GameState.skill_tree.unlocked_nodes.has(id)
        var can_afford: bool = GameState.currency.get_amount("fame").gte(cost)
        if owned:
            btn.text = "✓ %s" % node["name"]
            btn.disabled = true
        else:
            btn.text = "%s (%s fame)" % [node["name"], Formatter.short(cost)]
            btn.disabled = not can_afford
