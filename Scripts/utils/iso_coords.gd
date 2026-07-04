extends RefCounted

# Изометрические преобразования координат.
# Соответствует _tile_float_to_local, _sort_z_for_cell, _sort_z_for_footprint в game_world.gd.

# Преобразовать тайловые координаты в экранные (для изометрии).
static func tile_to_local(tile_pos: Vector2, tile_size: Vector2i) -> Vector2:
	return Vector2(
		(tile_pos.x - tile_pos.y) * float(tile_size.x) * 0.5,
		(tile_pos.x + tile_pos.y) * float(tile_size.y) * 0.5
	)

# Z-index для одной клетки (для y-sort ручного).
static func sort_z_for_cell(cell: Vector2i, bias: int = 0) -> int:
	return 1000 + (cell.x + cell.y) * 10 + bias

# Z-index для footprint'а (здания 2×2 или 3×3).
# Берём максимальную (x+y) клетку footprint'а, чтобы здание рисовалось поверх более "нижних" объектов.
static func sort_z_for_footprint(footprint: Array, bias: int = 0) -> int:
	var best_sum := -999999
	for value in footprint:
		if not value is Vector2i:
			continue
		var cell: Vector2i = value
		best_sum = maxi(best_sum, cell.x + cell.y)
	if best_sum < -1000:
		return 1000 + bias
	return 1000 + best_sum * 10 + bias

# Преобразовать экранные координаты в тайловые.
static func local_to_tile(screen_pos: Vector2, tile_size: Vector2i) -> Vector2i:
	var tx := int(round((screen_pos.x / float(tile_size.x) + screen_pos.y / float(tile_size.y))))
	var ty := int(round((screen_pos.y / float(tile_size.y) - screen_pos.x / float(tile_size.x))))
	return Vector2i(tx, ty)
