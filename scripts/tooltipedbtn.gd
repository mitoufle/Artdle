@tool
extends TextureButton
class_name Tooltipedbtn

# --- EXPORT VARIABLES ---
@export var custom_texture: Texture2D:
	set = _set_texture

@export var button_text: String = "Button":
	set = _set_button_text

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
