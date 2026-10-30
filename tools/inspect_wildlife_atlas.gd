extends SceneTree
## Read-only atlas inspection: find disconnected silhouettes, not assumed cell cuts.
func _initialize() -> void:
	for species in ["fox","squirrel","bird","frog","butterfly"]:
		var im := Image.load_from_file("res://assets/wildlife/"+species+"-directions.png")
		var w := im.get_width()
		var h := im.get_height()
		var seen := PackedByteArray()
		seen.resize(w*h)
		var boxes: Array = []
		for y in h:
			for x in w:
				var start := y*w+x
				if seen[start] or im.get_pixel(x,y).a<0.45:
					continue
				var stack := PackedInt32Array([start])
				seen[start] = 1
				var box := Rect2i(x,y,1,1)
				var count := 0
				while not stack.is_empty():
					var v := stack[-1]
					stack.resize(stack.size()-1)
					var p := Vector2i(v%w,v/w)
					box = box.expand(p)
					count += 1
					for d in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
						var n: Vector2i = p+d
						if n.x<0 or n.y<0 or n.x>=w or n.y>=h:
							continue
						var ni: int = n.y*w+n.x
						if seen[ni] or im.get_pixelv(n).a<0.45:
							continue
						seen[ni] = 1
						stack.append(ni)
				if count>1000:
					boxes.append({"box":[box.position.x,box.position.y,box.size.x,box.size.y],"row":int(box.get_center().y*4/h),"column":int(box.get_center().x*5/w)})
		boxes.sort_custom(func(a,b): return a.row*5+a.column < b.row*5+b.column)
		print(species," ",w,"x",h," ",JSON.stringify(boxes))
	quit()
