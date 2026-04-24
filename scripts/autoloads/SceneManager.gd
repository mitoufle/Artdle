extends Node

# Minimal scene loader. Expanded in Phase 4 when UI views exist.

func load_scene(scene_path: String) -> void:
    var err = get_tree().change_scene_to_file(scene_path)
    if err != OK:
        push_error("Failed to load scene: %s (err %d)" % [scene_path, err])
