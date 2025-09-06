extends Control
class_name BaseView

## Classe de base pour toutes les vues du jeu
## Fournit des fonctionnalités communes et standardise l'architecture

#==============================================================================
# Signals
#==============================================================================
signal view_initialized()
signal view_ready()

#==============================================================================
# Virtual Methods (à surcharger dans les classes filles)
#==============================================================================

## Appelée lors de l'initialisation de la vue
## À surcharger dans les classes filles
func _initialize_view() -> void:
	pass

## Appelée pour connecter les signaux
## À surcharger dans les classes filles
func _connect_view_signals() -> void:
	pass

## Appelée pour initialiser l'UI
## À surcharger dans les classes filles
func _initialize_ui() -> void:
	pass

## Appelée lors de la destruction de la vue
## À surcharger dans les classes filles
func _cleanup_view() -> void:
	pass

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_initialize_view()
	_connect_view_signals()
	_initialize_ui()
	view_initialized.emit()
	view_ready.emit()
	GameState.logger.info("%s initialized" % get_class(), get_class())

func _exit_tree() -> void:
	_cleanup_view()
	GameState.logger.debug("%s cleaned up" % get_class(), get_class())

#==============================================================================
# Utility Methods
#==============================================================================

## Centre une caméra 2D dans la vue
func center_camera2d(camera: Camera2D) -> void:
	if camera:
		camera.position = get_size() / 2
		GameState.logger.debug("Camera centered at position: %s" % str(camera.position), get_class())

## Trouve et centre une caméra 2D dans un nœud enfant
func center_camera_in_child(child_node: Node) -> void:
	var camera = child_node.find_child("Camera2D")
	center_camera2d(camera)

## Affiche un message de feedback
func show_feedback(amount: int, icon: Texture2D, hframes: int, vframes: int, animation_name: String, color: Color = Color(1,1,0)) -> void:
	const FLOATING_TEXT_SCENE = preload("res://Scenes/floating_text.tscn")
	var ft = FLOATING_TEXT_SCENE.instantiate()
	add_child(ft)
	ft.start("+%d" % amount, icon, hframes, vframes, animation_name, color)

## Valide qu'un nœud existe avant de l'utiliser
func validate_node(node: Node, node_name: String) -> bool:
	if not node:
		GameState.logger.error("Node '%s' not found!" % node_name, get_class())
		return false
	return true

## Connecte un signal avec validation
func connect_signal_safe(signal_obj: Object, signal_name: String, callable: Callable) -> bool:
	if not signal_obj:
		GameState.logger.error("Cannot connect signal '%s' - object is null" % signal_name, get_class())
		return false
	
	if not signal_obj.has_signal(signal_name):
		GameState.logger.error("Signal '%s' does not exist on object" % signal_name, get_class())
		return false
	
	signal_obj.connect(signal_name, callable)
	GameState.logger.debug("Signal '%s' connected successfully" % signal_name, get_class())
	return true

## Met à jour l'UI (à surcharger si nécessaire)
func update_ui() -> void:
	pass

## Récupère le nom de la classe pour le logging
func get_class_name() -> String:
	return "BaseView"
