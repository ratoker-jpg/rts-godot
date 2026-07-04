extends Node2D

signal return_to_menu_requested

const TILE_SET_PATH := "res://Scenes/isometric_tiles_TOP_FACE_try.tres"
const CHUNK_MIN_SIZE := 6
const CHUNK_MAX_SIZE := 9
const EDGE_TILE := Vector2i(12, 0)
const PRIMARY_FLOOR_TILE := Vector2i(2, 0)
const PRIMARY_FLOOR_CHANCE := 0.72
const SOURCE_ID := 0
const ALT_ID := 0
const PLAYER_BASE_SIZE := 3
const PLAYER_BASE_CENTER_RATIO := Vector2(0.90, 0.90)
const PLAYER_BASE_EDGE_MARGIN := 10
const PLAYER_BASE_MAX_TIER := 3
const TREE_CLEAR_RADIUS_RATIO := 0.08
const DESTRUCTIBLE_ENVIRONMENT_SCRIPT := preload("res://Scripts/destructible_environment.gd")
const RESOURCE_DEPOSIT_SCRIPT := preload("res://Scripts/resource_deposit.gd")
const COMBAT_UNIT_SCRIPT := preload("res://Scripts/combat_unit.gd")
const BUILDING_CATALOG := preload("res://Scripts/building_catalog.gd")
const BUILDING_REGISTRY := preload("res://Scripts/building_registry.gd")
const ECONOMY_STATE := preload("res://Scripts/economy_state.gd")
const BUILDER_SPEED_TILES := 3.0
const HARVESTER_SPEED_TILES := 2.5
const HARVESTER_GATHER_MS := 1000
const HARVESTER_UNLOAD_MS := 500
const HARVESTER_CAPACITY := 20
const MODULAR_UNIT_SCALE := 0.16
# ─── Новые core-модули (Этап 1-4 рефакторинга) ───────
const Constants := preload("res://Scripts/core/constants.gd")
const Direction := preload("res://Scripts/utils/direction.gd")
const TextureLoader := preload("res://Scripts/utils/texture_loader.gd")
const IsoCoords := preload("res://Scripts/utils/iso_coords.gd")
const OccupancyMap := preload("res://Scripts/core/occupancy_map.gd")
const TileReservationMapClass := preload("res://Scripts/core/tile_reservation.gd")
const Pathfinding := preload("res://Scripts/core/pathfinding.gd")
const MovementStateMachine := preload("res://Scripts/core/movement_state_machine.gd")
const CombatRange := preload("res://Scripts/core/combat_range.gd")
const CombatTargeting := preload("res://Scripts/core/combat_targeting.gd")
const DamageFormula := preload("res://Scripts/core/damage_formula.gd")
const BuildSiteSelector := preload("res://Scripts/core/build_site_selector.gd")
const DebugFlags := preload("res://Scripts/core/debug_flags.gd")
const FACTORY_SPAWN_TIMEOUT_MS := 5000
const MODULAR_DIRECTIONS := [
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
const CIVIL_UNIT_VISUALS := {
        "builder": {"hull": "hunter", "turret": "railgun", "hull_mod": 0, "turret_mod": 0},
        "harvester": {"hull": "wasp", "turret": "smoky", "hull_mod": 0, "turret_mod": 0},
}
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
const RESOURCE_CLEARANCE_BY_TIER := [0, 0, 1, 1, 2, 4]
const CORNER_CYAN_FIELD_PATTERN := [
        {"offset": Vector2i(7, 7), "tier": 1},
        {"offset": Vector2i(6, 7), "tier": 1},
        {"offset": Vector2i(5, 7), "tier": 1},
        {"offset": Vector2i(4, 7), "tier": 1},
        {"offset": Vector2i(3, 7), "tier": 2},
        {"offset": Vector2i(2, 7), "tier": 2},
        {"offset": Vector2i(1, 7), "tier": 2},
        {"offset": Vector2i(7, 6), "tier": 1},
        {"offset": Vector2i(6, 6), "tier": 1},
        {"offset": Vector2i(5, 6), "tier": 1},
        {"offset": Vector2i(4, 6), "tier": 1},
        {"offset": Vector2i(3, 6), "tier": 1},
        {"offset": Vector2i(2, 6), "tier": 1},
        {"offset": Vector2i(1, 6), "tier": 2},
        {"offset": Vector2i(7, 5), "tier": 1},
        {"offset": Vector2i(6, 5), "tier": 1},
        {"offset": Vector2i(5, 5), "tier": 1},
        {"offset": Vector2i(4, 5), "tier": 1},
        {"offset": Vector2i(3, 5), "tier": 1},
        {"offset": Vector2i(2, 5), "tier": 1},
        {"offset": Vector2i(1, 5), "tier": 2},
        {"offset": Vector2i(7, 4), "tier": 1},
        {"offset": Vector2i(6, 4), "tier": 1},
        {"offset": Vector2i(5, 4), "tier": 1},
        {"offset": Vector2i(4, 4), "tier": 1},
        {"offset": Vector2i(3, 4), "tier": 1},
        {"offset": Vector2i(2, 4), "tier": 1},
        {"offset": Vector2i(1, 4), "tier": 3},
        {"offset": Vector2i(3, 3), "tier": 1},
        {"offset": Vector2i(2, 3), "tier": 1},
        {"offset": Vector2i(1, 3), "tier": 3},
        {"offset": Vector2i(3, 2), "tier": 1},
        {"offset": Vector2i(2, 2), "tier": 1},
        {"offset": Vector2i(1, 2), "tier": 3},
        {"offset": Vector2i(1, 1), "tier": 4},
]
const CORNER_CYAN_TRAIL_PATTERN := [
        {"offset": Vector2i(25, 25), "tier": 1},
        {"offset": Vector2i(26, 25), "tier": 1},
        {"offset": Vector2i(25, 26), "tier": 1},
        {"offset": Vector2i(24, 26), "tier": 1},
        {"offset": Vector2i(24, 27), "tier": 1},
        {"offset": Vector2i(23, 27), "tier": 1},
        {"offset": Vector2i(23, 28), "tier": 1},
        {"offset": Vector2i(22, 28), "tier": 1},
]
const START_CYAN_FIELD_PATTERN := [
        {"inward": Vector2i(4, 4), "tier": 2},
        {"inward": Vector2i(6, 4), "tier": 1},
        {"inward": Vector2i(4, 6), "tier": 1},
        {"inward": Vector2i(7, 6), "tier": 2},
        {"inward": Vector2i(6, 8), "tier": 1},
        {"inward": Vector2i(9, 5), "tier": 1},
        {"inward": Vector2i(5, 10), "tier": 3},
        {"inward": Vector2i(10, 9), "tier": 2},
]
const START_YELLOW_FIELD_PATTERN := [
        {"inward": Vector2i(12, 7), "tier": 2},
        {"inward": Vector2i(8, 12), "tier": 2},
]

var map_size: int = 32
var world_seed: int = 0
var player_faction_id: String = "cyan"
var player_faction_name: String = "Голубая"
var player_base_t1_path: String = "res://Assets/Buildings/cyan/base/t1.png"
var player_base_tier: int = 1

var _tile_map: TileMapLayer
var _camera: Camera2D
var _hud_label: Label
var _buildings_layer: Node2D
var _environment_layer: Node2D
var _resources_layer: Node2D
var _units_layer: Node2D
var _player_base: Sprite2D
var _player_base_origin_cell: Vector2i
var _player_base_center_cell: Vector2i
var _generated_chunks: Dictionary = {}
var _chunk_count: int = 0
var _blocked_cells: Dictionary = {}
var _building_cells: Dictionary = {}
var _reserved_building_cells: Dictionary = {}
var _passable_cover_cells: Dictionary = {}
var _occupied_environment_cells: Dictionary = {}
var _resource_cells: Dictionary = {}
var _reserved_resource_cells: Dictionary = {}
var _units: Array[Node2D] = []
var _selected_unit: Node2D
var _economy = ECONOMY_STATE.new()
var _gameplay_buildings: Array[Node2D] = []
var _gameplay_building_order: Array[Node2D] = []
var _construction_sites: Array[Node2D] = []
var _construction_cells: Dictionary = {}
var _civil_units: Array[Node2D] = []
var _builders: Array[Node2D] = []
var _harvesters: Array[Node2D] = []
var _selected_civil_unit: Node2D
var _selected_building: Node2D
var _selected_site: Node2D
var _build_mode_id: String = ""
var _build_ghost: Sprite2D
var _feedback_text: String = ""
var _next_construction_id: int = 1
var _next_civil_unit_id: int = 1
var _is_camera_dragging: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO
# ─── Новые поля для pathfinding и tile reservation ───
var _occupancy_map
var _tile_reservation_map

var _mineral_richness_defs: Array[Dictionary] = [
        {"id": "very_poor", "name": "Очень бедный", "amount": 300, "tier": 1, "infinite": false},
        {"id": "poor", "name": "Бедный", "amount": 650, "tier": 2, "infinite": false},
        {"id": "medium", "name": "Средний", "amount": 1200, "tier": 3, "infinite": false},
        {"id": "rich", "name": "Богатый", "amount": 2200, "tier": 4, "infinite": false},
        {"id": "very_rich", "name": "Очень богатый", "amount": 4200, "tier": 5, "infinite": false},
        {"id": "infinite", "name": "Бесконечный", "amount": 999999999, "tier": 6, "infinite": true}
]
var _infinite_mineral_def: Dictionary = _mineral_richness_defs[5]

var _metal_tiles: Array[Vector2i] = [
        Vector2i(0, 0),
        Vector2i(1, 0),
        Vector2i(3, 0),
        Vector2i(4, 0),
        Vector2i(5, 0),
        Vector2i(8, 0),
        Vector2i(9, 0),
        Vector2i(10, 0),
        Vector2i(14, 0),
        Vector2i(4, 1),
        Vector2i(9, 1),
        Vector2i(13, 1),
        Vector2i(4, 2),
        Vector2i(5, 2),
        Vector2i(9, 2),
        Vector2i(11, 5),
        Vector2i(15, 5),
        Vector2i(2, 6),
        Vector2i(3, 6)
]

var _sand_tiles: Array[Vector2i] = [
        Vector2i(2, 0),
        Vector2i(5, 0),
        Vector2i(8, 2),
        Vector2i(10, 2),
        Vector2i(14, 2),
        Vector2i(15, 3),
        Vector2i(6, 4),
        Vector2i(8, 4),
        Vector2i(10, 4),
        Vector2i(12, 4),
        Vector2i(0, 5),
        Vector2i(1, 5),
        Vector2i(2, 5),
        Vector2i(5, 5),
        Vector2i(6, 5),
        Vector2i(10, 5),
        Vector2i(0, 6),
        Vector2i(1, 6)
]

var _rust_tiles: Array[Vector2i] = [
        Vector2i(0, 1),
        Vector2i(3, 1),
        Vector2i(7, 1),
        Vector2i(10, 1),
        Vector2i(2, 2),
        Vector2i(7, 3),
        Vector2i(15, 3),
        Vector2i(5, 4),
        Vector2i(8, 4),
        Vector2i(9, 4),
        Vector2i(12, 4),
        Vector2i(14, 5)
]

var _glow_tiles: Array[Vector2i] = [
        Vector2i(11, 0),
        Vector2i(15, 0),
        Vector2i(2, 1),
        Vector2i(8, 1),
        Vector2i(7, 2),
        Vector2i(11, 2),
        Vector2i(12, 2),
        Vector2i(2, 3),
        Vector2i(10, 3),
        Vector2i(1, 4),
        Vector2i(4, 4),
        Vector2i(12, 5)
]

var _bush_assets: Array[String] = [
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_01.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_02.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_03.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_04.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_05.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_06.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_07.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_08.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_09.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_10.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_11.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_12.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_13.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_14.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_15.png",
        "res://Assets/Environment/Vegetation/bushes_a/bushes_a_16.png"
]

var _tree_a_assets: Array[String] = [
        "res://Assets/Environment/Vegetation/trees_a/trees_a_01.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_02.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_03.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_04.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_05.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_06.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_07.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_08.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_09.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_10.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_11.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_12.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_13.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_14.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_15.png",
        "res://Assets/Environment/Vegetation/trees_a/trees_a_16.png"
]

var _tree_b_assets: Array[String] = [
        "res://Assets/Environment/Vegetation/trees_b/trees_b_01.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_02.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_03.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_04.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_05.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_06.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_07.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_08.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_09.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_10.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_11.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_12.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_13.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_14.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_15.png",
        "res://Assets/Environment/Vegetation/trees_b/trees_b_16.png"
]


func _ready() -> void:
        world_seed = randi()
        _economy.reset()
        # Инициализация occupancy map и tile reservation
        _occupancy_map = OccupancyMap.new(map_size, map_size)
        _tile_reservation_map = TileReservationMapClass.new(map_size)
        _build_world_nodes()
        _generate_world_by_chunks()
        _spawn_player_base()
        _spawn_resource_deposits()
        _spawn_vegetation()
        # Перестроить occupancy после спавна всех объектов
        _rebuild_occupancy_map()
        _spawn_initial_combat_units()
        _spawn_initial_civil_units()
        _focus_camera_on_player_base()


# Перестроить occupancy map с учётом всех blockers (здания, ресурсы, вегетация).
# Вызывается при изменении мира (постройка/снос здания, depleted ресурс, etc.).
func _rebuild_occupancy_map() -> void:
        _occupancy_map = OccupancyMap.new(map_size, map_size)
        # Здания (включая player base)
        for cell in _building_cells.keys():
                _occupancy_map.add_impassable_point(cell.x, cell.y)
        # Ресурсы
        for cell in _resource_cells.keys():
                _occupancy_map.add_resource_point(cell.x, cell.y)
        # Вегетация (trees — blocks path, bushes — нет)
        for cell in _blocked_cells.keys():
                if not _building_cells.has(cell) and not _resource_cells.has(cell):
                        _occupancy_map.add_impassable_point(cell.x, cell.y)
        # Construction sites
        for cell in _construction_cells.keys():
                _occupancy_map.add_impassable_point(cell.x, cell.y)


# Callable для MovementStateMachine: возвращает свежую occupancy map с учётом юнитов.
func build_occupancy_for_repath():
        var fresh := _occupancy_map.duplicate()
        # Добавить гражданских юнитов как blockers
        for unit in _civil_units:
                if is_instance_valid(unit):
                        var cell: Vector2i = _civil_unit_cell(unit)
                        fresh.add_impassable_point(cell.x, cell.y)
        # Добавить боевых юнитов как blockers
        for unit in _units:
                if is_instance_valid(unit) and not unit.get("is_destroyed"):
                        var gm = unit.get("grid_movement")
                        if gm != null:
                                var cell := gm.round_tile()
                                fresh.add_impassable_point(cell.x, cell.y)
        # Добавить tile reservations
        for r in _tile_reservation_map.get_all_reservations():
                fresh.add_impassable_point(r.tx, r.ty)
        return fresh


func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_cancel"):
                if not _build_mode_id.is_empty():
                        _cancel_build_mode()
                else:
                        return_to_menu_requested.emit()
        elif event is InputEventMouseButton:
                var mouse_event := event as InputEventMouseButton
                if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
                        _camera.zoom *= 1.1
                elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
                        _camera.zoom /= 1.1
                elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
                        _is_camera_dragging = mouse_event.pressed
                        _last_mouse_position = mouse_event.position
                elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
                        if not _build_mode_id.is_empty():
                                _try_place_active_building(get_global_mouse_position())
                        else:
                                _select_unit_at_world_position(get_global_mouse_position())
                elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
                        if not _build_mode_id.is_empty():
                                _cancel_build_mode()
                        else:
                                _command_selected_unit_at_world_position(get_global_mouse_position())
        elif event is InputEventMouseMotion and _is_camera_dragging:
                var motion := event as InputEventMouseMotion
                _camera.position -= motion.relative / _camera.zoom.x
                _last_mouse_position = motion.position
        elif event is InputEventKey and event.pressed and not event.echo:
                _handle_unit_hotkey(event.keycode)


func _process(delta: float) -> void:
        _update_civil_runtime(delta * 1000.0)
        _update_build_ghost()
        _update_rts_hud_text()


func _build_world_nodes() -> void:
        y_sort_enabled = true

        _tile_map = TileMapLayer.new()
        _tile_map.name = "ProceduralTileMap"
        _tile_map.tile_set = load(TILE_SET_PATH)
        _tile_map.y_sort_enabled = true
        _tile_map.z_index = 0
        _tile_map.z_as_relative = false
        add_child(_tile_map)

        _environment_layer = Node2D.new()
        _environment_layer.name = "Environment"
        _environment_layer.y_sort_enabled = true
        _environment_layer.z_index = 10
        _environment_layer.z_as_relative = false
        add_child(_environment_layer)

        _resources_layer = Node2D.new()
        _resources_layer.name = "Resources"
        _resources_layer.y_sort_enabled = true
        _resources_layer.z_index = 15
        _resources_layer.z_as_relative = false
        add_child(_resources_layer)

        _units_layer = Node2D.new()
        _units_layer.name = "Units"
        _units_layer.y_sort_enabled = true
        _units_layer.z_index = 18
        _units_layer.z_as_relative = false
        add_child(_units_layer)

        _buildings_layer = Node2D.new()
        _buildings_layer.name = "Buildings"
        _buildings_layer.y_sort_enabled = true
        _buildings_layer.z_index = 20
        _buildings_layer.z_as_relative = false
        add_child(_buildings_layer)

        _camera = Camera2D.new()
        _camera.name = "Camera2D"
        _camera.enabled = true
        _camera.zoom = Vector2(0.55, 0.55)
        add_child(_camera)

        var ui := CanvasLayer.new()
        ui.name = "HUD"
        add_child(ui)

        _hud_label = Label.new()
        _hud_label.position = Vector2(16, 16)
        _update_rts_hud_text()
        _hud_label.add_theme_font_size_override("font_size", 16)
        ui.add_child(_hud_label)


func _generate_world_by_chunks() -> void:
        _generated_chunks.clear()
        _chunk_count = 0

        var rng := RandomNumberGenerator.new()
        rng.seed = world_seed

        var y: int = 0
        while y < map_size:
                var chunk_h: int = _pick_chunk_span(rng, y)
                var x: int = 0
                while x < map_size:
                        var chunk_w: int = _pick_chunk_span(rng, x)
                        _generate_chunk(Rect2i(x, y, chunk_w, chunk_h))
                        x += chunk_w
                y += chunk_h

        _update_rts_hud_text()


func _generate_chunk(chunk_rect: Rect2i) -> void:
        var chunk_key := "%d:%d:%d:%d" % [
                chunk_rect.position.x,
                chunk_rect.position.y,
                chunk_rect.size.x,
                chunk_rect.size.y
        ]
        if _generated_chunks.has(chunk_key):
                return

        var start_x: int = chunk_rect.position.x
        var start_y: int = chunk_rect.position.y
        var end_x: int = min(start_x + chunk_rect.size.x, map_size)
        var end_y: int = min(start_y + chunk_rect.size.y, map_size)
        var chunk_theme: Dictionary = _pick_chunk_theme(chunk_rect)

        for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                        var cell := Vector2i(x, y)
                        var atlas_coords := EDGE_TILE if _is_map_edge(cell) else _pick_interior_tile(cell, chunk_rect, chunk_theme)
                        _tile_map.set_cell(cell, SOURCE_ID, atlas_coords, ALT_ID)

        _generated_chunks[chunk_key] = true
        _chunk_count += 1


func _pick_chunk_span(rng: RandomNumberGenerator, start: int) -> int:
        var remaining: int = map_size - start
        if remaining <= CHUNK_MAX_SIZE:
                return remaining

        var span: int = rng.randi_range(CHUNK_MIN_SIZE, CHUNK_MAX_SIZE)
        var leftover: int = remaining - span
        if leftover > 0 and leftover < CHUNK_MIN_SIZE:
                span = remaining - CHUNK_MIN_SIZE

        return clampi(span, CHUNK_MIN_SIZE, CHUNK_MAX_SIZE)


func _is_map_edge(cell: Vector2i) -> bool:
        return cell.x == 0 or cell.y == 0 or cell.x == map_size - 1 or cell.y == map_size - 1


func _pick_chunk_theme(chunk_rect: Rect2i) -> Dictionary:
        var rng := RandomNumberGenerator.new()
        rng.seed = _hash_chunk(chunk_rect)

        var center_strength: float = _center_strength_for_cell(_chunk_center_cell(chunk_rect))
        var theme_roll: float = rng.randf()
        var tile_pool: Array[Vector2i]
        var accent_pool: Array[Vector2i]
        var glow_multiplier: float = 1.0
        var kind := "main"

        if theme_roll < 0.68:
                kind = "main"
                tile_pool = _metal_tiles
                accent_pool = _sand_tiles
                glow_multiplier = 0.25
        elif center_strength > 0.74 and theme_roll < 0.82:
                kind = "center_metal"
                tile_pool = _metal_tiles
                accent_pool = _sand_tiles
                glow_multiplier = 1.0
        elif theme_roll < 0.88:
                kind = "sand"
                tile_pool = _sand_tiles
                accent_pool = _metal_tiles
                glow_multiplier = 0.15
        elif theme_roll < 0.96:
                kind = "metal"
                tile_pool = _metal_tiles
                accent_pool = _sand_tiles
                glow_multiplier = 0.2
        else:
                kind = "rust"
                tile_pool = _rust_tiles
                accent_pool = _sand_tiles
                glow_multiplier = 0.1

        var base_a: Vector2i = tile_pool[rng.randi_range(0, tile_pool.size() - 1)]
        var base_b: Vector2i = tile_pool[rng.randi_range(0, tile_pool.size() - 1)]
        var accent: Vector2i = accent_pool[rng.randi_range(0, accent_pool.size() - 1)]

        return {
                "kind": kind,
                "base_a": base_a,
                "base_b": base_b,
                "accent": accent,
                "glow_multiplier": glow_multiplier
        }


func _pick_interior_tile(cell: Vector2i, chunk_rect: Rect2i, chunk_theme: Dictionary) -> Vector2i:
        var hash_value: int = abs(_hash_cell(cell))
        var local_pattern: int = abs((cell.x - chunk_rect.position.x) * 31 + (cell.y - chunk_rect.position.y) * 17)
        var center_strength: float = _center_strength_for_cell(cell)
        var glow_strength: float = clampf((center_strength - 0.68) / 0.32, 0.0, 1.0)
        var glow_chance: float = glow_strength * glow_strength * 0.09 * float(chunk_theme["glow_multiplier"])
        var roll: float = float(hash_value % 1000) / 1000.0

        if roll < glow_chance:
                var glow_index: int = int(hash_value / 11.0) % _glow_tiles.size()
                return _glow_tiles[glow_index]

        var kind: String = str(chunk_theme["kind"])
        if kind == "main":
                if roll < 0.84:
                        return PRIMARY_FLOOR_TILE
                if local_pattern % 13 == 0:
                        return chunk_theme["accent"]
                return chunk_theme["base_a"]

        if roll < PRIMARY_FLOOR_CHANCE and kind == "center_metal":
                return PRIMARY_FLOOR_TILE

        if local_pattern % 17 == 0:
                return chunk_theme["accent"]

        if local_pattern % 4 == 0:
                return chunk_theme["base_b"]

        return chunk_theme["base_a"]


func _center_strength_for_cell(cell: Vector2i) -> float:
        var center := Vector2((map_size - 1) * 0.5, (map_size - 1) * 0.5)
        var cell_position := Vector2(cell.x, cell.y)
        var max_distance := center.length()
        if max_distance <= 0.0:
                return 1.0

        var normalized_distance: float = clampf(cell_position.distance_to(center) / max_distance, 0.0, 1.0)
        var strength: float = 1.0 - normalized_distance
        return strength * strength


func _chunk_center_cell(chunk_rect: Rect2i) -> Vector2i:
        return Vector2i(
                chunk_rect.position.x + int(chunk_rect.size.x * 0.5),
                chunk_rect.position.y + int(chunk_rect.size.y * 0.5)
        )


func _hash_cell(cell: Vector2i) -> int:
        var value := int(world_seed)
        value = value ^ int(cell.x * 73856093)
        value = value ^ int(cell.y * 19349663)
        value = value ^ int((cell.x + cell.y) * 83492791)
        return value


func _hash_chunk(chunk_rect: Rect2i) -> int:
        var value := int(world_seed)
        value = value ^ int(chunk_rect.position.x * 92837111)
        value = value ^ int(chunk_rect.position.y * 689287499)
        value = value ^ int(chunk_rect.size.x * 283923481)
        value = value ^ int(chunk_rect.size.y * 1928476349)
        return abs(value)


func _center_camera() -> void:
        var center_cell := Vector2i(int(map_size * 0.5), int(map_size * 0.5))
        _camera.position = _tile_map.map_to_local(center_cell)


func _spawn_player_base() -> void:
        var target_center_x: int = mini(
                roundi(float(map_size - 1) * PLAYER_BASE_CENTER_RATIO.x),
                map_size - PLAYER_BASE_EDGE_MARGIN
        )
        var target_center_y: int = mini(
                roundi(float(map_size - 1) * PLAYER_BASE_CENTER_RATIO.y),
                map_size - PLAYER_BASE_EDGE_MARGIN
        )
        _player_base_center_cell = Vector2i(
                clampi(target_center_x, 2, map_size - 3),
                clampi(target_center_y, 2, map_size - 3)
        )
        var base_texture_path := _base_texture_path_for_tier(player_base_tier)
        var base_footprint := BUILDING_CATALOG.get_footprint(base_texture_path)
        var base_x: int = clampi(_player_base_center_cell.x - int(base_footprint.x * 0.5), 1, map_size - base_footprint.x - 1)
        var base_y: int = clampi(_player_base_center_cell.y - int(base_footprint.y * 0.5), 1, map_size - base_footprint.y - 1)
        _player_base_origin_cell = Vector2i(base_x, base_y)
        var base_center_cell := _player_base_origin_cell + BUILDING_CATALOG.get_visual_anchor_cell(base_texture_path)
        _player_base_center_cell = base_center_cell

        for y in range(_player_base_origin_cell.y, _player_base_origin_cell.y + base_footprint.y):
                for x in range(_player_base_origin_cell.x, _player_base_origin_cell.x + base_footprint.x):
                        _tile_map.set_cell(Vector2i(x, y), SOURCE_ID, EDGE_TILE, ALT_ID)

        var texture := _load_png_texture(base_texture_path)
        if texture == null:
                return

        _player_base = Sprite2D.new()
        _player_base.name = "PlayerBase"
        _player_base.texture = texture
        _player_base.centered = true
        _player_base.position = _building_visual_position(base_texture_path, _player_base_origin_cell)
        _player_base.z_index = _sort_z_for_footprint(BUILDING_CATALOG.get_footprint_cells(_player_base_origin_cell, base_texture_path), 2)
        _player_base.set_meta("gameplay_building", true)
        _player_base.set_meta("building_id", "hq")
        _player_base.set_meta("modification_tier", player_base_tier)

        _scale_player_base_to_footprint(texture, base_texture_path)
        _register_building_occupancy(_player_base, base_texture_path, _player_base_origin_cell)
        _player_base.set_meta("gameplay_building", true)
        _player_base.set_meta("building_id", "hq")
        _player_base.set_meta("modification_tier", player_base_tier)

        _buildings_layer.add_child(_player_base)


func upgrade_player_base_to_tier(tier: int) -> void:
        player_base_tier = clampi(tier, 1, PLAYER_BASE_MAX_TIER)
        if _player_base == null:
                return

        var texture_path := _base_texture_path_for_tier(player_base_tier)
        var texture := _load_png_texture(texture_path)
        if texture == null:
                return

        _player_base.texture = texture
        _player_base.position = _building_visual_position(texture_path, _player_base_origin_cell)
        _player_base.z_index = _sort_z_for_footprint(BUILDING_CATALOG.get_footprint_cells(_player_base_origin_cell, texture_path), 2)
        _scale_player_base_to_footprint(texture, texture_path)
        _player_base.set_meta("asset_key", BUILDING_CATALOG.asset_key(texture_path))
        _player_base.set_meta("building_id", "hq")
        _player_base.set_meta("modification_tier", player_base_tier)


func _base_texture_path_for_tier(tier: int) -> String:
        if tier <= 1:
                return player_base_t1_path
        return "res://Assets/Buildings/%s/base/t%d.png" % [player_faction_id, clampi(tier, 1, PLAYER_BASE_MAX_TIER)]


func _scale_player_base_to_footprint(texture: Texture2D, texture_path: String) -> void:
        _player_base.scale = BUILDING_CATALOG.get_visual_scale(texture_path, texture, _tile_map.tile_set.tile_size)


func can_place_building(texture_path: String, origin_cell: Vector2i) -> bool:
        return _is_building_placement_allowed(texture_path, origin_cell)


func spawn_building(texture_path: String, origin_cell: Vector2i, gameplay_id: String = "") -> Node2D:
        if not _is_building_placement_allowed(texture_path, origin_cell):
                return null
        var texture := _load_png_texture(texture_path)
        if texture == null:
                return null

        var building := Sprite2D.new()
        building.name = "%s_%d_%d" % [BUILDING_CATALOG.asset_key(texture_path).get_file().get_basename().capitalize(), origin_cell.x, origin_cell.y]
        building.texture = texture
        building.centered = true
        building.position = _building_visual_position(texture_path, origin_cell)
        building.scale = BUILDING_CATALOG.get_visual_scale(texture_path, texture, _tile_map.tile_set.tile_size)
        building.z_index = _sort_z_for_footprint(BUILDING_CATALOG.get_footprint_cells(origin_cell, texture_path), 2)
        building.z_as_relative = false
        _register_building_occupancy(building, texture_path, origin_cell)
        if not gameplay_id.is_empty():
                building.set_meta("building_id", gameplay_id)
        _buildings_layer.add_child(building)
        return building


func _building_visual_position(texture_path: String, origin_cell: Vector2i) -> Vector2:
        var anchor_cell := origin_cell + BUILDING_CATALOG.get_visual_anchor_cell(texture_path)
        return _tile_map.map_to_local(anchor_cell) + BUILDING_CATALOG.get_visual_offset(texture_path)


func _register_building_occupancy(building: Node2D, texture_path: String, origin_cell: Vector2i) -> void:
        var footprint_cells := BUILDING_CATALOG.get_footprint_cells(origin_cell, texture_path)
        var reserved_cells := BUILDING_CATALOG.get_reserved_cells(origin_cell, texture_path)
        building.set_meta("cell", origin_cell)
        building.set_meta("origin_cell", origin_cell)
        building.set_meta("asset_key", BUILDING_CATALOG.asset_key(texture_path))
        var gameplay_id := BUILDING_REGISTRY.building_id_from_texture_path(texture_path)
        building.set_meta("building_id", gameplay_id if not gameplay_id.is_empty() else BUILDING_CATALOG.get_building_id(texture_path))
        building.set_meta("modification_tier", BUILDING_CATALOG.get_modification_tier(texture_path))
        building.set_meta("footprint", BUILDING_CATALOG.get_footprint(texture_path))
        building.set_meta("footprint_cells", footprint_cells)
        building.set_meta("reserved_cells", reserved_cells)
        building.set_meta("blocks_path", true)

        for footprint_cell in footprint_cells:
                _building_cells[footprint_cell] = building
                _blocked_cells[footprint_cell] = building
        for reserved_cell in reserved_cells:
                _reserved_building_cells[reserved_cell] = building


func _is_building_placement_allowed(texture_path: String, origin_cell: Vector2i) -> bool:
        for footprint_cell in BUILDING_CATALOG.get_footprint_cells(origin_cell, texture_path):
                if not _is_cell_inside_map(footprint_cell):
                        return false
                if _reserved_building_cells.has(footprint_cell):
                        return false
                if _blocked_cells.has(footprint_cell):
                        return false
                if _resource_cells.has(footprint_cell):
                        return false
                if _occupied_environment_cells.has(footprint_cell):
                        return false
                for unit in _civil_units:
                        if is_instance_valid(unit) and _civil_unit_cell(unit) == footprint_cell:
                                return false
        return true


func _spawn_vegetation() -> void:
        _blocked_cells.clear()
        _passable_cover_cells.clear()
        _occupied_environment_cells.clear()

        var rng := RandomNumberGenerator.new()
        rng.seed = int(world_seed) ^ 0x6a8e3f2d

        _spawn_environment_walls(rng)

        var tree_cluster_count: int = maxi(2, int(float(map_size) / 12.0))
        var bush_cluster_count: int = maxi(3, int(float(map_size) / 10.0))

        for i in range(tree_cluster_count):
                var center_cell := _pick_environment_patch_center(rng)
                var use_tree_a := rng.randf() < 0.55
                var tree_assets := _tree_a_assets if use_tree_a else _tree_b_assets
                var tree_kind := "trees_a" if use_tree_a else "trees_b"
                _spawn_environment_patch(rng, center_cell, tree_kind, tree_assets, rng.randi_range(3, 8), rng.randi_range(2, 4))

        for i in range(bush_cluster_count):
                var center_cell := _pick_environment_patch_center(rng)
                _spawn_environment_patch(rng, center_cell, "bushes_a", _bush_assets, rng.randi_range(3, 7), rng.randi_range(2, 5))


func _spawn_environment_walls(rng: RandomNumberGenerator) -> void:
        var wall_count := maxi(3, int(float(map_size) / 16.0))
        for i in range(wall_count):
                var use_trees := rng.randf() < 0.58
                var kind := "trees_a" if rng.randf() < 0.5 else "trees_b"
                var assets := _tree_a_assets if kind == "trees_a" else _tree_b_assets
                if not use_trees:
                        kind = "bushes_a"
                        assets = _bush_assets

                var start := _pick_environment_patch_center(rng)
                var direction := _random_wall_direction(rng)
                var length := rng.randi_range(maxi(5, int(float(map_size) * 0.12)), maxi(8, int(float(map_size) * 0.24)))
                var thickness := 1 if use_trees else rng.randi_range(1, 2)
                _spawn_environment_wall(rng, start, direction, kind, assets, length, thickness)


func _spawn_environment_wall(
        rng: RandomNumberGenerator,
        start_cell: Vector2i,
        direction: Vector2i,
        kind: String,
        asset_paths: Array[String],
        length: int,
        thickness: int
) -> void:
        var perpendicular := Vector2i(-direction.y, direction.x)
        for step in range(length):
                var bend := 0
                if step > 0 and step % rng.randi_range(4, 7) == 0:
                        bend = rng.randi_range(-1, 1)
                for width_offset in range(-thickness, thickness + 1):
                        if rng.randf() < 0.18:
                                continue
                        var cell := start_cell + direction * step + perpendicular * width_offset + perpendicular * bend
                        if not _is_environment_cell_allowed(cell):
                                continue
                        var texture_path := asset_paths[rng.randi_range(0, asset_paths.size() - 1)]
                        _spawn_environment_object(kind, cell, texture_path)


func _random_wall_direction(rng: RandomNumberGenerator) -> Vector2i:
        var directions: Array[Vector2i] = [
                Vector2i(1, 0),
                Vector2i(0, 1),
                Vector2i(1, 1),
                Vector2i(1, -1),
        ]
        return directions[rng.randi_range(0, directions.size() - 1)]


func _pick_environment_patch_center(rng: RandomNumberGenerator) -> Vector2i:
        for attempt in range(80):
                var cell := Vector2i(
                        rng.randi_range(3, map_size - 4),
                        rng.randi_range(3, map_size - 4)
                )
                if _is_environment_cell_allowed(cell):
                        return cell

        return Vector2i(int(map_size * 0.5), int(map_size * 0.5))


func _spawn_environment_patch(
        rng: RandomNumberGenerator,
        center_cell: Vector2i,
        kind: String,
        asset_paths: Array[String],
        count: int,
        radius: int
) -> void:
        for i in range(count):
                var cell := center_cell + Vector2i(
                        rng.randi_range(-radius, radius),
                        rng.randi_range(-radius, radius)
                )
                if not _is_environment_cell_allowed(cell):
                        continue
                var texture_path := asset_paths[rng.randi_range(0, asset_paths.size() - 1)]
                _spawn_environment_object(kind, cell, texture_path)


func _spawn_environment_object(kind: String, cell: Vector2i, texture_path: String) -> void:
        var texture := _load_png_texture(texture_path)
        if texture == null:
                return

        var is_tree := kind.begins_with("trees")
        var root: Node2D
        if is_tree:
                var body := DESTRUCTIBLE_ENVIRONMENT_SCRIPT.new()
                body.name = _environment_name_for(kind, cell)
                body.max_health = 100
                body.blocks_path = true
                body.destroyed.connect(_on_environment_destroyed.bind(cell))
                root = body

                var shape := CollisionShape2D.new()
                var circle := CircleShape2D.new()
                circle.radius = 34.0
                shape.shape = circle
                shape.position = Vector2(0, 22)
                body.add_child(shape)
                _blocked_cells[cell] = body
        else:
                root = Node2D.new()
                root.name = _environment_name_for(kind, cell)
                root.set_meta("blocks_path", false)
                root.set_meta("passable_cover", true)
                _passable_cover_cells[cell] = root

        root.position = _tile_map.map_to_local(cell) + _environment_offset_for(kind)
        root.z_index = _sort_z_for_cell(cell, -2)
        root.z_as_relative = false
        root.set_meta("cell", cell)
        root.set_meta("environment_kind", kind)

        var sprite := Sprite2D.new()
        sprite.name = "Sprite"
        sprite.texture = texture
        sprite.centered = true
        sprite.scale = _environment_scale_for(kind)
        root.add_child(sprite)

        _environment_layer.add_child(root)
        _reserve_environment_cells(root, kind, cell)


func _reserve_environment_cells(root: Node2D, kind: String, cell: Vector2i) -> void:
        var reserved_cells: Array[Vector2i] = []
        var radius := _environment_clearance_radius(kind)
        for y in range(cell.y - radius, cell.y + radius + 1):
                for x in range(cell.x - radius, cell.x + radius + 1):
                        var reserved_cell := Vector2i(x, y)
                        if not _is_cell_inside_map(reserved_cell):
                                continue
                        reserved_cells.append(reserved_cell)
                        _occupied_environment_cells[reserved_cell] = root
        root.set_meta("reserved_cells", reserved_cells)


func _environment_offset_for(kind: String) -> Vector2:
        match kind:
                "bushes_a":
                        return Vector2(-4, -14)
                "trees_a":
                        return Vector2(-6, 15)
                "trees_b":
                        return Vector2(8, 8)
        return Vector2.ZERO


func _environment_scale_for(kind: String) -> Vector2:
        if kind == "bushes_a":
                return Vector2(0.5080971, 0.5080971)
        return Vector2.ONE


func _environment_clearance_radius(kind: String) -> int:
        if kind == "bushes_a":
                return 1
        return 2


func _environment_name_for(kind: String, cell: Vector2i) -> String:
        return "%s_%d_%d" % [kind.replace("_", "").capitalize(), cell.x, cell.y]


func _is_environment_cell_allowed(cell: Vector2i) -> bool:
        if cell.x <= 1 or cell.y <= 1 or cell.x >= map_size - 2 or cell.y >= map_size - 2:
                return false
        if _is_cell_reserved_for_base(cell):
                return false
        if _reserved_building_cells.has(cell):
                return false
        if _resource_cells.has(cell) or _reserved_resource_cells.has(cell):
                return false
        return not _occupied_environment_cells.has(cell)


func _is_cell_reserved_for_base(cell: Vector2i) -> bool:
        if cell.x >= _player_base_origin_cell.x - 1 and cell.x <= _player_base_origin_cell.x + PLAYER_BASE_SIZE:
                if cell.y >= _player_base_origin_cell.y - 1 and cell.y <= _player_base_origin_cell.y + PLAYER_BASE_SIZE:
                        return true

        var clear_radius: float = maxf(4.0, float(map_size) * TREE_CLEAR_RADIUS_RATIO)
        return Vector2(cell.x, cell.y).distance_to(Vector2(_player_base_center_cell.x, _player_base_center_cell.y)) < clear_radius


func _is_cell_on_player_base_footprint(cell: Vector2i, margin: int = 0) -> bool:
        if cell.x < _player_base_origin_cell.x - margin:
                return false
        if cell.y < _player_base_origin_cell.y - margin:
                return false
        if cell.x > _player_base_origin_cell.x + PLAYER_BASE_SIZE - 1 + margin:
                return false
        if cell.y > _player_base_origin_cell.y + PLAYER_BASE_SIZE - 1 + margin:
                return false
        return true


func is_cell_blocked(cell: Vector2i) -> bool:
        return _building_cells.has(cell) or _resource_cells.has(cell) or _blocked_cells.has(cell)


func is_cell_passable_cover(cell: Vector2i) -> bool:
        return _passable_cover_cells.has(cell)


func damage_environment_at_cell(cell: Vector2i, amount: int) -> void:
        var environment_object: Object = _blocked_cells.get(cell)
        if environment_object == null:
                return
        if environment_object.has_method("apply_damage"):
                environment_object.apply_damage(amount)


func _on_environment_destroyed(cell: Vector2i) -> void:
        _blocked_cells.erase(cell)
        var environment_object: Object = _occupied_environment_cells.get(cell)
        if environment_object != null and environment_object.has_meta("reserved_cells"):
                for reserved_cell in environment_object.get_meta("reserved_cells"):
                        if _occupied_environment_cells.get(reserved_cell) == environment_object:
                                _occupied_environment_cells.erase(reserved_cell)
        else:
                _occupied_environment_cells.erase(cell)


func _spawn_initial_combat_units() -> void:
        _spawn_combat_unit_near_player_base("wasp", "smoky")


func _spawn_combat_unit_near_player_base(hull_id: String, turret_id: String) -> Node2D:
        var preferred_cell := _player_base_center_cell + Vector2i(-5, -5)
        var spawn_cell := _nearest_free_unit_cell(preferred_cell, 8)
        if spawn_cell.x < 0:
                spawn_cell = _player_base_center_cell + Vector2i(-4, -4)
        var spawn_position := _tile_map.map_to_local(spawn_cell)
        return _spawn_combat_unit(hull_id, turret_id, spawn_position)


func _spawn_combat_unit(hull_id: String, turret_id: String, spawn_position: Vector2) -> Node2D:
        var unit: Node2D = COMBAT_UNIT_SCRIPT.new()
        unit.name = "%s_%s_%02d" % [hull_id.capitalize(), turret_id.capitalize(), _units.size() + 1]
        unit.global_position = spawn_position
        unit.call("setup", player_faction_id, hull_id, turret_id, 0, 0)
        _units_layer.add_child(unit)
        # Инициализация movement state machine (после add_child, чтобы было дерево)
        var tile_size: Vector2i = _tile_map.tile_set.tile_size
        unit.call("init_combat_unit", self, _occupancy_map, _tile_reservation_map, tile_size, build_occupancy_for_repath)
        _units.append(unit)
        _select_unit(unit)
        return unit


func _nearest_free_unit_cell(origin: Vector2i, max_radius: int = 6) -> Vector2i:
        if _is_unit_cell_allowed(origin):
                return origin

        for radius in range(1, max_radius + 1):
                for y in range(-radius, radius + 1):
                        for x in range(-radius, radius + 1):
                                if abs(x) != radius and abs(y) != radius:
                                        continue
                                var candidate := Vector2i(
                                        clampi(origin.x + x, 2, map_size - 3),
                                        clampi(origin.y + y, 2, map_size - 3)
                                )
                                if _is_unit_cell_allowed(candidate):
                                        return candidate

        return Vector2i(-1, -1)


func _is_unit_cell_allowed(cell: Vector2i) -> bool:
        if not _is_cell_inside_map(cell):
                return false
        if _is_cell_on_player_base_footprint(cell, 1):
                return false
        if is_cell_blocked(cell):
                return false
        return true


func _select_unit_at_world_position(world_position: Vector2) -> void:
        var civil_unit := _find_civil_unit_near_world_position(world_position, 70.0)
        if civil_unit != null:
                _select_civil_unit(civil_unit)
                return

        var building := _find_building_at_world_position(world_position)
        if building != null:
                _select_building(building)
                return

        var site := _find_construction_site_at_world_position(world_position)
        if site != null:
                _select_site(site)
                return

        var nearest_unit: Node2D
        var nearest_distance := 999999.0
        for unit in _units:
                if not is_instance_valid(unit):
                        continue
                var distance := unit.global_position.distance_to(world_position)
                if distance < nearest_distance:
                        nearest_distance = distance
                        nearest_unit = unit

        if nearest_unit != null and nearest_distance <= 80.0:
                _select_unit(nearest_unit)
        else:
                _select_unit(null)


func _select_unit(unit: Node2D) -> void:
        if is_instance_valid(_selected_unit) and _selected_unit.has_method("set_selected"):
                _selected_unit.call("set_selected", false)
        _clear_civil_selection()
        _selected_unit = unit
        if is_instance_valid(_selected_unit) and _selected_unit.has_method("set_selected"):
                _selected_unit.call("set_selected", true)
        _update_rts_hud_text()


func _command_selected_unit_at_world_position(world_position: Vector2) -> void:
        if is_instance_valid(_selected_civil_unit):
                _command_civil_unit_at_world_position(_selected_civil_unit, world_position)
                return

        if not is_instance_valid(_selected_unit):
                return

        var cell := _tile_map.local_to_map(_tile_map.to_local(world_position))
        # Проверка: RMB на вражеском боевом юните → target-lock
        var enemy_unit := _find_combat_unit_near_world_position(world_position, 70.0)
        if enemy_unit != null and enemy_unit != _selected_unit:
                _selected_unit.call("command_attack", enemy_unit)
                return
        # Проверка: RMB на destructible environment
        var target_object: Object = _blocked_cells.get(cell)
        if target_object is Node2D and target_object.has_meta("destructible"):
                _selected_unit.call("command_attack", target_object)
                return

        var nearby_target := _find_destructible_target_near_world_position(world_position, 110.0)
        if nearby_target != null:
                _selected_unit.call("command_attack", nearby_target)
                return

        # Иначе — движение
        var destination := _tile_map.map_to_local(_clamp_unit_cell(cell))
        _selected_unit.call("command_move", destination)


# Найти боевой юнит рядом с позицией (для RMB attack command).
func _find_combat_unit_near_world_position(world_position: Vector2, radius: float) -> Node2D:
        var nearest_unit: Node2D
        var nearest_distance := radius
        for unit in _units:
                if not is_instance_valid(unit):
                        continue
                if unit == _selected_unit:
                        continue
                var distance := unit.global_position.distance_to(world_position)
                if distance < nearest_distance:
                        nearest_distance = distance
                        nearest_unit = unit
        return nearest_unit


func _clamp_unit_cell(cell: Vector2i) -> Vector2i:
        return Vector2i(
                clampi(cell.x, 1, map_size - 2),
                clampi(cell.y, 1, map_size - 2)
        )


func _find_destructible_target_near_world_position(world_position: Vector2, radius: float) -> Node2D:
        var nearest_target: Node2D
        var nearest_distance := radius
        for target_object in _blocked_cells.values():
                if not target_object is Node2D:
                        continue
                var target := target_object as Node2D
                if not is_instance_valid(target):
                        continue
                if not target.has_meta("destructible"):
                        continue
                var distance := target.global_position.distance_to(world_position)
                if distance < nearest_distance:
                        nearest_distance = distance
                        nearest_target = target
        return nearest_target


func _spawn_initial_civil_units() -> void:
        var builder_cell := _nearest_free_civil_cell(_player_base_center_cell + Vector2i(-4, -2), 8)
        if builder_cell.x >= 0:
                _spawn_civil_unit("builder", builder_cell)

        var harvester_cell := _nearest_free_civil_cell(_player_base_center_cell + Vector2i(-5, -3), 8)
        if harvester_cell.x >= 0:
                _spawn_civil_unit("harvester", harvester_cell)

        if _builders.size() > 0:
                _select_civil_unit(_builders[0])


func _spawn_civil_unit(unit_type: String, cell: Vector2i) -> Node2D:
        if not _is_civil_spawn_cell_allowed(cell):
                return null

        var unit := Node2D.new()
        unit.name = "%s_%02d" % [unit_type.capitalize(), _next_civil_unit_id]
        _next_civil_unit_id += 1
        unit.y_sort_enabled = true
        unit.z_index = _sort_z_for_cell(cell, 5)
        unit.z_as_relative = false

        var hull_sprite := Sprite2D.new()
        hull_sprite.name = "Hull"
        hull_sprite.centered = true
        unit.add_child(hull_sprite)

        var turret_sprite := Sprite2D.new()
        turret_sprite.name = "Turret"
        turret_sprite.centered = true
        turret_sprite.z_index = 2
        unit.add_child(turret_sprite)

        var ring := _make_selection_ring(34.0)
        ring.name = "SelectionRing"
        ring.visible = false
        unit.add_child(ring)

        var progress := Line2D.new()
        progress.name = "ProgressLine"
        progress.width = 4.0
        progress.default_color = Color(0.1, 0.9, 1.0, 1.0)
        progress.visible = false
        unit.add_child(progress)

        unit.set_meta("civil_unit", true)
        unit.set_meta("unit_type", unit_type)
        unit.set_meta("phase", "idle")
        unit.set_meta("cell", cell)
        unit.set_meta("fpos", Vector2(cell))
        unit.set_meta("visual_dir", 4)
        unit.set_meta("path", [])
        unit.set_meta("path_index", 0)
        unit.set_meta("blocked_reason", "")
        unit.set_meta("cargo", 0)
        unit.global_position = _tile_float_to_local(Vector2(cell))
        _refresh_civil_unit_visual(unit)

        _units_layer.add_child(unit)
        _civil_units.append(unit)
        if unit_type == "builder":
                _builders.append(unit)
        else:
                _harvesters.append(unit)
        return unit


func _make_selection_ring(radius: float) -> Line2D:
        var line := Line2D.new()
        line.width = 3.0
        line.default_color = Color(0.0, 0.9, 1.0, 0.95)
        var points := PackedVector2Array()
        for i in range(33):
                var angle := TAU * float(i) / 32.0
                points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.48))
        line.points = points
        return line


