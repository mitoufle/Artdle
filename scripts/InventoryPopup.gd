extends PopupPanel
class_name InventoryPopup

## Modale d'inventaire et d'équipement

#==============================================================================
# UI References
#==============================================================================
@onready var equipment_grid: GridContainer = $VBoxContainer/MainHBox/EquipmentContainer/EquipmentPanel/EquipmentGrid
@onready var inventory_grid: GridContainer = $VBoxContainer/MainHBox/InventoryContainer/InventoryPanel/InventoryGrid
@onready var stats_label: RichTextLabel = $VBoxContainer/StatsPanel/StatsLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

#==============================================================================
# State
#==============================================================================
var equipment_buttons: Dictionary = {}
var inventory_buttons: Dictionary = {}

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_connect_signals()
	_create_equipment_slots()
	_update_display()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	
	# Connecter les signaux de l'inventaire
	if not GameState.inventory_manager.item_equipped.is_connected(_on_item_equipped):
		GameState.inventory_manager.item_equipped.connect(_on_item_equipped)
	
	if not GameState.inventory_manager.item_unequipped.is_connected(_on_item_unequipped):
		GameState.inventory_manager.item_unequipped.connect(_on_item_unequipped)
	
	if not GameState.inventory_manager.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_manager.inventory_changed.connect(_on_inventory_changed)

#==============================================================================
# Display Methods
#==============================================================================
func _create_equipment_slots() -> void:
	# Clear existing buttons
	for child in equipment_grid.get_children():
		child.queue_free()
	equipment_buttons.clear()
	
	# Create equipment slots
	var slot_names = ["hat", "shirt", "boots", "gloves", "brush", "palette", "ring_1", "ring_2", "amulet", "badge_1", "badge_2", "badge_3"]
	var slot_labels = ["Hat", "Shirt", "Boots", "Gloves", "Brush", "Palette", "Ring 1", "Ring 2", "Amulet", "Badge 1", "Badge 2", "Badge 3"]
	
	for i in range(slot_names.size()):
		var slot_name = slot_names[i]
		var slot_label = slot_labels[i]
		
		# Create slot button
		var button = Button.new()
		button.text = slot_label
		button.custom_minimum_size = Vector2(120, 80)
		button.pressed.connect(_on_equipment_slot_pressed.bind(slot_name))
		
		# Create slot container
		var slot_container = VBoxContainer.new()
		slot_container.add_child(button)
		
		# Add equipped item label
		var item_label = Label.new()
		item_label.name = "ItemLabel"
		item_label.text = "Empty"
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_container.add_child(item_label)
		
		equipment_grid.add_child(slot_container)
		equipment_buttons[slot_name] = button
		
		# Update slot display
		_update_equipment_slot(slot_name)

func _update_display() -> void:
	_create_inventory_items()
	_update_stats_display()

func _create_inventory_items() -> void:
	# Clear existing buttons
	for child in inventory_grid.get_children():
		child.queue_free()
	inventory_buttons.clear()
	
	# Create buttons for each inventory item (only unequipped items)
	var inventory_items = GameState.inventory_manager.get_inventory_items()
	var equipped_items = GameState.inventory_manager.get_all_equipped_items()
	
	for item in inventory_items:
		# Check if item is equipped
		var is_equipped = false
		for slot in equipped_items.keys():
			if equipped_items[slot].id == item.id:
				is_equipped = true
				break
		
		# Only show unequipped items
		if not is_equipped:
			_create_inventory_item_button(item)

