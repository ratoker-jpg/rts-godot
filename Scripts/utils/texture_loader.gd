extends RefCounted

# Единая функция загрузки PNG-текстур с fallback.
# Заменяет дубликаты _load_png_texture() в main.gd, game_world.gd, combat_unit.gd.

static func load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported
	var image_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var image := Image.load_from_file(image_path)
	if image == null:
		push_error("Cannot load PNG: " + path)
		return null
	return ImageTexture.create_from_image(image)
