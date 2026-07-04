extends Node2D
class_name Projectile

# Снаряд с homing-поведением и поддержкой pierce (для railgun).
# Соответствует src/state/blockoutWeaponVfx.ts + combatHitModel.ts из four-elements-phaser.

var target: Node2D
var damage: int = 25
var speed: float = 900.0
var max_lifetime: float = 2.0
var pierce_count: int = 1  # 1 = обычный снаряд, 3 = railgun pierce
var weapon_id: String = "smoky"
var faction_id: String = "cyan"  # для цвета следа

var _age: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _hit_targets: Array[Node2D] = []  # для pierce — цели, по которым уже попали


func setup(start_position: Vector2, target_node: Node2D, projectile_damage: int, \
		projectile_speed: float, pierce: int = 1) -> void:
	global_position = start_position
	target = target_node
	damage = projectile_damage
	speed = projectile_speed
	pierce_count = maxi(pierce, 1)

	var target_position := _target_position()
	var direction := target_position - global_position
	if direction.length() < 1.0:
		direction = Vector2.RIGHT
	_velocity = direction.normalized() * speed
	rotation = _velocity.angle()


func setup_with_faction(start_position: Vector2, target_node: Node2D, projectile_damage: int, \
		projectile_speed: float, pierce: int, faction: String) -> void:
	faction_id = faction
	setup(start_position, target_node, projectile_damage, projectile_speed, pierce)


func _ready() -> void:
	z_index = 240
	z_as_relative = false

	var line := Line2D.new()
	line.name = "Trail"
	line.width = 4.0
	# Цвет зависит от фракции стреляющего
	line.default_color = _faction_trail_color(faction_id)
	line.points = PackedVector2Array([Vector2(-13, 0), Vector2(10, 0)])
	add_child(line)


func _faction_trail_color(faction: String) -> Color:
	match faction:
		"cyan":
			return Color(0.35, 0.95, 1.0, 0.95)
		"green":
			return Color(0.35, 0.95, 0.4, 0.95)
		"yellow":
			return Color(0.95, 0.85, 0.2, 0.95)
		"purple":
			return Color(0.7, 0.4, 0.95, 0.95)
	return Color(0.35, 0.95, 1.0, 0.95)


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
		# Если цель уничтожена и pierce не исчерпан — летим дальше по инерции до max_lifetime
		if _hit_targets.size() >= pierce_count:
			queue_free()
		return

	# Проверка попадания
	if global_position.distance_to(_target_position()) <= 24.0:
		# Если цель уже была в списке попаданий — не наносим урон повторно
		if not _hit_targets.has(target):
			if target.has_method("apply_damage"):
				target.apply_damage(damage)
			_hit_targets.append(target)
		# Если pierce исчерпан — удалить снаряд
		if _hit_targets.size() >= pierce_count:
			queue_free()
			return
		# Иначе летим дальше (pierce) — но нужно найти следующую цель
		# Для простоты: если pierce > 1 и цель уничтожена, продолжаем по инерции
		if not is_instance_valid(target):
			# Цель исчезла — летим прямо ещё max_lifetime секунд
			target = null
		else:
			# Цель ещё жива — pierce не должен проходить сквозь одну цель многократно
			# Удаляем снаряд
			queue_free()
			return


func _target_position() -> Vector2:
	if not is_instance_valid(target):
		return global_position
	return target.global_position
