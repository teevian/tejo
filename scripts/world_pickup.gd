extends Node2D
const ItemArt = preload("res://scripts/item_art.gd")
const WorldScale = preload("res://scripts/world_scale.gd")
var item: Dictionary

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,9,Color(0.07,0.12,0.08,0.25))
	draw_set_transform(Vector2.ZERO)
	var size_value: float = WorldScale.PICKUP_SIZES[int(item.porte)-1]
	ItemArt.draw_item(self,item,Rect2(-size_value*0.5,-size_value*0.8,size_value,size_value))
