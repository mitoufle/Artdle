extends PanelContainer
class_name CustomTooltips

@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var vbox_container: VBoxContainer  = $VBoxContainer

@export var text_style: String

var box_radius = 5
var vertical_margin = 5
var max_width = 300
var time := 0.0
var base_text := ""
var default_color = "#2B2D69"

func _ready():
	# Ensure the RichTextLabel exists.
	if not rich_text_label:
		print("Error: RichTextLabel not assigned in the Inspector.")
		return	
	
	# Créer un StyleBoxFlat
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BURLYWOOD
	style.border_color = Color.BLUE_VIOLET
	style.set_border_width_all(5)
	style.border_blend = 5
	style.expand_margin_bottom = vertical_margin
	style.expand_margin_top = vertical_margin
	style.corner_radius_top_left = box_radius
	style.corner_radius_top_right = box_radius
	style.corner_radius_bottom_left = box_radius
	style.corner_radius_bottom_right = box_radius
	self.add_theme_stylebox_override("panel", style) # "panel" ici peut être n'importe quelle clé si tu l'utilises via theme
	
	rich_text_label.fit_content = true
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # ou AUTOWRAP_ARBITRARY
	rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_text_label.custom_minimum_size.x = max_width-50
	rich_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rich_text_label.bbcode_enabled = true
 
 # Configuration de base pour le label.
	rich_text_label.fit_content = true
	rich_text_label.mouse_filter = MOUSE_FILTER_IGNORE

## Définit le texte de l'infobulle.
func set_style(new_style: String):
	text_style = new_style

## Définit le texte de l'infobulle.
func set_text(new_text: String):
		base_text = new_text
		var temp
		match text_style:
			"wave":
				temp = "[wave]" + base_text + "[/wave]"
			"wave+bold":
				temp = "[b][wave]" + base_text + "[/wave][/b]"
			"shake":
				temp = "[shake]" + base_text + "[/shake]"
			"rainbow+shake":
				temp = "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0][shake]" + base_text + "[/shake][/rainbow]"
			"rainbow":
				temp = "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]" + base_text + "[/rainbow]"
			"wave+rainbow":
				temp = "[wave][rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]" + base_text + "[/rainbow][/wave]"
			"bold":
				temp = "[b]" + base_text + "[/b]"
			"italic":
				temp = "[i]" + base_text + "[/i]"
			"underline":
				temp = "[u]" + base_text + "[/u]"
			"strikethrough":
				temp = "[s]" + base_text + "[/s]"
			"fade":
				temp = "[fade]" + base_text + "[/fade]"
			"tornado":
				temp = "[tornado]" + base_text + "[/tornado]"
			"pulse":
				temp = "[pulse]" + base_text + "[/pulse]"
			_:
				# fallback : texte simple
				temp = base_text
		size = get_combined_minimum_size()
		rich_text_label.bbcode_text = "[color="+default_color+"]" + temp + "[/color]"
		

## Met à jour la position de l'infobulle pour qu'elle suive le curseur et reste dans l'écran.
func update_position(cursor_pos: Vector2):
	var viewport_size = get_viewport_rect().size
	var tooltip_size = get_combined_minimum_size()
 
 # Calcule la nouvelle position.
	var new_pos = cursor_pos + Vector2(10, 10) # Décalage pour ne pas recouvrir le curseur.
 
 # Ajuste la position si l'infobulle dépasse le bord droit.
	if new_pos.x + tooltip_size.x > viewport_size.x:
		new_pos.x = cursor_pos.x - tooltip_size.x - 10
 
 # Ajuste la position si l'infobulle dépasse le bord inférieur.
	if new_pos.y + tooltip_size.y > viewport_size.y:
		new_pos.y = cursor_pos.y - tooltip_size.y - 10
 
	position = new_pos

## Appeler set_anchors_and_offsets_preset une fois que le nœud est dans l'arbre.
func _notification(what):
	if what == NOTIFICATION_READY:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
