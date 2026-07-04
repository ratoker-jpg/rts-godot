extends Node2D
class_name CombatUnit

signal selection_changed(selected: bool)
signal died(unit: Node2D)

const Constants := preload("res://Scripts/core/constants.gd")
const Direction := preload("res://Scripts/utils/direction.gd")
const TextureLoader := preload("res://Scripts/utils/texture_loader.gd")
const IsoCoords := preload("res://Scripts/utils/iso_coords.gd")
const MovementStateMachine := preload("res://Scripts/core/movement_state_machine.gd")
const Pathfinding := preload("res://Scripts/core/pathfinding.gd")
const CombatRange := preload("res://Scripts/core/combat_range.gd")
const CombatTargeting := preload("res://Scripts/core/combat_targeting.gd")
const DamageFormula := preload("res://Scripts/core/damage_formula.gd")
const ProjectileScene := preload("res://Scripts/projectile.gd")

const DIRECTIONS := [
        "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW",
        "W", "WNW", "NW", "NNW", "N", "NNE", "NE", "ENE",
]

const MAX_MOD_LEVEL := 3
const MODULAR_UNIT_SCALE := 0.16

const HULL_STATS := {
        "wasp": {
                "speed": [265.0, 285.0, 305.0, 330.0],
                "health": [120, 150, 185, 225],
                "armor": [2, 3, 4, 5],
                "min_damage_percent": 0.25,
                "scale": MODULAR_UNIT_SCALE,
                "turn_speed_deg": 130,
                "accel": 8.0,
                "braking": 6.0,
        },
        "hunter": {
                "speed": [205.0, 220.0, 238.0, 255.0],
                "health": [220, 270, 325, 390],
                "armor": [5, 7, 9, 12],
                "min_damage_percent": 0.20,
                "scale": MODULAR_UNIT_SCALE,
                "turn_speed_deg": 140,
                "accel": 6.0,
                "braking": 5.0,
        },
}

const TURRET_STATS := {
        "smoky": {
                "range_min": 1.0, "range_ideal": 5.0, "range_max": 7.0, "stop_distance": 5.0,
                "damage": [28, 38, 50, 64],
                "cooldown": [0.72, 0.64, 0.56, 0.48],
                "projectile_speed": [920.0, 980.0, 1040.0, 1120.0],
                "turret_turn_speed_deg": [130, 138, 144, 150],
                "pierce_count": 1,
        },
        "railgun": {
                "range_min": 3.0, "range_ideal": 9.0, "range_max": 13.0, "stop_distance": 8.0,
                "damage": [70, 94, 124, 160],
                "cooldown": [1.65, 1.45, 1.25, 1.05],
                "projectile_speed": [1300.0, 1420.0, 1560.0, 1700.0],
                "turret_turn_speed_deg": [70, 76, 83, 90],
                "pierce_count": 3,
        },
}

# ─── Публичные поля ───────────────────────────────────
var faction_id: String = "cyan"
var hull_id: String = "wasp"
var turret_id: String = "smoky"
var hull_mod: int = 0
var turret_mod: int = 0
var current_health: int = 120
var max_health: int = 120
var armor: int = 2
var min_damage_percent: float = 0.25
var move_target: Vector2
var attack_target: Node2D
var is_destroyed: bool = false

# Состояние движения (MovementStateMachine)
var grid_movement: MovementStateMachine.GridMovementState
var movement_config: MovementStateMachine.GridMovementConfig
# Ссылки на внешние объекты (получаются от GameWorld)
var _occupancy  # OccupancyMap
var _reservation_map  # TileReservationMap
var _game_world: Node2D
var _get_occupancy_for_repath: Callable

# Turret state
var turret_angle: float = 0.0
var turret_target_angle: float = 0.0

# ─── Внутренние поля ──────────────────────────────────
var _hull_sprite: Sprite2D
var _turret_sprite: Sprite2D
var _selection_ring: Line2D
var _hull_direction_index: int = 0
var _turret_direction_index: int = 0
var _fire_timer: float = 0.0
var _is_selected: bool = false
var damage_flash_until_ms: int = 0
var _tile_size: Vector2i = Vector2i(203, 116)


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

        # Инициализация движения (начальный угол = South, как в Phaser)
        grid_movement = MovementStateMachine.GridMovementState.new(0, 0, PI / 2)
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


