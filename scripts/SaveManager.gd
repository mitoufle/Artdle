extends Node
class_name SaveManager

## Gestionnaire de sauvegarde pour le jeu Artdle
## Gère la sérialisation et désérialisation des données de jeu

#==============================================================================
# Configuration
#==============================================================================
const SAVE_FILE_PATH = "user://artdle_save.json"
const SAVE_VERSION = "1.0"

#==============================================================================
# Signals
#==============================================================================
signal save_completed(success: bool)
signal load_completed(success: bool)
signal save_data_cleared()

#==============================================================================
# Public API
#==============================================================================

## Sauvegarde les données de jeu
func save_game() -> bool:
	var save_data = _collect_save_data()
	
	var basic_keys: Array[String] = ["version", "timestamp"]
	if not GameState.data_validator.validate_config_dict(save_data, basic_keys):
		GameState.logger.error("Save data validation failed")
		save_completed.emit(false)
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		GameState.logger.error("Failed to open save file for writing: %s" % SAVE_FILE_PATH)
		save_completed.emit(false)
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	GameState.logger.info("Game saved successfully", "SaveManager")
	save_completed.emit(true)
	return true

## Charge les données de jeu
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		GameState.logger.warning("No save file found, starting new game")
		load_completed.emit(false)
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		GameState.logger.error("Failed to open save file for reading: %s" % SAVE_FILE_PATH)
		load_completed.emit(false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		GameState.logger.error("Failed to parse save file JSON")
		load_completed.emit(false)
		return false
	
	var save_data = json.data
	if not _validate_save_data(save_data):
		GameState.logger.error("Save data validation failed")
		load_completed.emit(false)
		return false
	
	_apply_save_data(save_data)
	GameState.logger.info("Game loaded successfully", "SaveManager")
	load_completed.emit(true)
	return true

## Supprime le fichier de sauvegarde
func clear_save() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE_PATH)
			GameState.logger.info("Save file cleared", "SaveManager")
			save_data_cleared.emit()
			return true
	
	GameState.logger.warning("No save file to clear")
	return false

## Vérifie si une sauvegarde existe
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## Récupère les informations de la sauvegarde
func get_save_info() -> Dictionary:
	if not has_save_file():
		return {
			"success": false,
			"message": "No save file found"
		}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return {
			"success": false,
			"message": "Failed to open save file"
		}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {
			"success": false,
			"message": "Failed to parse save file"
		}
	
	var save_data = json.data
	var file_size = json_string.length()
	var timestamp = save_data.get("timestamp", 0)
	var date_string = Time.get_datetime_string_from_unix_time(timestamp)
	
	return {
		"success": true,
		"data": {
			"version": save_data.get("version", "unknown"),
			"date": date_string,
			"timestamp": timestamp,
			"size": file_size,
			"level": save_data.get("experience", {}).get("level", 0),
			"ascendancy_points": save_data.get("currencies", {}).get("ascendancy_points", 0)
		}
	}

#==============================================================================
# Private Methods
#==============================================================================

func _collect_save_data() -> Dictionary:
	var timestamp = Time.get_unix_time_from_system()
	
	return {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"currencies": GameState.currency_manager.get_all_currencies(),
		"experience": {
			"experience": GameState.experience_manager.get_experience(),
			"level": GameState.experience_manager.get_level(),
			"experience_to_next_level": GameState.experience_manager.get_experience_to_next_level()
		},
		"canvas": {
			"resolution_level": GameState.canvas_manager.resolution_level,
			"fill_speed_level": GameState.canvas_manager.fill_speed_level,
			"sell_price": GameState.canvas_manager.sell_price,
			"stored_canvases": GameState.canvas_manager.stored_canvases,
			"canvas_storage_level": GameState.canvas_manager.canvas_storage_level,
			"upgrade_resolution_cost": GameState.canvas_manager.upgrade_resolution_cost,
			"upgrade_fill_speed_cost": GameState.canvas_manager.upgrade_fill_speed_cost,
			"canvas_storage_cost": GameState.canvas_manager.canvas_storage_cost
		},
		"clicker": {
			"click_power": GameState.clicker_manager.click_power,
			"autoclick_speed": GameState.clicker_manager.autoclick_speed
		},
		"ascension": {
			"ascendancy_cost": GameState.ascension_manager.ascendancy_cost,
			"ascend_level": GameState.ascension_manager.ascend_level
		},
		"skill_tree": {
			"unlocked_skills": GameState.skill_tree_manager.get_unlocked_skills(),
			"skill_levels": _collect_skill_levels()
		},
		"passive_income": {
			"sources": GameState.passive_income_manager.get_passive_sources()
		},
		"workshop": {
			"workshop_level": GameState.craft_manager.workshop_level,
			"workshop_upgrade_cost": GameState.craft_manager.workshop_upgrade_cost
		},
		"inventory": {
			"equipped_items": _collect_equipped_items(),
			"inventory_items": _collect_inventory_items()
		}
	}

