@tool
extends TextureButton
class_name Tooltipedbtn

# --- EXPORT VARIABLES ---
@export_category("Main")
@export var custom_texture: Texture2D:
	set = _set_texture
@export var button_text: String = "Button":
	set = _set_button_text

@export_category("font")
@export var font: Font:
	set = _set_font
@export var font_size: int:
	set = _set_font_size
@export var font_color: Color = Color.WHITE:
	set = _set_font_color

@export_category("layout")
@export var h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set = _set_h_align
@export var v_align: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set = _set_v_align
@export var autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF:
	set = _set_autowrap_mode

@export_category("tootltip")
@export var tooltip_scene_path: PackedScene
@export_multiline var custom_tooltip_text: String
@export var tooltype_style: String

# --- PRIVATE VARIABLES ---
var tooltip_instance: Control
@onready var label: Label = $Label

# --- GODOT METHODS ---
func _ready() -> void:
	# Ensure label text is set on load
	if label:
		label.text = button_text
	_set_font_properties()
	_set_alignment_properties()
	_set_autowrap_mode(autowrap_mode)

func _process(_delta:float):
	# Mettre à jour la position de l'infobulle pour qu'elle suive le curseur
	if tooltip_instance != null:
		if tooltip_instance is CustomTooltips:
			var custom_tooltip = tooltip_instance as CustomTooltips
			custom_tooltip.update_position(get_global_mouse_position())

# --- SETTERS ---
func _set_button_text(new_text: String) -> void:
	button_text = new_text
	if label:
		label.text = new_text

func _set_texture(new_texture: Texture2D) -> void:
	custom_texture = new_texture
	if custom_texture:
		self.texture_normal = new_texture
		if Engine.is_editor_hint():
			var image: Image = custom_texture.get_image()
			if image:
				var bitmap = BitMap.new()
				bitmap.create_from_image_alpha(image)
				self.texture_click_mask = bitmap

func _set_font(new_font: Font) -> void:
	font = new_font
	_set_font_properties()

func _set_font_size(new_font_size: int) -> void:
	font_size = new_font_size
	_set_font_properties()

func _set_font_color(new_color: Color) -> void:
	font_color = new_color
	_set_font_properties()

func _set_font_properties() -> void:
	if label:
		if font:
			label.add_theme_font_override("font", font)
		if font_size > 0:
			label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", font_color)

func _set_h_align(new_align: HorizontalAlignment) -> void:
	h_align = new_align
	_set_alignment_properties()

func _set_v_align(new_align: VerticalAlignment) -> void:
	v_align = new_align
	_set_alignment_properties()

func _set_alignment_properties() -> void:
	if label:
		label.horizontal_alignment = h_align
		label.vertical_alignment = v_align

func _set_autowrap_mode(new_mode: TextServer.AutowrapMode) -> void:
	autowrap_mode = new_mode
	if label:
		label.autowrap_mode = autowrap_mode

# --- SIGNAL CONNECTIONS ---
func _on_mouse_entered():
	# Si un chemin de scène d'infobulle est défini
	if tooltip_scene_path != null:
		# Instancier la scène d'infobulle
		tooltip_instance = tooltip_scene_path.instantiate()
		
		# Assurez-vous que l'instance est un Control Node.
		if tooltip_instance is CustomTooltips:
			var custom_tooltip = tooltip_instance as CustomTooltips
			custom_tooltip.call_deferred("set_style", tooltype_style)
			custom_tooltip.call_deferred("set_text", custom_tooltip_text)
		
		# Ajouter l'infobulle à l'arbre de la scène (à la racine)
		# pour qu'elle s'affiche au-dessus de tous les éléments de l'interface utilisateur.
		get_tree().get_root().get_node("Main").get_node("MainLayout").add_child(tooltip_instance)

func _on_mouse_exited():
	# Si l'infobulle est affichée, la supprimer
	if tooltip_instance != null:
		tooltip_instance.queue_free()
