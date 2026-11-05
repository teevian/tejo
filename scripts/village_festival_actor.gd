extends "res://scripts/village_resident.gd"
var ride: CharacterBody2D
var companion_dog: CharacterBody2D
var dog_wait := 0.0
var rejoining_dog := false
func begin_appointment(index: int) -> void:
	if is_instance_valid(ride) and ride.boarded:
		if schedule[index].mode!="inside":
			routine_index = index
			appointment = schedule[index]
			return
		ride.disembark()
		if schedule[index].place=="meal": schedule[index].destination = population.routines.doorway(position,false,"Café")
	super.begin_appointment(index)
func seek_day(minutes: float) -> void:
	if is_instance_valid(ride): ride.disembark()
	super.seek_day(minutes)
func step(delta: float, cycle: RefCounted) -> void:
	if state=="riding":
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		queue_redraw()
		return
	if is_instance_valid(companion_dog) and companion_dog.visible and state in ["walking","commuting","returning"]:
		var gap := position.distance_to(companion_dog.position)
		if rejoining_dog and gap<125:
			rejoining_dog = false
			dog_wait = 0
			_begin_walk(anchor,"commuting")
		elif gap>220 and not rejoining_dog:
			dog_wait += delta
			if dog_wait>6:
				var back: Vector2 = population.free_point(companion_dog.position+Vector2(35,0))
				if back!=Vector2.INF: rejoining_dog = _begin_walk(back,"returning")
			clock += delta
			greet_time = maxf(0,greet_time-delta)
			velocity = Vector2.ZERO
			motion.step(self,delta,0)
			art.queue_redraw()
			return
		elif gap<180: dog_wait = 0
	if available() and not social_lock and state=="activity" and entry.role=="cinema" and appointment.place=="cinema":
		if position.distance_to(anchor)>24:
			_begin_walk(anchor,"returning")
			super.step(delta,cycle)
			return
		clock += delta
		greet_time = maxf(0,greet_time-delta)
		frame = 1 if fposmod(clock+ordinal*.7,9)<1.6 else 0
		motion.extra = -1
		motion.phase = "watch"
		facing_left = population.event_props.cinema.position.x<position.x
		art.queue_redraw()
		return
	super.step(delta,cycle)
func interaction_prompt() -> String:
	return {"fruit_vendor":"Comprar fruta à Dona Ana","sweets_vendor":"Pedir um doce ao Quim","organizer":"Participar no campeonato de toques","referee":"Consultar a classificação dos toques","announcer":"Ouvir os resultados do campeonato","projectionist":"Saber qual é o filme de hoje","chess":"Desafiar a Idalina no xadrez","flowers":"Pedir uma flor à Rita"}.get(entry.role,"Cumprimentar "+str(entry.name)+" · "+activity_label())
func greet() -> String:
	_cancel_encounter()
	if is_instance_valid(ride) and ride.boarded: return ride.interact(null)
	var player: CharacterBody2D
	for person in population.world.people:
		if person.controlled: player = person; break
	var kind: String = {"fruit_vendor":"fruit","sweets_vendor":"sweets","organizer":"score","referee":"results","announcer":"results","projectionist":"cinema","chess":"chess","flowers":"flowers","poet":"poetry"}.get(entry.role,"")
	if not kind.is_empty():
		greetings += 1
		greet_time = 3
		return population.interact_event(kind,player)
	return super.greet()
