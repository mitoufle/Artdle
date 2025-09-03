extends HBoxContainer

@export var currency_type: String
@export var icon_texture: Texture2D

@onready var icon_node: TextureRect = $Icon
@onready var amount_label: Label = $Amount

func _ready():
	icon_node.texture = icon_texture
	
	match currency_type:
		"inspiration":
			GameState.inspiration_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.inspiration)
		"gold":
			GameState.gold_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.gold)
		"fame":
			GameState.fame_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.fame)
		# Add other currency types here as needed

func _on_currency_changed(value: float, type: String = ""):
	amount_label.text = str(round(value * 1000) / 1000.0)