func _create_inventory_item_button(item: InventoryManager.Item) -> void:
	# Create container for item with buttons
	var item_container = VBoxContainer.new()
	
	# Main button to equip
	var equip_button = Button.new()
	equip_button.text = item.name
	equip_button.custom_minimum_size = Vector2(100, 40)
	equip_button.pressed.connect(_on_inventory_item_pressed.bind(item))
	
	# Color based on tier
	var tier_colors = {
		InventoryManager.ItemTier.TIER_1: Color.WHITE,
		InventoryManager.ItemTier.TIER_2: Color.GREEN,
		InventoryManager.ItemTier.TIER_3: Color.BLUE,
		InventoryManager.ItemTier.TIER_4: Color.PURPLE,
		InventoryManager.ItemTier.TIER_5: Color.ORANGE
	}
	equip_button.modulate = tier_colors.get(item.tier, Color.WHITE)
	
	# Tooltip with stats
	equip_button.tooltip_text = item.description
	
	# Sell button
	var sell_button = Button.new()
	sell_button.text = "Sell"
	sell_button.custom_minimum_size = Vector2(100, 20)
	sell_button.pressed.connect(_on_sell_item_pressed.bind(item))
	
	# Calculate sell price
	var sell_price = _calculate_sell_price(item)
	sell_button.tooltip_text = "Sell for %d fame and %d XP" % [sell_price.fame, sell_price.experience]
	
	item_container.add_child(equip_button)
	item_container.add_child(sell_button)
	
	inventory_grid.add_child(item_container)
	inventory_buttons[item.id] = equip_button

func _update_equipment_slot(slot_name: String) -> void:
	var item = GameState.inventory_manager.get_equipped_item(slot_name)
	var button = equipment_buttons.get(slot_name)
	
	if not button:
		return
	
	var slot_container = button.get_parent()
	var item_label = slot_container.get_node("ItemLabel")
	
	# Disconnect existing signals to avoid duplicates
	if button.mouse_entered.is_connected(_on_equipment_slot_mouse_entered):
		button.mouse_entered.disconnect(_on_equipment_slot_mouse_entered)
	if button.mouse_exited.is_connected(_on_equipment_slot_mouse_exited):
		button.mouse_exited.disconnect(_on_equipment_slot_mouse_exited)
	
	if item:
		button.text = item.name
		item_label.text = _get_tier_name(item.tier)
		
		# Couleur selon le tier
		var tier_colors = {
			InventoryManager.ItemTier.TIER_1: Color.WHITE,
			InventoryManager.ItemTier.TIER_2: Color.GREEN,
			InventoryManager.ItemTier.TIER_3: Color.BLUE,
			InventoryManager.ItemTier.TIER_4: Color.PURPLE,
			InventoryManager.ItemTier.TIER_5: Color.ORANGE
		}
		button.modulate = tier_colors.get(item.tier, Color.WHITE)
		
		# Connect tooltip signals for equipped items
		button.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(item))
		button.mouse_exited.connect(_on_equipment_slot_mouse_exited)
	else:
		button.text = _get_slot_label(slot_name)
		item_label.text = "Empty"
		button.modulate = Color.WHITE

func _update_stats_display() -> void:
	var total_bonuses = GameState.inventory_manager.get_total_bonuses()
	
	var stats_text = "[b]Equipment Bonuses:[/b]\n"
	
	if total_bonuses.size() == 0:
		stats_text += "No equipment\n"
	else:
		for stat_name in total_bonuses.keys():
			var stat_value = total_bonuses[stat_name]
			var stat_display = _format_stat_name(stat_name)
			var bonus_percent = (stat_value - 1.0) * 100
			stats_text += "%s: +%.1f%%\n" % [stat_display, bonus_percent]
	
	stats_label.text = stats_text

#==============================================================================
# Tooltip Methods
#==============================================================================
func _on_equipment_slot_mouse_entered(item: InventoryManager.Item) -> void:
	_show_equipment_tooltip(item)

func _on_equipment_slot_mouse_exited() -> void:
	_hide_equipment_tooltip()

var current_tooltip: Control = null

func _show_equipment_tooltip(item: InventoryManager.Item) -> void:
	# Hide existing tooltip if any
	_hide_equipment_tooltip()
	
	# Create tooltip text
	var tooltip_text = _generate_equipment_tooltip_text(item)
	
	# Load and instantiate the custom tooltip scene
	var tooltip_scene = preload("res://Scenes/CustomTooltip.tscn")
	current_tooltip = tooltip_scene.instantiate()
	
	# Add to scene
	get_tree().get_root().add_child(current_tooltip)
	
	# Set tooltip content
	if current_tooltip.has_method("set_text"):
		current_tooltip.set_text(tooltip_text)
	
	# Position tooltip
	var mouse_pos = get_viewport().get_mouse_position()
	current_tooltip.global_position = mouse_pos + Vector2(20, -20)

func _hide_equipment_tooltip() -> void:
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null

