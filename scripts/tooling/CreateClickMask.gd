@tool
extends TextureButton

func _ready() -> void:
# Vérifie si une texture normale est assignée
	if not texture_normal:
		return

# Vérifie si un masque existe déjà pour ne pas l'écraser
	if texture_click_mask:
		return

# Crée le masque de clics
	print("Tentative de création du masque de clics...")
	var image: Image = texture_normal.get_image()
	if not image:
		print("Impossible d'obtenir l'image de la texture.")
		return

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)

# Assigne le nouveau masque
	self.texture_click_mask = bitmap
	
	print("Masque de clics créé et assigné avec succès !")
