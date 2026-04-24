extends PopupPanel

@onready var tier_label: Label = $MarginContainer/VBoxContainer/TierLabel
@onready var upgrade_btn: Button = $MarginContainer/VBoxContainer/UpgradeButton
@onready var close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    upgrade_btn.pressed.connect(_on_upgrade)
    close_btn.pressed.connect(queue_free)
    GameState.currency.changed.connect(_on_currency_changed)
    _refresh()

func _on_upgrade() -> void:
    var cost: BigNumber = CanvasTiers.upgrade_cost(GameState.canvas.tier)
    if GameState.currency.spend("gold", cost):
        GameState.canvas.upgrade_tier()
    _refresh()

func _on_currency_changed(_k: String, _v: float) -> void:
    _refresh()

func _refresh() -> void:
    var t: int = GameState.canvas.tier
    var cost: BigNumber = CanvasTiers.upgrade_cost(t)
    tier_label.text = "Tier actuel : %d" % t
    upgrade_btn.text = "Upgrade → Tier %d (%s gold)" % [t + 1, Formatter.short(cost)]
    upgrade_btn.disabled = t >= CanvasTiers.MAX_TIER or not GameState.currency.get_amount("gold").gte(cost)
