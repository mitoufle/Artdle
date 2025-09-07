extends PopupPanel
class_name CraftPopup

## Modale d'atelier de craft

#==============================================================================
# UI References
#==============================================================================
@onready var level_label: Label = $VBoxContainer/WorkshopInfoPanel/WorkshopHBox3/LevelLabel
@onready var upgrade_button: Button = $VBoxContainer/WorkshopInfoPanel/WorkshopHBox/UpgradeButton
@onready var upgrade_cost_label: Label = $VBoxContainer/WorkshopInfoPanel/WorkshopHBox/UpgradeCostLabel
@onready var tier_chances_label: Label = $VBoxContainer/WorkshopInfoPanel/WorkshopHBox2/TierChancesLabel
@onready var current_craft_panel: Panel = $VBoxContainer/CurrentCraftPanel
@onready var current_craft_info_label: Label = $VBoxContainer/CurrentCraftPanel/CraftVBox/InfoLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/CurrentCraftPanel/CraftVBox/ProgressBar
@onready var cancel_button: Button = $VBoxContainer/CurrentCraftPanel/CraftVBox/CancelButton
@onready var craft_button: Button = $VBoxContainer/CraftButton
@onready var craft_info_label: Label = $VBoxContainer/CraftInfoLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

#==============================================================================
# State
#==============================================================================
var craft_item_buttons: Dictionary = {}

#==============================================================================
# Godot Lifecycle
#==============================================================================
func _ready() -> void:
	_connect_signals()
	_update_workshop_info()
	_update_current_craft()
	_update_craft_button()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	upgrade_button.pressed.connect(_on_upgrade_workshop_pressed)
	cancel_button.pressed.connect(_on_cancel_craft_pressed)
	craft_button.pressed.connect(_on_craft_button_pressed)
	
	# Connecter les signaux du craft manager
	if not GameState.craft_manager.craft_started.is_connected(_on_craft_started):
		GameState.craft_manager.craft_started.connect(_on_craft_started)
	
	if not GameState.craft_manager.craft_completed.is_connected(_on_craft_completed):
		GameState.craft_manager.craft_completed.connect(_on_craft_completed)
	
	if not GameState.craft_manager.craft_finished.is_connected(_on_craft_finished):
		GameState.craft_manager.craft_finished.connect(_on_craft_finished)
	
	if not GameState.craft_manager.craft_progress_updated.is_connected(_on_craft_progress_updated):
		GameState.craft_manager.craft_progress_updated.connect(_on_craft_progress_updated)
	
	if not GameState.craft_manager.workshop_upgraded.is_connected(_on_workshop_upgraded):
		GameState.craft_manager.workshop_upgraded.connect(_on_workshop_upgraded)
	
	# Connecter les signaux de devises
	if not GameState.currency_manager.currency_changed.is_connected(_on_currency_changed):
		GameState.currency_manager.currency_changed.connect(_on_currency_changed)

#==============================================================================
# Display Methods
#==============================================================================
func _update_craft_button() -> void:
	var current_craft = GameState.craft_manager.get_current_craft()
	var is_crafting = current_craft.size() > 0
	
	craft_button.disabled = is_crafting
	
	if is_crafting:
		craft_button.text = "Crafting in Progress..."
		craft_button.modulate = Color.GRAY
		craft_info_label.text = "Wait for current craft to finish"
	else:
		craft_button.text = "Start Random Craft"
		craft_button.modulate = Color.WHITE
		craft_info_label.text = "Click to craft a random item"

func _update_workshop_info() -> void:
	var level = GameState.craft_manager.get_workshop_level()
	var upgrade_cost = GameState.craft_manager.get_workshop_upgrade_cost()
	var tier_chances = GameState.craft_manager.get_tier_chances()
	
	level_label.text = "Workshop Level: %d" % level
	upgrade_cost_label.text = "Cost: %d gold" % upgrade_cost
	
	# Mettre à jour l'état du bouton d'amélioration
	upgrade_button.disabled = not GameState.currency_manager.has_enough("gold", upgrade_cost)
	
	# Afficher les chances de tiers
	var chances_text = "Tier Chances: "
	var chance_strings = []
	for tier in tier_chances.keys():
		var tier_name = _get_tier_name(tier)
		var chance = tier_chances[tier] * 100
		chance_strings.append("%s %.1f%%" % [tier_name, chance])
	chances_text += ", ".join(chance_strings)
	tier_chances_label.text = chances_text

