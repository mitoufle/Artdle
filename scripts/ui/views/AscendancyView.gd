extends BaseView

const HoverableScript = preload("res://scripts/ui/widgets/Hoverable.gd")

@onready var palier_label: Label = $VBoxContainer/PalierLabel
@onready var preview_label: Label = $VBoxContainer/FamePreviewLabel
@onready var ascend_btn: Button = $VBoxContainer/AscendButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

func _initialize_view() -> void:
    var hov = HoverableScript.new()
    hov.content_provider = func() -> Array:
        var palier: BigNumber  = Balance.palier_ascend(GameState.ascend.ascend_count)
        var current: BigNumber = GameState.currency.get_amount("inspiration")
        var preview: BigNumber = Balance.fame_conversion(current)
        return [
            "Ascendance",
            "Réinitialise le run et donne de la fame permanente. Gagne actuellement %s %s." % [
                Formatter.short(preview), Icons.bbcode("fame")
            ],
            "Palier : %s / %s %s" % [
                Formatter.short(current), Formatter.short(palier), Icons.bbcode("inspiration")
            ]
        ]
    ascend_btn.add_child(hov)

func _connect_view_signals() -> void:
    ascend_btn.pressed.connect(_on_ascend_pressed)
    GameState.currency.changed.connect(_on_currency_changed)
    GameState.ascended.connect(_on_ascended)

func _initialize_ui() -> void:
    status_label.text = ""
    _refresh()

func _on_currency_changed(_kind: String, _value: float) -> void:
    _refresh()

func _on_ascended(fame_gained: float, count: int) -> void:
    status_label.text = "Ascend #%d : +%s fame" % [count, Formatter.short(BigNumber.from_float(fame_gained))]
    _refresh()

func _on_ascend_pressed() -> void:
    GameState.ascend.perform()

func _refresh() -> void:
    var count: int = GameState.ascend.ascend_count
    var palier: BigNumber = Balance.palier_ascend(count)
    var current_inspi: BigNumber = GameState.currency.get_amount("inspiration")
    palier_label.text = "Palier : %s / %s inspi" % [Formatter.short(current_inspi), Formatter.short(palier)]
    var preview_fame: BigNumber = Balance.fame_conversion(current_inspi)
    preview_label.text = "Fame projetée : +%s" % Formatter.short(preview_fame)
    ascend_btn.disabled = not GameState.ascend.can_ascend()
