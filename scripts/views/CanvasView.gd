extends MarginContainer

#==============================================================================
# Références aux Nœuds de la Scène
#==============================================================================
@onready var canvas_display: TextureRect = $VBoxContainer/CanvasDisplay
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var sell_button: Button = $VBoxContainer/SellButton

#==============================================================================
# Données & État du Canvas
#==============================================================================
var canvas_image: Image
var canvas_texture: ImageTexture
var canvas_fill_timer: Timer

var current_pixel_count: int = 0
var max_pixels: int
var unfilled_pixels: Array[Vector2i] = []

# Propriétés du Canvas (pourront être gérées par PaintingView plus tard)
var resolution_level: int = 1
var fill_speed_level: int = 50
var sell_price:       int = 1000

#==============================================================================
# Fonctions Godot
#==============================================================================
func _ready():
	# Préparer un nouveau canvas
	_initialize_new_canvas()
	
	# Mettre en place le timer
	canvas_fill_timer = Timer.new()
	add_child(canvas_fill_timer)
	canvas_fill_timer.timeout.connect(_on_canvas_fill_timer_timeout)
	_update_fill_speed()
	canvas_fill_timer.start()
	
	# État initial de l'UI
	sell_button.disabled = true
	sell_button.pressed.connect(_on_sell_button_pressed)

#==============================================================================
# Logique du Canvas
#==============================================================================
func _initialize_new_canvas():
	var width = 32 * resolution_level
	var height = 32 * resolution_level
	max_pixels = width * height
	current_pixel_count = 0
	
	progress_bar.max_value = max_pixels
	progress_bar.value = 0
	
	unfilled_pixels.clear()
	for y in range(height):
		for x in range(width):
			unfilled_pixels.append(Vector2i(x, y))
	
	canvas_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	canvas_image.fill(Color.TRANSPARENT)
	canvas_texture = ImageTexture.create_from_image(canvas_image)
	canvas_display.texture = canvas_texture

func _on_canvas_fill_timer_timeout():
	if current_pixel_count >= max_pixels:
		if not sell_button.disabled:
			return # Déjà terminé

		print("Canvas terminé !")
		canvas_fill_timer.stop()
		sell_button.disabled = false
		return

	# Choisir un pixel au hasard
	var random_index = randi() % unfilled_pixels.size()
	var pixel_pos = unfilled_pixels.pop_at(random_index)
	
	# Dessiner le pixel
	canvas_image.set_pixelv(pixel_pos, Color(randf(), randf(), randf(), snapped(randf(), 0.01)))
	
	# Mettre à jour la texture
	canvas_texture.update(canvas_image)
	
	current_pixel_count += 1
	progress_bar.value = current_pixel_count

func _update_fill_speed():
	var speed = 1.0 / float(fill_speed_level)
	canvas_fill_timer.wait_time = speed

func _on_sell_button_pressed():
	print("Vente du canvas !")
	GameState.set_inspiration(sell_price)
	# TODO: Ajouter la logique pour donner les récompenses
	
	# Réinitialiser pour un nouveau canvas
	sell_button.disabled = true
	_initialize_new_canvas()
	canvas_fill_timer.start()