func _refresh_civil_unit_visual(unit: Node2D) -> void:
        var hull_sprite := unit.get_node_or_null("Hull") as Sprite2D
        var turret_sprite := unit.get_node_or_null("Turret") as Sprite2D
        if hull_sprite == null or turret_sprite == null:
                return
        var unit_type := str(unit.get_meta("unit_type", "harvester"))
        var visual: Dictionary = CIVIL_UNIT_VISUALS.get(unit_type, CIVIL_UNIT_VISUALS["harvester"])
        var direction_index := int(unit.get_meta("visual_dir", 4))
        var hull_texture := _load_png_texture(_modular_unit_texture_path("Hulls", str(visual["hull"]), int(visual["hull_mod"]), direction_index))
        if hull_texture != null:
                hull_sprite.texture = hull_texture
                hull_sprite.scale = Vector2(MODULAR_UNIT_SCALE, MODULAR_UNIT_SCALE)

        var turret_texture := _load_png_texture(_modular_unit_texture_path("Turrets", str(visual["turret"]), int(visual["turret_mod"]), direction_index))
        if turret_texture != null:
                turret_sprite.texture = turret_texture
                turret_sprite.scale = Vector2(MODULAR_UNIT_SCALE, MODULAR_UNIT_SCALE)


func _modular_unit_texture_path(kind: String, asset_id: String, mod_level: int, direction_index: int) -> String:
        var direction_name: String = MODULAR_DIRECTIONS[clampi(direction_index, 0, MODULAR_DIRECTIONS.size() - 1)]
        return "res://Assets/Units/%s/%s/%s/m%d/%s_%s_m%d_dir%02d_%s.png" % [
                kind,
                asset_id,
                player_faction_id,
                mod_level,
                asset_id,
                player_faction_id,
                mod_level,
                direction_index,
                direction_name,
        ]


