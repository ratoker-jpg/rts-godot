extends RefCounted

# Карта занятости тайлов.
# Соответствует src/state/occupancy.ts из four-elements-phaser.
# Хранит флаги IMPASSABLE | UNBUILDABLE | RESOURCE | SOFT_OCCUPIED для каждой клетки.

enum TileFlag {
	IMPASSABLE = 1,
	UNBUILDABLE = 2,
	RESOURCE = 4,
	SOFT_OCCUPIED = 8,
}

var width: int
var height: int
var _flags: PackedInt32Array  # width × height, битовая маска


func _init(w: int = 1, h: int = 1) -> void:
	width = w
	height = h
	_flags = PackedInt32Array()
	_flags.resize(w * h)


func _key(tx: int, ty: int) -> int:
	return ty * width + tx


func is_in_bounds(tx: int, ty: int) -> bool:
	return tx >= 0 and ty >= 0 and tx < width and ty < height


func is_passable(tx: int, ty: int) -> bool:
	if not is_in_bounds(tx, ty):
		return false
	return (_flags[_key(tx, ty)] & TileFlag.IMPASSABLE) == 0


func is_buildable(tx: int, ty: int) -> bool:
	if not is_in_bounds(tx, ty):
		return false
	var flags := _flags[_key(tx, ty)]
	return (flags & TileFlag.UNBUILDABLE) == 0 and (flags & TileFlag.IMPASSABLE) == 0


func is_buildable_rect(origin: Vector2i, fp_w: int, fp_h: int) -> bool:
	for y in range(origin.y, origin.y + fp_h):
		for x in range(origin.x, origin.x + fp_w):
			if not is_buildable(x, y):
				return false
	return true


func get_flags(tx: int, ty: int) -> int:
	if not is_in_bounds(tx, ty):
		return 0
	return _flags[_key(tx, ty)]


func add_flag(tx: int, ty: int, flag: int) -> void:
	if is_in_bounds(tx, ty):
		_flags[_key(tx, ty)] |= flag


func remove_flag(tx: int, ty: int, flag: int) -> void:
	if is_in_bounds(tx, ty):
		_flags[_key(tx, ty)] &= ~flag


func add_impassable_rect(origin: Vector2i, fp_w: int, fp_h: int) -> void:
	for y in range(origin.y, origin.y + fp_h):
		for x in range(origin.x, origin.x + fp_w):
			add_flag(x, y, TileFlag.IMPASSABLE | TileFlag.UNBUILDABLE)


func add_impassable_point(tx: int, ty: int) -> void:
	add_flag(tx, ty, TileFlag.IMPASSABLE | TileFlag.UNBUILDABLE)


func add_resource_point(tx: int, ty: int) -> void:
	add_flag(tx, ty, TileFlag.IMPASSABLE | TileFlag.UNBUILDABLE | TileFlag.RESOURCE)


func add_soft_occupied(tx: int, ty: int) -> void:
	add_flag(tx, ty, TileFlag.SOFT_OCCUPIED)


func remove_soft_occupied(tx: int, ty: int) -> void:
	remove_flag(tx, ty, TileFlag.SOFT_OCCUPIED)


func clear() -> void:
	_flags.fill(0)


# Создать копию карты (для thread-safe операций или pathfinding с временными блокерами).
func duplicate() -> OccupancyMap:
	var copy := OccupancyMap.new(width, height)
	copy._flags = _flags.duplicate()
	return copy
