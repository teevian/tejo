extends "res://scripts/village_architecture.gd"
## Permanent painted equipment, with small real bases and live activity displays.
const ART = preload("res://data/village/festival-art.json")
var kind := ""
var director: Node2D
var movie_rect := Rect2()
func setup(world: Node2D, type: String, at: Vector2, width: float) -> void:
	kind = type
	name = "Festival_"+kind
	var spec: Dictionary = ART.data.props[kind]
	var r: Array = spec.rect
	var base := Rect2(at-Vector2(width*.34,16),Vector2(width*.68,16))
	build(load(spec.path),Rect2(r[0],r[1],r[2],r[3]),at,width,[base],world.opaque_paint)
	if kind=="cinema":
		var factor: float = width/float(r[2])
		movie_rect = Rect2(Vector2(133-float(r[0])-float(r[2])*.5,147-float(r[1])-float(r[3]))*factor,Vector2(318,275)*factor)
	if kind in ["fruit","sweets","flowers"]: set_meta("festival_counter",true)
	world.blocked_rects.append(base)
	world.actors.add_child(self)
	var display := preload("res://scripts/village_festival_display.gd").new()
	display.prop = self
	add_child(display)
func available() -> bool: return true
func interaction_prompt() -> String:
	return {"cinema":"Ver o programa / assistir ao cinema","fruit":"Comprar fruta à Dona Ana","sweets":"Pedir um doce na roulotte","score":"Participar no campeonato de toques","chess":"Desafiar a Idalina no xadrez","flowers":"Pedir uma flor à Rita","poetry":"Ouvir um poema curto","bicycle":"Conversar com a Susana"}.get(kind,"Conhecer a atividade")
func interact(player: CharacterBody2D) -> String: return director.interact_event(kind,player)
