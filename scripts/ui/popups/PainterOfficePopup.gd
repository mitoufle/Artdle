extends PopupPanel

@onready var worker_label: Label = $MarginContainer/VBoxContainer/WorkerLabel
@onready var hire_btn: Button = $MarginContainer/VBoxContainer/HireButton
@onready var close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    close_btn.pressed.connect(queue_free)
    hire_btn.pressed.connect(func(): GameState.painter_office.hire_worker(); _refresh())
    GameState.currency.changed.connect(func(_k, _v): _refresh())
    GameState.painter_office.worker_hired.connect(func(_c): _refresh())
    _refresh()

func _refresh() -> void:
    var count: int = GameState.painter_office.worker_count
    worker_label.text = "Ouvriers : %d  (+%d%% vitesse)" % [count, int(PainterOffice.SPEED_PER_WORKER * 100.0 * count)]
    var cost: BigNumber = PainterOffice.hire_cost(count)
    hire_btn.text = "Embaucher (%s gold)" % Formatter.short(cost)
    hire_btn.disabled = not GameState.currency.get_amount("gold").gte(cost)