func _generate_equipment_tooltip_text(item: InventoryManager.Item) -> String:
	var tooltip = ""
	
	# Item name and tier
	tooltip += "[b]%s[/b]\n" % item.name
	tooltip += "[color=gray]%s[/color]\n\n" % _get_tier_name(item.tier)
	
	# Item type
	tooltip += "[b]Type:[/b] %s\n" % _get_type_name(item.type)
	
	# Stats
	if item.stats.size() > 0:
		tooltip += "\n[b]Stats:[/b]\n"
		for stat_name in item.stats.keys():
			var stat_value = item.stats[stat_name]
			var stat_display = _format_stat_name(stat_name)
			var bonus_percent = (stat_value - 1.0) * 100
			tooltip += "• %s: +%.1f%%\n" % [stat_display, bonus_percent]
	
	# Description if available
	if item.description != "":
		tooltip += "\n[b]Description:[/b]\n%s" % item.description
	
	return tooltip

func _get_tier_name(tier: InventoryManager.ItemTier) -> String:
	match tier:
		InventoryManager.ItemTier.TIER_1:
			return "Common"
		InventoryManager.ItemTier.TIER_2:
			return "Uncommon"
		InventoryManager.ItemTier.TIER_3:
			return "Rare"
		InventoryManager.ItemTier.TIER_4:
			return "Epic"
		InventoryManager.ItemTier.TIER_5:
			return "Legendary"
		_:
			return "Unknown"

func _get_type_name(item_type: InventoryManager.ItemType) -> String:
	match item_type:
		InventoryManager.ItemType.HAT:
			return "Hat"
		InventoryManager.ItemType.SHIRT:
			return "Shirt"
		InventoryManager.ItemType.BOOTS:
			return "Boots"
		InventoryManager.ItemType.GLOVES:
			return "Gloves"
		InventoryManager.ItemType.BRUSH:
			return "Brush"
		InventoryManager.ItemType.PALETTE:
			return "Palette"
		InventoryManager.ItemType.RING:
			return "Ring"
		InventoryManager.ItemType.AMULET:
			return "Amulet"
		InventoryManager.ItemType.BADGE:
			return "Badge"
		_:
			return "Unknown"

func _format_stat_name(stat_name: String) -> String:
	match stat_name:
		"fame_generation":
			return "Fame Generation"
		"coin_generation":
			return "Coin Generation"
		"inspiration_generation":
			return "Inspiration Generation"
		"craft_speed":
			return "Craft Speed"
		"painting_speed":
			return "Painting Speed"
		"pixel_gain":
			return "Pixel Gain"
		"canvas_speed":
			return "Canvas Speed"
		"fame_gain":
			return "Fame Gain"
		"gold_gain":
			return "Gold Gain"
		"inspiration_gain":
			return "Inspiration Gain"
		"ascendancy_gain":
			return "Ascendancy Gain"
		"experience_gain":
			return "Experience Gain"
		"special_effect":
			return "Special Effect"
		_:
			return stat_name.capitalize()

func _get_slot_label(slot_name: String) -> String:
	match slot_name:
		"hat":
			return "Hat"
		"shirt":
			return "Shirt"
		"boots":
			return "Boots"
		"gloves":
			return "Gloves"
		"brush":
			return "Brush"
		"palette":
			return "Palette"
		"ring_1":
			return "Ring 1"
		"ring_2":
			return "Ring 2"
		"amulet":
			return "Amulet"
		"badge_1":
			return "Badge 1"
		"badge_2":
			return "Badge 2"
		"badge_3":
			return "Badge 3"
		_:
			return slot_name.capitalize()

#==============================================================================
# Signal Handlers
#==============================================================================
func _on_close_pressed() -> void:
	hide()

func _on_item_equipped(slot: String, item: InventoryManager.Item) -> void:
	_update_equipment_slot(slot)
	_update_stats_display()
	# Update inventory display to hide the equipped item
	_create_inventory_items()

func _on_item_unequipped(slot: String, item: InventoryManager.Item) -> void:
	_update_equipment_slot(slot)
	_update_stats_display()
	# Update inventory display to show the unequipped item
	_create_inventory_items()

func _on_inventory_changed() -> void:
	_create_inventory_items()

