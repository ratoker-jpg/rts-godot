extends RefCounted
class_name Pathfinding

# BFS 4-connectivity pathfinding.
# Соответствует src/state/pathfinding.ts из four-elements-phaser.
# 4 направления: N → E → S → W (детерминированный порядок).
# Возвращает массив тайлов БЕЗ стартового (как в Phaser).

const DIRS_4 := [
	Vector2i(0, -1),  # N
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # S
	Vector2i(-1, 0),  # W
]


# Найти кратчайший путь от (from) к (to).
# Возвращает массив тайлов (Vector2i) БЕЗ стартового.
# Пустой массив если: цель непроходима, недостижима, или from == to.
static func find_path(
		occupancy: OccupancyMap,
		from: Vector2i,
		to: Vector2i
	) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not occupancy.is_passable(to.x, to.y):
		return result
	if not occupancy.is_in_bounds(from.x, from.y):
		return result
	if from == to:
		return result

	var w := occupancy.width
	var start_key := _flat_key(from.x, from.y, w)
	var dest_key := _flat_key(to.x, to.y, w)

	# parent map: child_key → parent_key (-1 для start)
	var visited: Dictionary = {}
	visited[start_key] = -1

	# BFS queue с индексом head (вместо pop_front O(N))
	var queue: PackedInt64Array = PackedInt64Array()
	queue.append(start_key)
	var head := 0

	while head < queue.size():
		var ck: int = queue[head]
		head += 1
		var cx: int = ck % w
		var cy: int = int(ck / w)

		for d in DIRS_4:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if not occupancy.is_in_bounds(nx, ny):
				continue
			var nk := _flat_key(nx, ny, w)
			if visited.has(nk):
				continue
			if not occupancy.is_passable(nx, ny):
				continue
			visited[nk] = ck
			if nk == dest_key:
				return _reconstruct_path(visited, nk, start_key, w)
			queue.append(nk)

	return result  # unreachable


# Найти путь к тайлу, смежному с footprint'ом.
# Используется харвестером (подойти к ресурсу) и билдером (подойти к стройплощадке).
# Возвращает массив тайлов БЕЗ стартового. Пустой массив если уже смежный или недостижимо.
static func find_path_to_adjacent(
		occupancy: OccupancyMap,
		from: Vector2i,
		target_origin: Vector2i,
		fp_w: int,
		fp_h: int
	) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not occupancy.is_in_bounds(from.x, from.y):
		return result
	if _is_adjacent_to_footprint(from, target_origin, fp_w, fp_h):
		return result

	var w := occupancy.width
	var start_key := _flat_key(from.x, from.y, w)
	var visited: Dictionary = {}
	visited[start_key] = -1
	var queue: PackedInt64Array = PackedInt64Array()
	queue.append(start_key)
	var head := 0

	while head < queue.size():
		var ck: int = queue[head]
		head += 1
		var cx: int = ck % w
		var cy: int = int(ck / w)

		for d in DIRS_4:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if not occupancy.is_in_bounds(nx, ny):
				continue
			var nk := _flat_key(nx, ny, w)
			if visited.has(nk):
				continue
			if not occupancy.is_passable(nx, ny):
				continue
			visited[nk] = ck
			if _is_adjacent_to_footprint(Vector2i(nx, ny), target_origin, fp_w, fp_h):
				return _reconstruct_path(visited, nk, start_key, w)
			queue.append(nk)

	return result


# ─── Внутренние хелперы ────────────────────────────────

static func _flat_key(tx: int, ty: int, width: int) -> int:
	return tx + ty * width


static func _is_adjacent_to_footprint(cell: Vector2i, origin: Vector2i, fp_w: int, fp_h: int) -> bool:
	# Внутри footprint → не смежный
	if cell.x >= origin.x and cell.x < origin.x + fp_w \
			and cell.y >= origin.y and cell.y < origin.y + fp_h:
		return false
	# Северная граница
	if cell.y == origin.y - 1 and cell.x >= origin.x and cell.x < origin.x + fp_w:
		return true
	# Южная граница
	if cell.y == origin.y + fp_h and cell.x >= origin.x and cell.x < origin.x + fp_w:
		return true
	# Западная граница
	if cell.x == origin.x - 1 and cell.y >= origin.y and cell.y < origin.y + fp_h:
		return true
	# Восточная граница
	if cell.x == origin.x + fp_w and cell.y >= origin.y and cell.y < origin.y + fp_h:
		return true
	return false


static func _reconstruct_path(visited: Dictionary, dest_key: int, start_key: int, width: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var k: int = dest_key
	while k != -1 and k != start_key:
		path.append(Vector2i(k % width, int(k / width)))
		k = int(visited[k])
	path.reverse()
	return path
