extends PanelContainer
class_name CustomTooltips

@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var vbox_container: VBoxContainer  = $VBoxContainer



var max_width = 300
var _pending_text: String = ""


func _ready():
	# Ensure the RichTextLabel exists.
	if not rich_text_label:
		print("Error: RichTextLabel not assigned in the Inspector.")
		return
		
	if _pending_text != "":
		set_text(_pending_text)
		_pending_text = ""	
	
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
func set_text(new_text: String):
	if rich_text_label:
		rich_text_label.add_text(new_text)   # ou .text / set_text selon ton usage
	else:
		_pending_text = new_text
		

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
