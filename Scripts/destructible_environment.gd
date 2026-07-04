extends StaticBody2D

signal destroyed

@export var max_health: int = 100
@export var blocks_path: bool = true

var current_health: int


func _ready() -> void:
	current_health = max_health
	set_meta("blocks_path", blocks_path)
	set_meta("destructible", true)
	set_meta("health", current_health)


func apply_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	set_meta("health", current_health)
	if current_health == 0:
		destroyed.emit()
		queue_free()