func _grid_delta_to_dir16(delta: Vector2) -> int:
        if delta.length_squared() <= 0.0001:
                return 4
        var angle := atan2(delta.y, delta.x)
        var adjusted := fposmod(angle + PI * 0.5, TAU)
        return posmod(int(round(adjusted / (TAU / 16.0))), 16)


func _clear_civil_selection() -> void:
        if is_instance_valid(_selected_civil_unit):
                var ring := _selected_civil_unit.get_node_or_null("SelectionRing")
                if ring != null:
                        ring.visible = false
        _selected_civil_unit = null
        _selected_building = null
        _selected_site = null


func _clear_combat_selection() -> void:
        if is_instance_valid(_selected_unit) and _selected_unit.has_method("set_selected"):
                _selected_unit.call("set_selected", false)
        _selected_unit = null


func _select_civil_unit(unit: Node2D) -> void:
        _clear_combat_selection()
        _clear_civil_selection()
        _selected_civil_unit = unit
        if is_instance_valid(_selected_civil_unit):
                var ring := _selected_civil_unit.get_node_or_null("SelectionRing")
                if ring != null:
                        ring.visible = true
        _update_rts_hud_text()


func _select_building(building: Node2D) -> void:
        _clear_combat_selection()
        _clear_civil_selection()
        _selected_building = building
        _update_rts_hud_text()


