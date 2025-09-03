extends PopupPanel

#==============================================================================
# Exports
#==============================================================================
@export var coin_icon: Texture2D

#==============================================================================
# Scene References
#==============================================================================
@onready var click_power_label: Label = $VBoxContainer/ClickPowerLabel
@onready var autoclick_speed_label: Label = $VBoxContainer/AutoclickSpeedLabel
@onready var click_button: Button = $VBoxContainer/ClickButton
@onready var upgrade_click_power_button: Button = $VBoxContainer/UpgradeClickPowerButton
@onready var upgrade_autoclick_speed_button: Button = $VBoxContainer/UpgradeAutoclickSpeedButton

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready():
	# Connect to GameState signals
	GameState.click_stats_changed.connect(_on_click_stats_changed)
	
	# Connect UI signals
	click_button.pressed.connect(_on_click_button_pressed)
	upgrade_click_power_button.pressed.connect(GameState.upgrade_click_power)
	upgrade_autoclick_speed_button.pressed.connect(GameState.upgrade_autoclick_speed)
	
	# Initial UI state
	_on_click_stats_changed({"click_power": GameState.click_power, "autoclick_speed": GameState.autoclick_speed})

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_click_stats_changed(new_stats: Dictionary):
	click_power_label.text = "Click Power: %d" % new_stats["click_power"]
	autoclick_speed_label.text = "Autoclick Speed: %.1f" % new_stats["autoclick_speed"]

func _on_click_button_pressed():
	GameState.manual_click()
	var main_node = get_tree().get_root().get_node("Main")
	if main_node:
		main_node.add_ressource_feedback(GameState.click_power, coin_icon)
