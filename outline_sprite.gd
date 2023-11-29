extends Sprite2D
class_name OutlineSprite2D

@export var outlined_texture: Texture2D

var original_texture = texture
var outline = false :
	set(value):
		outline = value
		set_outline()
	get:
		return outline

func set_outline():
	texture = outlined_texture if outline else original_texture