func _select_site(site: Node2D) -> void:
        _clear_combat_selection()
        _clear_civil_selection()
        _selected_site = site
        _update_rts_hud_text()


func _find_civil_unit_near_world_position(world_position: Vector2, radius: float) -> Node2D:
        var nearest_unit: Node2D
        var nearest_distance := radius
        for unit in _civil_units:
                if not is_instance_valid(unit):
                        continue
                var distance := unit.global_position.distance_to(world_position)
                if distance < nearest_distance:
                        nearest_distance = distance
                        nearest_unit = unit
        return nearest_unit


func _find_building_at_world_position(world_position: Vector2) -> Node2D:
        var cell := _tile_map.local_to_map(_tile_map.to_local(world_position))
        var building: Node2D = _building_cells.get(cell)
        if is_instance_valid(building):
                return building
        for candidate in _gameplay_buildings:
                if not is_instance_valid(candidate):
                        continue
                if candidate.global_position.distance_to(world_position) < 80.0:
                        return candidate
        if is_instance_valid(_player_base) and _player_base.global_position.distance_to(world_position) < 140.0:
                return _player_base
        return null


func _find_construction_site_at_world_position(world_position: Vector2) -> Node2D:
        var cell := _tile_map.local_to_map(_tile_map.to_local(world_position))
        var site: Node2D = _construction_cells.get(cell)
        if is_instance_valid(site):
                return site
        for candidate in _construction_sites:
                if not is_instance_valid(candidate):
                        continue
                if candidate.global_position.distance_to(world_position) < 80.0:
                        return candidate
        return null


func _command_civil_unit_at_world_position(unit: Node2D, world_position: Vector2) -> void:
        var cell := _tile_map.local_to_map(_tile_map.to_local(world_position))
        var unit_type := str(unit.get_meta("unit_type", ""))
        if unit_type == "harvester" and _resource_cells.has(cell):
                var deposit: Node2D = _resource_cells[cell]
                _dispatch_harvester_to_resource(unit, deposit)
                return
        _command_civil_manual_move(unit, _clamp_unit_cell(cell))


func _command_civil_manual_move(unit: Node2D, target_cell: Vector2i) -> void:
        var path := _find_path(_civil_unit_cell(unit), target_cell, unit)
        if path.is_empty():
                _feedback_text = "No path"
                return
        _detach_builder_from_site(unit)
        unit.set_meta("phase", "manual_move")
        unit.set_meta("path", path)
        unit.set_meta("path_index", 1 if path.size() > 1 else 0)
        unit.set_meta("blocked_reason", "")


func _enter_build_mode(building_id: String) -> void:
        if not BUILDING_REGISTRY.is_buildable(building_id):
                return
        _build_mode_id = building_id
        _feedback_text = "Build: %s" % str(BUILDING_REGISTRY.get_config(building_id).get("display_name", building_id))
        if _build_ghost == null:
                _build_ghost = Sprite2D.new()
                _build_ghost.name = "BuildGhost"
                _build_ghost.centered = true
                _build_ghost.z_index = 500
                _build_ghost.z_as_relative = false
                _buildings_layer.add_child(_build_ghost)
        _update_build_ghost()


func _cancel_build_mode() -> void:
        _build_mode_id = ""
        if _build_ghost != null:
                _build_ghost.visible = false
        _feedback_text = ""


func _update_build_ghost() -> void:
        if _build_ghost == null:
                return
        if _build_mode_id.is_empty():
                _build_ghost.visible = false
                return
        var texture_path := BUILDING_REGISTRY.texture_path_for(_build_mode_id, player_faction_id)
        var texture := _load_png_texture(texture_path)
        if texture == null:
                _build_ghost.visible = false
                return
        var cell := _tile_map.local_to_map(_tile_map.to_local(get_global_mouse_position()))
        _build_ghost.visible = true
        _build_ghost.texture = texture
        _build_ghost.position = _building_visual_position(texture_path, cell)
        _build_ghost.scale = BUILDING_CATALOG.get_visual_scale(texture_path, texture, _tile_map.tile_set.tile_size)
        _build_ghost.modulate = Color(0.2, 1.0, 0.55, 0.58) if _can_place_gameplay_building(_build_mode_id, cell, true) else Color(1.0, 0.15, 0.15, 0.58)


func _try_place_active_building(world_position: Vector2) -> void:
        if _build_mode_id.is_empty():
                return
        var cell := _tile_map.local_to_map(_tile_map.to_local(world_position))
        if _try_create_construction_site(_build_mode_id, cell):
                _cancel_build_mode()


