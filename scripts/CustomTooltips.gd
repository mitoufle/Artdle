extends PanelContainer
class_name CustomTooltips

@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var vbox_container: VBoxContainer  = $VBoxContainer

@export var style: String

var max_width = 300
var time := 0.0
var base_text := ""

func _ready():
	# Ensure the RichTextLabel exists.
	if not rich_text_label:
		print("Error: RichTextLabel not assigned in the Inspector.")
		return	
	
	self.add_theme_color_override("panel", Color(0.1, 0.1, 0.25, 0.9)) # fond bleu foncé semi-transparent
	self.add_theme_constant_override("corner_radius", 15)
	
	rich_text_label.fit_content = true
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # ou AUTOWRAP_ARBITRARY
	rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_text_label.custom_minimum_size.x = max_width
	rich_text_label.bbcode_enabled = true
 
 # Configuration de base pour le label.
	rich_text_label.fit_content = true
	rich_text_label.mouse_filter = MOUSE_FILTER_IGNORE


## Définit le texte de l'infobulle.
func set_style(new_style: String):
	style = new_style

## Définit le texte de l'infobulle.
func set_text(new_text: String):
		base_text = new_text
		match style:
			"wave":
				rich_text_label.bbcode_text = "[wave]" + base_text + "[/wave]"
			"shake":
				rich_text_label.bbcode_text = "[shake]" + base_text + "[/shake]"
			"rainbow":
				rich_text_label.bbcode_text = "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]" + base_text + "[/rainbow]"
			"wave+rainbow":
				rich_text_label.bbcode_text = "[wave][rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]" + base_text + "[/rainbow][/wave]"
			"bold":
				rich_text_label.bbcode_text = "[b]" + base_text + "[/b]"
			"italic":
				rich_text_label.bbcode_text = "[i]" + base_text + "[/i]"
			"underline":
				rich_text_label.bbcode_text = "[u]" + base_text + "[/u]"
			"strikethrough":
				rich_text_label.bbcode_text = "[s]" + base_text + "[/s]"
			"outline":
				rich_text_label.bbcode_text = "[outline]" + base_text + "[/outline]"
			"shadow":
				rich_text_label.bbcode_text = "[shadow]" + base_text + "[/shadow]"
			"scale":
				rich_text_label.bbcode_text = "[scale=1.5]" + base_text + "[/scale]"
			"smallcaps":
				rich_text_label.bbcode_text = "[smallcaps]" + base_text + "[/smallcaps]"
			_:
				# fallback : texte simple
				rich_text_label.bbcode_text = base_text

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
