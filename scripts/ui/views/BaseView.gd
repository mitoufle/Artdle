class_name BaseView
extends Control

# Subclasses override these three hooks in order:
#   1. _initialize_view() — state setup (called once on ready)
#   2. _connect_view_signals() — subscribe to GameState signals
#   3. _initialize_ui() — refresh UI from current state

func _ready() -> void:
    _initialize_view()
    _connect_view_signals()
    _initialize_ui()

func _initialize_view() -> void:
    pass

func _connect_view_signals() -> void:
    pass

func _initialize_ui() -> void:
    pass
