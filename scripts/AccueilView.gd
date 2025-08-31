extends Control

@onready var lbl_prestigeCount: Label = $Layout/LblPrestigeCount
@onready var lbl_prestigeCost: Label = $Layout/LblPrestigeCost
@onready var btn_prestige: Button = $Layout/BtnPrestige

func _ready() -> void:
	btn_prestige.pressed.connect(_on_btn_prestige_pressed)
	
	update_ui()

func _on_btn_prestige_pressed() -> void:
	GameState.reset_prestige()
	update_ui()

func update_ui() -> void:
	lbl_prestigeCount.text = "prestige: " + str(int(GameState.prestige))
	lbl_prestigeCost.text =str(float(GameState.global_inspiration_multiplier)) + " added inspiration gain multilier "
