extends "res://scripts/village_resident.gd"
## Event participants use the same real walking/arrival state machine as residents.
func _group_for(index: int) -> void:
	var place: String = schedule[index].place
	if entry.has("follow") and (place.begins_with("guide_") or place.begins_with("family_")): profile.guardian = entry.follow
	else: profile.erase("guardian")
func begin_appointment(index: int) -> void:
	_group_for(index)
	super.begin_appointment(index)
func seek_day(minutes: float) -> void:
	_group_for(population.routines.index_at(self,minutes))
	super.seek_day(minutes)
func interaction_prompt() -> String:
	match entry.role:
		"scout": return "Comprar uma rifa · atividade de Minecraft"
		"gelato": return "Pedir um gelado Nannarella"
		"police": return "Pedir indicações à agente Sofia"
		"musician": return "Ouvir o concerto / aplaudir"
		_: return "Cumprimentar "+str(entry.name)+" · "+activity_label()
func greet() -> String:
	_cancel_encounter()
	greetings += 1
	greet_time = 3.2
	velocity = Vector2.ZERO
	var player: CharacterBody2D = population.world.people.filter(func(p): return p.controlled)[0] if not population.world.people.is_empty() else null
	return population.interact_role(entry.role,player,self)+population.world.social_life.memory_line(self)