func _update_current_craft() -> void:
	var current_craft = GameState.craft_manager.get_current_craft()
	
	if current_craft.size() > 0:
		current_craft_panel.visible = true
		
		var item_data = GameState.craft_manager.get_craftable_items()[current_craft.item_type]
		var progress = GameState.craft_manager.get_craft_progress()
		
		current_craft_info_label.text = "Crafting: %s x%d" % [item_data.name, current_craft.quantity]
		progress_bar.value = progress * 100
		
		# Mettre à jour le texte de progression
		var remaining_time = current_craft.duration * (1.0 - progress)
		current_craft_info_label.text += "\nTime remaining: %.1fs" % remaining_time
	else:
		current_craft_panel.visible = false


#==============================================================================
# Signal Handlers
#==============================================================================
func _on_close_pressed() -> void:
	hide()

func _on_upgrade_workshop_pressed() -> void:
	var success = GameState.craft_manager.upgrade_workshop()
	if success:
		GameState.feedback_manager.show_feedback("Workshop upgraded!", Color.BLUE)
		_update_workshop_info()
	else:
		GameState.feedback_manager.show_feedback("Cannot upgrade workshop", Color.RED)

func _on_cancel_craft_pressed() -> void:
	var success = GameState.craft_manager.cancel_craft()
	if success:
		GameState.feedback_manager.show_feedback("Craft cancelled", Color.YELLOW)
		_update_current_craft()
		_update_craft_button()
	else:
		GameState.feedback_manager.show_feedback("Cannot cancel craft", Color.RED)

func _on_craft_button_pressed() -> void:
	if GameState.craft_manager.is_crafting():
		GameState.feedback_manager.show_feedback("Craft already in progress!", Color.RED)
		return
	
	# Choisir un type d'item aléatoire
	var craftable_items = GameState.craft_manager.get_craftable_items()
	var item_types = craftable_items.keys()
	var random_type = item_types[randi() % item_types.size()]
	
	var success = GameState.craft_manager.start_craft(random_type, 1)
	if success:
		var item_data = craftable_items[random_type]
		GameState.feedback_manager.show_feedback("Craft started: %s" % item_data.name, Color.BLUE)
	else:
		GameState.feedback_manager.show_feedback("Cannot start craft", Color.RED)

func _on_craft_started(item_type: InventoryManager.ItemType, quantity: int, duration: float) -> void:
	_update_current_craft()
	_update_craft_button()

func _on_craft_completed(item: InventoryManager.Item) -> void:
	# Donner de l'expérience pour le craft
	var xp_gained = 10 + (item.tier * 5)
	GameState.experience_manager.add_experience(xp_gained)
	
	GameState.feedback_manager.show_feedback("Item created: %s (%s) (+%d XP)" % [item.name, _get_tier_name(item.tier), xp_gained], Color.GREEN)

func _on_craft_finished() -> void:
	# Mettre à jour l'UI quand le craft est complètement terminé
	_update_current_craft()
	_update_craft_button()

func _on_craft_progress_updated(progress: float) -> void:
	_update_current_craft()

func _on_workshop_upgraded(new_level: int) -> void:
	GameState.feedback_manager.show_feedback("Workshop upgraded to level %d!" % new_level, Color.BLUE)
	_update_workshop_info()

func _on_currency_changed(currency_type: String, new_value: float) -> void:
	if currency_type == "gold":
		_update_workshop_info()
		_update_craft_button()

#==============================================================================
# Helper Methods
#==============================================================================
func _get_tier_name(tier: InventoryManager.ItemTier) -> String:
	match tier:
		InventoryManager.ItemTier.TIER_1: return "Normal"
		InventoryManager.ItemTier.TIER_2: return "Magic"
		InventoryManager.ItemTier.TIER_3: return "Rare"
		InventoryManager.ItemTier.TIER_4: return "Epic"
		InventoryManager.ItemTier.TIER_5: return "Legendary"
		_: return "Unknown"