func _can_place_gameplay_building(building_id: String, origin_cell: Vector2i, check_cost: bool) -> bool:
        var config := BUILDING_REGISTRY.get_config(building_id)
        if config.is_empty():
                return false
        if check_cost and not _economy.can_afford(int(config.get("matter_cost", 0)), int(config.get("element_cost", 0))):
                return false
        var texture_path := BUILDING_REGISTRY.texture_path_for(building_id, player_faction_id)
        if texture_path.is_empty():
                return false
        return _is_building_placement_allowed(texture_path, origin_cell)


func _try_create_construction_site(building_id: String, origin_cell: Vector2i) -> bool:
        if not _can_place_gameplay_building(building_id, origin_cell, true):
                _feedback_text = "Invalid placement or not enough resources"
                return false

        var config := BUILDING_REGISTRY.get_config(building_id)
        if not _economy.spend(int(config.get("matter_cost", 0)), int(config.get("element_cost", 0))):
                _feedback_text = "Not enough resources"
                return false

        var texture_path := BUILDING_REGISTRY.texture_path_for(building_id, player_faction_id)
        var texture := _load_png_texture(texture_path)
        if texture == null:
                return false

        var site := Node2D.new()
        site.name = "Construction_%s_%02d" % [building_id, _next_construction_id]
        _next_construction_id += 1
        site.z_index = _sort_z_for_footprint(BUILDING_CATALOG.get_footprint_cells(origin_cell, texture_path), 1)
        site.z_as_relative = false
        site.position = _building_visual_position(texture_path, origin_cell)
        site.set_meta("construction_site", true)
        site.set_meta("building_id", building_id)
        site.set_meta("texture_path", texture_path)
        site.set_meta("origin_cell", origin_cell)
        site.set_meta("elapsed_ms", 0.0)
        site.set_meta("duration_ms", float(config.get("build_time_ms", 10000)))
        site.set_meta("pending", true)
        site.set_meta("active_builder", null)

        var sprite := Sprite2D.new()
        sprite.name = "Sprite"
        sprite.texture = texture
        sprite.centered = true
        sprite.scale = BUILDING_CATALOG.get_visual_scale(texture_path, texture, _tile_map.tile_set.tile_size)
        sprite.modulate = Color(0.65, 0.8, 1.0, 0.62)
        site.add_child(sprite)

        var progress := Line2D.new()
        progress.name = "ProgressLine"
        progress.width = 6.0
        progress.default_color = Color(0.1, 0.95, 1.0, 1.0)
        site.add_child(progress)

        _register_site_occupancy(site, texture_path, origin_cell)
        _buildings_layer.add_child(site)
        _construction_sites.append(site)
        _assign_idle_builders()
        _feedback_text = "Construction placed"
        return true


func _register_site_occupancy(site: Node2D, texture_path: String, origin_cell: Vector2i) -> void:
        var footprint_cells := BUILDING_CATALOG.get_footprint_cells(origin_cell, texture_path)
        var reserved_cells := BUILDING_CATALOG.get_reserved_cells(origin_cell, texture_path)
        site.set_meta("footprint_cells", footprint_cells)
        site.set_meta("reserved_cells", reserved_cells)
        for footprint_cell in footprint_cells:
                _construction_cells[footprint_cell] = site
                _blocked_cells[footprint_cell] = site
        for reserved_cell in reserved_cells:
                _reserved_building_cells[reserved_cell] = site


func _unregister_site_occupancy(site: Node2D) -> void:
        for footprint_cell in site.get_meta("footprint_cells", []):
                if _construction_cells.get(footprint_cell) == site:
                        _construction_cells.erase(footprint_cell)
                if _blocked_cells.get(footprint_cell) == site:
                        _blocked_cells.erase(footprint_cell)
        for reserved_cell in site.get_meta("reserved_cells", []):
                if _reserved_building_cells.get(reserved_cell) == site:
                        _reserved_building_cells.erase(reserved_cell)


func _update_civil_runtime(dt_ms: float) -> void:
        _cleanup_runtime_lists()
        _assign_idle_builders()
        for builder in _builders:
                if is_instance_valid(builder):
                        _update_builder(builder, dt_ms)
        for harvester in _harvesters:
                if is_instance_valid(harvester):
                        _update_harvester(harvester, dt_ms)
        _update_construction_sites(dt_ms)
        _update_economy_consumers(dt_ms)


func _cleanup_runtime_lists() -> void:
        _civil_units = _filter_valid_nodes(_civil_units)
        _builders = _filter_valid_nodes(_builders)
        _harvesters = _filter_valid_nodes(_harvesters)
        _gameplay_buildings = _filter_valid_nodes(_gameplay_buildings)
        _gameplay_building_order = _filter_valid_nodes(_gameplay_building_order)
        _construction_sites = _filter_valid_nodes(_construction_sites)


func _filter_valid_nodes(nodes: Array[Node2D]) -> Array[Node2D]:
        var result: Array[Node2D] = []
        for node in nodes:
                if is_instance_valid(node):
                        result.append(node)
        return result


func _assign_idle_builders() -> void:
        for site in _construction_sites:
                if not is_instance_valid(site):
                        continue
                if not bool(site.get_meta("pending", true)):
                        continue
                if is_instance_valid(site.get_meta("active_builder", null)):
                        continue
                var builder := _nearest_idle_builder_for_site(site)
                if builder != null:
                        _dispatch_builder_to_site(builder, site)


func _nearest_idle_builder_for_site(site: Node2D) -> Node2D:
        var origin: Vector2i = site.get_meta("origin_cell")
        var nearest_builder: Node2D
        var nearest_distance := 999999.0
        for builder in _builders:
                if not is_instance_valid(builder):
                        continue
                if str(builder.get_meta("phase", "")) != "idle":
                        continue
                var distance := Vector2(_civil_unit_cell(builder)).distance_to(Vector2(origin))
                if distance < nearest_distance:
                        nearest_distance = distance
                        nearest_builder = builder
        return nearest_builder


func _dispatch_builder_to_site(builder: Node2D, site: Node2D) -> void:
        var path := _find_path_to_footprint_adjacent(_civil_unit_cell(builder), site.get_meta("footprint_cells", []), builder)
        if path.is_empty():
                site.set_meta("pending", true)
                return
        builder.set_meta("phase", "moving_to_site")
        builder.set_meta("assigned_site", site)
        builder.set_meta("path", path)
        builder.set_meta("path_index", 1 if path.size() > 1 else 0)
        site.set_meta("active_builder", builder)
        site.set_meta("pending", false)


func _update_builder(builder: Node2D, dt_ms: float) -> void:
        var phase := str(builder.get_meta("phase", "idle"))
        if phase == "moving_to_site":
                if _move_civil_unit_along_path(builder, BUILDER_SPEED_TILES, dt_ms):
                        var site: Node2D = builder.get_meta("assigned_site", null)
                        if is_instance_valid(site):
                                builder.set_meta("phase", "building")
                        else:
                                builder.set_meta("phase", "idle")
        elif phase == "building":
                var site: Node2D = builder.get_meta("assigned_site", null)
                if not is_instance_valid(site):
                        builder.set_meta("phase", "idle")
                        builder.set_meta("assigned_site", null)
        elif phase == "manual_move":
                if _move_civil_unit_along_path(builder, BUILDER_SPEED_TILES, dt_ms):
                        builder.set_meta("phase", "idle")


func _detach_builder_from_site(builder: Node2D) -> void:
        if str(builder.get_meta("unit_type", "")) != "builder":
                return
        var site: Node2D = builder.get_meta("assigned_site", null)
        if is_instance_valid(site) and site.get_meta("active_builder", null) == builder:
                site.set_meta("pending", true)
                site.set_meta("active_builder", null)
        builder.set_meta("assigned_site", null)


func _update_construction_sites(dt_ms: float) -> void:
        var completed_sites: Array[Node2D] = []
        for site in _construction_sites:
                if not is_instance_valid(site):
                        continue
                var builder: Node2D = site.get_meta("active_builder", null)
                if is_instance_valid(builder) and str(builder.get_meta("phase", "")) == "building":
                        var elapsed := float(site.get_meta("elapsed_ms", 0.0)) + dt_ms
                        site.set_meta("elapsed_ms", elapsed)
                        _update_site_progress_visual(site)
                        if elapsed >= float(site.get_meta("duration_ms", 1.0)):
                                completed_sites.append(site)
                else:
                        _update_site_progress_visual(site)

        for site in completed_sites:
                _complete_construction_site(site)


func _update_site_progress_visual(site: Node2D) -> void:
        var line := site.get_node_or_null("ProgressLine") as Line2D
        if line == null:
                return
        var duration := maxf(1.0, float(site.get_meta("duration_ms", 1.0)))
        var progress := clampf(float(site.get_meta("elapsed_ms", 0.0)) / duration, 0.0, 1.0)
        line.points = PackedVector2Array([Vector2(-38, 42), Vector2(-38 + 76.0 * progress, 42)])


func _complete_construction_site(site: Node2D) -> void:
        var building_id := str(site.get_meta("building_id", ""))
        var origin_cell: Vector2i = site.get_meta("origin_cell")
        var builder: Node2D = site.get_meta("active_builder", null)
        _unregister_site_occupancy(site)
        _construction_sites.erase(site)
        site.queue_free()

        var building := _spawn_gameplay_building(building_id, origin_cell)
        if building != null:
                _apply_building_completion_effects(building)
                _feedback_text = "Completed: %s" % str(BUILDING_REGISTRY.get_config(building_id).get("display_name", building_id))

        if is_instance_valid(builder):
                builder.set_meta("phase", "idle")
                builder.set_meta("assigned_site", null)


func _spawn_gameplay_building(building_id: String, origin_cell: Vector2i) -> Node2D:
        var texture_path := BUILDING_REGISTRY.texture_path_for(building_id, player_faction_id)
        var building := spawn_building(texture_path, origin_cell, building_id)
        if building == null:
                return null
        building.set_meta("gameplay_building", true)
        building.set_meta("completed", true)
        building.set_meta("hp", int(BUILDING_REGISTRY.get_config(building_id).get("hp", 100)))
        if building_id == "separator":
                building.set_meta("sep_progress_ms", 0.0)
                building.set_meta("powered", false)
        elif building_id == "units_factory":
                building.set_meta("queue", [])
                building.set_meta("powered", false)
        _gameplay_buildings.append(building)
        _gameplay_building_order.append(building)
        return building


func _apply_building_completion_effects(building: Node2D) -> void:
        var building_id := str(building.get_meta("building_id", ""))
        var config := BUILDING_REGISTRY.get_config(building_id)
        if config.has("storage"):
                _economy.add_storage_delta(config["storage"])
        _recalculate_power_generated()


func _update_harvester(harvester: Node2D, dt_ms: float) -> void:
        var phase := str(harvester.get_meta("phase", "idle"))
        if phase == "idle":
                if int(harvester.get_meta("cargo", 0)) >= HARVESTER_CAPACITY:
                        _dispatch_harvester_to_hq(harvester)
                else:
                        _auto_dispatch_harvester(harvester)
        elif phase == "moving_to_resource":
                if _move_civil_unit_along_path(harvester, HARVESTER_SPEED_TILES, dt_ms):
                        harvester.set_meta("phase", "gathering")
                        harvester.set_meta("timer_ms", 0.0)
        elif phase == "gathering":
                _update_harvester_gathering(harvester, dt_ms)
        elif phase == "returning_to_hq":
                if _move_civil_unit_along_path(harvester, HARVESTER_SPEED_TILES, dt_ms):
                        harvester.set_meta("phase", "unloading")
                        harvester.set_meta("timer_ms", 0.0)
        elif phase == "unloading":
                _update_harvester_unloading(harvester, dt_ms)
        elif phase == "manual_move":
                if _move_civil_unit_along_path(harvester, HARVESTER_SPEED_TILES, dt_ms):
                        harvester.set_meta("phase", "idle")


func _auto_dispatch_harvester(harvester: Node2D) -> void:
        var best := _find_nearest_reachable_resource(harvester)
        if best == null:
                harvester.set_meta("blocked_reason", "no-resources")
                return
        _dispatch_harvester_to_resource(harvester, best)


func _dispatch_harvester_to_resource(harvester: Node2D, deposit: Node2D) -> void:
        if not is_instance_valid(deposit):
                harvester.set_meta("phase", "idle")
                return
        var path := _find_path_to_footprint_adjacent(_civil_unit_cell(harvester), deposit.get_meta("footprint_cells", []), harvester)
        if path.is_empty():
                harvester.set_meta("blocked_reason", "no-approach-path")
                return
        harvester.set_meta("phase", "moving_to_resource")
        harvester.set_meta("target_resource", deposit)
        harvester.set_meta("path", path)
        harvester.set_meta("path_index", 1 if path.size() > 1 else 0)
        harvester.set_meta("blocked_reason", "")


func _dispatch_harvester_to_hq(harvester: Node2D) -> void:
        var path := _find_path_to_footprint_adjacent(_civil_unit_cell(harvester), _player_base.get_meta("footprint_cells", []), harvester)
        if path.is_empty():
                harvester.set_meta("blocked_reason", "no-path-to-hq")
                return
        harvester.set_meta("phase", "returning_to_hq")
        harvester.set_meta("path", path)
        harvester.set_meta("path_index", 1 if path.size() > 1 else 0)
        harvester.set_meta("blocked_reason", "")


func _find_nearest_reachable_resource(harvester: Node2D) -> Node2D:
        var best_deposit: Node2D
        var best_distance := 999999.0
        for deposit in _unique_resource_deposits():
                if not is_instance_valid(deposit):
                        continue
                if not bool(deposit.get("infinite")) and int(deposit.get("current_amount")) <= 0:
                        continue
                var path := _find_path_to_footprint_adjacent(_civil_unit_cell(harvester), deposit.get_meta("footprint_cells", []), harvester)
                if path.is_empty():
                        continue
                var distance := float(path.size())
                if distance < best_distance:
                        best_distance = distance
                        best_deposit = deposit
        return best_deposit


func _unique_resource_deposits() -> Array[Node2D]:
        var deposits: Array[Node2D] = []
        var seen := {}
        for value in _resource_cells.values():
                if not value is Node2D:
                        continue
                var deposit := value as Node2D
                if not is_instance_valid(deposit):
                        continue
                var key := deposit.get_instance_id()
                if seen.has(key):
                        continue
                seen[key] = true
                deposits.append(deposit)
        return deposits


