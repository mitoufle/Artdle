extends Node

# Signal hub. Systems emit here; UI and other systems listen here.
# Currency + Save are held as children so they participate in the scene tree.

signal canvas_sold(tier: int, gold_amount: float)
signal ascended(fame_gained: float, ascend_count: int)
signal stage_entered(stage_index: int)
signal possibility_unlocked(mechanic_id: String)
signal sub_mechanic_activated(mechanic_id: String)

var currency: Currency
var save_system: Save

func _ready() -> void:
    currency = Currency.new()
    currency.name = "Currency"
    add_child(currency)
    save_system = Save.new()
    save_system.name = "Save"
    add_child(save_system)

func save_game() -> bool:
    var payload: Dictionary = {
        "currency": currency.serialize(),
    }
    return save_system.write(payload)

func load_game() -> bool:
    var data = save_system.read()
    if data == null:
        return false
    if data.has("currency"):
        currency.deserialize(data["currency"])
    return true
