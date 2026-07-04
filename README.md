# RTS: Four Elements (Godot 4.7)

Изометрическая RTS с модульными танками и гражданской экономикой. Перенос с Phaser 4 + TypeScript на Godot 4.7 + GDScript.

## Запуск

1. Установить Godot 4.7+ (https://godotengine.org/download).
2. Открыть `project.godot` в Godot Editor.
3. Запустить сцену `Scenes/main.tscn` (F5).

## Управление

### Главное меню
- `Enter` / `Space` — далее (выбор фракции)
- `1`–`4` — выбор фракции (Голубая / Зелёная / Фиолетовая / Жёлтая)
- `Esc` — назад

### Игра
- **LMB** — выбрать юнит / здание / стройплощадку
- **RMB** — команда:
  - на врага → атаковать (target-lock + auto-chase)
  - на ресурс (с harvester'ом) — собирать
  - на землю — двигаться
- **S** — остановить выбранный юнит / снять target-lock
- **MMB + drag** — пан камеры
- **Wheel** — зум
- **Esc** — пауза / выход в меню

#### Строительство (авто-размещение)
При нажатии система автоматически находит ближайшую валидную позицию:
- если выбран **builder** → рядом с builder'ом
- иначе → рядом с HQ

| Клавиша | Здание | Стоимость (matter) |
|---------|--------|---------------------|
| Q | Separator | 60 |
| W | Raw Storage | 40 |
| E | Matter Storage | 40 |
| R | Elements Storage | 50 |
| A | Power Plant | 100 |
| F | Units Factory | 120 |

#### Производство юнитов (на Factory)
- **Z** — заказать Builder (40 matter + 10 elements)
- **X** — заказать Harvester (50 matter + 10 elements)
- **C** — отменить последний заказ (с возвратом ресурсов)

#### Апгрейды боевых юнитов
- **H** — апгрейд hull (M0 → M1 → M2 → M3)
- **T** — апгрейд turret
- **1** / **2** — переключить hull (wasp / hunter)
- **3** / **4** — переключить turret (smoky / railgun)
- **5** / **6** / **7** — апгрейд базы до тира 1 / 2 / 3

## Структура проекта

```
rts-godot/
├── project.godot              # Godot 4.7, Forward+
├── Scripts/
│   ├── core/                  # Подсистемы (pathfinding, movement, combat, build)
│   │   ├── constants.gd              # Все магические числа
│   │   ├── occupancy_map.gd          # Карта занятости тайлов
│   │   ├── tile_reservation.gd       # Резервирование тайлов юнитами
│   │   ├── pathfinding.gd            # BFS 4-connectivity
│   │   ├── movement_state_machine.gd # 11-state движение (Battle of Azer model)
│   │   ├── damage_formula.gd         # Armor formula
│   │   ├── combat_range.gd           # Range bands (point_blank/in_range/at_stop/out_of_range)
│   │   ├── combat_targeting.gd       # Target-lock, auto-chase, auto-fire
│   │   ├── build_site_selector.gd    # Авто-выбор позиции для здания
│   │   └── debug_flags.gd            # Флаги debug-команд
│   ├── utils/                 # Утилиты
│   │   ├── texture_loader.gd         # load_png с fallback
│   │   ├── iso_coords.gd             # Изометрические преобразования
│   │   └── direction.gd              # 16-dir encoding, conversion
│   ├── main.gd                # Меню, выбор фракции
│   ├── game_world.gd          # Главный игровой мир (orchestrator)
│   ├── combat_unit.gd         # Боевой юнит (hull + turret + movement + combat)
│   ├── projectile.gd          # Снаряд с pierce
│   ├── building_catalog.gd    # Визуальные offset/scale таблицы
│   ├── building_registry.gd   # Gameplay-конфиги зданий
│   ├── economy_state.gd       # Экономика (raw/matter/elements/power)
│   ├── resource_deposit.gd    # Ресурсный узел
│   ├── destructible_environment.gd  # Деревья с HP
│   └── map_editor.gd          # Редактор карт
├── Scenes/                    # Godot сцены и TileSet'ы
├── Assets/                    # PNG ассеты (4 фракции × 2 hull × 2 turret × 4 mod × 16 dir)
└── Data/                      # Сохранённые раскладки редактора карт
```

## Архитектура движения (модель "Battle of Azer")

Все наземные юниты (combat, builder, harvester) используют единую `MovementStateMachine` с 11 состояниями:

- `IDLE` — нет команды
- `PATH_REQUESTED` — путь задан, начинается движение
- `TURNING_TO_SEGMENT` — корпус поворачивается к направлению следующего сегмента
- `MOVING_SEGMENT` — движение к waypoint с ускорением
- `BRAKING` — торможение перед waypoint
- `NEXT_SEGMENT` — прибытие, переход к следующему сегменту
- `STOPPING` — торможение после команды остановки
- `BLOCKED` — тайл занят, ожидание 500мс
- `REPATHING` — поиск нового пути (макс. 3 попытки)
- `TARGET_CHASE` — преследование цели
- `ATTACKING` — в бою (управляется боевой системой)

### Tile Reservation
Каждый юнит резервирует следующий тайл перед входом. Другие юниты не могут path'ить в занятые тайлы. Это предотвращает наложение.

### Pathfinding
BFS 4-connectivity (N→E→S→W детерминированный порядок). Возвращает массив тайлов без стартового. Использует `PackedInt64Array` с индексом head вместо `pop_front()` (O(1) вместо O(N)).

## Боевая система

### Урон с бронёй
```
finalDamage = max(rawDamage - armor, rawDamage × minDamagePercent)
```

| Hull | Armor [M0..M3] | minDamage% |
|------|----------------|------------|
| wasp | 2, 3, 4, 5 | 0.25 |
| hunter | 5, 7, 9, 12 | 0.20 |

### Range Bands
- `POINT_BLANK` — цель ближе minRange (auto-hit assist)
- `IN_RANGE` — цель между minRange и maxRange
- `AT_STOP` — цель на stopDistance (идеальная дистанция)
- `OUT_OF_RANGE` — цель вне maxRange → auto-chase

### Turret Aiming
Башня плавно поворачивается к цели со скоростью из turret-конфига (smoky: 130-150 deg/s, railgun: 70-90 deg/s). Огонь открывается только когда башня наведена (tolerance ~3°).

### Auto-Chase
Если цель вне диапазона, юнит автоматически ищет путь через pathfinding и приближается. На stop_distance останавливается и продолжает огонь.

## Экономика

```
harvester → RAW (cyan mineral)  →  separator  →  MATTER + ELEMENTS
                                                       ↑
                                            power_plant (POWER) → separator + factory
```

- **RAW** — добывается harvester'ом из cyan-минералов
- **MATTER** — производится separator'ом (12 RAW → 10 MATTER + 2 ELEMENTS за 5 сек)
- **ELEMENTS** — добывается из yellow-минералов / побочный продукт separator'а
- **POWER** — генерируется HQ (10) + power_plant (15)

## Разработка

### Требования
- Godot 4.7+
- Git LFS (для PNG-ассетов)

### Запуск тестов
```bash
godot --headless --path . --script Scripts/main.gd
```

### CI/CD
GitHub Actions настроен в `.github/workflows/ci.yml`:
- GDScript lint
- Export Windows build
- Telegram notification

## Документация

- `RTS_GODOT_FULL_AUDIT.md` — полный технический аудит проекта
- `RTS_GODOT_IMPLEMENTATION_PLAN.md` — план реализации (5 этапов)
- `FOUR_ELEMENTS_FULL_AUDIT.md` — аудит исходного Phaser-проекта

## Лицензия

Приватный проект. Все права защищены.
