extends Parryable
class_name Bullet

var speed: float

func _process(delta: float) -> void:
	var direction = Vector2.from_angle(deg_to_rad(rotation_degrees - 90))
	position += direction * speed * delta