func _collect_skill_levels() -> Dictionary:
	var skill_levels = {}
	for skill_name in GameState.skill_tree_manager.skills.keys():
		skill_levels[skill_name] = GameState.skill_tree_manager.get_skill_level(skill_name)
	return skill_levels

func _collect_equipped_items() -> Dictionary:
	var equipped_data = {}
	var equipped_items = GameState.inventory_manager.get_all_equipped_items()
	
	for slot in equipped_items.keys():
		var item = equipped_items[slot]
		equipped_data[slot] = {
			"id": item.id,
			"name": item.name,
			"type": item.type,
			"tier": item.tier,
			"stats": item.stats
		}
	
	return equipped_data

func _collect_inventory_items() -> Array:
	var inventory_data = []
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	
	for item in inventory_items:
		inventory_data.append({
			"id": item.id,
			"name": item.name,
			"type": item.type,
			"tier": item.tier,
			"stats": item.stats
		})
	
	return inventory_data

func _validate_save_data(save_data: Dictionary) -> bool:
	var required_keys: Array[String] = ["version", "timestamp", "currencies", "experience", "canvas", "clicker", "ascension", "skill_tree", "passive_income"]
	
	if not GameState.data_validator.validate_config_dict(save_data, required_keys):
		return false
	
	# Vérifier la version
	if save_data.get("version") != SAVE_VERSION:
		GameState.logger.warning("Save file version mismatch: %s vs %s" % [save_data.get("version"), SAVE_VERSION])
	
	return true

func _apply_save_data(save_data: Dictionary) -> void:
	# Restaurer les devises
	var currencies = save_data.get("currencies", {})
	for currency_type in currencies.keys():
		GameState.currency_manager.set_currency(currency_type, currencies[currency_type])
	
	# Restaurer l'expérience
	var experience_data = save_data.get("experience", {})
	GameState.experience_manager.set_experience(experience_data.get("experience", GameConfig.DEFAULT_EXPERIENCE))
	GameState.experience_manager.set_level(experience_data.get("level", GameConfig.DEFAULT_LEVEL))
	GameState.experience_manager.set_experience_to_next_level(experience_data.get("experience_to_next_level", GameConfig.DEFAULT_EXPERIENCE_TO_NEXT_LEVEL))
	
	# Restaurer le canvas
	var canvas_data = save_data.get("canvas", {})
	GameState.canvas_manager.set_resolution_level(canvas_data.get("resolution_level", GameConfig.BASE_RESOLUTION_LEVEL))
	GameState.canvas_manager.set_fill_speed_level(canvas_data.get("fill_speed_level", GameConfig.BASE_FILL_SPEED_LEVEL))
	GameState.canvas_manager.set_sell_price(canvas_data.get("sell_price", GameConfig.BASE_SELL_PRICE))
	GameState.canvas_manager.set_stored_canvases(canvas_data.get("stored_canvases", 0))
	GameState.canvas_manager.set_canvas_storage_level(canvas_data.get("canvas_storage_level", GameConfig.BASE_CANVAS_STORAGE_LEVEL))
	GameState.canvas_manager.set_upgrade_resolution_cost(canvas_data.get("upgrade_resolution_cost", GameConfig.BASE_RESOLUTION_UPGRADE_COST))
	GameState.canvas_manager.set_upgrade_fill_speed_cost(canvas_data.get("upgrade_fill_speed_cost", GameConfig.BASE_FILL_SPEED_UPGRADE_COST))
	GameState.canvas_manager.set_canvas_storage_cost(canvas_data.get("canvas_storage_cost", GameConfig.BASE_CANVAS_STORAGE_UPGRADE_COST))
	
	# Restaurer le clicker
	var clicker_data = save_data.get("clicker", {})
	GameState.clicker_manager.set_click_power(clicker_data.get("click_power", GameConfig.BASE_CLICK_POWER))
	GameState.clicker_manager.set_autoclick_speed(clicker_data.get("autoclick_speed", GameConfig.BASE_AUTOCLICK_SPEED))
	
	# Restaurer l'ascension
	var ascension_data = save_data.get("ascension", {})
	GameState.ascension_manager.set_ascendancy_cost(ascension_data.get("ascendancy_cost", GameConfig.BASE_ASCENDANCY_COST))
	GameState.ascension_manager.set_ascend_level(ascension_data.get("ascend_level", GameConfig.DEFAULT_ASCEND_LEVEL))
	
	# Restaurer l'arbre de compétences
	var skill_tree_data = save_data.get("skill_tree", {})
	_restore_skill_tree(skill_tree_data)
	
	# Restaurer les revenus passifs
	var passive_income_data = save_data.get("passive_income", {})
	_restore_passive_income(passive_income_data)
	
	# Restaurer l'atelier
	var workshop_data = save_data.get("workshop", {})
	GameState.craft_manager.workshop_level = workshop_data.get("workshop_level", 1)
	GameState.craft_manager.workshop_upgrade_cost = workshop_data.get("workshop_upgrade_cost", 100)
	
	# Restaurer l'inventaire
	var inventory_data = save_data.get("inventory", {})
	_restore_inventory(inventory_data)
	
	# Réinitialiser le canvas
	GameState.canvas_manager._initialize_new_canvas()
	GameState.canvas_manager._update_fill_speed()
	
	# Réinitialiser l'autoclick
	GameState.clicker_manager._update_autoclick_timer()

