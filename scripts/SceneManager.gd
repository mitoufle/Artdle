extends Node

## Manages scene transitions to maintain a persistent UI.
## This script should be added as a singleton (autoload) in Project Settings.

# A reference to the container node in the main scene.
# This variable is set by the main scene's script at runtime.
var scene_container: Node = null

# A reference to the currently active game scene.
var current_scene: Node = null

## Called by the main scene to provide a reference to its scene container.
func set_scene_container(container: Node) -> void:
 scene_container = container
 if not is_instance_valid(scene_container):
  push_error("Scene container reference is invalid.")
 else:
  print("SceneManager: Scene container successfully set!")

## Loads a new scene and replaces the current one.
## The UI remains unaffected.
func load_game_scene(path: String) -> void:
 # Ensure the scene container is valid before proceeding.
 if not is_instance_valid(scene_container):
  push_error("Scene container is not a valid instance. Please ensure it's set correctly.")
  return
  
 # Load the new scene from its file path.
 var new_scene_resource: PackedScene = load(path)
 
 if new_scene_resource == null:
  push_error("Failed to load scene at path: ", path)
  return
 
 # Instance the new scene.
 var new_scene_instance: Node = new_scene_resource.instantiate()
 
 # If there is a scene currently loaded, queue it for deletion.
 if current_scene != null:
  # Use call_deferred to avoid freeing the node while it's in use.
  current_scene.call_deferred("queue_free")
  
 # Add the new scene to our container.
 scene_container.add_child(new_scene_instance)
 
 # Update our reference to the current scene.
 current_scene = new_scene_instance
