class_name Save
extends Node

const SAVE_VERSION: int = 1
var save_path: String = "user://artdle.save"

func write(payload: Dictionary) -> bool:
	var full: Dictionary = payload.duplicate(true)
	full["version"] = SAVE_VERSION
	var tmp_path: String = save_path + ".tmp"
	var f = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(full))
	f.close()
	var err = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(save_path)
	)
	return err == OK

func read() -> Variant:
	if not FileAccess.file_exists(save_path):
		return null
	var f = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return null
	var text = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return null
	var version: int = int(parsed.get("version", 0))
	if version > SAVE_VERSION:
		push_error("Save from newer version (%d > %d) — refusing to load" % [version, SAVE_VERSION])
		return null
	if version < SAVE_VERSION:
		parsed = _migrate(parsed, version, SAVE_VERSION)
	return parsed

func _migrate(data: Dictionary, from_v: int, to_v: int) -> Dictionary:
	if from_v == to_v:
		return data
	push_error("No migration path from v%d to v%d" % [from_v, to_v])
	return data
