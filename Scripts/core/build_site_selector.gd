extends RefCounted
class_name BuildSiteSelector

# Автоматический выбор позиции для строительства.
# Соответствует src/state/buildSiteSelection.ts из four-elements-phaser.
# Расширение: поиск не только вокруг зданий, но и вокруг выбранного builder'а.
#
# Логика:
# 1. Игрок нажимает Q/W/E/R/A/F (без выбора позиции мышью).
# 2. Система ищет ближайшую валидную позицию рядом с якорем:
#    - выбран builder → рядом с builder'ом
#    - иначе → рядом с HQ
# 3. Проверка: can_place (occupancy + границы) + gap rule (минимум 1 пустая клетка между зданиями).
# 4. Создаётся construction site, builder автоматически подходит.

const BuildingCatalog := preload("res://Scripts/building_catalog.gd")
const BuildingRegistry := preload("res://Scripts/building_registry.gd")


class SearchOptions:
	var gap_tiles: int = 1
	var max_radius_from_anchor: int = 15

	func _init(gap: int = 1, max_radius: int = 15) -> void:
		gap_tiles = gap
		max_radius_from_anchor = max_radius


class SearchResult:
	var ok: bool
	var origin_cell: Vector2i
	var reason: String

	func _init(success: bool, cell: Vector2i = Vector2i.ZERO, why: String = "") -> void:
		ok = success
		origin_cell = cell
		reason = why


# Найти позицию для здания рядом с указанной клеткой-якорем (builder или HQ).
# building_id: "separator" | "raw_storage" | "matter_storage" | "elements_storage" | "power_plant" | "units_factory"
# anchor_cell: клетка, относительно которой искать (позиция builder'а или центр HQ)
# existing_footprints: Array of {origin: Vector2i, fp: Vector2i}
# map_size: размер карты (квадратная)
static func find_site_near_anchor(
		occupancy,  # OccupancyMap
		building_id: String,
		anchor_cell: Vector2i,
		map_size: int,
		existing_footprints: Array,
		options: SearchOptions
	) -> SearchResult:
	var config: Dictionary = BuildingRegistry.get_config(building_id)
	if config.is_empty():
		return SearchResult.new(false, Vector2i.ZERO, "unknown-building-type")

	var asset_key: String = BuildingRegistry.asset_key_for(building_id, 1)
	# Используем cyan фракцию как референс для определения footprint (footprint не зависит от фракции)
	var ref_path := "res://Assets/Buildings/cyan/" + asset_key
	var footprint: Vector2i = BuildingCatalog.get_footprint(ref_path)

	# Генерируем кандидатов, сортируемых по дистанции до якоря
	var candidates: Array = []
	var cx := (footprint.x - 1) / 2.0
	var cy := (footprint.y - 1) / 2.0

	for ty in range(0, map_size - footprint.y + 1):
		for tx in range(0, map_size - footprint.x + 1):
			var dx := (tx + cx) - anchor_cell.x
			var dy := (ty + cy) - anchor_cell.y
			var dist := abs(dx) + abs(dy)  # Manhattan
			if dist <= options.max_radius_from_anchor:
				candidates.append({"tx": tx, "ty": ty, "dist": dist})

	# Сортировка по (dist, tx, ty) — ближайший первый, детерминированный tie-break
	candidates.sort_custom(func(a, b):
		if a.dist != b.dist:
			return a.dist < b.dist
		if a.tx != b.tx:
			return a.tx < b.tx
		return a.ty < b.ty
	)

	# Проверяем каждого кандидата
	for c in candidates:
		var origin := Vector2i(c.tx, c.ty)
		# 1. Можно ли разместить (occupancy + границы)
		if not _can_place(occupancy, origin, footprint, map_size):
			continue
		# 2. Соблюдается ли gap rule
		if not _passes_gap_rule(origin, footprint, existing_footprints, options.gap_tiles):
			continue
		return SearchResult.new(true, origin)

	return SearchResult.new(false, Vector2i.ZERO, "no-valid-site")


# ─── Внутренние хелперы ───────────────────────────────

static func _can_place(
		occupancy,
		origin: Vector2i,
		footprint: Vector2i,
		map_size: int
	) -> bool:
	# Границы
	if origin.x < 0 or origin.y < 0:
		return false
	if origin.x + footprint.x > map_size or origin.y + footprint.y > map_size:
		return false
	# Занятость
	return occupancy.is_buildable_rect(origin, footprint.x, footprint.y)


static func _passes_gap_rule(
		origin: Vector2i,
		footprint: Vector2i,
		existing: Array,
		gap: int
	) -> bool:
	for fp in existing:
		# Расширяем кандидат на gap во все стороны
		var exp_x := origin.x - gap
		var exp_y := origin.y - gap
		var exp_w := footprint.x + 2 * gap
		var exp_h := footprint.y + 2 * gap
		# Если расширенный кандидат пересекается с существующим footprint — gap нарушен
		if _rects_overlap(exp_x, exp_y, exp_w, exp_h,
				fp.origin.x, fp.origin.y, fp.fp.x, fp.fp.y):
			return false
	return true


static func _rects_overlap(ax: int, ay: int, aw: int, ah: int,
		bx: int, by: int, bw: int, bh: int) -> bool:
	return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
