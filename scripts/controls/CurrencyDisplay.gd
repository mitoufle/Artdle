extends HBoxContainer

@export var currency_type: String
@export var icon_texture: Texture2D

@onready var icon_node: TextureRect = $Icon
@onready var amount_label: Label = $Amount

func _ready():
	icon_node.texture = icon_texture
	print("CurrencyDisplay: _ready() called for currency_type: ", currency_type) # DEBUG
	match currency_type:
		"inspiration":
			GameState.inspiration_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.currency_manager.get_currency("inspiration"))
		"gold":
			GameState.gold_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.currency_manager.get_currency("gold"))
		"fame":
			GameState.fame_changed.connect(_on_currency_changed)
			_on_currency_changed(GameState.currency_manager.get_currency("fame"))
		"ascendancy_point":
			# Connection moved to BottomBar.gd
			_on_currency_changed(GameState.currency_manager.get_currency("ascendancy_points")) # Initial update
		# Add other currency types here as needed

func _on_currency_changed(value: float):
	#print("CurrencyDisplay: Received signal for ", currency_type, " with value ", value) # DEBUG
	amount_label.text = str(round(value * 1000) / 1000.0)
