extends RefCounted
class_name CombatTargeting

# Боевой AI: target-lock, range bands, auto-chase, auto-fire.
# Соответствует src/state/combatTargeting.ts из four-elements-phaser.
#
# Логика:
# 1. RMB на враге → устанавливает target-lock (в combat_unit.gd).
# 2. Каждый кадр: проверяем range band.
# 3. Если OUT_OF_RANGE → auto-chase (через MovementStateMachine).
# 4. Если IN_RANGE / AT_STOP / POINT_BLANK → остановиться и стрелять когда turret наведена.
# 5. Turret поворачивается к цели (не к мышке) пока есть target-lock.
# 6. S key очищает target-lock и останавливает преследование.

const Constants := preload("res://Scripts/core/constants.gd")
const Direction := preload("res://Scripts/utils/direction.gd")
const CombatRange := preload("res://Scripts/core/combat_range.gd")
const Pathfinding := preload("res://Scripts/core/pathfinding.gd")
const MovementStateMachine := preload("res://Scripts/core/movement_state_machine.gd")


# Обновить боевой AI для одного юнита с активным target-lock.
# vehicle: CombatUnit (Node2D с полями grid_movement, attack_target, turret_angle, etc.)
# target: Node2D цели (combat_unit или destructible_environment или building)
# now_ms: Time.get_ticks_msec()
# delta_ms: кадр в мс
# get_occupancy_for_repath: Callable () -> OccupancyMap
static func update_combat_for_vehicle(
		vehicle: Node,
		target: Node,
		now_ms: int,
		delta_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	if not is_instance_valid(target):
		_clear_target_lock(vehicle)
		return {"intent": "none", "band": CombatRange.RangeBand.OUT_OF_RANGE}

	# Получаем позиции в tile-координатах
	var attacker_pos: Vector2 = vehicle.grid_movement.fractional_pos()
	var target_pos: Vector2
	if target.has_method("get") and target.get("grid_movement") != null:
		target_pos = target.grid_movement.fractional_pos()
	else:
		# Для зданий/ресурсов без grid_movement — берём global_position
		# и конвертируем в tile (приблизительно)
		target_pos = target.global_position

	# Получаем range stats из turret конфига
	var range_info := CombatRange.check_range_band(
		attacker_pos,
		target_pos,
		float(vehicle.call("_turret_stat", "range_min")),
		float(vehicle.call("_turret_stat", "range_ideal")),
		float(vehicle.call("_turret_stat", "range_max")),
		float(vehicle.call("_turret_stat", "stop_distance"))
	)

	# Turret aim toward target
	var target_angle := atan2(target_pos.y - attacker_pos.y, target_pos.x - attacker_pos.x)
	vehicle.turret_target_angle = target_angle
	var aimed := _is_turret_aimed(vehicle, target_angle)

	# Поведение по range band
	var intent: String
	var should_stop := false
	var should_fire := false

	match range_info["band"]:
		CombatRange.RangeBand.POINT_BLANK:
			intent = "point_blank"
			should_stop = true
			should_fire = aimed

		CombatRange.RangeBand.IN_RANGE, CombatRange.RangeBand.AT_STOP:
			intent = "in_range"
			if CombatRange.is_at_stop_distance(attacker_pos, target_pos,
					float(vehicle.call("_turret_stat", "stop_distance"))):
				should_stop = true
			should_fire = aimed

		CombatRange.RangeBand.OUT_OF_RANGE:
			intent = "approaching"
			should_stop = false
			should_fire = false

	# Drive movement based on combat result
	if intent == "approaching":
		_issue_chase(vehicle, target, now_ms, get_occupancy_for_repath)
	elif should_stop:
		if vehicle.grid_movement.phase != MovementStateMachine.Phase.IDLE \
				and vehicle.grid_movement.phase != MovementStateMachine.Phase.STOPPING:
			MovementStateMachine.issue_stop_command(
				vehicle.grid_movement,
				vehicle._reservation_map,
				vehicle.name
			)

	# Auto-fire when shouldFire and turret aimed
	if should_fire and aimed:
		vehicle.call("try_fire_weapon", target, now_ms)

	return {
		"intent": intent,
		"band": range_info["band"],
		"distance": range_info["distance"],
		"aimed": aimed,
	}


# Подать команду преследования.
static func _issue_chase(
		vehicle: Node,
		target: Node,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> void:
	var attacker_pos: Vector2 = vehicle.grid_movement.fractional_pos()
	var target_pos: Vector2
	if target.has_method("get") and target.get("grid_movement") != null:
		target_pos = target.grid_movement.fractional_pos()
	else:
		target_pos = target.global_position

	var chase_tile := CombatRange.get_chase_target_tile(
		attacker_pos,
		target_pos,
		float(vehicle.call("_turret_stat", "stop_distance"))
	)

	# Если уже преследуем эту цель — не подаём новую команду
	var gm = vehicle.grid_movement
	if gm.phase == MovementStateMachine.Phase.TARGET_CHASE:
		if abs(gm.target_tile.x - chase_tile.x) <= 1 \
				and abs(gm.target_tile.y - chase_tile.y) <= 1:
			return

	var occupancy: OccupancyMap = get_occupancy_for_repath.call()
	var from := Vector2i(roundi(gm.ftx), roundi(gm.fty))
	var path := Pathfinding.find_path(occupancy, from, chase_tile)
	if path.is_empty():
		path = Pathfinding.find_path_to_adjacent(occupancy, from, chase_tile, 1, 1)
	if path.size() > 0:
		gm.phase = MovementStateMachine.Phase.TARGET_CHASE
		MovementStateMachine.issue_move_command(gm, path, chase_tile)


# Проверить, наведена ли башня.
static func _is_turret_aimed(vehicle: Node, target_angle: float) -> bool:
	var diff := Direction.normalize_angle(vehicle.turret_angle - target_angle)
	return abs(diff) < Constants.TURRET_AIM_TOLERANCE_RAD


# Очистить target-lock.
static func _clear_target_lock(vehicle: Node) -> void:
	vehicle.attack_target = null
	# Сбросить turret в rest position (параллельно корпусу)
	if vehicle.has_method("get"):
		vehicle.turret_target_angle = vehicle.grid_movement.body_angle


# Полная очистка: target + stop chase + cancel weapon pending states.
static func clear_target_and_stop(vehicle: Node) -> void:
	_clear_target_lock(vehicle)
	if vehicle.has_method("get") and vehicle.get("grid_movement") != null:
		MovementStateMachine.issue_stop_command(
			vehicle.grid_movement,
			vehicle._reservation_map,
			vehicle.name
		)
