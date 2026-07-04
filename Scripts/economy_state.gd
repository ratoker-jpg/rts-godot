extends RefCounted

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

var raw: int = START_RAW
var matter: int = START_MATTER
var elements: int = START_ELEMENTS

var raw_cap: int = HQ_RAW_CAP
var matter_cap: int = HQ_MATTER_CAP
var element_cap: int = HQ_ELEMENT_CAP

var power_generated: int = HQ_BASE_POWER
var power_consumed: int = 0


func reset() -> void:
	raw = START_RAW
	matter = START_MATTER
	elements = START_ELEMENTS
	raw_cap = HQ_RAW_CAP
	matter_cap = HQ_MATTER_CAP
	element_cap = HQ_ELEMENT_CAP
	power_generated = HQ_BASE_POWER
	power_consumed = 0


func can_afford(matter_cost: int, element_cost: int) -> bool:
	return matter >= matter_cost and elements >= element_cost


func spend(matter_cost: int, element_cost: int) -> bool:
	if not can_afford(matter_cost, element_cost):
		return false
	matter -= matter_cost
	elements -= element_cost
	return true


func add_raw(amount: int) -> int:
	var accepted: int = mini(amount, maxi(0, raw_cap - raw))
	raw += accepted
	return accepted


func add_matter(amount: int) -> int:
	var accepted: int = mini(amount, maxi(0, matter_cap - matter))
	matter += accepted
	return accepted


func add_elements(amount: int) -> int:
	var accepted: int = mini(amount, maxi(0, element_cap - elements))
	elements += accepted
	return accepted


func add_storage_delta(storage: Dictionary) -> void:
	raw_cap += int(storage.get("raw", 0))
	matter_cap += int(storage.get("matter", 0))
	element_cap += int(storage.get("elements", 0))


func set_power_generated(value: int) -> void:
	power_generated = value


func set_power_consumed(value: int) -> void:
	power_consumed = value


func status_text() -> String:
	return "RAW %d/%d | MAT %d/%d | EL %d/%d | PWR %d/%d" % [
		raw,
		raw_cap,
		matter,
		matter_cap,
		elements,
		element_cap,
		power_consumed,
		power_generated,
	]