func _update_harvester_gathering(harvester: Node2D, dt_ms: float) -> void:
        var deposit: Node2D = harvester.get_meta("target_resource", null)
        if not is_instance_valid(deposit):
                harvester.set_meta("phase", "idle")
                return
        var timer := float(harvester.get_meta("timer_ms", 0.0)) + dt_ms
        if timer < HARVESTER_GATHER_MS:
                harvester.set_meta("timer_ms", timer)
                return
        timer -= HARVESTER_GATHER_MS
        var cargo_raw := int(harvester.get_meta("cargo_raw", 0))
        var cargo_elements := int(harvester.get_meta("cargo_elements", 0))
        var total_cargo := cargo_raw + cargo_elements
        var can_take := mini(HARVESTER_CAPACITY - total_cargo, HARVESTER_CAPACITY)
        var taken := 0
        if can_take > 0 and deposit.has_method("harvest"):
                taken = int(deposit.call("harvest", can_take))
        # Баг B3: harvester собирал yellow как raw. Теперь раздельно.
        var resource_id := str(deposit.get("resource_id", "cyan"))
        if resource_id == "yellow":
                cargo_elements += taken
        else:
                cargo_raw += taken
        harvester.set_meta("cargo_raw", cargo_raw)
        harvester.set_meta("cargo_elements", cargo_elements)
        harvester.set_meta("cargo", cargo_raw + cargo_elements)  # для совместимости
        harvester.set_meta("timer_ms", timer)
        var total := cargo_raw + cargo_elements
        _update_civil_progress_line(harvester, float(total) / float(HARVESTER_CAPACITY))
        if total >= HARVESTER_CAPACITY or not is_instance_valid(deposit):
                _dispatch_harvester_to_hq(harvester)


func _update_harvester_unloading(harvester: Node2D, dt_ms: float) -> void:
        var cargo_raw := int(harvester.get_meta("cargo_raw", 0))
        var cargo_elements := int(harvester.get_meta("cargo_elements", 0))
        var total_cargo := cargo_raw + cargo_elements
        if total_cargo <= 0:
                harvester.set_meta("phase", "idle")
                _update_civil_progress_line(harvester, 0.0)
                return
        var timer := float(harvester.get_meta("timer_ms", 0.0)) + dt_ms
        if timer < HARVESTER_UNLOAD_MS:
                harvester.set_meta("timer_ms", timer)
                return
        timer -= HARVESTER_UNLOAD_MS
        # Разгружаем raw в raw storage
        var accepted_raw := 0
        if cargo_raw > 0:
                accepted_raw = _economy.add_raw(cargo_raw)
                cargo_raw -= accepted_raw
        # Разгружаем elements в element storage (баг B3 — ранее шло в raw)
        var accepted_elements := 0
        if cargo_elements > 0:
                accepted_elements = _economy.add_elements(cargo_elements)
                cargo_elements -= accepted_elements
        harvester.set_meta("cargo_raw", cargo_raw)
        harvester.set_meta("cargo_elements", cargo_elements)
        harvester.set_meta("cargo", cargo_raw + cargo_elements)
        harvester.set_meta("timer_ms", timer)
        var new_total := cargo_raw + cargo_elements
        _update_civil_progress_line(harvester, float(new_total) / float(HARVESTER_CAPACITY))
        if new_total <= 0:
                harvester.set_meta("phase", "idle")
                harvester.set_meta("blocked_reason", "")
        elif (cargo_raw > 0 and accepted_raw <= 0) or (cargo_elements > 0 and accepted_elements <= 0):
                harvester.set_meta("blocked_reason", "storage-full")


func _update_civil_progress_line(unit: Node2D, progress: float) -> void:
        var line := unit.get_node_or_null("ProgressLine") as Line2D
        if line == null:
                return
        if progress <= 0.0:
                line.visible = false
                return
        line.visible = true
        line.points = PackedVector2Array([Vector2(-24, 28), Vector2(-24 + 48.0 * clampf(progress, 0.0, 1.0), 28)])


func _update_economy_consumers(dt_ms: float) -> void:
        _recalculate_power_generated()
        var remaining_power: int = _economy.power_generated
        var consumed: int = 0
        for building in _gameplay_building_order:
                if not is_instance_valid(building):
                        continue
                var building_id := str(building.get_meta("building_id", ""))
                if building_id == "separator":
                        if _can_separator_work() and remaining_power >= ECONOMY_STATE.SEPARATOR_POWER_COST:
                                remaining_power -= ECONOMY_STATE.SEPARATOR_POWER_COST
                                consumed += ECONOMY_STATE.SEPARATOR_POWER_COST
                                building.set_meta("powered", true)
                                _update_separator(building, dt_ms)
                        else:
                                building.set_meta("powered", false)
                elif building_id == "units_factory":
                        if _factory_has_active_work(building):
                                if remaining_power >= ECONOMY_STATE.FACTORY_POWER_COST:
                                        remaining_power -= ECONOMY_STATE.FACTORY_POWER_COST
                                        consumed += ECONOMY_STATE.FACTORY_POWER_COST
                                        building.set_meta("powered", true)
                                        _update_factory_queue(building, dt_ms)
                                else:
                                        building.set_meta("powered", false)
                        else:
                                building.set_meta("powered", false)
                        _try_spawn_completed_factory_item(building)
        _update_building_activity_visuals()
        _economy.set_power_consumed(consumed)


func _recalculate_power_generated() -> void:
        var total := ECONOMY_STATE.HQ_BASE_POWER
        for building in _gameplay_buildings:
                if not is_instance_valid(building):
                        continue
                if str(building.get_meta("building_id", "")) == "power_plant":
                        total += ECONOMY_STATE.POWER_PLANT_GENERATION
        _economy.set_power_generated(total)


func _can_separator_work() -> bool:
        if _economy.raw < ECONOMY_STATE.SEP_RAW_COST:
                return false
        if _economy.matter + ECONOMY_STATE.SEP_MATTER_YIELD > _economy.matter_cap:
                return false
        if _economy.elements + ECONOMY_STATE.SEP_ELEMENT_YIELD > _economy.element_cap:
                return false
        return true


func _update_separator(building: Node2D, dt_ms: float) -> void:
        var progress := float(building.get_meta("sep_progress_ms", 0.0)) + dt_ms
        while progress >= ECONOMY_STATE.SEP_CYCLE_MS and _can_separator_work():
                progress -= ECONOMY_STATE.SEP_CYCLE_MS
                _economy.raw -= ECONOMY_STATE.SEP_RAW_COST
                _economy.add_matter(ECONOMY_STATE.SEP_MATTER_YIELD)
                _economy.add_elements(ECONOMY_STATE.SEP_ELEMENT_YIELD)
        building.set_meta("sep_progress_ms", progress)


func _factory_has_active_work(factory: Node2D) -> bool:
        var queue: Array = factory.get_meta("queue", [])
        return queue.size() > 0 and not bool(queue[0].get("completed", false))


func _queue_selected_factory_unit(unit_type: String) -> void:
        if not is_instance_valid(_selected_building):
                _feedback_text = "Select factory first"
                return
        if str(_selected_building.get_meta("building_id", "")) != "units_factory":
                _feedback_text = "Selected building is not factory"
                return
        _queue_factory_unit(_selected_building, unit_type)


func _queue_factory_unit(factory: Node2D, unit_type: String) -> void:
        var queue: Array = factory.get_meta("queue", [])
        if queue.size() >= ECONOMY_STATE.FACTORY_QUEUE_LIMIT:
                _feedback_text = "Factory queue full"
                return
        if _civil_unit_count_with_queued() >= ECONOMY_STATE.CIVIL_UNIT_CAP:
                _feedback_text = "Civil unit cap reached"
                return
        var config := BUILDING_REGISTRY.get_civil_unit_config(unit_type)
        if config.is_empty():
                return
        var matter_cost := int(config.get("matter_cost", 0))
        var element_cost := int(config.get("element_cost", 0))
        if not _economy.spend(matter_cost, element_cost):
                _feedback_text = "Not enough resources"
                return
        queue.append({
                "unit_type": unit_type,
                "elapsed_ms": 0.0,
                "duration_ms": float(config.get("production_time_ms", 10000)),
                "completed": false,
        })
        factory.set_meta("queue", queue)
        _feedback_text = "Queued: %s" % unit_type


func _cancel_selected_factory_item() -> void:
        if not is_instance_valid(_selected_building):
                return
        if str(_selected_building.get_meta("building_id", "")) != "units_factory":
                return
        var queue: Array = _selected_building.get_meta("queue", [])
        if queue.is_empty():
                return
        var item: Dictionary = queue.pop_back()
        # Возврат ресурсов при отмене (баг B4 — ранее ресурсы терялись)
        var unit_type := str(item.get("unit_type", "builder"))
        var config := BUILDING_REGISTRY.get_civil_unit_config(unit_type)
        _economy.matter += int(config.get("matter_cost", 0))
        _economy.elements += int(config.get("element_cost", 0))
        _selected_building.set_meta("queue", queue)
        _feedback_text = "Queue item cancelled, resources refunded"


func _update_factory_queue(factory: Node2D, dt_ms: float) -> void:
        var queue: Array = factory.get_meta("queue", [])
        if queue.is_empty():
                return
        var item: Dictionary = queue[0]
        if bool(item.get("completed", false)):
                return
        item["elapsed_ms"] = float(item.get("elapsed_ms", 0.0)) + dt_ms
        if float(item["elapsed_ms"]) >= float(item.get("duration_ms", 1.0)):
                item["completed"] = true
                item["completed_at_ms"] = Time.get_ticks_msec()
        queue[0] = item
        factory.set_meta("queue", queue)


func _try_spawn_completed_factory_item(factory: Node2D) -> void:
        var queue: Array = factory.get_meta("queue", [])
        if queue.is_empty():
                return
        var item: Dictionary = queue[0]
        if not bool(item.get("completed", false)):
                return
        if _civil_unit_count() >= ECONOMY_STATE.CIVIL_UNIT_CAP:
                return
        var spawn_cell := _find_factory_spawn_cell(factory)
        if spawn_cell.x < 0:
                # Таймаут: если ждём спавн слишком долго — вернуть ресурсы (баг B5)
                var completed_at := int(item.get("completed_at_ms", Time.get_ticks_msec()))
                var wait_time := Time.get_ticks_msec() - completed_at
                if wait_time > FACTORY_SPAWN_TIMEOUT_MS:
                        var unit_type := str(item.get("unit_type", "builder"))
                        var config := BUILDING_REGISTRY.get_civil_unit_config(unit_type)
                        _economy.matter += int(config.get("matter_cost", 0))
                        _economy.elements += int(config.get("element_cost", 0))
                        queue.pop_front()
                        factory.set_meta("queue", queue)
                        _feedback_text = "Factory spawn timeout — resources refunded"
                return
        var unit := _spawn_civil_unit(str(item.get("unit_type", "builder")), spawn_cell)
        if unit != null:
                queue.pop_front()
                factory.set_meta("queue", queue)


func _find_factory_spawn_cell(factory: Node2D) -> Vector2i:
        var footprint: Array = factory.get_meta("footprint_cells", [])
        if footprint.is_empty():
                return Vector2i(-1, -1)
        for radius in range(1, 6):
                for footprint_cell in footprint:
                        for y in range(footprint_cell.y - radius, footprint_cell.y + radius + 1):
                                for x in range(footprint_cell.x - radius, footprint_cell.x + radius + 1):
                                        if abs(x - footprint_cell.x) != radius and abs(y - footprint_cell.y) != radius:
                                                continue
                                        var candidate := Vector2i(x, y)
                                        if _is_civil_spawn_cell_allowed(candidate):
                                                return candidate
        return Vector2i(-1, -1)


func _civil_unit_count() -> int:
        return _filter_valid_nodes(_civil_units).size()


func _civil_unit_count_with_queued() -> int:
        var total := _civil_unit_count()
        for building in _gameplay_buildings:
                if not is_instance_valid(building):
                        continue
                if str(building.get_meta("building_id", "")) == "units_factory":
                        total += (building.get_meta("queue", []) as Array).size()
        return total


func _update_building_activity_visuals() -> void:
        for building in _gameplay_buildings:
                if not is_instance_valid(building):
                        continue
                var powered := bool(building.get_meta("powered", true))
                var building_id := str(building.get_meta("building_id", ""))
                if building_id == "separator" or building_id == "units_factory":
                        building.modulate = Color(1.0, 1.0, 1.0, 1.0) if powered else Color(0.55, 0.55, 0.65, 1.0)


func _move_civil_unit_along_path(unit: Node2D, speed_tiles: float, dt_ms: float) -> bool:
        var path: Array = unit.get_meta("path", [])
        if path.is_empty():
                return true
        var path_index := int(unit.get_meta("path_index", 0))
        if path_index >= path.size():
                return true
        var fpos: Vector2 = unit.get_meta("fpos", Vector2(_civil_unit_cell(unit)))
        var target := Vector2(path[path_index])
        var to_target := target - fpos
        if to_target.length_squared() > 0.0001:
                var next_dir := _grid_delta_to_dir16(to_target)
                if next_dir != int(unit.get_meta("visual_dir", -1)):
                        unit.set_meta("visual_dir", next_dir)
                        _refresh_civil_unit_visual(unit)
        var step := speed_tiles * dt_ms / 1000.0
        if to_target.length() <= step:
                fpos = target
                path_index += 1
        else:
                fpos += to_target.normalized() * step
        unit.set_meta("fpos", fpos)
        unit.set_meta("cell", Vector2i(roundi(fpos.x), roundi(fpos.y)))
        unit.set_meta("path_index", path_index)
        unit.global_position = _tile_float_to_local(fpos)
        unit.z_index = _sort_z_for_cell(_civil_unit_cell(unit), 5)
        return path_index >= path.size()


func _tile_float_to_local(tile_pos: Vector2) -> Vector2:
        var tile_size := _tile_map.tile_set.tile_size
        return Vector2(
                (tile_pos.x - tile_pos.y) * float(tile_size.x) * 0.5,
                (tile_pos.x + tile_pos.y) * float(tile_size.y) * 0.5
        )


func _sort_z_for_cell(cell: Vector2i, bias: int = 0) -> int:
        return 1000 + (cell.x + cell.y) * 10 + bias


func _sort_z_for_footprint(footprint: Array, bias: int = 0) -> int:
        var best_sum := -999999
        for value in footprint:
                if not value is Vector2i:
                        continue
                var cell: Vector2i = value
                best_sum = maxi(best_sum, cell.x + cell.y)
        if best_sum < -1000:
                return 1000 + bias
        return 1000 + best_sum * 10 + bias


func _civil_unit_cell(unit: Node2D) -> Vector2i:
        return unit.get_meta("cell", Vector2i.ZERO)


