class_name TreeVisual
extends Control

# Minimal placeholder: one circle per active part, radius proportional to level.
# Confirms signals wire through; real art comes later.

func _ready() -> void:
    GameState.tree.part_upgraded.connect(_on_any_change)
    GameState.tree.stage_entered.connect(_on_any_change)
    queue_redraw()

func _on_any_change(_a = null, _b = null) -> void:
    queue_redraw()

func _draw() -> void:
    var stage = TreeStages.get_stage(GameState.tree.stage_index)
    if stage.is_empty():
        return
    var center: Vector2 = size / 2.0
    draw_rect(Rect2(center.x - 10.0, center.y, 20.0, 80.0), Color(0.35, 0.22, 0.12))
    var part_ids: Array = stage["parts"].keys()
    for i in range(part_ids.size()):
        var part_id: String = part_ids[i]
        var lvl: int = GameState.tree.get_part_level(part_id)
        var radius: float = 15.0 + 8.0 * float(lvl)
        var angle: float = TAU * float(i) / float(part_ids.size())
        var pos: Vector2 = center + Vector2(cos(angle), sin(angle) - 1.0) * 60.0
        draw_circle(pos, radius, Color(0.23, 0.48, 0.23))
