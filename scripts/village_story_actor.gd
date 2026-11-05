extends "res://scripts/village_resident.gd"
## Same real walking/doors as existing residents; authored window and errand modes.
var story_reserved := false
var bench_sitting := false
var bench_waiting := false
var window_node: Node2D
var errand := Vector2.INF
var delivery_mode := ""
func begin_appointment(index: int) -> void:
	bench_sitting = false
	bench_waiting = false
	event_busy = false
	if is_instance_valid(population.world.social_life): population.cancel_for(entry.id)
	if delivery_mode in ["escort","trail"]: return
	if is_instance_valid(art): art.show()
	super.begin_appointment(index)
func seek_day(minutes: float) -> void:
	reset_errand()
	super.seek_day(minutes)
	_update_window()
func reset_errand() -> void:
	set_meta("seeking_bench",false)
	bench_sitting = false
	bench_waiting = false
	story_reserved = false
	event_busy = false
	delivery_mode = ""
	show_body()
func show_body() -> void:
	if is_instance_valid(art): art.show()
func _update_window() -> bool:
	if appointment.get("mode","")=="window" and position.distance_to(anchor)<44 and not event_busy and not story_reserved:
		state = "window"
		collision_layer = 0
		collision_mask = 0
		art.hide()
		if is_instance_valid(window_node): window_node.queue_redraw()
		return true
	return false
func available() -> bool: return super.available() and state!="window"
func step(delta: float, cycle: RefCounted) -> void:
	if _update_window():
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		frame = 1 if fposmod(clock+ordinal,8)<2.5 else 0
		return
	if bench_sitting:
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		art.queue_redraw()
		return
	super.step(delta,cycle)
	if entry.role=="late" and state in ["walking","commuting"]:
		profile.commute_speed = 175
func interaction_prompt() -> String: return "Falar com "+str(entry.name)+" · "+str(entry.purpose)
func greet() -> String:
	if story_reserved and population.open_episode(self,population.player()): return ""
	_cancel_encounter()
	greet_time = 1.5
	var player: CharacterBody2D = population.player()
	population.open_character(self,player)
	return ""
