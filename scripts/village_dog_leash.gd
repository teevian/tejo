extends Node2D
func _draw() -> void:
	var dog: CharacterBody2D = get_parent()
	var hand: Vector2 = dog.walker.position-dog.position+Vector2(20,-76)
	draw_line(Vector2(0,-30),hand,Color("536d43"),1.6,true)