func _nearest_free_civil_cell(origin: Vector2i, max_radius: int) -> Vector2i:
        if _is_civil_spawn_cell_allowed(origin):
                return origin
        for radius in range(1, max_radius + 1):
                for y in range(-radius, radius + 1):
                        for x in range(-radius, radius + 1):
                                if abs(x) != radius and abs(y) != radius:
                                        continue
                                var candidate := Vector2i(origin.x + x, origin.y + y)
                                if _is_civil_spawn_cell_allowed(candidate):
                                        return candidate
        return Vector2i(-1, -1)


func _is_civil_spawn_cell_allowed(cell: Vector2i) -> bool:
        if not _is_cell_inside_map(cell):
                return false
        if is_cell_blocked(cell):
                return false
        for unit in _civil_units:
                if is_instance_valid(unit) and _civil_unit_cell(unit) == cell:
                        return false
        return true


func _find_path(start: Vector2i, goal: Vector2i, ignore_unit: Node2D = null) -> Array[Vector2i]:
        var result: Array[Vector2i] = []
        if not _is_cell_inside_map(start) or not _is_cell_inside_map(goal):
                return result
        var blockers: Dictionary = _movement_blockers(ignore_unit)
        if blockers.has(goal) and goal != start:
                return result
        var queue: Array[Vector2i] = [start]
        var came_from: Dictionary = {start: start}
        var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
        while not queue.is_empty():
                var current: Vector2i = queue.pop_front()
                if current == goal:
                        break
                for direction in directions:
                        var next: Vector2i = current + direction
                        if came_from.has(next):
                                continue
                        if not _is_cell_inside_map(next):
                                continue
                        if blockers.has(next) and next != goal:
                                continue
                        came_from[next] = current
                        queue.append(next)
        if not came_from.has(goal):
                return result
        var cursor := goal
        while cursor != start:
                result.push_front(cursor)
                cursor = came_from[cursor]
        result.push_front(start)
        return result


func _find_path_to_footprint_adjacent(start: Vector2i, footprint: Array, ignore_unit: Node2D = null) -> Array[Vector2i]:
        var result: Array[Vector2i] = []
        if footprint.is_empty():
                return result
        var blockers: Dictionary = _movement_blockers(ignore_unit)
        var queue: Array[Vector2i] = [start]
        var came_from: Dictionary = {start: start}
        var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
        var goal: Vector2i = Vector2i(-9999, -9999)
        while not queue.is_empty():
                var current: Vector2i = queue.pop_front()
                if current != start and blockers.has(current):
                        continue
                if _is_cell_adjacent_to_footprint(current, footprint):
                        goal = current
                        break
                for direction in directions:
                        var next: Vector2i = current + direction
                        if came_from.has(next):
                                continue
                        if not _is_cell_inside_map(next):
                                continue
                        if blockers.has(next):
                                continue
                        came_from[next] = current
                        queue.append(next)
        if goal.x < -1000:
                return result
        var cursor := goal
        while cursor != start:
                result.push_front(cursor)
                cursor = came_from[cursor]
        result.push_front(start)
        return result


func _movement_blockers(ignore_unit: Node2D = null) -> Dictionary:
        var blockers := {}
        for cell in _building_cells.keys():
                blockers[cell] = true
        for cell in _resource_cells.keys():
                blockers[cell] = true
        for cell in _blocked_cells.keys():
                blockers[cell] = true
        for cell in _construction_cells.keys():
                blockers[cell] = true
        for unit in _civil_units:
                if not is_instance_valid(unit) or unit == ignore_unit:
                        continue
                blockers[_civil_unit_cell(unit)] = true
        return blockers


func _is_cell_adjacent_to_footprint(cell: Vector2i, footprint: Array) -> bool:
        for footprint_cell in footprint:
                var fp: Vector2i = footprint_cell
                var dx := absi(cell.x - fp.x)
                var dy := absi(cell.y - fp.y)
                if dx + dy == 1:
                        return true
        return false


func _handle_unit_hotkey(keycode: Key) -> void:
        match keycode:
                KEY_Q:
                        _auto_place_building("separator")
                KEY_W:
                        _auto_place_building("raw_storage")
                KEY_E:
                        _auto_place_building("matter_storage")
                KEY_R:
                        _auto_place_building("elements_storage")
                KEY_A:
                        _auto_place_building("power_plant")
                KEY_F:
                        _auto_place_building("units_factory")
                KEY_Z:
                        _queue_selected_factory_unit("builder")
                KEY_X:
                        _queue_selected_factory_unit("harvester")
                KEY_C:
                        _cancel_selected_factory_item()
                KEY_U:
                        if DebugFlags.SPAWN_UNITS_FREELY:
                                _spawn_combat_unit_near_player_base("wasp", "smoky")
                KEY_I:
                        if DebugFlags.SPAWN_UNITS_FREELY:
                                _spawn_combat_unit_near_player_base("hunter", "railgun")
                KEY_H:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("upgrade_hull"):
                                _selected_unit.call("upgrade_hull")
                KEY_T:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("upgrade_turret"):
                                _selected_unit.call("upgrade_turret")
                KEY_1:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("switch_hull"):
                                _selected_unit.call("switch_hull", "wasp")
                KEY_2:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("switch_hull"):
                                _selected_unit.call("switch_hull", "hunter")
                KEY_3:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("switch_turret"):
                                _selected_unit.call("switch_turret", "smoky")
                KEY_4:
                        if is_instance_valid(_selected_unit) and _selected_unit.has_method("switch_turret"):
                                _selected_unit.call("switch_turret", "railgun")
                KEY_5:
                        upgrade_player_base_to_tier(1)
                KEY_6:
                        upgrade_player_base_to_tier(2)
                KEY_7:
                        upgrade_player_base_to_tier(3)
                KEY_S:
                        # Stop selected unit / clear target-lock
                        if is_instance_valid(_selected_unit):
                                if _selected_unit.has_method("command_attack"):
                                        _selected_unit.call("command_attack", null)
                                if _selected_unit.has_method("grid_movement") and _selected_unit.get("grid_movement") != null:
                                        MovementStateMachine.issue_stop_command(_selected_unit.grid_movement, _tile_reservation_map, _selected_unit.name)
        _update_rts_hud_text()


# ─── Авто-размещение здания (Этап 4 рефакторинга) ────
# Заменяет интерактивный build mode с ghost preview.
# Система автоматически находит ближайшую валидную позицию рядом с выбранным builder'ом
# (или HQ если builder не выбран).
func _auto_place_building(building_id: String) -> void:
        var config := BUILDING_REGISTRY.get_config(building_id)
        if config.is_empty():
                _feedback_text = "Unknown building: " + building_id
                return
        # Проверка стоимости
        if not _economy.can_afford(int(config.get("matter_cost", 0)), int(config.get("element_cost", 0))):
                _feedback_text = "Not enough resources for " + building_id
                return
        # Выбрать якорь: выбранный builder → иначе HQ
        var anchor: Vector2i
        var anchor_label := "HQ"
        if is_instance_valid(_selected_civil_unit) \
                        and str(_selected_civil_unit.get_meta("unit_type", "")) == "builder":
                anchor = _civil_unit_cell(_selected_civil_unit)
                anchor_label = "builder"
        else:
                anchor = _player_base_center_cell
        # Построить occupancy map
        _rebuild_occupancy_map()
        # Собрать существующие footprints (для gap rule)
        var existing: Array = []
        if _player_base:
                existing.append({
                        "origin": _player_base_origin_cell,
                        "fp": Vector2i(3, 3)
                })
        for building in _gameplay_buildings:
                if is_instance_valid(building):
                        existing.append({
                                "origin": building.get_meta("origin_cell"),
                                "fp": building.get_meta("footprint")
                        })
        for site in _construction_sites:
                if is_instance_valid(site):
                        existing.append({
                                "origin": site.get_meta("origin_cell"),
                                "fp": site.get_meta("footprint")
                        })
        # Найти позицию
        var options := BuildSiteSelector.SearchOptions.new(1, 15)
        var result := BuildSiteSelector.find_site_near_anchor(
                _occupancy_map, building_id, anchor, map_size, existing, options
        )
        if not result.ok:
                _feedback_text = "No valid build site near %s: %s" % [anchor_label, result.reason]
                return
        # Создать construction site
        if _try_create_construction_site(building_id, result.origin_cell):
                _feedback_text = "Placed %s at (%d, %d) near %s" % [
                        BUILDING_REGISTRY.get_config(building_id).get("display_name", building_id),
                        result.origin_cell.x, result.origin_cell.y, anchor_label
                ]
                # Перестроить occupancy после размещения site
                _rebuild_occupancy_map()


func _spawn_resource_deposits() -> void:
        _resource_cells.clear()
        _reserved_resource_cells.clear()
        _spawn_infinite_center_mineral()
        _spawn_center_yellow_ring()

        var rng := RandomNumberGenerator.new()
        rng.seed = int(world_seed) ^ 0x51f27b8d

        _spawn_mirrored_start_resource_fields()
        _spawn_mirrored_cyan_edge_fields(rng)
        _spawn_random_mirrored_cyan_edge_resources(rng)
        _spawn_random_yellow_center_resources(rng)


func _spawn_infinite_center_mineral() -> void:
        var center_origin := Vector2i(int(map_size * 0.5) - 1, int(map_size * 0.5) - 1)
        var footprint: Array = [
                center_origin,
                center_origin + Vector2i(1, 0),
                center_origin + Vector2i(0, 1),
                center_origin + Vector2i(1, 1)
        ]
        var visual_center := Vector2.ZERO
        for cell in footprint:
                _reserved_resource_cells[cell] = true
                visual_center += _tile_map.map_to_local(cell)
        visual_center /= float(footprint.size())

        _spawn_resource_deposit_at_position(center_origin, visual_center, "cyan", _infinite_mineral_def, footprint)


func _spawn_center_yellow_ring() -> void:
        var center := Vector2i(int(map_size * 0.5), int(map_size * 0.5))
        var ring := maxi(4, int(float(map_size) * 0.08))
        var near_ring := maxi(3, ring - 2)
        var positions: Array[Vector2i] = [
                center + Vector2i(-near_ring, -near_ring),
                center + Vector2i(near_ring, -near_ring),
                center + Vector2i(-near_ring, near_ring),
                center + Vector2i(near_ring, near_ring),
                center + Vector2i(-ring, -ring),
                center + Vector2i(ring, -ring),
                center + Vector2i(-ring, ring),
                center + Vector2i(ring, ring),
                center + Vector2i(0, -ring),
                center + Vector2i(ring, 0),
                center + Vector2i(0, ring),
                center + Vector2i(-ring, 0),
        ]

        for i in range(positions.size()):
                var cell := _nearest_free_resource_cell(_clamp_resource_cell(positions[i]), 3)
                if cell.x < 0:
                        continue
                var richness_index := 4 if i < 8 else 3
                _spawn_resource_deposit(cell, "yellow", _mineral_richness_defs[richness_index])


func _spawn_random_yellow_center_resources(rng: RandomNumberGenerator) -> void:
        var center := Vector2i(int(map_size * 0.5), int(map_size * 0.5))
        var count := maxi(4, int(float(map_size) / 12.0))
        var min_radius := maxi(8, int(float(map_size) * 0.14))
        var max_radius := maxi(min_radius + 4, int(float(map_size) * 0.32))

        for i in range(count):
                var offset := Vector2i(
                        rng.randi_range(-max_radius, max_radius),
                        rng.randi_range(-max_radius, max_radius)
                )
                var distance := Vector2(offset).length()
                if distance < float(min_radius) or distance > float(max_radius):
                        continue
                var cell := _nearest_free_resource_cell(_clamp_resource_cell(center + offset), 5)
                if cell.x < 0:
                        continue
                var richness_index := 2
                if rng.randf() > 0.72:
                        richness_index = 3
                if rng.randf() > 0.92:
                        richness_index = 4
                _spawn_resource_deposit(cell, "yellow", _mineral_richness_defs[richness_index])


func _spawn_mirrored_start_resource_fields() -> void:
        var anchors := _start_anchor_cells()
        for side in anchors.keys():
                var anchor: Vector2i = anchors[side]
                for item in START_CYAN_FIELD_PATTERN:
                        var inward: Vector2i = item["inward"]
                        var tier := clampi(int(item["tier"]), 1, 5)
                        var cell := anchor + _start_resource_offset(str(side), _scale_start_resource_offset(inward))
                        _spawn_resource_if_possible(cell, "cyan", _mineral_richness_defs[tier - 1], 3)

                for item in START_YELLOW_FIELD_PATTERN:
                        var inward: Vector2i = item["inward"]
                        var tier := clampi(int(item["tier"]), 1, 5)
                        var cell := anchor + _start_resource_offset(str(side), _scale_start_resource_offset(inward))
                        _spawn_resource_if_possible(cell, "yellow", _mineral_richness_defs[tier - 1], 3)


func _scale_start_resource_offset(offset: Vector2i) -> Vector2i:
        var scale_factor := clampf(float(map_size) / 64.0, 0.65, 1.55)
        return Vector2i(
                maxi(3, roundi(float(offset.x) * scale_factor)),
                maxi(3, roundi(float(offset.y) * scale_factor))
        )


func _spawn_mirrored_cyan_edge_fields(rng: RandomNumberGenerator) -> void:
        for item in CORNER_CYAN_FIELD_PATTERN:
                var offset: Vector2i = item["offset"]
                var tier := clampi(int(item["tier"]), 1, 5)
                for cell in _mirror_corner_offset(offset):
                        _spawn_resource_if_possible(cell, "cyan", _mineral_richness_defs[tier - 1], 1)

        var trail_scale := clampf(float(map_size) / 64.0, 0.5, 2.0)
        for item in CORNER_CYAN_TRAIL_PATTERN:
                var source_offset: Vector2i = item["offset"]
                var scaled_offset := Vector2i(
                        maxi(9, roundi(float(source_offset.x) * trail_scale)),
                        maxi(9, roundi(float(source_offset.y) * trail_scale))
                )
                var tier := clampi(int(item["tier"]), 1, 5)
                for cell in _mirror_corner_offset(scaled_offset):
                        _spawn_resource_if_possible(cell, "cyan", _mineral_richness_defs[tier - 1], 2)


func _spawn_random_mirrored_cyan_edge_resources(rng: RandomNumberGenerator) -> void:
        var attempts := maxi(5, int(float(map_size) / 8.0))
        for i in range(attempts):
                var offset := Vector2i(
                        rng.randi_range(2, maxi(6, int(float(map_size) * 0.18))),
                        rng.randi_range(2, maxi(6, int(float(map_size) * 0.18)))
                )
                var tier := 1
                var roll := rng.randf()
                if roll > 0.90:
                        tier = 3
                elif roll > 0.60:
                        tier = 2
                for cell in _mirror_corner_offset(offset):
                        _spawn_resource_if_possible(cell, "cyan", _mineral_richness_defs[tier - 1], 2)


