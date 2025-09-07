extends Node
class_name UIDisplayFormatter

## Gestionnaire central pour l'affichage unifié des prix et niveaux
## Assure la cohérence visuelle dans toute l'interface

#==============================================================================
# Currency Icons
#==============================================================================
const CURRENCY_ICONS = {
	"inspiration": preload("res://artdleAsset/Currency/Inspiration.png"),
	"gold": preload("res://artdleAsset/Currency/coin.png"),  # Test avec coin.png
	"fame": preload("res://artdleAsset/Currency/fame.png"),
	"ascendancy_points": preload("res://artdleAsset/Currency/Ascendancy_point.png"),
	"paint_mastery": preload("res://artdleAsset/Currency/Painting_mastery.png")
}

#==============================================================================
# Price Display
#==============================================================================

## Formate un prix avec icône et nombre formaté
static func format_price(currency_type: String, amount: float) -> String:
	var formatted_amount = BigNumberManager.format_number(amount)
	var icon_text = _get_currency_icon_text(currency_type)
	return "%s %s" % [icon_text, formatted_amount]

## Formate un prix avec vraie icône (pour les boutons)
static func format_price_with_icon(currency_type: String, amount: float) -> String:
	var formatted_amount = BigNumberManager.format_number(amount)
	var icon_name = _get_currency_icon_name(currency_type)
	return "%s %s" % [icon_name, formatted_amount]

## Formate un prix multiple (plusieurs devises)
static func format_multi_price(prices: Dictionary) -> String:
	var price_strings = []
	
	for currency_type in prices.keys():
		var amount = prices[currency_type]
		if amount > 0:
			price_strings.append(format_price(currency_type, amount))
	
	return " + ".join(price_strings)

## Formate un prix multiple avec vraies icônes (pour les boutons)
static func format_multi_price_with_icons(prices: Dictionary) -> String:
	var price_strings = []
	
	for currency_type in prices.keys():
		var amount = prices[currency_type]
		if amount > 0:
			price_strings.append(format_price_with_icon(currency_type, amount))
	
	return " + ".join(price_strings)

## Crée un nœud d'affichage de prix avec icône
static func create_price_display(currency_type: String, amount: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	# Icône
	var icon = TextureRect.new()
	icon.texture = CURRENCY_ICONS.get(currency_type)
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(icon)
	
	# Texte du prix
	var label = Label.new()
	label.text = BigNumberManager.format_number(amount)
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)
	
	return container

## Crée un nœud d'affichage de prix multiple
static func create_multi_price_display(prices: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	for currency_type in prices.keys():
		var amount = prices[currency_type]
		if amount > 0:
			var price_display = create_price_display(currency_type, amount)
			container.add_child(price_display)
	
	return container

#==============================================================================
# Level Display
#==============================================================================

## Formate un niveau avec préfixe
static func format_level(level: int, prefix: String = "Level") -> String:
	return "%s %d" % [prefix, level]

## Formate un niveau avec progression (ex: Level 5 (2/10))
static func format_level_with_progress(level: int, current: float, max: float, prefix: String = "Level") -> String:
	return "%s %d (%.0f/%.0f)" % [prefix, level, current, max]

## Formate un niveau avec pourcentage (ex: Level 5 (20%))
static func format_level_with_percentage(level: int, current: float, max: float, prefix: String = "Level") -> String:
	var percentage = (current / max) * 100 if max > 0 else 0
	return "%s %d (%.0f%%)" % [prefix, level, percentage]

## Crée un nœud d'affichage de niveau
static func create_level_display(level: int, prefix: String = "Level") -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	# Icône de niveau (optionnel)
	var icon = Label.new()
	icon.text = "📊"
	icon.add_theme_font_size_override("font_size", 16)
	container.add_child(icon)
	
	# Texte du niveau
	var label = Label.new()
	label.text = format_level(level, prefix)
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)
	
	return container

## Crée un nœud d'affichage de niveau avec progression
static func create_level_progress_display(level: int, current: float, max: float, prefix: String = "Level") -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	# Niveau
	var level_display = create_level_display(level, prefix)
	container.add_child(level_display)
	
	# Barre de progression
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = max
	progress_bar.value = current
	progress_bar.custom_minimum_size = Vector2(100, 8)
	container.add_child(progress_bar)
	
	return container

#==============================================================================
# Helper Functions
#==============================================================================

## Récupère le texte d'icône pour une devise
static func _get_currency_icon_text(currency_type: String) -> String:
	match currency_type:
		"inspiration": return "💡"  # Ampoule pour inspiration
		"gold": return "🪙"  # Pièce de monnaie pour or
		"fame": return "⭐"  # Étoile pour renommée
		"ascendancy_points": return "⬆️"  # Flèche pour ascension
		"paint_mastery": return "🎨"  # Palette pour peinture
		_: return "❓"

## Récupère le nom de l'icône pour une devise (pour affichage texte)
static func _get_currency_icon_name(currency_type: String) -> String:
	match currency_type:
		"inspiration": return "[Inspiration]"
		"gold": return "[Coin]"
		"fame": return "[Fame]"
		"ascendancy_points": return "[Ascendancy]"
		"paint_mastery": return "[Paint Mastery]"
		_: return "[?]"

## Récupère la texture de l'icône pour une devise
static func get_currency_icon(currency_type: String) -> Texture2D:
	if CURRENCY_ICONS.has(currency_type):
		return CURRENCY_ICONS[currency_type]
	return null

## Vérifie si un prix est abordable
static func can_afford_price(prices: Dictionary) -> bool:
	if not GameState or not GameState.currency_manager:
		return false
	
	for currency_type in prices.keys():
		var required = prices[currency_type]
		var available = GameState.currency_manager.get_currency(currency_type)
		if available < required:
			return false
	
	return true

## Applique un style d'achat possible/impossible à un bouton
static func apply_affordability_style(button: Button, prices: Dictionary) -> void:
	var can_afford = can_afford_price(prices)
	
	if can_afford:
		button.modulate = Color.WHITE
		button.disabled = false
	else:
		button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		button.disabled = true
