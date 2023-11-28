extends CharacterBody2D
class_name Player

enum { MOVE, PARRY }

@export_group("Movement")
@export var run_speed = 160
@export var jump_velocity = 300
@export var gravity = 980
@export var fall_gravity = 1200
@export var double_jump = false
@export var deceleration = 1000

@export_group("Parrying")
@export var parry_rotation_speed = 500
@export var parry_distance = 25
@export var parry_knockback = Vector2(400, 450)
@export var parry_bullet_speed = 200

@export_group("Animation")
@export var stretch = 1.8
@export var squash = 1.8
@export var squash_stretch_smoothing = 5
@export var run_rotation_degrees = 30
@export var rotation_smoothing = 800
@export var parry_rotation_smoothing = 400

@onready var sprite := $Sprite
@onready var arrow := $Arrow

var state = MOVE
var original_scale = Vector2.ONE
var run_rotation = 0
var double_jump_rotation = 0
var can_double_jump = false
var dash_ghost_timer = 0

var touching_parryable: Array[Parryable] = []
var current_parryable: Parryable = null
var parry_angle = 0

func _enter_tree() -> void:
	Globals.player = self

func _process(delta: float) -> void:
	sprite.scale = sprite.scale.move_toward(original_scale, squash_stretch_smoothing * delta)
	sprite.rotation_degrees = move_toward(sprite.rotation_degrees, run_rotation + double_jump_rotation, rotation_smoothing * delta)

func _physics_process(delta: float) -> void:
	var input := Input.get_axis("left", "right")

	match state:
		MOVE: move_state(input, delta)
		PARRY: parry_state(input, delta)

func move_state(input: float, delta: float):
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += fall_gravity * delta
		else:
			velocity.y += gravity * delta
	else:
		can_double_jump = true

	if input:
		run_rotation = input * run_rotation_degrees
		velocity.x = input * run_speed
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		run_rotation = 0

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = -jump_velocity
			sprite.scale = Vector2(original_scale.x / stretch, original_scale.y * stretch)
		else:
			if can_double_jump and double_jump:
				velocity.y = -jump_velocity
				double_jump_rotation += (1.0 if input == 0 else input) * 360
				can_double_jump = false

	if Input.is_action_just_pressed("parry") and touching_parryable:
		start_parry()

	var was_on_floor = is_on_floor()

	move_and_slide()

	if not was_on_floor and is_on_floor():
		sprite.scale = Vector2(original_scale.x * squash, original_scale.y / squash)

func parry_state(input: float, delta: float):
	parry_angle += input * parry_rotation_speed * delta
	var direction = (Vector2.RIGHT).rotated(deg_to_rad(parry_angle))
	set_arrow(direction)

	if Input.is_action_just_released("parry") and current_parryable:
		end_parry()

func start_parry():
	print("start parry")
	current_parryable = find_closest_parryable()
	arrow.visible = true
	velocity = Vector2.ZERO
	run_rotation = 0

	var direction = (position - current_parryable.position).normalized()
	parry_angle = rad_to_deg(direction.angle())
	set_arrow(direction)

	if current_parryable is Bullet:
		var bullet = current_parryable as Bullet
		bullet.set_to_player_bullet()
		bullet.speed = 0

	state = PARRY

func end_parry():
	print("end parry")
	arrow.visible = false
	var direction = (arrow.position - current_parryable.position).normalized()
	velocity += -direction * parry_knockback

	if current_parryable is Bullet:
		var bullet = current_parryable as Bullet
		bullet.rotation = arrow.rotation
		bullet.speed = parry_bullet_speed

	current_parryable = null
	state = MOVE

func set_arrow(direction: Vector2):
	arrow.position = current_parryable.position + -direction * parry_distance
	arrow.rotation_degrees = parry_angle - 90

func find_closest_parryable():
	touching_parryable.sort_custom(distance)
	return touching_parryable[0]

func distance(a: Parryable, b: Parryable):
	var a_distance = position.distance_to(a.position)
	var b_distance = position.distance_to(b.position)
	return a_distance - b_distance < 0

func _on_parry_area_area_entered(area: Area2D) -> void:
	print(area.name)
	if area is Parryable:
		print("touched")
		touching_parryable.append(area)

func _on_parry_area_area_exited(area: Area2D) -> void:
	if not area is Parryable: return
	var parryable_index = touching_parryable.find(area)
	if parryable_index != -1:
		print("exited")
		touching_parryable.remove_at(parryable_index)
