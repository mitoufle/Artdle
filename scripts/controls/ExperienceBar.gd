extends Control

@onready var progress_bar = $ProgressBar
@onready var level_label = $LevelLabel

func _ready():
	GameState.experience_changed.connect(_on_experience_changed)
	GameState.level_changed.connect(_on_level_changed)
	
	# Initial setup
	_on_experience_changed(GameState.experience, GameState.experience_to_next_level)
	_on_level_changed(GameState.level)

func _on_experience_changed(new_experience: float, experience_to_next_level: float):
	progress_bar.max_value = experience_to_next_level
	progress_bar.value = new_experience
	progress_bar.tooltip_text = "%d/%d" % [new_experience, experience_to_next_level]

func _on_level_changed(new_level: int):
	level_label.text = "Level: %d" % new_level
