extends RefCounted
class_name CombatRange

# Range bands для боевой системы.
# Соответствует src/state/combatRange.ts из four-elements-phaser.

enum RangeBand {
	POINT_BLANK,  # цель очень близко (< minRange)
	IN_RANGE,     # цель между minRange и maxRange
	AT_STOP,      # цель на stopDistance (идеальная дистанция)
	OUT_OF_RANGE, # цель вне maxRange — нужно приблизиться
}

const Constants := preload("res://Scripts/core/constants.gd")


# Вычислить дистанцию на плоскости тайлов.
static func ground_distance_tiles(a_pos: Vector2, b_pos: Vector2) -> float:
	return a_pos.distance_to(b_pos)


# Определить range band между атакующим и целью.
# Возвращает Dictionary с ключами:
#   band (int - RangeBand), distance (float), min_range, max_range, stop_distance
static func check_range_band(
		attacker_pos: Vector2,
		target_pos: Vector2,
		min_range: float,
		ideal_range: float,
		max_range: float,
		stop_distance: float
	) -> Dictionary:
	var dist := ground_distance_tiles(attacker_pos, target_pos)
	var band: int
	if dist <= Constants.POINT_BLANK_RANGE_TILES or dist < min_range:
		band = RangeBand.POINT_BLANK
	elif dist <= max_range + Constants.RANGE_TOLERANCE_TILES:
		if dist >= stop_distance - Constants.RANGE_TOLERANCE_TILES \
				and dist <= stop_distance + Constants.RANGE_TOLERANCE_TILES:
			band = RangeBand.AT_STOP
		else:
			band = RangeBand.IN_RANGE
	else:
		band = RangeBand.OUT_OF_RANGE
	return {
		"band": band,
		"distance": dist,
		"min_range": min_range,
		"ideal_range": ideal_range,
		"max_range": max_range,
		"stop_distance": stop_distance,
	}


# Находится ли атакующий в дистанции остановки?
static func is_at_stop_distance(attacker_pos: Vector2, target_pos: Vector2, stop_distance: float) -> bool:
	return ground_distance_tiles(attacker_pos, target_pos) <= stop_distance + Constants.RANGE_TOLERANCE_TILES


# Находится ли цель в зоне поражения?
static func is_in_range(attacker_pos: Vector2, target_pos: Vector2, max_range: float) -> bool:
	return ground_distance_tiles(attacker_pos, target_pos) <= max_range + Constants.RANGE_TOLERANCE_TILES


# Вычислить точку преследования (stop_distance от цели по направлению к атакующему).
# Используется для auto-chase.
static func get_chase_target_tile(
		attacker_pos: Vector2,
		target_pos: Vector2,
		stop_distance: float
	) -> Vector2i:
	var dist := ground_distance_tiles(attacker_pos, target_pos)
	if dist <= stop_distance + Constants.RANGE_TOLERANCE_TILES:
		# Уже в дистанции остановки — стоим
		return Vector2i(roundi(attacker_pos.x), roundi(attacker_pos.y))

	if dist < 0.01:
		return Vector2i(roundi(attacker_pos.x), roundi(attacker_pos.y))

	# Точка на stop_distance от цели по направлению к атакующему
	var dx := attacker_pos.x - target_pos.x
	var dy := attacker_pos.y - target_pos.y
	var stop_x := target_pos.x + (dx / dist) * stop_distance
	var stop_y := target_pos.y + (dy / dist) * stop_distance
	return Vector2i(roundi(stop_x), roundi(stop_y))
