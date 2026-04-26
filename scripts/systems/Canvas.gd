class_name Canvas
extends Node

# Per-slot canvas. Holds only progress + the snapshot of paint_time/quality
# that was active at canvas-start. Reconfiguration of sticky config does NOT
# affect a canvas already in flight — it only affects subsequent canvases
# (see spec §3 "sticky configuration + observed loop").

signal finished(payload: Dictionary)
# payload keys: quality (float), tier (int), subject_id (String), gambled (bool),
#               chef_doeuvre (bool). Slot manager fills tier/subject/gambled/chef before emit.

var paint_time: float = 0.0
var quality: float = 0.0
var progress_seconds: float = 0.0
var is_running: bool = false

func start(p_paint_time: float, p_quality: float) -> void:
    paint_time = p_paint_time
    quality = p_quality
    progress_seconds = 0.0
    is_running = true

func tick(delta: float) -> void:
    if not is_running:
        return
    progress_seconds += delta
    if progress_seconds >= paint_time:
        is_running = false
        progress_seconds = 0.0
        finished.emit({"quality": quality})

func reset() -> void:
    paint_time = 0.0
    quality = 0.0
    progress_seconds = 0.0
    is_running = false

func serialize() -> Dictionary:
    return {
        "paint_time": paint_time,
        "quality": quality,
        "progress_seconds": progress_seconds,
        "is_running": is_running,
    }

func deserialize(data: Dictionary) -> void:
    paint_time = float(data.get("paint_time", 0.0))
    quality = float(data.get("quality", 0.0))
    progress_seconds = float(data.get("progress_seconds", 0.0))
    is_running = bool(data.get("is_running", false))
