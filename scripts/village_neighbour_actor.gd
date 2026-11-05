extends "res://scripts/village_resident.gd"
## A named neighbour can be acting, travelling or visibly at an actual window.
var story_frame := -1
var story_locked := false
var story_reserved := false
var window_node: Node2D
var entered_shops := 0
func begin_appointment(index: int) -> void:
	story_frame = -1
	story_locked = false
	story_reserved = false
	super.begin_appointment(index)
func seek_day(minutes: float) -> void:
	story_frame = -1
	story_locked = false
	story_reserved = false
	super.seek_day(minutes)
	_window()
func _window() -> bool:
	if appointment.get("mode","")!="window" or position.distance_to(anchor)>34: return false
	state = "window"
	collision_layer = 0; collision_mask = 0
	art.hide()
	if is_instance_valid(window_node): window_node.queue_redraw()
	return true
func _arrive() -> void:
	super._arrive()
	if state=="entering": entered_shops += 1
	_window()
func step(delta: float,cycle: RefCounted) -> void:
	if _window():
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		return
	if is_instance_valid(art): art.show()
	if story_locked:
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		velocity = Vector2.ZERO
		motion.phase = "work"
		art.queue_redraw()
		return
	super.step(delta,cycle)
func available() -> bool: return super.available() and state!="window"
func greet() -> String:
	_cancel_encounter()
	population.open_person(self)
	return ""
func interaction_prompt() -> String: return "Falar com "+str(entry.name)+" · "+activity_label()
