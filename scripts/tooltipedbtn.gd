extends Button
class_name Tooltipedbtn

@export var tooltip_scene_path: PackedScene
@export_multiline var custom_tooltip_text: String

var tooltip_instance: Control

func _on_mouse_entered():
 # Si un chemin de scène d'infobulle est défini
 if tooltip_scene_path != null:
  # Instancier la scène d'infobulle
  tooltip_instance = tooltip_scene_path.instantiate()
  
  # Assurez-vous que l'instance est un Control Node.
  if tooltip_instance is CustomTooltips:
   var custom_tooltip = tooltip_instance as CustomTooltips
   custom_tooltip.set_text(custom_tooltip_text)
  
  # Ajouter l'infobulle à l'arbre de la scène (à la racine)
  # pour qu'elle s'affiche au-dessus de tous les éléments de l'interface utilisateur.
  get_tree().get_root().add_child(tooltip_instance)

func _on_mouse_exited():
 # Si l'infobulle est affichée, la supprimer
 if tooltip_instance != null:
  tooltip_instance.queue_free()

func _process(delta):
 # Mettre à jour la position de l'infobulle pour qu'elle suive le curseur
 if tooltip_instance != null:
  if tooltip_instance is CustomTooltips:
   var custom_tooltip = tooltip_instance as CustomTooltips
   custom_tooltip.update_position(get_global_mouse_position())