func _spawn_resource_if_possible(cell: Vector2i, color_id: String, richness: Dictionary, search_radius: int = 0) -> void:
        var final_cell := _nearest_free_resource_cell(_clamp_resource_cell(cell), search_radius)
        if final_cell.x < 0:
                return
        _spawn_resource_deposit(final_cell, color_id, richness)


func _mirror_corner_offset(offset_from_edge: Vector2i) -> Array[Vector2i]:
        var max_index := map_size - 1
        return [
                Vector2i(max_index - offset_from_edge.x, max_index - offset_from_edge.y),
                Vector2i(offset_from_edge.x, max_index - offset_from_edge.y),
                Vector2i(max_index - offset_from_edge.x, offset_from_edge.y),
                Vector2i(offset_from_edge.x, offset_from_edge.y),
        ]


func _start_anchor_cells() -> Dictionary:
        var high_x := clampi(
                mini(roundi(float(map_size - 1) * PLAYER_BASE_CENTER_RATIO.x), map_size - PLAYER_BASE_EDGE_MARGIN),
                2,
                map_size - 3
        )
        var high_y := clampi(
                mini(roundi(float(map_size - 1) * PLAYER_BASE_CENTER_RATIO.y), map_size - PLAYER_BASE_EDGE_MARGIN),
                2,
                map_size - 3
        )
        var low_x := map_size - 1 - high_x
        var low_y := map_size - 1 - high_y
        return {
                "bottom": Vector2i(high_x, high_y),
                "top": Vector2i(low_x, low_y),
                "left": Vector2i(low_x, high_y),
                "right": Vector2i(high_x, low_y),
        }


func _start_resource_offset(side: String, inward: Vector2i) -> Vector2i:
        match side:
                "bottom":
                        return Vector2i(-inward.x, -inward.y)
                "top":
                        return Vector2i(inward.x, inward.y)
                "left":
                        return Vector2i(inward.x, -inward.y)
                "right":
                        return Vector2i(-inward.x, inward.y)
        return inward


func _pick_start_cyan_richness(rng: RandomNumberGenerator) -> Dictionary:
        var roll := rng.randf()
        if roll > 0.88:
                return _mineral_richness_defs[3]
        if roll > 0.58:
                return _mineral_richness_defs[2]
        if roll > 0.22:
                return _mineral_richness_defs[1]
        return _mineral_richness_defs[0]


func _spawn_cyan_edge_resources(rng: RandomNumberGenerator) -> void:
        var margin: int = maxi(4, int(map_size * 0.08))
        var lanes: Array[int] = [
                roundi(float(map_size - 1) * 0.22),
                roundi(float(map_size - 1) * 0.38),
                roundi(float(map_size - 1) * 0.62),
                roundi(float(map_size - 1) * 0.78)
        ]

        for lane in lanes:
                var mirrored_cells: Array[Vector2i] = [
                        Vector2i(lane, margin),
                        Vector2i(map_size - 1 - lane, map_size - 1 - margin),
                        Vector2i(margin, lane),
                        Vector2i(map_size - 1 - margin, map_size - 1 - lane)
                ]
                for cell in mirrored_cells:
                        var final_cell := _nearest_free_resource_cell(_clamp_resource_cell(cell))
                        if final_cell.x < 0:
                                continue
                        var richness := _pick_cyan_edge_richness(rng)
                        _spawn_resource_deposit(final_cell, "cyan", richness)


func _pick_cyan_edge_richness(rng: RandomNumberGenerator) -> Dictionary:
        var roll := rng.randf()
        if roll > 0.9:
                return _mineral_richness_defs[3]
        if roll > 0.62:
                return _mineral_richness_defs[2]
        if roll > 0.28:
                return _mineral_richness_defs[1]
        return _mineral_richness_defs[0]


func _clamp_resource_cell(cell: Vector2i) -> Vector2i:
        return Vector2i(
                clampi(cell.x, 3, map_size - 4),
                clampi(cell.y, 3, map_size - 4)
        )


func _nearest_free_resource_cell(origin: Vector2i, max_radius: int = 4) -> Vector2i:
        if _is_resource_cell_allowed(origin):
                return origin

        for radius in range(1, max_radius + 1):
                for y in range(-radius, radius + 1):
                        for x in range(-radius, radius + 1):
                                if abs(x) != radius and abs(y) != radius:
                                        continue
                                var candidate := _clamp_resource_cell(origin + Vector2i(x, y))
                                if _is_resource_cell_allowed(candidate):
                                        return candidate

        return Vector2i(-1, -1)


func _pick_resource_richness(rng: RandomNumberGenerator, cell: Vector2i) -> Dictionary:
        var center_strength := _center_strength_for_cell(cell)
        var roll := rng.randf()
        var index := 0
        if center_strength > 0.58 and roll > 0.92:
                index = 4
        elif center_strength > 0.42 and roll > 0.78:
                index = 3
        elif roll > 0.52:
                index = 2
        elif roll > 0.22:
                index = 1

        return _mineral_richness_defs[index]


func _spawn_resource_deposit(cell: Vector2i, color_id: String, richness: Dictionary) -> void:
        _spawn_resource_deposit_at_position(cell, _tile_map.map_to_local(cell), color_id, richness, [cell])


func _spawn_resource_deposit_at_position(
        cell: Vector2i,
        base_position: Vector2,
        color_id: String,
        richness: Dictionary,
        footprint: Array
) -> void:
        var tier: int = int(richness["tier"])
        var texture_path := "res://Assets/Resources/Minerals/%s/tier_%02d.png" % [color_id, tier]
        var texture := _load_png_texture(texture_path)
        if texture == null:
                return

        var deposit := RESOURCE_DEPOSIT_SCRIPT.new()
        deposit.name = "Mineral%s%s_%d_%d" % [color_id.capitalize(), str(richness["id"]).capitalize(), cell.x, cell.y]
        deposit.resource_id = color_id
        deposit.richness_id = str(richness["id"])
        deposit.richness_name = str(richness["name"])
        deposit.max_amount = _resource_amount_for_color(color_id, richness)
        deposit.infinite = bool(richness["infinite"])
        deposit.blocks_path = true
        deposit.position = base_position + _resource_offset_for_tier(tier)
        deposit.z_index = _sort_z_for_footprint(footprint, 0)
        deposit.z_as_relative = false
        deposit.depleted.connect(_on_resource_depleted.bind(cell))
        deposit.set_meta("cell", cell)
        deposit.set_meta("footprint_cells", footprint)

        var shape := CollisionShape2D.new()
        var circle := CircleShape2D.new()
        circle.radius = _resource_collision_radius_for_tier(tier)
        if footprint.size() > 1:
                circle.radius *= 1.7
        shape.shape = circle
        shape.position = Vector2(0, 18)
        deposit.add_child(shape)

        var sprite := Sprite2D.new()
        sprite.name = "Sprite"
        sprite.texture = texture
        sprite.centered = true
        sprite.scale = _resource_scale_for_tier(tier, footprint.size())
        deposit.add_child(sprite)

        _resources_layer.add_child(deposit)
        var reserved_cells := _reserve_resource_cells(deposit, tier, footprint)
        deposit.set_meta("reserved_cells", reserved_cells)
        for footprint_cell in footprint:
                _resource_cells[footprint_cell] = deposit
                _blocked_cells[footprint_cell] = deposit


func _reserve_resource_cells(deposit: Node2D, tier: int, footprint: Array) -> Array[Vector2i]:
        var reserved_cells: Array[Vector2i] = []
        var radius := _resource_clearance_radius(tier, footprint.size())
        for footprint_cell in footprint:
                for y in range(footprint_cell.y - radius, footprint_cell.y + radius + 1):
                        for x in range(footprint_cell.x - radius, footprint_cell.x + radius + 1):
                                var reserved_cell := Vector2i(x, y)
                                if not _is_cell_inside_map(reserved_cell):
                                        continue
                                if reserved_cells.has(reserved_cell):
                                        continue
                                reserved_cells.append(reserved_cell)
                                _reserved_resource_cells[reserved_cell] = deposit
        return reserved_cells


func _resource_amount_for_color(color_id: String, richness: Dictionary) -> int:
        var amount := int(richness["amount"])
        if color_id == "yellow" and not bool(richness["infinite"]):
                amount *= 2
        return amount


func _resource_offset_for_tier(tier: int) -> Vector2:
        var index := clampi(tier - 1, 0, RESOURCE_VISUAL_OFFSETS.size() - 1)
        return RESOURCE_VISUAL_OFFSETS[index]


func _resource_scale_for_tier(tier: int, _footprint_size: int = 1) -> Vector2:
        var index := clampi(tier - 1, 0, RESOURCE_VISUAL_SCALES.size() - 1)
        var resource_scale: float = RESOURCE_VISUAL_SCALES[index]
        return Vector2(resource_scale, resource_scale)


func _resource_clearance_radius(tier: int, footprint_size: int = 1) -> int:
        if footprint_size > 1:
                return 5
        var index := clampi(tier - 1, 0, RESOURCE_CLEARANCE_BY_TIER.size() - 1)
        return RESOURCE_CLEARANCE_BY_TIER[index]


func _resource_collision_radius_for_tier(tier: int) -> float:
        return lerpf(26.0, 46.0, float(tier - 1) / 5.0)


func _is_resource_cell_allowed(cell: Vector2i) -> bool:
        if cell.x <= 2 or cell.y <= 2 or cell.x >= map_size - 3 or cell.y >= map_size - 3:
                return false
        if _is_cell_on_player_base_footprint(cell, 1):
                return false
        if _reserved_building_cells.has(cell):
                return false
        if _occupied_environment_cells.has(cell):
                return false
        if _resource_cells.has(cell):
                return false
        if _reserved_resource_cells.has(cell):
                return false
        return true


func _is_cell_inside_map(cell: Vector2i) -> bool:
        return cell.x >= 0 and cell.y >= 0 and cell.x < map_size and cell.y < map_size


func harvest_resource_at_cell(cell: Vector2i, amount: int) -> int:
        var deposit: Object = _resource_cells.get(cell)
        if deposit == null:
                return 0
        if deposit.has_method("harvest"):
                return deposit.harvest(amount)
        return 0


func _on_resource_depleted(cell: Vector2i) -> void:
        var deposit: Object = _resource_cells.get(cell)
        if deposit == null:
                return

        if deposit.has_meta("reserved_cells"):
                for reserved_cell in deposit.get_meta("reserved_cells"):
                        if _reserved_resource_cells.get(reserved_cell) == deposit:
                                _reserved_resource_cells.erase(reserved_cell)

        var footprint: Array = deposit.get_meta("footprint_cells", [cell])
        for footprint_cell in footprint:
                _resource_cells.erase(footprint_cell)
                _blocked_cells.erase(footprint_cell)


func _focus_camera_on_player_base() -> void:
        if _player_base:
                _camera.position = _player_base.position
        else:
                _center_camera()


func _load_png_texture(path: String) -> Texture2D:
        var imported_texture := load(path)
        if imported_texture is Texture2D:
                return imported_texture

        var image_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
        var image := Image.load_from_file(image_path)
        if image == null:
                push_error("Не удалось загрузить PNG: " + path)
                return null

        return ImageTexture.create_from_image(image)


func _selected_object_status() -> String:
        if is_instance_valid(_selected_civil_unit):
                var unit_type := str(_selected_civil_unit.get_meta("unit_type", "unit"))
                var phase := str(_selected_civil_unit.get_meta("phase", "idle"))
                var cargo := int(_selected_civil_unit.get_meta("cargo", 0))
                var blocked := str(_selected_civil_unit.get_meta("blocked_reason", ""))
                var text := "%s | %s" % [unit_type, phase]
                if unit_type == "harvester":
                        text += " | cargo %d/%d" % [cargo, HARVESTER_CAPACITY]
                if not blocked.is_empty():
                        text += " | blocked: %s" % blocked
                return text
        if is_instance_valid(_selected_building):
                return _building_status_text(_selected_building)
        if is_instance_valid(_selected_site):
                var building_id := str(_selected_site.get_meta("building_id", "site"))
                var duration := maxf(1.0, float(_selected_site.get_meta("duration_ms", 1.0)))
                var progress := int(roundf(float(_selected_site.get_meta("elapsed_ms", 0.0)) * 100.0 / duration))
                return "site %s | %d%%" % [building_id, progress]
        if is_instance_valid(_selected_unit) and _selected_unit.has_method("get_status_text"):
                return str(_selected_unit.call("get_status_text"))
        return "none"


func _building_status_text(building: Node2D) -> String:
        var building_id := str(building.get_meta("building_id", "building"))
        if building_id == "units_factory":
                var queue_text: Array[String] = []
                var queue: Array = building.get_meta("queue", [])
                for item in queue:
                        var unit_type := str(item.get("unit_type", "unit"))
                        var duration := maxf(1.0, float(item.get("duration_ms", 1.0)))
                        var progress := int(roundf(float(item.get("elapsed_ms", 0.0)) * 100.0 / duration))
                        var state_text := "done" if bool(item.get("completed", false)) else "%d%%" % progress
                        queue_text.append("%s %s" % [unit_type, state_text])
                return "units_factory | queue [%s] | Z builder X harvester C cancel" % ", ".join(queue_text)
        if building_id == "separator":
                var progress := int(roundf(float(building.get_meta("sep_progress_ms", 0.0)) * 100.0 / float(ECONOMY_STATE.SEP_CYCLE_MS)))
                return "separator | %s | %d%%" % ["powered" if bool(building.get_meta("powered", false)) else "paused", progress]
        return "%s | tier %s" % [building_id, str(building.get_meta("modification_tier", "-"))]


func _build_card_text() -> String:
        return "Build (auto-place near builder/HQ): Q sep | W raw | E matter | R elem | A power | F factory | S stop"


func _update_rts_hud_text() -> void:
        if not _hud_label:
                return

        var selected_text := _selected_object_status()
        var build_mode := "auto-place"

        _hud_label.text = "%s\nFaction: %s | Map: %d x %d | Chunks: %d | Seed: %d\nSelected: %s\nMode: %s | %s\nFeedback: %s\nLMB select | RMB move/attack | S stop | wheel zoom | middle drag | Esc" % [
                _economy.status_text(),
                player_faction_name,
                map_size,
                map_size,
                _chunk_count,
                world_seed,
                selected_text,
                build_mode,
                _build_card_text(),
                _feedback_text
        ]


# _update_hud_text() удалён — использовался только в устаревшем коде.