# Инициализация ссылки на game_world и tile_size (вызывается из GameWorld после add_child).
func init_combat_unit(game_world: Node2D, occupancy, reservation_map: TileReservationMap, \
                tile_size: Vector2i, get_occupancy_for_repath: Callable) -> void:
        _game_world = game_world
        _occupancy = occupancy
        _reservation_map = reservation_map
        _tile_size = tile_size
        _get_occupancy_for_repath = get_occupancy_for_repath

        # Создать movement config из hull stats
        movement_config = _create_movement_config()

        # Установить начальную позицию в tile-координатах
        var tile := IsoCoords.local_to_tile(global_position, _tile_size)
        grid_movement.ftx = float(tile.x)
        grid_movement.fty = float(tile.y)
        grid_movement.current_tile = tile
        grid_movement.target_tile = tile


func _create_movement_config() -> MovementStateMachine.GridMovementConfig:
        var stats: Dictionary = HULL_STATS.get(hull_id, HULL_STATS["wasp"])
        # speed указан в "pixel per sec"-подобных единицах; конвертируем в tiles/sec
        # В Phaser PIXELS_PER_TILE = 42. Здесь tile_size = 203, но для движения мы используем
        # tile-координаты напрямую, поэтому speed уже в tiles/sec (числа подобраны для геймплея).
        var speed_tiles := float(_hull_stat("speed")) / 42.0
        var config := MovementStateMachine.GridMovementConfig.new(
                speed_tiles,
                float(stats.get("accel", 8.0)),
                float(stats.get("braking", 6.0)),
                float(stats.get("turn_speed_deg", 120.0)),
                Constants.DEFAULT_ARRIVAL_THRESHOLD
        )
        return config


func _process(delta: float) -> void:
        if is_destroyed:
                return

        _fire_timer = maxf(_fire_timer - delta, 0.0)

        var now_ms := Time.get_ticks_msec()
        var delta_ms := int(delta * 1000)

        # Обновить turret aim (плавный поворот к turret_target_angle)
        _update_turret_aim(delta)

        # Если есть attack_target — боевой AI управляет движением (включая chase/stop решения)
        if is_instance_valid(attack_target):
                CombatTargeting.update_combat_for_vehicle(
                        self, attack_target, now_ms, delta_ms, _get_occupancy_for_repath
                )

        # Обновить движение через state machine (работает для всех фаз включая TARGET_CHASE)
        # State machine сама решает: turning/moving/braking/blocked/repathing
        var _result := MovementStateMachine.update(
                grid_movement, movement_config, delta_ms,
                _occupancy, _reservation_map, name, now_ms, _get_occupancy_for_repath
        )

        # Синхронизация визуальной позиции
        global_position = _tile_to_world(Vector2(grid_movement.ftx, grid_movement.fty))

        # Обновить поворот hull спрайта
        var new_hull_dir := Direction.angle_to_dir16(grid_movement.body_angle)
        if new_hull_dir != _hull_direction_index:
                _hull_direction_index = new_hull_dir
                _refresh_hull_sprite()

        # Обновить z-index
        z_index = _sort_z_from_position()

        # Восстановление цвета после damage flash
        if _hull_sprite and Time.get_ticks_msec() > damage_flash_until_ms:
                _hull_sprite.modulate = Color.WHITE


# ─── Команды ──────────────────────────────────────────

func command_move(target_position: Vector2) -> void:
        if _game_world == null or _occupancy == null:
                return
        # Конвертировать world position в tile (учитывая смещение game_world)
        var local_pos := target_position - _game_world.global_position
        var tile := IsoCoords.local_to_tile(local_pos, _tile_size)
        move_target = target_position
        attack_target = null
        # Найти путь через pathfinding
        var path := Pathfinding.find_path(_occupancy, grid_movement.round_tile(), tile)
        if path.size() > 0:
                MovementStateMachine.issue_move_command(grid_movement, path, tile)
        elif _occupancy.is_passable(tile.x, tile.y):
                # Возможно, цель совпадает с текущей позицией
                grid_movement.target_tile = tile


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
        # Обновить movement config (speed мог измениться)
        movement_config = _create_movement_config()
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
        movement_config = _create_movement_config()


func switch_turret(new_turret_id: String) -> void:
        if not TURRET_STATS.has(new_turret_id):
                return
        turret_id = new_turret_id
        _refresh_sprites()


func get_status_text() -> String:
        return "%s m%d + %s m%d | HP %d/%d" % [
                hull_id.capitalize(), hull_mod,
                turret_id.capitalize(), turret_mod,
                current_health, max_health
        ]


# ─── Боевая система ───────────────────────────────────

