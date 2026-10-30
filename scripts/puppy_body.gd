extends Node2D
var puppy: Node2D
func _draw() -> void:
	preload("res://scripts/puppy_art.gd").draw_pose(self,puppy)