func _on_equipment_slot_pressed(slot_name: String) -> void:
	# Unequip item if there is one
	var item = GameState.inventory_manager.get_equipped_item(slot_name)
	if item:
		GameState.inventory_manager.unequip_item(slot_name)
		GameState.feedback_manager.show_feedback("Item unequipped: %s" % item.name, Color.YELLOW)

func _on_inventory_item_pressed(item: InventoryManager.Item) -> void:
	# Find appropriate slot for this item
	var slot_name = _find_available_slot(item.type)
	
	if slot_name:
		if GameState.inventory_manager.equip_item(item, slot_name):
			GameState.feedback_manager.show_feedback("Item equipped: %s" % item.name, Color.GREEN)
		else:
			GameState.feedback_manager.show_feedback("Cannot equip item", Color.RED)
	else:
		GameState.feedback_manager.show_feedback("No slot available for this item", Color.RED)

func _on_sell_item_pressed(item: InventoryManager.Item) -> void:
	# Calculate sell price
	var sell_price = _calculate_sell_price(item)
	
	# Check if item is equipped
	var is_equipped = false
	for slot_name in GameState.inventory_manager.equipment_slots.keys():
		var equipped_item = GameState.inventory_manager.get_equipped_item(slot_name)
		if equipped_item and equipped_item.id == item.id:
			is_equipped = true
			# Unequip item
			GameState.inventory_manager.unequip_item(slot_name)
			break
	
	# Remove item from inventory
	GameState.inventory_manager.inventory_items.erase(item)
	
	# Give fame and experience
	GameState.currency_manager.add_currency("fame", sell_price.fame)
	GameState.experience_manager.add_experience(sell_price.experience)
	
	# Visual feedback
	GameState.feedback_manager.show_feedback("Item sold: %s (+%d fame, +%d XP)" % [item.name, sell_price.fame, sell_price.experience], Color.YELLOW)
	
	# Update display
	_update_display()

#==============================================================================
# Helper Methods
#==============================================================================
func _find_available_slot(item_type: InventoryManager.ItemType) -> String:
	var equipment_slots = GameState.inventory_manager.equipment_slots
	
	# For rings, find a free slot
	if item_type == InventoryManager.ItemType.RING:
		if not GameState.inventory_manager.get_equipped_item("ring_1"):
			return "ring_1"
		elif not GameState.inventory_manager.get_equipped_item("ring_2"):
			return "ring_2"
		else:
			return ""
	
	# For badges, find a free slot
	if item_type == InventoryManager.ItemType.BADGE:
		if not GameState.inventory_manager.get_equipped_item("badge_1"):
			return "badge_1"
		elif not GameState.inventory_manager.get_equipped_item("badge_2"):
			return "badge_2"
		else:
			return ""
	
	# For other types, find corresponding slot
	for slot_name in equipment_slots.keys():
		if equipment_slots[slot_name] == item_type:
			return slot_name
	
	return ""


func _calculate_sell_price(item: InventoryManager.Item) -> Dictionary:
	# Base price based on tier
	var base_fame = 0
	var base_experience = 0
	
	match item.tier:
		InventoryManager.ItemTier.TIER_1:
			base_fame = 10
			base_experience = 5
		InventoryManager.ItemTier.TIER_2:
			base_fame = 25
			base_experience = 12
		InventoryManager.ItemTier.TIER_3:
			base_fame = 50
			base_experience = 25
		InventoryManager.ItemTier.TIER_4:
			base_fame = 100
			base_experience = 50
		InventoryManager.ItemTier.TIER_5:
			base_fame = 200
			base_experience = 100
	
	# Bonus based on item type
	var type_multiplier = 1.0
	match item.type:
		InventoryManager.ItemType.BRUSH, InventoryManager.ItemType.PALETTE:
			type_multiplier = 1.5  # Painting tools more valuable
		InventoryManager.ItemType.RING, InventoryManager.ItemType.AMULET:
			type_multiplier = 1.3  # Precious jewelry
		InventoryManager.ItemType.BADGE:
			type_multiplier = 2.0  # Badges very precious
	
	# Calculate final price
	var final_fame = int(base_fame * type_multiplier)
	var final_experience = int(base_experience * type_multiplier)
	
	return {
		"fame": final_fame,
		"experience": final_experience
	}
