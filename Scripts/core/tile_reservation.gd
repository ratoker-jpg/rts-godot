extends RefCounted

# Предотвращает наложение юнитов.
# Соответствует src/state/tileReservation.ts из four-elements-phaser.
# Юнит резервирует следующий тайл перед входом в него.
# Другие юниты не могут path'ить в занятые/зарезервированные тайлы.

const WAIT_BEFORE_REPATH_MS := 500
const REPATH_RETRY_INTERVAL_MS := 1000
const RESERVATION_MAX_AGE_MS := 10000


class ReservationHolder:
	var unit_id: String
	var unit_type: String  # "harvester" | "builder" | "combat-vehicle"

	func _init(id: String, t: String) -> void:
		unit_id = id
		unit_type = t


class Reservation:
	var tx: int
	var ty: int
	var holder: ReservationHolder
	var created_at_ms: int


var _reservations: Dictionary = {}  # flat_key (int) → Reservation
var _width: int


func _init(w: int = 1) -> void:
	_width = w


func _key(tx: int, ty: int) -> int:
	return tx + ty * _width


func is_reserved(tx: int, ty: int) -> bool:
	return _reservations.has(_key(tx, ty))


func is_reserved_by_other(tx: int, ty: int, exclude_unit_id: String) -> bool:
	var r = _reservations.get(_key(tx, ty))
	if r == null:
		return false
	return r.holder.unit_id != exclude_unit_id


func get_reservation(tx: int, ty: int) -> Reservation:
	return _reservations.get(_key(tx, ty))


func reserve(tx: int, ty: int, holder: ReservationHolder, now_ms: int) -> bool:
	var k := _key(tx, ty)
	var existing = _reservations.get(k)
	if existing != null and existing.holder.unit_id != holder.unit_id:
		return false  # уже занят другим юнитом
	var r := Reservation.new()
	r.tx = tx
	r.ty = ty
	r.holder = holder
	r.created_at_ms = now_ms
	_reservations[k] = r
	return true


func release(tx: int, ty: int, unit_id: String) -> void:
	var k := _key(tx, ty)
	var r = _reservations.get(k)
	if r != null and r.holder.unit_id == unit_id:
		_reservations.erase(k)


func release_all(unit_id: String) -> void:
	var to_erase: Array = []
	for k in _reservations.keys():
		var r = _reservations[k]
		if r.holder.unit_id == unit_id:
			to_erase.append(k)
	for k in to_erase:
		_reservations.erase(k)


func clean_stale(now_ms: int, max_age_ms: int) -> int:
	var count := 0
	var to_erase: Array = []
	for k in _reservations.keys():
		var r = _reservations[k]
		if now_ms - r.created_at_ms > max_age_ms:
			to_erase.append(k)
			count += 1
	for k in to_erase:
		_reservations.erase(k)
	return count


func get_all_reservations() -> Array:
	return _reservations.values()


func size() -> int:
	return _reservations.size()


func clear() -> void:
	_reservations.clear()
