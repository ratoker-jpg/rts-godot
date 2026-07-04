extends RefCounted
class_name MovementStateMachine

# Unified grid movement state machine.
# Соответствует src/state/movementStateMachine.ts из four-elements-phaser.
# Все наземные юниты (builder, harvester, combat_unit) используют эту же машину.
# Движение по сетке через центры тайлов с физическим поворотом, accel/braking,
# сглаживанием дуг и tile reservation.
#
# Принцип "Battle of Azer":
# - Все юниты двигаются по сетке через центры тайлов (нет свободного arcade-движения).
# - Физический поворот корпуса к направлению следующего сегмента.
# - Ускорение и торможение из конфига корпуса.
# - Tile reservation для предотвращения наложения юнитов.

enum Phase {
	IDLE,
	PATH_REQUESTED,
	TURNING_TO_SEGMENT,
	MOVING_SEGMENT,
	BRAKING,
	NEXT_SEGMENT,
	STOPPING,
	BLOCKED,
	REPATHING,
	TARGET_CHASE,
	ATTACKING,
}

const Constants := preload("res://Scripts/core/constants.gd")
const Direction := preload("res://Scripts/utils/direction.gd")
const Pathfinding := preload("res://Scripts/core/pathfinding.gd")


class GridMovementConfig:
	var max_speed_tiles_per_sec: float
	var acceleration_tiles_per_sec2: float
	var braking_tiles_per_sec2: float
	var turn_speed_deg: float
	var arrival_threshold: float = Constants.DEFAULT_ARRIVAL_THRESHOLD

	func _init(
			max_speed: float = 3.0,
			accel: float = 8.0,
			braking: float = 6.0,
			turn_deg: float = 120.0,
			threshold: float = Constants.DEFAULT_ARRIVAL_THRESHOLD
		) -> void:
		max_speed_tiles_per_sec = max_speed
		acceleration_tiles_per_sec2 = accel
		braking_tiles_per_sec2 = braking
		turn_speed_deg = turn_deg
		arrival_threshold = threshold


class GridMovementState:
	var phase: int = Phase.IDLE
	var path: Array[Vector2i] = []
	var path_index: int = 0
	var ftx: float = 0.0  # fractional tile X
	var fty: float = 0.0  # fractional tile Y
	var body_angle: float = 0.0  # radians
	var speed: float = 0.0  # tiles/sec
	var current_tile: Vector2i = Vector2i.ZERO
	var reserved_tile: Vector2i = Vector2i(-1, -1)
	var wait_started_at_ms: int = 0
	var repath_attempts: int = 0
	var current_direction: String = "none"  # N/E/S/W/none
	var smoothing_active: bool = false
	var smoothing_progress: float = 0.0
	var target_tile: Vector2i = Vector2i.ZERO

	func _init(tx: int = 0, ty: int = 0, angle: float = PI / 2) -> void:
		ftx = float(tx)
		fty = float(ty)
		current_tile = Vector2i(tx, ty)
		target_tile = Vector2i(tx, ty)
		body_angle = angle

	func fractional_pos() -> Vector2:
		return Vector2(ftx, fty)

	func round_tile() -> Vector2i:
		return Vector2i(roundi(ftx), roundi(fty))


# ─── Публичные команды ────────────────────────────────

# Подать команду движения по пути.
static func issue_move_command(
		state: GridMovementState,
		path: Array[Vector2i],
		target: Vector2i
	) -> void:
	state.path = path
	state.path_index = 0
	state.target_tile = target
	state.phase = Phase.PATH_REQUESTED
	state.repath_attempts = 0
	state.speed = 0.0


# Подать команду остановки.
static func issue_stop_command(
		state: GridMovementState,
		reservation_map: TileReservationMap,
		unit_id: String
	) -> void:
	if state.phase == Phase.IDLE:
		return
	state.phase = Phase.STOPPING
	state.path = []
	state.path_index = 0
	state.target_tile = Vector2i(roundi(state.ftx), roundi(state.fty))
	_release_reservation(state, reservation_map, unit_id)


# ─── Главный update ───────────────────────────────────

