extends Node2D

var target: Node2D
var damage: int = 25
var speed: float = 900.0
var max_lifetime: float = 2.0

var _age: float = 0.0
var _velocity: Vector2 = Vector2.ZERO


func setup(start_position: Vector2, target_node: Node2D, projectile_damage: int, projectile_speed: float) -> void:
	global_position = start_position
	target = target_node
	damage = projectile_damage
	speed = projectile_speed

	var target_position := _target_position()
	var direction := target_position - global_position
	if direction.length() < 1.0:
		direction = Vector2.RIGHT
	_velocity = direction.normalized() * speed
	rotation = _velocity.angle()


func _ready() -> void:
	z_index = 240
	z_as_relative = false

	var line := Line2D.new()
	line.name = "Trail"
	line.width = 4.0
	line.default_color = Color(0.35, 0.95, 1.0, 0.95)
	line.points = PackedVector2Array([Vector2(-13, 0), Vector2(10, 0)])
	add_child(line)


func _process(delta: float) -> void:
	_age += delta
	if _age >= max_lifetime:
		queue_free()
		return

	if is_instance_valid(target):
		var desired := _target_position() - global_position
		if desired.length() > 1.0:
			_velocity = _velocity.lerp(desired.normalized() * speed, clampf(delta * 5.0, 0.0, 1.0))
			rotation = _velocity.angle()

	global_position += _velocity * delta

	if not is_instance_valid(target):
		return

	if global_position.distance_to(_target_position()) <= 24.0:
		if target.has_method("apply_damage"):
			target.apply_damage(damage)
		queue_free()


func _target_position() -> Vector2:
	if not is_instance_valid(target):
		return global_position
	return target.global_position
