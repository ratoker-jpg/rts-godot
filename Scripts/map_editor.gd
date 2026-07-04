extends Node2D

signal return_to_menu_requested

const TILE_SET_PATH := "res://Scenes/isometric_tiles_TOP_FACE_try.tres"
const OUTPUT_PATH := "res://Data/map_editor_layout.json"
const BUILDING_CATALOG := preload("res://Scripts/building_catalog.gd")
const BUILDING_REGISTRY := preload("res://Scripts/building_registry.gd")
const SOURCE_ID := 0
const ALT_ID := 0
const EDGE_TILE := Vector2i(12, 0)
const PRIMARY_FLOOR_TILE := Vector2i(2, 0)
const RESOURCE_VISUAL_OFFSETS := [
	Vector2(-6.0, -10.0),
	Vector2(-2.5, -18.0),
	Vector2(-1.5, -28.0),
	Vector2(1.0, -27.0),
	Vector2(-0.5, -39.0),
	Vector2(-8.0, -22.0),
]
const RESOURCE_VISUAL_SCALES := [
	0.53305787,
	0.55748487,
	0.55241936,
	0.47697377,
	0.45658687,
	0.6446384,
]

@export var map_size: int = 64

var _tile_map: TileMapLayer
var _objects_layer: Node2D
var _camera: Camera2D
var _hud_layer: CanvasLayer
var _hud: Label
var _palette: Array[Dictionary] = []
var _selected_index: int = 0
var _placed: Dictionary = {}
var _building_footprint_cells: Dictionary = {}
var _building_reserved_cells: Dictionary = {}
var _last_drag_cell := Vector2i(-9999, -9999)


func _ready() -> void:
	y_sort_enabled = true
	_build_nodes()
	_build_palette()
	_draw_floor()
	_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				return_to_menu_requested.emit()
			KEY_Q:
				_select_delta(-1)
			KEY_E:
				_select_delta(1)
			KEY_DELETE, KEY_BACKSPACE:
				_erase_cell(_mouse_cell())
			KEY_S:
				if event.ctrl_pressed:
					_save_layout()
			KEY_L:
				if event.ctrl_pressed:
					_load_layout()

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_camera.zoom *= 1.1
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_camera.zoom /= 1.1
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			_last_drag_cell = Vector2i(-9999, -9999)
			if mouse.pressed:
				_place_selected(_mouse_cell())
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_erase_cell(_mouse_cell())

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var cell := _mouse_cell()
		if cell != _last_drag_cell:
			_place_selected(cell)


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		_camera.position += direction.normalized() * 900.0 * delta / _camera.zoom.x


func _build_nodes() -> void:
	_tile_map = TileMapLayer.new()
	_tile_map.name = "EditorTileMap"
	_tile_map.tile_set = load(TILE_SET_PATH)
	_tile_map.y_sort_enabled = true
	_tile_map.z_index = 0
	_tile_map.z_as_relative = false
	add_child(_tile_map)

	_objects_layer = Node2D.new()
	_objects_layer.name = "PlacedObjects"
	_objects_layer.y_sort_enabled = true
	_objects_layer.z_index = 20
	_objects_layer.z_as_relative = false
	add_child(_objects_layer)

	_camera = Camera2D.new()
	_camera.name = "EditorCamera"
	_camera.enabled = true
	_camera.zoom = Vector2(0.55, 0.55)
	_camera.position = _tile_map.map_to_local(Vector2i(map_size / 2, map_size / 2))
	add_child(_camera)

	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HudLayer"
	add_child(_hud_layer)

	_hud = Label.new()
	_hud.name = "EditorHud"
	_hud.position = Vector2(24, 24)
	_hud.add_theme_font_size_override("font_size", 15)
	_hud_layer.add_child(_hud)


func _build_palette() -> void:
	for color in ["cyan", "yellow"]:
		var max_tier := 6 if color == "cyan" else 5
		for tier in range(1, max_tier + 1):
			_palette.append({
				"id": "%s_tier_%02d" % [color, tier],
				"type": "mineral",
				"label": "%s mineral tier %d" % [color, tier],
				"path": "res://Assets/Resources/Minerals/%s/tier_%02d.png" % [color, tier],
				"color": color,
				"tier": tier,
			})

	_add_environment_assets("bushes_a", "res://Assets/Environment/Vegetation/bushes_a")
	_add_environment_assets("trees_a", "res://Assets/Environment/Vegetation/trees_a")
	_add_environment_assets("trees_b", "res://Assets/Environment/Vegetation/trees_b")

	for faction in ["cyan", "green", "purple", "yellow"]:
		_add_building_assets(faction, "base", "res://Assets/Buildings/%s/base" % faction)
		_add_building_assets(faction, "structures", "res://Assets/Buildings/%s/structures" % faction)
		_add_building_assets(faction, "tech", "res://Assets/Buildings/%s/tech" % faction)


