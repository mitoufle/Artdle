class_name CanvasSlotCard
extends PanelContainer
@onready var _subject_label: Label = $VBoxContainer/SubjectLabel
@onready var _progress: ProgressBar = $VBoxContainer/Progress
@onready var _quality_label: Label = $VBoxContainer/QualityLabel
var slot_index: int = -1
var canvas: Canvas = null
func bind(idx: int, c: Canvas) -> void:
	slot_index = idx
	canvas = c
func _process(_delta: float) -> void:
	if canvas == null:
		return
	if canvas.paint_time > 0.0:
		_progress.value = canvas.progress_seconds / canvas.paint_time
	else:
		_progress.value = 0.0
	_quality_label.text = "Q: %.1f" % canvas.quality
	var subject_id: String = String(canvas.get_meta("subject_id", "—"))
	var subject_name: String = String(Subjects.get_subject(subject_id).get("name", subject_id))
	_subject_label.text = "%s • Tier %d" % [subject_name, int(canvas.get_meta("tier", 1))]
