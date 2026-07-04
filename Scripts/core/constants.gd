extends RefCounted

# ─── Tile & projection ─────────────────────────────────
const TILE_SET_PATH := "res://Scenes/isometric_tiles_TOP_FACE_try.tres"
const TILE_W_PX := 203
const TILE_H_PX := 116
const SOURCE_ID := 0
const ALT_ID := 0

# ─── Map generation ────────────────────────────────────
const CHUNK_MIN_SIZE := 6
const CHUNK_MAX_SIZE := 9
const EDGE_TILE := Vector2i(12, 0)
const PRIMARY_FLOOR_TILE := Vector2i(2, 0)
const PRIMARY_FLOOR_CHANCE := 0.72

# ─── Player base ───────────────────────────────────────
const PLAYER_BASE_SIZE := 3
const PLAYER_BASE_CENTER_RATIO := Vector2(0.90, 0.90)
const PLAYER_BASE_EDGE_MARGIN := 10
const PLAYER_BASE_MAX_TIER := 3
const TREE_CLEAR_RADIUS_RATIO := 0.08

# ─── Movement (из Phaser movementStateMachine.ts) ──────
const DEFAULT_ARRIVAL_THRESHOLD := 0.08
const SUBPIXEL_ARRIVAL_THRESHOLD := 0.03
const MAX_REPATH_ATTEMPTS := 3
const SMOOTHING_ARC_FACTOR := 0.4
const WAIT_BEFORE_REPATH_MS := 500
const RESERVATION_MAX_AGE_MS := 10000

# ─── Movement speeds (tiles/sec) ──────────────────────
const BUILDER_SPEED_TILES := 3.0
const HARVESTER_SPEED_TILES := 2.5

# ─── Harvester (из updateGameState.ts) ────────────────
const HARVESTER_GATHER_MS := 1000
const HARVESTER_UNLOAD_MS := 500
const HARVESTER_CAPACITY := 20

# ─── Economy ───────────────────────────────────────────
const START_RAW := 30
const START_MATTER := 120
const START_ELEMENTS := 0
const HQ_RAW_CAP := 200
const HQ_MATTER_CAP := 200
const HQ_ELEMENT_CAP := 200
const HQ_BASE_POWER := 10
const SEP_RAW_COST := 12
const SEP_MATTER_YIELD := 10
const SEP_ELEMENT_YIELD := 2
const SEP_CYCLE_MS := 5000
const POWER_PLANT_GENERATION := 15
const SEPARATOR_POWER_COST := 5
const FACTORY_POWER_COST := 4
const CIVIL_UNIT_CAP := 10
const FACTORY_QUEUE_LIMIT := 2
const FACTORY_SPAWN_TIMEOUT_MS := 5000

# ─── Combat (из combatRange.ts) ───────────────────────
const RANGE_TOLERANCE_TILES := 0.5
const POINT_BLANK_RANGE_TILES := 1.0
const AIM_FORGIVENESS_TILES := 0.5
const HEIGHT_TOLERANCE_TILES := 0.4
const DAMAGE_FLASH_DURATION_MS := 200
const AI_TICK_INTERVAL_MS := 200
const TURRET_AIM_TOLERANCE_RAD := 0.05
const DEFAULT_TURRET_TURN_SPEED_DEG := 120

# ─── Direction encoding (16-dir) ──────────────────────
const DIR_NAMES_16 := [
	"E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW",
	"W", "WNW", "NW", "NNW", "N", "NNE", "NE", "ENE"
]

# ─── Z-sort ───────────────────────────────────────────
const Z_INDEX_BASE := 1000
const Z_INDEX_TILE_BIAS := 10
const Z_INDEX_FOOTPRINT_BIAS := 2

# ─── Modular unit scale ───────────────────────────────
const MODULAR_UNIT_SCALE := 0.16
