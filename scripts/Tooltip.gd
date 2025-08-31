extends Control

@onready var lbl_line1: Label = $VBoxContainer/Line1
@onready var lbl_line2: Label = $VBoxContainer/Line2
@onready var lbl_container: VBoxContainer = $VBoxContainer



@export var offset: Vector2 = Vector2(-30, -40)
@export var fade_duration: float = 0.3

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_tooltip(line1: String, line2: String, position: Vector2):
	
	lbl_line1.text = line1
	lbl_line2.text = line2
	lbl_container.position = position + offset
	modulate.a = 0
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
func hide_tooltip():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(self.queue_free)
	
