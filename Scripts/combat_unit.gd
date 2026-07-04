extends Node2D

signal selection_changed(selected: bool)

const ProjectileScene := preload("res://Scripts/projectile.gd")

const DIRECTIONS := [
	"E",
	"ESE",
	"SE",
	"SSE",
	"S",
	"SSW",
	"SW",
	"WSW",
	"W",
	"WNW",
	"NW",
	"NNW",
	"N",
	"NNE",
	"NE",
	"ENE",
]

const MAX_MOD_LEVEL := 3
const MODULAR_UNIT_SCALE := 0.16
const HULL_STATS := {
	"wasp": {
		"speed": [265.0, 285.0, 305.0, 330.0],
		"health": [120, 150, 185, 225],
		"scale": MODULAR_UNIT_SCALE,
	},
	"hunter": {
		"speed": [205.0, 220.0, 238.0, 255.0],
		"health": [220, 270, 325, 390],
		"scale": MODULAR_UNIT_SCALE,
	},
}
const TURRET_STATS := {
	"smoky": {
		"range": [520.0, 580.0, 640.0, 710.0],
		"damage": [28, 38, 50, 64],
		"cooldown": [0.72, 0.64, 0.56, 0.48],
		"projectile_speed": [920.0, 980.0, 1040.0, 1120.0],
	},
	"railgun": {
		"range": [700.0, 790.0, 890.0, 1000.0],
		"damage": [70, 94, 124, 160],
		"cooldown": [1.65, 1.45, 1.25, 1.05],
		"projectile_speed": [1300.0, 1420.0, 1560.0, 1700.0],
	},
}

var faction_id: String = "cyan"
var hull_id: String = "wasp"
var turret_id: String = "smoky"
var hull_mod: int = 0
var turret_mod: int = 0
var current_health: int = 120
var move_target: Vector2
var attack_target: Node2D

var _hull_sprite: Sprite2D
var _turret_sprite: Sprite2D
var _selection_ring: Line2D
var _hull_direction_index: int = 0
var _turret_direction_index: int = 0
var _fire_timer: float = 0.0
var _is_selected: bool = false


func _ready() -> void:
	y_sort_enabled = true
	z_index = _sort_z_from_position()
	z_as_relative = false
	move_target = global_position

	_hull_sprite = Sprite2D.new()
	_hull_sprite.name = "Hull"
	_hull_sprite.centered = true
	add_child(_hull_sprite)

	_turret_sprite = Sprite2D.new()
	_turret_sprite.name = "Turret"
	_turret_sprite.centered = true
	_turret_sprite.z_index = 2
	add_child(_turret_sprite)

	_selection_ring = Line2D.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.width = 3.0
	_selection_ring.default_color = Color(0.2, 0.95, 1.0, 0.95)
	_selection_ring.closed = true
	_selection_ring.points = PackedVector2Array([
		Vector2(-56, 0),
		Vector2(0, -28),
		Vector2(56, 0),
		Vector2(0, 28),
	])
	_selection_ring.visible = false
	add_child(_selection_ring)

	_refresh_stats()
	_refresh_sprites()


func setup(faction: String, hull: String, turret: String, hull_level: int = 0, turret_level: int = 0) -> void:
	faction_id = faction
	hull_id = hull
	turret_id = turret
	hull_mod = clampi(hull_level, 0, MAX_MOD_LEVEL)
	turret_mod = clampi(turret_level, 0, MAX_MOD_LEVEL)
	if is_inside_tree():
		_refresh_stats()
		_refresh_sprites()


func _process(delta: float) -> void:
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	_process_movement(delta)
	_process_attack(delta)
	z_index = _sort_z_from_position()


func command_move(target_position: Vector2) -> void:
	move_target = target_position


func command_attack(target_node: Node2D) -> void:
	attack_target = target_node
	if is_instance_valid(target_node):
		move_target = target_node.global_position


func set_selected(selected: bool) -> void:
	_is_selected = selected
	if _selection_ring:
		_selection_ring.visible = selected
	selection_changed.emit(selected)


func is_selected() -> bool:
	return _is_selected


func upgrade_hull() -> bool:
	if hull_mod >= MAX_MOD_LEVEL:
		return false
	hull_mod += 1
	_refresh_stats()
	_refresh_sprites()
	return true


func upgrade_turret() -> bool:
	if turret_mod >= MAX_MOD_LEVEL:
		return false
	turret_mod += 1
	_refresh_sprites()
	return true


