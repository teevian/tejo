extends Node2D
## Small emissive sources are painted after the day grade, with facade occlusion.
var lighting: Node2D
var proxies: Dictionary = {}
var visible_lamps: Array = []
func _process(_delta: float) -> void:
	var transform: Transform2D = lighting.world.get_canvas_transform()
	var screen := get_viewport_rect().grow(140)
	visible_lamps.clear()
	for lamp in lighting.lamps:
		if not lamp.halo.visible: continue
		var point: Vector2 = lamp.node.position+lamp.halo.position
		if screen.has_point(transform*point) and _clear(point,lamp.node): visible_lamps.append(lamp)
	for proxy in proxies.values(): proxy.hide()
	for window in lighting.windows:
		if window.get("level",0)<.05: continue
		var owner: Node2D = window.building
		for pane in window.panes:
			var center: Vector2 = owner.position+(pane.polygon[0]+pane.polygon[2])*.5
			if not screen.has_point(transform*center) or not _clear(center,owner): continue
			var id: int = pane.get_instance_id()
			if not proxies.has(id):
				var proxy := Polygon2D.new()
				proxy.uv = pane.uv
				proxy.texture = pane.texture
				proxy.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				proxy.material = pane.material
				add_child(proxy)
				proxies[id] = proxy
			var polygon := PackedVector2Array()
			for point in pane.polygon: polygon.append(transform*(owner.position+point))
			proxies[id].polygon = polygon
			proxies[id].show()
	queue_redraw()
func _clear(point: Vector2, owner: Node2D) -> bool:
	for building in lighting.world.buildings:
		if building==owner or building.position.y<=owner.position.y: continue
		if building.screen_bounds.has_point(point): return false
	for actor in lighting.world.people+lighting.world.population.residents+lighting.world.street_life.residents:
		if actor.visible and actor.position.y>owner.position.y and Rect2(actor.position-Vector2(24,160),Vector2(48,160)).has_point(point): return false
	return true
func _draw() -> void:
	var transform: Transform2D = lighting.world.get_canvas_transform()
	var zoom: float = transform.get_scale().x
	for lamp in visible_lamps:
		var head: Vector2 = transform*(lamp.node.position+lamp.halo.position)
		var radius := Vector2(58,68)*zoom
		draw_texture_rect(lighting.glow_texture,Rect2(head-radius,radius*2),false,Color(1,.83,.46,lighting.lamp_strength*.72))
		draw_circle(head,3.2*zoom,Color(1,.88,.55,lighting.lamp_strength))
		var floor_at: Vector2 = transform*lamp.node.position
		if _clear(lamp.node.position,lamp.node):
			var pool := Vector2(120,42)*zoom
			draw_texture_rect(lighting.glow_texture,Rect2(floor_at-pool,pool*2),false,Color(1,.75,.35,lighting.lamp_strength*.22))