# Обновить движение юнита на один кадр.
# occupancy: OccupancyMap
# reservation_map: TileReservationMap
# get_occupancy_for_repath: Callable () -> OccupancyMap (для repath)
# Возвращает Dictionary с ключами: phase (int), arrived (bool), blocked (bool), feedback (String).
static func update(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		occupancy: OccupancyMap,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	var dt := float(delta_ms) / 1000.0

	match state.phase:
		Phase.IDLE:
			return {"phase": Phase.IDLE, "arrived": false, "blocked": false, "feedback": ""}

		Phase.PATH_REQUESTED:
			if state.path.is_empty():
				state.phase = Phase.IDLE
				return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}
			state.phase = Phase.TURNING_TO_SEGMENT
			state.path_index = 0
			state.repath_attempts = 0
			return update(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

		Phase.TURNING_TO_SEGMENT:
			return _handle_turning(state, config, delta_ms, reservation_map, unit_id, now_ms)

		Phase.MOVING_SEGMENT:
			return _handle_moving(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

		Phase.BRAKING:
			return _handle_braking(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

		Phase.NEXT_SEGMENT:
			return _advance_to_next_segment(state, config, reservation_map, unit_id)

		Phase.STOPPING:
			return _handle_stopping(state, config, delta_ms, reservation_map, unit_id)

		Phase.BLOCKED:
			return _handle_blocked(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

		Phase.REPATHING:
			return _handle_repathing(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

		Phase.TARGET_CHASE, Phase.ATTACKING:
			# Управляется боевой системой
			return {"phase": state.phase, "arrived": false, "blocked": false, "feedback": ""}

	return {"phase": Phase.IDLE, "arrived": false, "blocked": false, "feedback": ""}


# ─── Внутренние хендлеры ──────────────────────────────

static func _handle_turning(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int
	) -> Dictionary:
	if state.path_index >= state.path.size():
		state.phase = Phase.IDLE
		state.speed = 0.0
		return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}

	var waypoint: Vector2i = state.path[state.path_index]
	var dir := Direction.direction_from_to(state.current_tile, waypoint)
	var desired_angle := Direction.direction_to_angle(dir)
	var max_turn_rad := deg_to_rad(config.turn_speed_deg) * float(delta_ms) / 1000.0
	var new_angle := Direction.rotate_toward(state.body_angle, desired_angle, max_turn_rad)
	state.body_angle = new_angle
	state.current_direction = dir

	var angle_diff := abs(Direction.normalize_angle(new_angle - desired_angle))
	if angle_diff < Constants.TURRET_AIM_TOLERANCE_RAD:  # ~3°
		state.body_angle = desired_angle  # snap

		# Резервируем следующий тайл
		var holder := TileReservationMap.ReservationHolder.new(unit_id, "unit")
		if reservation_map.reserve(waypoint.x, waypoint.y, holder, now_ms):
			state.reserved_tile = waypoint
			state.phase = Phase.MOVING_SEGMENT
		else:
			# Тайл занят другим юнитом — ждём
			state.phase = Phase.BLOCKED
			state.wait_started_at_ms = now_ms
			state.repath_attempts = 0
			return {"phase": Phase.BLOCKED, "arrived": false, "blocked": true, "feedback": "Заблокирован: тайл занят"}

	return {"phase": state.phase, "arrived": false, "blocked": false, "feedback": ""}


static func _handle_moving(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		occupancy: OccupancyMap,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	if state.path_index >= state.path.size():
		state.phase = Phase.IDLE
		state.speed = 0.0
		return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}

	var waypoint: Vector2i = state.path[state.path_index]
	var dx := float(waypoint.x) - state.ftx
	var dy := float(waypoint.y) - state.fty
	var dist := sqrt(dx * dx + dy * dy)

	# Тормозной путь: v² / (2 * braking)
	var stopping_dist := 0.0
	if state.speed > 0:
		stopping_dist = (state.speed * state.speed) / (2.0 * config.braking_tiles_per_sec2)

	if dist <= stopping_dist + config.arrival_threshold:
		state.phase = Phase.BRAKING
		return update(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)

	# Ускоряемся
	var dt := float(delta_ms) / 1000.0
	var accel_amount := config.acceleration_tiles_per_sec2 * dt
	state.speed = minf(config.max_speed_tiles_per_sec, state.speed + accel_amount)

	# Двигаемся
	var step := state.speed * dt
	var move_dist := minf(step, dist)
	if dist > 0:
		state.ftx += (dx / dist) * move_dist
		state.fty += (dy / dist) * move_dist

	# Проверка прибытия
	var new_dx := float(waypoint.x) - state.ftx
	var new_dy := float(waypoint.y) - state.fty
	var new_dist := sqrt(new_dx * new_dx + new_dy * new_dy)
	if new_dist <= config.arrival_threshold:
		return _advance_to_next_segment(state, config, reservation_map, unit_id)

	return {"phase": Phase.MOVING_SEGMENT, "arrived": false, "blocked": false, "feedback": ""}


static func _handle_braking(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		occupancy: OccupancyMap,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	if state.path_index >= state.path.size():
		state.phase = Phase.IDLE
		state.speed = 0.0
		return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}

	var dt := float(delta_ms) / 1000.0
	var brake_amount := config.braking_tiles_per_sec2 * dt
	state.speed = maxf(0.0, state.speed - brake_amount)

	var waypoint: Vector2i = state.path[state.path_index]
	var dx := float(waypoint.x) - state.ftx
	var dy := float(waypoint.y) - state.fty
	var dist := sqrt(dx * dx + dy * dy)
	if dist > 0 and state.speed > 0:
		var step := state.speed * dt
		var move_dist := minf(step, dist)
		state.ftx += (dx / dist) * move_dist
		state.fty += (dy / dist) * move_dist

	var new_dx := float(waypoint.x) - state.ftx
	var new_dy := float(waypoint.y) - state.fty
	var new_dist := sqrt(new_dx * new_dx + new_dy * new_dy)
	if new_dist <= config.arrival_threshold or state.speed <= 0:
		return _advance_to_next_segment(state, config, reservation_map, unit_id)

	return {"phase": Phase.BRAKING, "arrived": false, "blocked": false, "feedback": ""}


static func _advance_to_next_segment(
		state: GridMovementState,
		config: GridMovementConfig,
		reservation_map: TileReservationMap,
		unit_id: String
	) -> Dictionary:
	if state.path_index >= state.path.size():
		state.phase = Phase.IDLE
		state.speed = 0.0
		state.ftx = float(state.current_tile.x)
		state.fty = float(state.current_tile.y)
		_release_reservation(state, reservation_map, unit_id)
		return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}

	var waypoint: Vector2i = state.path[state.path_index]
	state.ftx = float(waypoint.x)
	state.fty = float(waypoint.y)
	state.current_tile = waypoint
	_release_reservation(state, reservation_map, unit_id)
	state.path_index += 1

	if state.path_index >= state.path.size():
		state.phase = Phase.IDLE
		state.speed = 0.0
		return {"phase": Phase.IDLE, "arrived": true, "blocked": false, "feedback": ""}

	state.phase = Phase.TURNING_TO_SEGMENT
	return {"phase": Phase.TURNING_TO_SEGMENT, "arrived": false, "blocked": false, "feedback": ""}


static func _handle_stopping(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		reservation_map: TileReservationMap,
		unit_id: String
	) -> Dictionary:
	var dt := float(delta_ms) / 1000.0
	var brake_amount := config.braking_tiles_per_sec2 * dt
	state.speed = maxf(0.0, state.speed - brake_amount)
	if state.speed <= 0:
		state.speed = 0
		state.phase = Phase.IDLE
		_release_reservation(state, reservation_map, unit_id)
		return {"phase": Phase.IDLE, "arrived": false, "blocked": false, "feedback": ""}
	if state.speed > 0:
		var step := state.speed * dt
		state.ftx += cos(state.body_angle) * step * 0.7
		state.fty += sin(state.body_angle) * step * 0.7
	return {"phase": Phase.STOPPING, "arrived": false, "blocked": false, "feedback": ""}


static func _handle_blocked(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		occupancy: OccupancyMap,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	var wait_duration := now_ms - state.wait_started_at_ms
	if wait_duration >= Constants.WAIT_BEFORE_REPATH_MS:
		state.phase = Phase.REPATHING
		state.repath_attempts += 1
		return update(state, config, delta_ms, occupancy, reservation_map, unit_id, now_ms, get_occupancy_for_repath)
	return {"phase": Phase.BLOCKED, "arrived": false, "blocked": true, "feedback": "Ожидание: тайл занят"}


static func _handle_repathing(
		state: GridMovementState,
		config: GridMovementConfig,
		delta_ms: int,
		occupancy: OccupancyMap,
		reservation_map: TileReservationMap,
		unit_id: String,
		now_ms: int,
		get_occupancy_for_repath: Callable
	) -> Dictionary:
	if state.repath_attempts > Constants.MAX_REPATH_ATTEMPTS:
		state.phase = Phase.BLOCKED
		state.speed = 0.0
		return {"phase": Phase.BLOCKED, "arrived": false, "blocked": true, "feedback": "Заблокирован: нет пути"}

	var fresh_occupancy: OccupancyMap = get_occupancy_for_repath.call()
	var new_path := Pathfinding.find_path(
		fresh_occupancy,
		Vector2i(roundi(state.ftx), roundi(state.fty)),
		state.target_tile
	)
	if new_path.size() > 0:
		state.path = new_path
		state.path_index = 0
		state.phase = Phase.TURNING_TO_SEGMENT
		_release_reservation(state, reservation_map, unit_id)
		return {"phase": Phase.TURNING_TO_SEGMENT, "arrived": false, "blocked": false, "feedback": ""}

	state.phase = Phase.BLOCKED
	state.speed = 0.0
	return {"phase": Phase.BLOCKED, "arrived": false, "blocked": true, "feedback": "Заблокирован: нет пути"}


# ─── Внутренние хелперы ───────────────────────────────

static func _release_reservation(
		state: GridMovementState,
		reservation_map: TileReservationMap,
		unit_id: String
	) -> void:
	if state.reserved_tile.x >= 0 and state.reserved_tile.y >= 0:
		reservation_map.release(state.reserved_tile.x, state.reserved_tile.y, unit_id)
		state.reserved_tile = Vector2i(-1, -1)
	reservation_map.release_all(unit_id)