func switch_hull(new_hull_id: String) -> void:
	if not HULL_STATS.has(new_hull_id):
		return
	hull_id = new_hull_id
	_refresh_stats()
	_refresh_sprites()


func switch_turret(new_turret_id: String) -> void:
	if not TURRET_STATS.has(new_turret_id):
		return
	turret_id = new_turret_id
	_refresh_sprites()


func get_status_text() -> String:
	return "%s m%d + %s m%d" % [hull_id.capitalize(), hull_mod, turret_id.capitalize(), turret_mod]


func _process_movement(delta: float) -> void:
	var to_target := move_target - global_position
	var stop_distance := 18.0
	if is_instance_valid(attack_target):
		stop_distance = _attack_range() * 0.82

	if to_target.length() <= stop_distance:
		return

	var direction := to_target.normalized()
	global_position += direction * _movement_speed() * delta
	var next_direction_index := _direction_index(direction)
	if next_direction_index != _hull_direction_index:
		_hull_direction_index = next_direction_index
		_refresh_sprites()


func _process_attack(_delta: float) -> void:
	if not is_instance_valid(attack_target):
		attack_target = null
		return

	var to_target := attack_target.global_position - global_position
	if to_target.length() > _attack_range():
		return

	var next_turret_direction_index := _direction_index(to_target.normalized())
	if next_turret_direction_index != _turret_direction_index:
		_turret_direction_index = next_turret_direction_index
		_refresh_sprites()

	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = _attack_cooldown()


func _fire() -> void:
	if not is_instance_valid(attack_target):
		return

	var projectile := ProjectileScene.new()
	projectile.setup(global_position + Vector2(0, -12), attack_target, _attack_damage(), _projectile_speed())
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		projectile_parent = get_parent()
	projectile_parent.add_child(projectile)


func _refresh_stats() -> void:
	current_health = int(_hull_stat("health"))


func _refresh_sprites() -> void:
	if _hull_sprite == null or _turret_sprite == null:
		return
	var hull_texture := _load_png_texture(_unit_texture_path("Hulls", hull_id, hull_mod, _hull_direction_index))
	if hull_texture:
		_hull_sprite.texture = hull_texture
		var hull_scale := float(_hull_stat("scale"))
		_hull_sprite.scale = Vector2(hull_scale, hull_scale)

	var turret_texture := _load_png_texture(_unit_texture_path("Turrets", turret_id, turret_mod, _turret_direction_index))
	if turret_texture:
		_turret_sprite.texture = turret_texture
		var turret_scale := float(_hull_stat("scale"))
		_turret_sprite.scale = Vector2(turret_scale, turret_scale)


func _unit_texture_path(kind: String, asset_id: String, mod_level: int, direction_index: int) -> String:
	var direction_name: String = DIRECTIONS[direction_index]
	return "res://Assets/Units/%s/%s/%s/m%d/%s_%s_m%d_dir%02d_%s.png" % [
		kind,
		asset_id,
		faction_id,
		mod_level,
		asset_id,
		faction_id,
		mod_level,
		direction_index,
		direction_name,
	]


func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var image := Image.load_from_file(image_path)
	if image == null:
		push_warning("Cannot load unit texture: " + path)
		return null
	return ImageTexture.create_from_image(image)


func _direction_index(direction: Vector2) -> int:
	if direction.length_squared() <= 0.0001:
		return _hull_direction_index
	var raw_index := int(round(direction.angle() / (TAU / 16.0)))
	return posmod(raw_index, 16)


func _movement_speed() -> float:
	return float(_hull_stat("speed"))


func _attack_range() -> float:
	return float(_turret_stat("range"))


func _attack_damage() -> int:
	return int(_turret_stat("damage"))


func _attack_cooldown() -> float:
	return float(_turret_stat("cooldown"))


func _projectile_speed() -> float:
	return float(_turret_stat("projectile_speed"))


func _sort_z_from_position() -> int:
	return 1000 + roundi(global_position.y / 6.0) + 5


func _hull_stat(stat_name: String) -> Variant:
	var stats: Dictionary = HULL_STATS.get(hull_id, HULL_STATS["wasp"])
	var value: Variant = stats.get(stat_name)
	if value is Array:
		var values: Array = value
		return values[clampi(hull_mod, 0, values.size() - 1)]
	return value


func _turret_stat(stat_name: String) -> Variant:
	var stats: Dictionary = TURRET_STATS.get(turret_id, TURRET_STATS["smoky"])
	var value: Variant = stats.get(stat_name)
	if value is Array:
		var values: Array = value
		return values[clampi(turret_mod, 0, values.size() - 1)]
	return value
