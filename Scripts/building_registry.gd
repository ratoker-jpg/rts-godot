extends RefCounted

const BUILDABLE_IDS := [
	"separator",
	"raw_storage",
	"matter_storage",
	"elements_storage",
	"power_plant",
	"units_factory",
]

const BUILDINGS := {
	"hq": {
		"display_name": "HQ",
		"asset_key": "base/t1.png",
		"buildable": false,
		"hp": 500,
		"storage": {"raw": 200, "matter": 200, "elements": 200},
		"power_generation": 10,
	},
	"separator": {
		"display_name": "Separator",
		"asset_key": "tech/tech_01.png",
		"buildable": true,
		"matter_cost": 60,
		"element_cost": 0,
		"build_time_ms": 20000,
		"hp": 200,
		"consumer": "separator",
	},
	"raw_storage": {
		"display_name": "Raw Storage",
		"asset_key": "structures/structure_02.png",
		"buildable": true,
		"matter_cost": 40,
		"element_cost": 0,
		"build_time_ms": 15000,
		"hp": 150,
		"storage": {"raw": 200},
	},
	"matter_storage": {
		"display_name": "Matter Storage",
		"asset_key": "structures/structure_03.png",
		"buildable": true,
		"matter_cost": 40,
		"element_cost": 0,
		"build_time_ms": 15000,
		"hp": 150,
		"storage": {"matter": 200},
	},
	"elements_storage": {
		"display_name": "Elements Storage",
		"asset_key": "tech/tech_08.png",
		"buildable": true,
		"matter_cost": 50,
		"element_cost": 5,
		"build_time_ms": 18000,
		"hp": 150,
		"storage": {"elements": 200},
	},
	"power_plant": {
		"display_name": "Power Plant",
		"asset_key": "tech/tech_05.png",
		"buildable": true,
		"matter_cost": 100,
		"element_cost": 5,
		"build_time_ms": 25000,
		"hp": 180,
		"power_generation": 15,
	},
	"units_factory": {
		"display_name": "Units Factory",
		"asset_key": "structures/structure_01.png",
		"buildable": true,
		"matter_cost": 120,
		"element_cost": 10,
		"build_time_ms": 40000,
		"hp": 250,
		"consumer": "factory",
	},
}

const ASSET_KEY_TO_BUILDING_ID := {
	"base/t1.png": "hq",
	"base/t2.png": "hq",
	"base/t3.png": "hq",
	"tech/tech_01.png": "separator",
	"structures/structure_02.png": "raw_storage",
	"structures/structure_03.png": "matter_storage",
	"tech/tech_08.png": "elements_storage",
	"structures/structure_01.png": "units_factory",
	"tech/tech_05.png": "power_plant",
}

const CIVIL_UNITS := {
	"builder": {
		"display_name": "Builder",
		"matter_cost": 40,
		"element_cost": 10,
		"production_time_ms": 15000,
	},
	"harvester": {
		"display_name": "Harvester",
		"matter_cost": 50,
		"element_cost": 10,
		"production_time_ms": 20000,
	},
}


static func has_building(building_id: String) -> bool:
	return BUILDINGS.has(building_id)


static func get_config(building_id: String) -> Dictionary:
	return BUILDINGS.get(building_id, {})


static func is_buildable(building_id: String) -> bool:
	return bool(get_config(building_id).get("buildable", false))


static func all_buildable_ids() -> Array:
	return BUILDABLE_IDS.duplicate()


static func asset_key_for(building_id: String, tier: int = 1) -> String:
	if building_id == "hq":
		return "base/t%d.png" % clampi(tier, 1, 3)
	return str(get_config(building_id).get("asset_key", ""))


static func texture_path_for(building_id: String, faction_id: String, tier: int = 1) -> String:
	var asset_key := asset_key_for(building_id, tier)
	if asset_key.is_empty():
		return ""
	return "res://Assets/Buildings/%s/%s" % [faction_id, asset_key]


static func building_id_from_asset_key(asset_key: String) -> String:
	return str(ASSET_KEY_TO_BUILDING_ID.get(asset_key.replace("\\", "/"), ""))


static func building_id_from_texture_path(texture_path: String) -> String:
	var path := texture_path.replace("\\", "/")
	var marker := "/Buildings/"
	var marker_index := path.find(marker)
	if marker_index < 0:
		return ""
	var relative := path.substr(marker_index + marker.length())
	var parts := relative.split("/", false)
	if parts.size() < 3:
		return ""
	return building_id_from_asset_key("%s/%s" % [parts[1], parts[2]])


static func get_civil_unit_config(unit_type: String) -> Dictionary:
	return CIVIL_UNITS.get(unit_type, {})
