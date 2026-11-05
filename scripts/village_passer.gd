extends "res://scripts/village_resident.gd"
## Anonymous circulation has a local circuit, actual shop door and a fixed daily shift.
var circuit: Array[Vector2] = []
var door := Vector2.ZERO
var circuit_index := 0
var pause_left := 0.0
var shopping_left := 0.0
var shopping := false
var stopped := 0.0
var crossings := 0
var shop_entries := 0
func begin_appointment(index: int) -> void:
	shopping = false
	super.begin_appointment(index)
func seek_day(minutes: float) -> void:
	shopping = false
	super.seek_day(minutes)
func step(delta: float,cycle: RefCounted) -> void:
	if appointment.get("mode","")=="inside": super.step(delta,cycle); return
	if shopping:
		clock += delta; shopping_left -= delta
		if shopping_left<=0:
			shopping = false; _outside(); _begin_walk(circuit[circuit_index],"walking")
		return
	if state=="walking" and goal==door and position.distance_to(door)<44:
		shopping = true; shopping_left = 4+ordinal%6; shop_entries += 1; _inside(); return
	if state=="activity" and encounter_id<0 and greet_time<=0 and not event_busy:
		pause_left -= delta
		if pause_left<=0:
			circuit_index = (circuit_index+1)%circuit.size()
			var shops_open: bool = cycle.minutes>=540 and cycle.minutes<1140
			var target: Vector2 = door if shops_open and crossings%5==4 and door.distance_to(anchor)<420 else circuit[circuit_index]
			if _begin_walk(target,"walking"): crossings += 1; pause_left = 7+ordinal%17
	super.step(delta,cycle)
func greet() -> String:
	_cancel_encounter()
	greet_time = 2
	return str(entry.name)+": "+str(entry.greeting)
