extends SceneTree
const Checks = preload("res://tests/neck_motion_checks.gd")
func _initialize() -> void:
	quit(0 if Checks.new().run(0) else 1)