func _add_environment_assets(kind: String, folder: String) -> void:
	for path in _collect_png_paths(folder):
		_palette.append({
			"id": "%s_%s" % [kind, path.get_file().get_basename()],
			"type": "environment",
			"label": "%s/%s" % [kind, path.get_file()],
			"path": path,
			"kind": kind,
		})


func _add_building_assets(faction: String, group: String, folder: String) -> void:
	for path in _collect_png_paths(folder):
		_palette.append({
			"id": "%s_%s_%s" % [faction, group, path.get_file().get_basename()],
			"type": "building",
			"label": "%s/%s/%s" % [faction, group, path.get_file()],
			"path": path,
			"faction": faction,
			"group": group,
		})


func _collect_png_paths(folder: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(folder)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			result.append(folder.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _draw_floor() -> void:
	for y in range(map_size):
		for x in range(map_size):
			var cell := Vector2i(x, y)
			var atlas := EDGE_TILE if x == 0 or y == 0 or x == map_size - 1 or y == map_size - 1 else PRIMARY_FLOOR_TILE
			_tile_map.set_cell(cell, SOURCE_ID, atlas, ALT_ID)


func _select_delta(delta: int) -> void:
	if _palette.is_empty():
		return
	_selected_index = wrapi(_selected_index + delta, 0, _palette.size())
	_update_hud()


func _mouse_cell() -> Vector2i:
	return _tile_map.local_to_map(get_global_mouse_position())


func _place_selected(cell: Vector2i) -> void:
	if not _is_cell_inside_map(cell) or _palette.is_empty():
		return
	_last_drag_cell = cell
	var asset := _palette[_selected_index]
	if str(asset["type"]) == "building":
		_erase_cell_if_building_footprint(cell)
		if not _can_place_building(asset, cell):
			_update_hud("Blocked: building footprint needs 1 empty cell around it")
			return
	else:
		_erase_cell(cell)

	var texture := load(str(asset["path"]))
	if not texture is Texture2D:
		return

	var sprite := Sprite2D.new()
	sprite.name = "%s_%d_%d" % [str(asset["id"]), cell.x, cell.y]
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _asset_position(cell, asset)
	sprite.scale = _asset_scale(asset, texture)
	sprite.z_index = _asset_z_index(asset, cell)
	sprite.z_as_relative = false
	sprite.set_meta("cell", cell)
	sprite.set_meta("origin_cell", cell)
	sprite.set_meta("asset", asset.duplicate(true))
	if str(asset["type"]) == "building":
		var path := str(asset["path"])
		sprite.set_meta("asset_key", BUILDING_CATALOG.asset_key(path))
		sprite.set_meta("building_id", _gameplay_building_id_for_path(path))
		sprite.set_meta("modification_tier", BUILDING_CATALOG.get_modification_tier(path))
		sprite.set_meta("footprint", BUILDING_CATALOG.get_footprint(path))
		sprite.set_meta("footprint_cells", BUILDING_CATALOG.get_footprint_cells(cell, path))
		sprite.set_meta("reserved_cells", BUILDING_CATALOG.get_reserved_cells(cell, path))
		sprite.set_meta("blocks_path", true)
	_objects_layer.add_child(sprite)
	_placed[_cell_key(cell)] = sprite
	_register_placement(sprite, asset)
	_update_hud()


func _erase_cell(cell: Vector2i) -> void:
	var node := _node_at_cell(cell)
	if node == null:
		return
	_unregister_placement(node)
	node.queue_free()
	_update_hud()


func _erase_cell_if_building_footprint(cell: Vector2i) -> void:
	var key := _cell_key(cell)
	if not _building_footprint_cells.has(key):
		return
	var node: Node = _building_footprint_cells[key]
	_unregister_placement(node)
	node.queue_free()
	_update_hud()


func _node_at_cell(cell: Vector2i) -> Node:
	var key := _cell_key(cell)
	if _placed.has(key):
		return _placed[key]
	if _building_footprint_cells.has(key):
		return _building_footprint_cells[key]
	return null


func _register_placement(node: Node, asset: Dictionary) -> void:
	if str(asset["type"]) != "building":
		return
	for footprint_value in node.get_meta("footprint_cells", []):
		if not footprint_value is Vector2i:
			continue
		var footprint_cell: Vector2i = footprint_value
		_building_footprint_cells[_cell_key(footprint_cell)] = node
	for reserved_value in node.get_meta("reserved_cells", []):
		if not reserved_value is Vector2i:
			continue
		var reserved_cell: Vector2i = reserved_value
		_building_reserved_cells[_cell_key(reserved_cell)] = node


func _unregister_placement(node: Node) -> void:
	var origin_cell: Vector2i = node.get_meta("origin_cell", node.get_meta("cell", Vector2i.ZERO))
	_placed.erase(_cell_key(origin_cell))
	if node.has_meta("footprint_cells"):
		for footprint_value in node.get_meta("footprint_cells"):
			if not footprint_value is Vector2i:
				continue
			var footprint_cell: Vector2i = footprint_value
			var footprint_key := _cell_key(footprint_cell)
			if _building_footprint_cells.get(footprint_key) == node:
				_building_footprint_cells.erase(footprint_key)
	if node.has_meta("reserved_cells"):
		for reserved_value in node.get_meta("reserved_cells"):
			if not reserved_value is Vector2i:
				continue
			var reserved_cell: Vector2i = reserved_value
			var reserved_key := _cell_key(reserved_cell)
			if _building_reserved_cells.get(reserved_key) == node:
				_building_reserved_cells.erase(reserved_key)


func _can_place_building(asset: Dictionary, origin_cell: Vector2i) -> bool:
	var path := str(asset["path"])
	for footprint_cell in BUILDING_CATALOG.get_footprint_cells(origin_cell, path):
		if not _is_cell_inside_map(footprint_cell):
			return false
		var key := _cell_key(footprint_cell)
		if _building_reserved_cells.has(key):
			return false
		if _placed.has(key):
			return false
	return true


func _gameplay_building_id_for_path(path: String) -> String:
	var gameplay_id := BUILDING_REGISTRY.building_id_from_texture_path(path)
	return gameplay_id if not gameplay_id.is_empty() else BUILDING_CATALOG.get_building_id(path)


func _asset_offset(asset: Dictionary) -> Vector2:
	match str(asset["type"]):
		"mineral":
			var index := clampi(int(asset["tier"]) - 1, 0, RESOURCE_VISUAL_OFFSETS.size() - 1)
			return RESOURCE_VISUAL_OFFSETS[index]
		"environment":
			match str(asset["kind"]):
				"bushes_a":
					return Vector2(-4, -14)
				"trees_a":
					return Vector2(-6, 15)
				"trees_b":
					return Vector2(8, 8)
		"building":
			return BUILDING_CATALOG.get_visual_offset(str(asset["path"]))
	return Vector2.ZERO


func _asset_position(cell: Vector2i, asset: Dictionary) -> Vector2:
	if str(asset["type"]) == "building":
		var path := str(asset["path"])
		return _tile_map.map_to_local(cell + BUILDING_CATALOG.get_visual_anchor_cell(path)) + _asset_offset(asset)
	return _tile_map.map_to_local(cell) + _asset_offset(asset)


func _asset_scale(asset: Dictionary, texture: Texture2D) -> Vector2:
	match str(asset["type"]):
		"mineral":
			var index := clampi(int(asset["tier"]) - 1, 0, RESOURCE_VISUAL_SCALES.size() - 1)
			return Vector2(RESOURCE_VISUAL_SCALES[index], RESOURCE_VISUAL_SCALES[index])
		"environment":
			if str(asset["kind"]) == "bushes_a":
				return Vector2(0.5080971, 0.5080971)
		"building":
			return BUILDING_CATALOG.get_visual_scale(str(asset["path"]), texture, _tile_map.tile_set.tile_size)
	return Vector2.ONE


func _asset_z_index(asset: Dictionary, cell: Vector2i) -> int:
	match str(asset["type"]):
		"mineral":
			return _sort_z_for_cell(cell, 0)
		"environment":
			return _sort_z_for_cell(cell, -2)
		"building":
			return _sort_z_for_footprint(BUILDING_CATALOG.get_footprint_cells(cell, str(asset.get("path", ""))), 2)
	return 10


func _sort_z_for_cell(cell: Vector2i, bias: int = 0) -> int:
	return 1000 + (cell.x + cell.y) * 10 + bias


func _sort_z_for_footprint(footprint: Array, bias: int = 0) -> int:
	var best_sum := -999999
	for value in footprint:
		if not value is Vector2i:
			continue
		var footprint_cell: Vector2i = value
		best_sum = maxi(best_sum, footprint_cell.x + footprint_cell.y)
	if best_sum < -1000:
		return 1000 + bias
	return 1000 + best_sum * 10 + bias


func _save_layout() -> void:
	var objects: Array[Dictionary] = []
	for key in _placed.keys():
		var sprite: Sprite2D = _placed[key]
		var asset: Dictionary = sprite.get_meta("asset")
		var cell: Vector2i = sprite.get_meta("cell")
		objects.append({
			"cell": [cell.x, cell.y],
			"type": asset.get("type", ""),
			"id": asset.get("id", ""),
			"path": asset.get("path", ""),
			"kind": asset.get("kind", ""),
			"faction": asset.get("faction", ""),
			"group": asset.get("group", ""),
			"color": asset.get("color", ""),
			"tier": asset.get("tier", 0),
			"offset": [sprite.position.x - _tile_map.map_to_local(cell).x, sprite.position.y - _tile_map.map_to_local(cell).y],
			"scale": [sprite.scale.x, sprite.scale.y],
			"asset_key": sprite.get_meta("asset_key", ""),
			"building_id": sprite.get_meta("building_id", ""),
			"modification_tier": sprite.get_meta("modification_tier", 0),
			"visual_offset": _vector2_to_array(_asset_offset(asset)),
			"visual_anchor_cell": _vector2i_to_array(BUILDING_CATALOG.get_visual_anchor_cell(str(asset.get("path", "")))) if str(asset.get("type", "")) == "building" else [],
			"footprint": _vector2i_to_array(sprite.get_meta("footprint", Vector2i.ONE)),
			"footprint_cells": _vector2i_array_to_arrays(sprite.get_meta("footprint_cells", [])),
			"reserved_cells": _vector2i_array_to_arrays(sprite.get_meta("reserved_cells", [])),
			"blocks_path": sprite.get_meta("blocks_path", false),
		})
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["cell"][1]) == int(b["cell"][1]):
			return int(a["cell"][0]) < int(b["cell"][0])
		return int(a["cell"][1]) < int(b["cell"][1])
	)

	var data := {
		"map_size": map_size,
		"objects": objects,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Data"))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_update_hud("Saved: %s (%d objects)" % [OUTPUT_PATH, objects.size()])


func _load_layout() -> void:
	if not FileAccess.file_exists(OUTPUT_PATH):
		_update_hud("No layout file: %s" % OUTPUT_PATH)
		return
	_clear_placed_objects()

	var text := FileAccess.get_file_as_string(OUTPUT_PATH)
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		_update_hud("Bad JSON: %s" % OUTPUT_PATH)
		return
	map_size = int(parsed.get("map_size", map_size))
	_tile_map.clear()
	_draw_floor()
	for item in parsed.get("objects", []):
		var asset := _asset_from_saved(item)
		var index := _find_palette_index_by_path(str(asset.get("path", "")))
		if index >= 0:
			_selected_index = index
		var cell_data: Array = item.get("cell", [0, 0])
		_place_selected(Vector2i(int(cell_data[0]), int(cell_data[1])))
	_update_hud("Loaded: %s" % OUTPUT_PATH)


func _asset_from_saved(item: Dictionary) -> Dictionary:
	return {
		"id": item.get("id", ""),
		"type": item.get("type", ""),
		"label": item.get("id", ""),
		"path": item.get("path", ""),
		"kind": item.get("kind", ""),
		"faction": item.get("faction", ""),
		"group": item.get("group", ""),
		"color": item.get("color", ""),
		"tier": item.get("tier", 0),
	}


func _find_palette_index_by_path(path: String) -> int:
	for i in range(_palette.size()):
		if str(_palette[i].get("path", "")) == path:
			return i
	return -1


func _clear_placed_objects() -> void:
	for key in _placed.keys():
		var node: Node = _placed[key]
		node.queue_free()
	_placed.clear()
	_building_footprint_cells.clear()
	_building_reserved_cells.clear()


func _vector2_to_array(value: Variant) -> Array:
	if value is Vector2:
		return [value.x, value.y]
	return []


func _vector2i_to_array(value: Variant) -> Array:
	if value is Vector2i:
		return [value.x, value.y]
	return []


func _vector2i_array_to_arrays(values: Variant) -> Array:
	var result: Array = []
	if not values is Array:
		return result
	for value in values:
		if value is Vector2i:
			result.append([value.x, value.y])
	return result


func _update_hud(extra: String = "") -> void:
	if _hud == null:
		return
	var selected := "none"
	if not _palette.is_empty():
		selected = "%d/%d %s" % [_selected_index + 1, _palette.size(), str(_palette[_selected_index]["label"])]
	_hud.text = "Map editor | Q/E asset | LMB place/drag | RMB erase | WASD move | Wheel zoom | Ctrl+S save | Ctrl+L load | Esc menu\nSelected: %s\nObjects: %d\n%s" % [selected, _placed.size(), extra]


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _is_cell_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size and cell.y < map_size
