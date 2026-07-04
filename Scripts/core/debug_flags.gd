extends RefCounted

# Флаги для debug-команд. В production = false.
# В development: установить в true для тестов.

# Спавнить боевых юнитов бесплатно (U/I).
const SPAWN_UNITS_FREELY := false

# Бесконечные ресурсы.
const INFINITE_RESOURCES := false

# Показывать отладку pathfinding (overlay).
const SHOW_PATHFINDING_DEBUG := false

# Показывать occupancy map.
const SHOW_OCCUPANCY_DEBUG := false

# Показывать tile reservations.
const SHOW_RESERVATIONS_DEBUG := false