func _restore_skill_tree(skill_tree_data: Dictionary) -> void:
	var skill_levels = skill_tree_data.get("skill_levels", {})
	
	# Restaurer les niveaux des skills
	for skill_name in skill_levels.keys():
		var level = skill_levels[skill_name]
		if level > 0 and GameState.skill_tree_manager.skills.has(skill_name):
			var skill = GameState.skill_tree_manager.skills[skill_name]
			skill.level = level
			skill.unlocked = true
			
			# Appliquer l'effet du skill pour chaque niveau
			for i in range(level):
				GameState.skill_tree_manager._apply_skill_effect(skill)

func _restore_passive_income(passive_income_data: Dictionary) -> void:
	var sources = passive_income_data.get("sources", {})
	
	# Restaurer chaque source de revenu passif
	for source_name in sources.keys():
		var source_data = sources[source_name]
		GameState.passive_income_manager.add_passive_income(
			source_name,
			source_data.get("currency_type", "inspiration"),
			source_data.get("amount", 1.0),
			source_data.get("interval", 5.0)
		)
		
		# Restaurer l'état enabled/disabled
		GameState.passive_income_manager.set_passive_income_enabled(
			source_name,
			source_data.get("enabled", true)
		)

func _restore_inventory(inventory_data: Dictionary) -> void:
	# Clear existing inventory
	GameState.inventory_manager.inventory_items.clear()
	GameState.inventory_manager.equipped_items.clear()
	
	# Restore inventory items
	var inventory_items = inventory_data.get("inventory_items", [])
	for item_data in inventory_items:
		var item = InventoryManager.Item.new(
			item_data.id,
			item_data.name,
			item_data.type,
			item_data.tier
		)
		item.stats = item_data.stats
		GameState.inventory_manager.inventory_items.append(item)
	
	# Restore equipped items
	var equipped_items = inventory_data.get("equipped_items", {})
	for slot in equipped_items.keys():
		var item_data = equipped_items[slot]
		var item = InventoryManager.Item.new(
			item_data.id,
			item_data.name,
			item_data.type,
			item_data.tier
		)
		item.stats = item_data.stats
		GameState.inventory_manager.equipped_items[slot] = item
		
		# Apply item stats
		GameState.inventory_manager._apply_item_stats(item)

#==============================================================================
# New Game Methods
#==============================================================================

## Réinitialise complètement le jeu (nouvelle partie)
func reset_game() -> bool:
	GameState.logger.info("Starting new game - resetting all data", "SaveManager")
	
	# Réinitialiser tous les managers
	_reset_all_managers()
	
	# Effacer la sauvegarde
	var clear_success = clear_save()
	
	# Sauvegarder l'état initial
	var save_success = save_game()
	
	if clear_success and save_success:
		GameState.logger.info("New game started successfully", "SaveManager")
		return true
	else:
		GameState.logger.error("Failed to start new game", "SaveManager")
		return false

## Réinitialise tous les managers aux valeurs par défaut
func _reset_all_managers() -> void:
	# Réinitialiser les devises
	GameState.currency_manager.reset_all_currencies()
	
	# Réinitialiser l'expérience
	GameState.experience_manager.reset_experience()
	
	# Réinitialiser le canvas
	GameState.canvas_manager.reset_canvas()
	
	# Réinitialiser le clicker
	GameState.clicker_manager.reset_clicker()
	
	# Réinitialiser l'ascension
	GameState.ascension_manager.reset_ascension()
	
	# Réinitialiser l'inventaire
	GameState.inventory_manager.reset_inventory()
	
	# Réinitialiser l'atelier
	GameState.craft_manager.reset_workshop()
	
	# Réinitialiser l'arbre de compétences
	GameState.skill_tree_manager.reset_skill_tree()
	
	# Réinitialiser le revenu passif
	GameState.passive_income_manager.reset_passive_income()
	
	GameState.logger.info("All managers reset to default values", "SaveManager")
