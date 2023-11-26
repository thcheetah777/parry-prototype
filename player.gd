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
@export var parry_knockback = 350

@export_group("Animation")
@export var stretch = 1.8
@export var squash = 1.8
@export var squash_stretch_smoothing = 5
@export var run_rotation_degrees = 30
@export var rotation_smoothing = 800
@export var parry_rotation_smoothing = 400

@onready var sprite := $Sprite

var state = MOVE
var original_scale = Vector2.ONE
var run_rotation = 0
var double_jump_rotation = 0
var can_double_jump = false
var dash_ghost_timer = 0

var touching_parryable: Parryable = null
var current_parryable: Parryable = null
var parry_angle = 0

func _ready():
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
	position = position.move_toward(current_parryable.position + direction * parry_distance, parry_rotation_smoothing * delta)

	if Input.is_action_just_released("parry") and current_parryable:
		end_parry()

func start_parry():
	print("start parry")
	velocity = Vector2.ZERO
	current_parryable = touching_parryable
	var direction = (position - current_parryable.position).normalized()
	parry_angle = rad_to_deg(direction.angle())
	state = PARRY

func end_parry():
	print("end parry")
	var direction = (position - current_parryable.position).normalized()
	velocity += direction * parry_knockback
	current_parryable = null
	state = MOVE

func _on_parry_area_area_entered(area: Area2D) -> void:
	if area is Parryable and not touching_parryable and not current_parryable:
		print("touched")
		touching_parryable = area

func _on_parry_area_area_exited(area: Area2D) -> void:
	if area == touching_parryable:
		print("exited")
		touching_parryable = null
