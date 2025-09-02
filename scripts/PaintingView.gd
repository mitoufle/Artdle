extends Control

# Variables locales pour le coût et la génération
var Painting_incrementer: float = 1
var atelier_count: int = 0
var atelier_cost: int = 10
var atelier_production: float = 0.2   # inspiration/sec/atelier
var enhanseInspiCost: int = 50 
#var painting_screen_scene = preload("res://views/paintingscreen.tscn")
var painting_screen_instance
var blinking = false
var hover = false
var tooltip_txt = "Workshop"



@onready var tooltip_scene = preload("res://Scenes/CustomTooltip.tscn")
@onready var painting_screen_scene = preload("res://Scenes/paintingscreen.tscn")
@onready var btn_peindre: Button = $BtnAddInspiration
@onready var btn_atelier: Button = $BtnBuildStuff
@onready var btn_enhancePainting: Button = $BtnEnhancePainting

func _ready() -> void:

	 # instancie PaintingScreen dans le control node
	painting_screen_instance = painting_screen_scene.instantiate()
	add_child(painting_screen_instance)
	
	# stop l'animation tant qu'on a pas assez d'argent pour acheter l'atelier
	painting_screen_instance.get_node("workshop_blink_sign").stop()
	painting_screen_instance.get_node("workshop_blink_sign").frame = 0
	
	# connecte la boutons à leurs fonctions
	btn_peindre.pressed.connect(_on_btn_peindre_pressed)
	btn_atelier.pressed.connect(_on_btn_atelier_pressed)
	btn_enhancePainting.pressed.connect(_on_btn_enhancepainting_pressed)
	
	btn_atelier.mouse_entered.connect(_on_btn_atelier_entered)
	btn_atelier.mouse_exited.connect(_on_btn_atelier_exited)
	
	var anim = painting_screen_instance.get_node("workshop_blink_sign")
	anim.frame = 0
	update_ui() 

func _process(delta: float) -> void:
	
	var anim = painting_screen_instance.get_node("workshop_blink_sign")
	
	# Production automatique par atelier
	if atelier_count > 0:
		GameState.set_inspiration(atelier_count * atelier_production * delta)
		
	# reset l'état du blink du paneau
	if GameState.inspiration >= 10 and not hover:
		tooltip_txt="Wah, mais en fait tu es Yann! achete cet atelier pour 10 Balles, quasiment rien pour toi!"
		if not blinking:
			anim.play()
			blinking = true
	else:
		if blinking:
			anim.stop()
			anim.frame = 0
			blinking = false
			
	# Met à jour l'UI chaque frame
	update_ui()

func _on_btn_peindre_pressed() -> void:
	var main_node = get_tree().get_root().get_node("Main")
	main_node.add_ressource_feedback()
	GameState.set_inspiration(Painting_incrementer)
	update_ui()

func _on_btn_enhancepainting_pressed() -> void:
	if GameState.inspiration >= enhanseInspiCost:
		GameState.update_inspiration(-enhanseInspiCost)
		enhanseInspiCost = enhanseInspiCost * 1.6
		GameState.enhanceInspi *= 2
	update_ui()

func _on_btn_atelier_pressed() -> void:
	
	if GameState.inspiration >= atelier_cost:
		GameState.inspiration -= atelier_cost
		atelier_count += 1
		atelier_cost = int(atelier_cost * 1.5) # le coût augmente
		update_ui()

func _on_btn_atelier_entered() -> void:
	
	TooltipManager.show_tooltip(tooltip_txt, "10$",btn_atelier.global_position)
		
	var anim = painting_screen_instance.get_node("workshop_blink_sign")
	hover = true
	anim.stop()
	anim.frame = 1
	blinking = false

func _on_btn_atelier_exited() -> void:
	
	TooltipManager.hide_tooltip()
	
	var anim = painting_screen_instance.get_node("workshop_blink_sign")
	
	hover = false
	anim.stop()
	anim.frame = 0
	blinking = false

func update_ui() -> void:

	btn_peindre.text = "Peindre (+1)"
	btn_enhancePainting.text = "enhance painting (" + str(int(enhanseInspiCost)) + "inspi)"

func show_floating_text(text: String):
	var label = Label.new()
	label.text = text
	label.modulate = Color(1, 1, 1, 1) # blanc opaque
	label.position = position
	
	add_child(label)

	var tween = get_tree().create_tween()
	tween.tween_property(label, "position", position + Vector2(0, -50), 0.8) # monte de 50px en 0.8s
	tween.tween_property(label, "modulate:a", 0.0, 0.8) # disparaît en fondu
	
	# supprimer le label quand l’animation est finie
	tween.finished.connect(func():
		label.queue_free()
	)
