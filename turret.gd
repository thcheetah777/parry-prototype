extends Area2D

@export var angle_range = 45
@export var bullet_speed = 50

@onready var gun := $Gun
@onready var fire_point := $Gun/FirePoint
@onready var fire_timer := $FireTimer

var target_angle = 0
var bullet_scene = preload("res://bullet.tscn")

func _ready() -> void:
	target_angle = randf_range(-angle_range, angle_range)

func _process(_delta: float) -> void:
	gun.rotation_degrees = move_toward(gun.rotation_degrees, target_angle, fire_timer.wait_time)

func _on_fire_timer_timeout() -> void:
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.global_position = fire_point.global_position
	bullet.speed = bullet_speed
	bullet.rotation = gun.rotation
	Globals.world.add_child(bullet)
	target_angle = randf_range(-angle_range, angle_range)
