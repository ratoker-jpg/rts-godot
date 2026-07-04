extends RefCounted
class_name Direction

# 16-направленное кодирование для модульных юнитов.
# Соответствует DIRECTIONS в combat_unit.gd и MODULAR_DIRECTIONS в game_world.gd.

const DIR_NAMES_16 := [
	"E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW",
	"W", "WNW", "NW", "NNW", "N", "NNE", "NE", "ENE"
]

# 4-connectivity для pathfinding (N→E→S→W, как в Phaser pathfinding.ts)
const DIRS_4 := [
	Vector2i(0, -1),  # N
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # S
	Vector2i(-1, 0),  # W
]

# Угол → 16-dir индекс (для поворота корпуса/башни).
# angle_rad: в радианах, 0 = East, PI/2 = South, -PI/2 = North, PI = West
static func angle_to_dir16(angle_rad: float) -> int:
	var raw := int(round(angle_rad / (TAU / 16.0)))
	return posmod(raw, 16)

# 4-dir delta → 16-dir индекс (для движения по сетке).
# В tile-пространстве (1,0)=East, (0,1)=South, (-1,0)=West, (0,-1)=North
static func grid_delta_to_dir16(delta: Vector2) -> int:
	if delta.length_squared() <= 0.0001:
		return 0  # default East
	var angle := atan2(delta.y, delta.x)
	return posmod(int(round(angle / (TAU / 16.0))), 16)

# Имя файла для текстуры модульного юнита.
# kind: "Hulls" или "Turrets"
# asset_id: "wasp", "hunter", "smoky", "railgun"
# faction_id: "cyan", "green", "purple", "yellow"
# mod_level: 0..3
# dir_index: 0..15
static func texture_path(kind: String, asset_id: String, faction_id: String, \
		mod_level: int, dir_index: int) -> String:
	var dir_name: String = DIR_NAMES_16[clampi(dir_index, 0, 15)]
	return "res://Assets/Units/%s/%s/%s/m%d/%s_%s_m%d_dir%02d_%s.png" % [
		kind, asset_id, faction_id, mod_level,
		asset_id, faction_id, mod_level, dir_index, dir_name
	]

# Определить 4-направление (N/E/S/W) из дельты между клетками.
static func direction_from_to(from: Vector2i, to: Vector2i) -> String:
	var dx := to.x - from.x
	var dy := to.y - from.y
	if dy < 0 and dx == 0:
		return "N"
	if dx > 0 and dy == 0:
		return "E"
	if dy > 0 and dx == 0:
		return "S"
	if dx < 0 and dy == 0:
		return "W"
	return "none"

# 4-направление → угол в радианах (для поворота корпуса).
static func direction_to_angle(dir: String) -> float:
	match dir:
		"N":
			return -PI / 2
		"E":
			return 0
		"S":
			return PI / 2
		"W":
			return PI
	return 0

# Нормализовать угол в диапазон [-PI, PI].
static func normalize_angle(angle: float) -> float:
	while angle > PI:
		angle -= 2 * PI
	while angle < -PI:
		angle += 2 * PI
	return angle

# Плавно повернуть current к target с максимальным шагом max_delta.
static func rotate_toward(current: float, target: float, max_delta: float) -> float:
	var diff := normalize_angle(target - current)
	if abs(diff) <= max_delta:
		return target
	return current + signf(diff) * max_delta
