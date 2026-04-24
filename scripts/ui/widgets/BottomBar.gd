class_name BottomBar
extends HBoxContainer

# Passive container — each CurrencyDisplay child self-subscribes to Currency.changed.
# Provides helpers for per-view visibility toggling.

func set_currency_visible(kind: String, visible_flag: bool) -> void:
    for child in get_children():
        if child is CurrencyDisplay and child.currency_kind == kind:
            child.visible = visible_flag
