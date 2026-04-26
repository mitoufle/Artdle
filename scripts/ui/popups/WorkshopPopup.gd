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
    GameState.workshop.upgrade_tier()
    _refresh()

func _on_currency_changed(_kind: String, _value: float) -> void:
    _refresh()

func _refresh() -> void:
    var t: int = GameState.workshop.tier
    var at_cap: bool = t >= Workshop.MAX_TIER
    tier_label.text = "Workshop Tier: %d / %d" % [t, Workshop.MAX_TIER]
    if at_cap:
        upgrade_btn.text = "Max tier reached"
        upgrade_btn.disabled = true
    else:
        var cost: BigNumber = Workshop.tier_upgrade_cost(t)
        upgrade_btn.text = "Upgrade to Tier %d (%s gold)" % [t + 1, Formatter.short(cost)]
        upgrade_btn.disabled = not GameState.currency.get_amount("gold").gte(cost)
