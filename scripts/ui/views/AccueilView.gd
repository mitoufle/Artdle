extends BaseView

const PartUpgradeButtonScript = preload("res://scripts/ui/widgets/PartUpgradeButton.gd")

@onready var stage_label: Label = $HBoxContainer/LeftPane/StageLabel
@onready var parts_container: VBoxContainer = $HBoxContainer/RightPane/PartsContainer
@onready var possibilities_container: VBoxContainer = $HBoxContainer/RightPane/PossibilitiesContainer

func _connect_view_signals() -> void:
    GameState.tree.stage_entered.connect(_on_stage_entered)
    GameState.possibility_unlocked.connect(_on_possibility_unlocked)
    GameState.sub_mechanic_activated.connect(_on_sub_mechanic_activated)

func _initialize_ui() -> void:
    _refresh_stage()
    _rebuild_part_buttons()
    _rebuild_possibilities()

func _on_stage_entered(_idx: int) -> void:
    _refresh_stage()
    _rebuild_part_buttons()

func _on_possibility_unlocked(_id: String) -> void:
    _rebuild_possibilities()

func _on_sub_mechanic_activated(_id: String) -> void:
    _rebuild_possibilities()

func _refresh_stage() -> void:
    var s: Dictionary = TreeStages.get_stage(GameState.tree.stage_index)
    if s.is_empty():
        stage_label.text = "—"
    else:
        stage_label.text = "Stade : %s" % s["name"]

func _rebuild_part_buttons() -> void:
    for child in parts_container.get_children():
        child.queue_free()
    var s: Dictionary = TreeStages.get_stage(GameState.tree.stage_index)
    if s.is_empty():
        return
    for part_id in s["parts"].keys():
        var btn: PartUpgradeButton = PartUpgradeButtonScript.new()
        parts_container.add_child(btn)
        btn.setup(part_id)

func _rebuild_possibilities() -> void:
    for child in possibilities_container.get_children():
        child.queue_free()
    for mech_id in ["workshop", "inventory", "painter_office"]:
        if GameState.is_possible(mech_id) and not GameState.is_active(mech_id):
            var btn: Button = Button.new()
            var cost: BigNumber = TreeStages.unlock_cost(mech_id)
            btn.text = "Débloquer %s (%s inspi)" % [mech_id, Formatter.short(cost)]
            var id_copy: String = mech_id
            btn.pressed.connect(func(): GameState.try_activate_mechanic(id_copy))
            possibilities_container.add_child(btn)
