extends RefCounted
class_name DamageFormula

# Формула урона с учётом брони.
# Соответствует src/config/armorFormula.ts из four-elements-phaser.
# finalDamage = max(rawDamage - armor, rawDamage * minDamagePercent)

# Применить урон к юниту с учётом брони.
# raw_damage: входящий урон (до брони).
# armor: значение брони цели (из body stats).
# min_damage_percent: минимальный процент урона (например 0.25 = 25%).
# Возвращает фактический нанесённый урон.
static func apply_armor_reduction(
		raw_damage: int,
		armor: int,
		min_damage_percent: float
	) -> int:
	var reduced := raw_damage - armor
	var floor_damage := int(round(raw_damage * min_damage_percent))
	return maxi(reduced, floor_damage)
