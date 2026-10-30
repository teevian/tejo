extends Node2D
var signpost: StaticBody2D
func _draw() -> void:
	signpost.draw_sign_labels(self)