# Применить урон к юниту с учётом брони.
# Вызывается из projectile.gd при попадании.
func apply_damage(raw_damage: int) -> void:
        if is_destroyed:
                return
        var final_damage := DamageFormula.apply_armor_reduction(
                raw_damage, armor, min_damage_percent
        )
        current_health = maxi(current_health - final_damage, 0)
        damage_flash_until_ms = Time.get_ticks_msec() + Constants.DAMAGE_FLASH_DURATION_MS
        if _hull_sprite:
                _hull_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)
        if current_health <= 0:
                _on_destroyed()


# Попробовать выстрелить. Вызывается из CombatTargeting когда shouldFire && isAimed.
func try_fire_weapon(target: Node2D, now_ms: int) -> void:
        if is_destroyed:
                return
        if _fire_timer > 0:
                return
        if not is_instance_valid(target):
                return
        _fire(target)
        _fire_timer = _attack_cooldown()


# ─── Внутренние методы ────────────────────────────────

func _on_destroyed() -> void:
        if is_destroyed:
                return
        is_destroyed = true
        died.emit(self)
        # Освободить все резервы
        if _reservation_map:
                _reservation_map.release_all(name)
        # Очистить target-lock у врагов, которые целились в нас (через died signal)
        # Анимация исчезновения
        var tween := create_tween()
        tween.tween_property(self, "modulate:a", 0.0, 0.5)
        tween.tween_callback(queue_free)


func _update_turret_aim(delta: float) -> void:
        var turn_speed_rad := deg_to_rad(_turret_stat("turret_turn_speed_deg"))
        var max_delta := turn_speed_rad * delta
        var diff := Direction.normalize_angle(turret_target_angle - turret_angle)
        if abs(diff) <= max_delta:
                turret_angle = turret_target_angle
        else:
                turret_angle += signf(diff) * max_delta
        # Обновить визуальный поворот turret sprite
        _turret_sprite.rotation = turret_angle - grid_movement.body_angle
        # Обновить 16-dir индекс для текстуры
        var new_turret_dir := Direction.angle_to_dir16(turret_angle)
        if new_turret_dir != _turret_direction_index:
                _turret_direction_index = new_turret_dir
                _refresh_turret_sprite_only()


func _fire() -> void:
        # Заглушка — не используется, нужен target
        pass


func _fire(target: Node2D) -> void:
        if not is_instance_valid(target):
                return
        var projectile: Node2D = ProjectileScene.new()
        var start_offset := Vector2(0, -12)
        projectile.setup(global_position + start_offset, target, _attack_damage(), _projectile_speed(), \
                        _turret_stat("pierce_count"))
        var projectile_parent := get_tree().current_scene
        if projectile_parent == null:
                projectile_parent = get_parent()
        projectile_parent.add_child(projectile)


func _refresh_stats() -> void:
        max_health = int(_hull_stat("health"))
        armor = int(_hull_stat("armor"))
        min_damage_percent = float(_hull_stat("min_damage_percent"))
        current_health = max_health


func _refresh_sprites() -> void:
        if _hull_sprite == null or _turret_sprite == null:
                return
        _refresh_hull_sprite()
        _refresh_turret_sprite_only()


func _refresh_hull_sprite() -> void:
        if _hull_sprite == null:
                return
        var hull_texture := TextureLoader.load_png(
                Direction.texture_path("Hulls", hull_id, faction_id, hull_mod, _hull_direction_index)
        )
        if hull_texture:
                _hull_sprite.texture = hull_texture
                var hull_scale := float(_hull_stat("scale"))
                _hull_sprite.scale = Vector2(hull_scale, hull_scale)


func _refresh_turret_sprite_only() -> void:
        if _turret_sprite == null:
                return
        var turret_texture := TextureLoader.load_png(
                Direction.texture_path("Turrets", turret_id, faction_id, turret_mod, _turret_direction_index)
        )
        if turret_texture:
                _turret_sprite.texture = turret_texture
                var turret_scale := float(_hull_stat("scale"))
                _turret_sprite.scale = Vector2(turret_scale, turret_scale)


func _tile_to_world(tile_pos: Vector2) -> Vector2:
        return IsoCoords.tile_to_local(tile_pos, _tile_size)


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


func _movement_speed() -> float:
        return float(_hull_stat("speed"))


func _attack_range() -> float:
        return float(_turret_stat("range_max"))


func _attack_damage() -> int:
        return int(_turret_stat("damage"))


func _attack_cooldown() -> float:
        return float(_turret_stat("cooldown"))


func _projectile_speed() -> float:
        return float(_turret_stat("projectile_speed"))
