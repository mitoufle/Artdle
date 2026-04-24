class_name Tooltip
extends PanelContainer

@export var label_path: NodePath

var _label: Label

func _ready() -> void:
    _label = get_node(label_path) as Label
    hide()

func show_text(text: String, at_position: Vector2) -> void:
    if _label != null:
        _label.text = text
    position = at_position
    show()

func hide_tooltip() -> void:
    hide()
