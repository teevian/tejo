extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node2D = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	var life: Node2D = scene.world.living_life
	var actor: CharacterBody2D = life.by_id.plutonio
	var ok: bool = actor.entry.name=="Prumo" and actor.entry.get("living_fallback",false) and life.ART.data.has("fallback") and ResourceLoader.exists(life.ART.data.fallback.path)
	if not ok: push_error("Public execution uses the original Prumo identity and its own native atlas")
	scene.queue_free()
	for i in 4: await physics_frame
	if ok: print("PASS: configurable fictional cameo has an original named and drawn replacement for public execution")
	quit(0 if ok else 1)
