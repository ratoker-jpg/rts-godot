extends Node

const GameWorld := preload("res://Scripts/game_world.gd")
const MapEditor := preload("res://Scripts/map_editor.gd")

const FACTIONS := [
	{
		"id": "cyan",
		"name": "Голубая",
		"description": "Технологичная фракция с холодным светом.",
		"base_t1": "res://Assets/Buildings/cyan/base/t1.png",
	},
	{
		"id": "green",
		"name": "Зелёная",
		"description": "Инженерная фракция с зелёной энергетикой.",
		"base_t1": "res://Assets/Buildings/green/base/t1.png",
	},
	{
		"id": "purple",
		"name": "Фиолетовая",
		"description": "Экспериментальная фракция с плазменными узлами.",
		"base_t1": "res://Assets/Buildings/purple/base/t1.png",
	},
	{
		"id": "yellow",
		"name": "Жёлтая",
		"description": "Промышленная фракция с тяжёлыми модулями.",
		"base_t1": "res://Assets/Buildings/yellow/base/t1.png",
	},
]

var _menu: Control
var _message_label: Label
var _size_selector: OptionButton
var _game_world: Node
var _map_editor: Node
var _pending_map_size: int = 32
var _screen_mode: String = "menu"


func _ready() -> void:
	_show_menu()


func _show_menu() -> void:
	_screen_mode = "menu"
	if _game_world:
		_game_world.queue_free()
		_game_world = null
	if _map_editor:
		_map_editor.queue_free()
		_map_editor = null

	_clear_menu()
	_menu = _create_screen("MainMenu")

	var panel := _create_center_panel(Vector2(420, 500))
	_menu.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "RTS: Изометрический мир"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Прототип меню и процедурной карты"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	box.add_child(subtitle)

	_size_selector = OptionButton.new()
	_size_selector.add_item("Маленькая карта 32 x 32", 32)
	_size_selector.add_item("Средняя карта 64 x 64", 64)
	_size_selector.add_item("Большая карта 128 x 128", 128)
	_size_selector.selected = 0
	box.add_child(_size_selector)

	_add_menu_button(box, "Дальше: выбор фракции", _on_start_pressed)
	_add_menu_button(box, "Редактор карты", _show_map_editor)
	_add_menu_button(box, "Продолжить", _on_continue_pressed)
	_add_menu_button(box, "Настройки", _on_settings_pressed)
	_add_menu_button(box, "Выход", _on_exit_pressed)

	_message_label = Label.new()
	_message_label.text = "Выбери размер карты и нажми Enter или «Дальше: выбор фракции»."
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message_label)


func _show_faction_menu() -> void:
	_screen_mode = "factions"
	_clear_menu()
	_menu = _create_screen("FactionMenu")

	var panel := _create_center_panel(Vector2(980, 560))
	_menu.add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_theme_constant_override("separation", 18)
	panel.add_child(root_box)

	var title := Label.new()
	title.text = "Выбор фракции"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Пока в игру добавляется только база T1. Нажми 1-4 или кнопку «Выбрать»."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	root_box.add_child(subtitle)

	var faction_row := HBoxContainer.new()
	faction_row.alignment = BoxContainer.ALIGNMENT_CENTER
	faction_row.add_theme_constant_override("separation", 14)
	root_box.add_child(faction_row)

	for index in range(FACTIONS.size()):
		faction_row.add_child(_create_faction_card(FACTIONS[index], index + 1))

	_add_menu_button(root_box, "Назад", _show_menu)


func _create_screen(screen_name: String) -> Control:
	var screen := Control.new()
	screen.name = screen_name
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.055, 0.06, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)

	return screen


func _create_center_panel(panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_bottom = panel_size.y * 0.5
	return panel


func _create_faction_card(faction: Dictionary, hotkey: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 360)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(190, 150)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _load_png_texture(str(faction["base_t1"]))
	box.add_child(preview)

	var name_label := Label.new()
	name_label.text = str(faction["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 21)
	box.add_child(name_label)

	var desc := Label.new()
	desc.text = str(faction["description"])
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(190, 70)
	box.add_child(desc)

	var button := Button.new()
	button.text = "Выбрать %d" % hotkey
	button.custom_minimum_size = Vector2(160, 38)
	button.pressed.connect(_start_game_with_faction.bind(faction))
	box.add_child(button)

	return card


func _add_menu_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 42)
	button.pressed.connect(callback)
	parent.add_child(button)


func _on_start_pressed() -> void:
	_pending_map_size = _size_selector.get_selected_id()
	if _pending_map_size <= 0:
		_pending_map_size = 32

	_show_faction_menu()


func _start_game_with_faction(faction: Dictionary) -> void:
	_screen_mode = "game"
	_clear_menu()

	_game_world = GameWorld.new()
	_game_world.name = "GameWorld"
	_game_world.map_size = _pending_map_size
	_game_world.player_faction_id = str(faction["id"])
	_game_world.player_faction_name = str(faction["name"])
	_game_world.player_base_t1_path = str(faction["base_t1"])
	_game_world.return_to_menu_requested.connect(_show_menu)
	add_child(_game_world)


func _show_map_editor() -> void:
	_screen_mode = "editor"
	_clear_menu()
	_map_editor = MapEditor.new()
	_map_editor.name = "MapEditor"
	_map_editor.return_to_menu_requested.connect(_show_menu)
	add_child(_map_editor)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match _screen_mode:
			"menu":
				if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
					_on_start_pressed()
					get_viewport().set_input_as_handled()
			"factions":
				if event.keycode == KEY_ESCAPE:
					_show_menu()
					get_viewport().set_input_as_handled()
				elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
					var index: int = int(event.keycode) - int(KEY_1)
					if index >= 0 and index < FACTIONS.size():
						_start_game_with_faction(FACTIONS[index])
						get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	_message_label.text = "Продолжить: заглушка. Тут позже будет загрузка сохранения."


func _on_settings_pressed() -> void:
	_message_label.text = "Настройки: заглушка. Тут позже будут звук, графика и управление."


func _on_exit_pressed() -> void:
	get_tree().quit()


func _clear_menu() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null


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
