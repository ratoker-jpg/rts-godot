@tool
extends Node2D

@export var child_z_index: int = 20


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	_apply_to_existing_children()


func _on_child_entered_tree(child: Node) -> void:
	if child is CanvasItem:
		var item := child as CanvasItem
		item.z_index = child_z_index


func _apply_to_existing_children() -> void:
	for child in get_children():
		_on_child_entered_tree(child)
