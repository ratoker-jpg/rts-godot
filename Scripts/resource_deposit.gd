extends StaticBody2D

signal depleted

@export var resource_id: String = "cyan"
@export var richness_id: String = "very_poor"
@export var richness_name: String = "Очень бедный"
@export var max_amount: int = 1000
@export var infinite: bool = false
@export var blocks_path: bool = true

var current_amount: int


func _ready() -> void:
	current_amount = max_amount
	set_meta("resource_id", resource_id)
	set_meta("richness_id", richness_id)
	set_meta("richness_name", richness_name)
	set_meta("resource_amount", current_amount)
	set_meta("resource_infinite", infinite)
	set_meta("resource_deposit", true)
	set_meta("blocks_path", blocks_path)


func harvest(amount: int) -> int:
	if infinite:
		return amount

	var taken: int = mini(amount, current_amount)
	current_amount -= taken
	set_meta("resource_amount", current_amount)
	if current_amount <= 0:
		depleted.emit()
		queue_free()
	return taken
