extends RefCounted

const CLEARANCE_CELLS := 1
const DEFAULT_FOOTPRINT := Vector2i(2, 2)
const BASE_FOOTPRINT := Vector2i(3, 3)
const SMALL_FOOTPRINT := Vector2i(1, 1)

const SMALL_BUILDINGS := {
	"structures/structure_09.png": true,
	"structures/structure_10.png": true,
	"tech/tech_07.png": true,
}

const VISUAL_LAYOUT := {
	"base/t1.png": {
		"offset": Vector2(4.501, 19.0),
		"scale": Vector2(1.121863, 1.121863),
	},
	"base/t2.png": {
		"offset": Vector2(-8.0, -22.0),
		"scale": Vector2(1.0, 1.0),
	},
	"base/t3.png": {
		"offset": Vector2(-3.5, -47.0),
		"scale": Vector2(0.888571, 0.888571),
	},
	"structures/structure_01.png": {
		"offset": Vector2(20.499, -2.999),
		"scale": Vector2(1.223214, 1.223214),
	},
	"structures/structure_02.png": {
		"offset": Vector2(2.001, 5.0),
		"scale": Vector2(1.236607, 1.236607),
	},
	"structures/structure_03.png": {
		"offset": Vector2(8.5, 15.0),
		"scale": Vector2(1.196832, 1.196832),
	},
	"structures/structure_04.png": {
		"offset": Vector2(2.0, -13.0),
		"scale": Vector2(1.231707, 1.231707),
	},
	"structures/structure_05.png": {
		"offset": Vector2(-7.5, 8.999),
		"scale": Vector2(1.166667, 1.166667),
	},
	"structures/structure_06.png": {
		"offset": Vector2(5.5, -6.0),
		"scale": Vector2(1.229358, 1.229358),
	},
	"structures/structure_07.png": {
		"offset": Vector2(2.5, -8.0),
		"scale": Vector2(1.257143, 1.257143),
	},
	"structures/structure_08.png": {
		"offset": Vector2(5.5, 16.0),
		"scale": Vector2(1.239535, 1.239535),
	},
	"structures/structure_09.png": {
		"offset": Vector2(0.5, 36.0),
		"scale": Vector2(0.898489, 0.898489),
	},
	"structures/structure_10.png": {
		"offset": Vector2(0.5, 49.0),
		"scale": Vector2(0.795337, 0.795337),
	},
	"structures/structure_11.png": {
		"offset": Vector2(7.0, -12.0),
		"scale": Vector2(1.138009, 1.138009),
	},
	"structures/structure_12.png": {
		"offset": Vector2(8.5, -3.001),
		"scale": Vector2(1.202054, 1.202054),
	},
	"structures/structure_13.png": {
		"offset": Vector2(5.0, -9.0),
		"scale": Vector2(1.160714, 1.160714),
	},
	"structures/structure_14.png": {
		"offset": Vector2(-2.0, -24.0),
		"scale": Vector2(1.35514, 1.35514),
	},
	"tech/tech_01.png": {
		"offset": Vector2(10.5, -20.0),
		"scale": Vector2(1.0, 1.0),
	},
	"tech/tech_02.png": {
		"offset": Vector2(9.0, -41.0),
		"scale": Vector2(1.0, 1.0),
	},
	"tech/tech_03.png": {
		"offset": Vector2(1.0, -42.0),
		"scale": Vector2(1.075972, 1.075972),
	},
	"tech/tech_04.png": {
		"offset": Vector2(-0.5, -40.0),
		"scale": Vector2(1.0, 1.0),
	},
	"tech/tech_05.png": {
		"offset": Vector2(-1.999, 52.0),
		"scale": Vector2(1.09854, 1.09854),
	},
	"tech/tech_06.png": {
		"offset": Vector2(8.0, -41.0),
		"scale": Vector2(1.0, 1.0),
	},
	"tech/tech_07.png": {
		"offset": Vector2(2.499, 38.001),
		"scale": Vector2(0.633212, 0.633212),
	},
	"tech/tech_08.png": {
		"offset": Vector2(2.0, -53.0),
		"scale": Vector2(1.0, 1.0),
	},
}


static func asset_key(path: String) -> String:
	var marker := "/Buildings/"
	var marker_index := path.find(marker)
	if marker_index < 0:
		return path.get_file()
	var parts := path.substr(marker_index + marker.length()).split("/", false)
	if parts.size() < 3:
		return path.get_file()
	return "%s/%s" % [parts[1], parts[2]]


static func get_footprint(path: String) -> Vector2i:
	var key := asset_key(path)
	if key.begins_with("base/"):
		return BASE_FOOTPRINT
	if SMALL_BUILDINGS.has(key):
		return SMALL_FOOTPRINT
	return DEFAULT_FOOTPRINT


static func get_building_id(path: String) -> String:
	var key := asset_key(path)
	if key.begins_with("base/"):
		return "base"
	return key.get_file().get_basename()


static func get_modification_tier(path: String) -> int:
	var key := asset_key(path)
	if not key.begins_with("base/"):
		return 0
	var basename := key.get_file().get_basename()
	if basename.length() < 2 or not basename.begins_with("t"):
		return 1
	var tier_text := basename.substr(1)
	if not tier_text.is_valid_int():
		return 1
	return clampi(int(tier_text), 1, 3)


static func get_visual_anchor_cell(path: String) -> Vector2i:
	if asset_key(path).begins_with("base/"):
		return Vector2i(1, 1)
	return Vector2i.ZERO


static func get_visual_offset(path: String) -> Vector2:
	var key := asset_key(path)
	var layout: Dictionary = VISUAL_LAYOUT.get(key, {})
	return layout.get("offset", Vector2.ZERO)


static func get_visual_scale(path: String, _texture: Texture2D, _tile_size: Vector2i) -> Vector2:
	var key := asset_key(path)
	var layout: Dictionary = VISUAL_LAYOUT.get(key, {})
	return layout.get("scale", Vector2(0.72, 0.72))


static func get_footprint_cells(origin_cell: Vector2i, path: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var footprint := get_footprint(path)
	for y in range(origin_cell.y, origin_cell.y + footprint.y):
		for x in range(origin_cell.x, origin_cell.x + footprint.x):
			cells.append(Vector2i(x, y))
	return cells


static func get_reserved_cells(origin_cell: Vector2i, path: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var footprint := get_footprint(path)
	for y in range(origin_cell.y - CLEARANCE_CELLS, origin_cell.y + footprint.y + CLEARANCE_CELLS):
		for x in range(origin_cell.x - CLEARANCE_CELLS, origin_cell.x + footprint.x + CLEARANCE_CELLS):
			cells.append(Vector2i(x, y))
	return cells
