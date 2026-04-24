class_name CurrencyDisplay
extends Control

@export var currency_kind: String = "gold"
@export var value_label_path: NodePath

var _value_label: Label

func _ready() -> void:
    if value_label_path.is_empty():
        _value_label = _find_first_label(self)
    else:
        _value_label = get_node(value_label_path) as Label
    GameState.currency.changed.connect(_on_currency_changed)
    _refresh()

func _find_first_label(node: Node) -> Label:
    for child in node.get_children():
        if child is Label:
            return child
        var found = _find_first_label(child)
        if found:
            return found
    return null

func _on_currency_changed(kind: String, _new_value: float) -> void:
    if kind == currency_kind:
        _refresh()

func _refresh() -> void:
    if _value_label == null:
        return
    _value_label.text = Formatter.short(GameState.currency.get_amount(currency_kind))
