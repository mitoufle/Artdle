extends PopupPanel

@onready var recipe_list: VBoxContainer = $MarginContainer/VBoxContainer/RecipeList
@onready var close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
    close_btn.pressed.connect(queue_free)
    GameState.currency.changed.connect(_on_currency_changed)
    _rebuild()

func _on_currency_changed(_k: String, _v: float) -> void:
    _refresh_button_states()

func _rebuild() -> void:
    for child in recipe_list.get_children():
        child.queue_free()
    for recipe_id in CraftRecipes.all_recipes():
        var r: Dictionary = CraftRecipes.get_recipe(recipe_id)
        var btn: Button = Button.new()
        btn.text = "%s — %s gold" % [r["name"], Formatter.short(BigNumber.from_float(float(r["gold_cost"])))]
        var id_copy: String = recipe_id
        btn.pressed.connect(func(): GameState.craft.craft(id_copy))
        btn.set_meta("recipe_id", recipe_id)
        recipe_list.add_child(btn)
    _refresh_button_states()

func _refresh_button_states() -> void:
    for btn in recipe_list.get_children():
        var id: String = btn.get_meta("recipe_id", "")
        var r: Dictionary = CraftRecipes.get_recipe(id)
        var cost: BigNumber = BigNumber.from_float(float(r.get("gold_cost", 0.0)))
        btn.disabled = not GameState.currency.get_amount("gold").gte(cost)
