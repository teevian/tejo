extends Node2D
## Camera-following emission, above daylight grading and below interface panels.
var ecosystem: Node2D

func _draw() -> void:
	var view: Rect2 = ecosystem.view_rect().grow(30)
	for owl in ecosystem.animals:
		if owl.species!="owl" or not owl.art.visible or owl.eye_open<0.15: continue
		var head: Vector2 = owl.position-Vector2(0,owl.altitude+40)
		if not view.has_point(head): continue
		for eye in owl.art.eye_points():
			var at: Vector2 = owl.position-Vector2(0,owl.altitude)+eye.position
			if ecosystem._covered_at(owl.position,at): continue
			# Yellow irises remain legible; the brief brighter catchlight follows a head turn.
			draw_set_transform(at,0,Vector2(1,owl.eye_open))
			draw_arc(Vector2.ZERO,eye.radius*1.12,0,TAU,16,Color(0.95,0.78,0.29,0.78*eye.weight),0.62,true)
			if owl.eye_glint>0:
				var shine: float = owl.eye_glint*eye.weight
				draw_circle(Vector2.ZERO,2.4,Color(0.94,0.80,0.39,shine*0.09))
				draw_circle(Vector2(-0.25,-0.2),0.72,Color(1.0,0.97,0.72,shine*0.95))
			draw_set_transform(Vector2.ZERO)
	for patch in ecosystem.firefly_patches:
		for insect in patch.members:
			var at: Vector2 = insect.anchor
			if not insect.glow_visible or insect.glow<0.01 or not view.has_point(at): continue
			# Fixed points sit on the ground between plants and behind opaque foliage.
			if ecosystem._covered_at(insect.position,at): continue
			var strength: float = insect.light_strength()
			# Small, soft falloff and a warm pale core; no large neon particles.
			for ring in range(8,0,-1):
				var radius := float(ring)*0.95
				draw_circle(at,radius,Color(0.69,0.84,0.26,strength*0.025*(1.0-float(ring)/10.0)))
			draw_circle(at,1.45,Color(0.83,0.95,0.42,strength*0.8))
			draw_circle(at,0.75,Color(1.0,1.0,0.76,strength))
