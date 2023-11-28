extends Parryable
class_name Bullet

var speed: float
var is_player_bullet = false

func _process(delta: float) -> void:
	var direction = Vector2.from_angle(deg_to_rad(rotation_degrees - 90))
	position += direction * speed * delta

func set_to_player_bullet():
	is_player_bullet = true
