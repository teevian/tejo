extends Node2D
## The lit projection stays bright after the night grade, and follows the real camera.
var director: Node2D
func _draw() -> void:
	if not director.world.is_visible_in_tree() or not director.cinema_open(): return
	var screen: Node2D = director.event_props.cinema
	draw_set_transform_matrix(get_viewport().get_canvas_transform()*screen.get_global_transform())
	preload("res://scripts/village_festival_display.gd").paint_movie(self,screen.movie_rect,director.minute,true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
