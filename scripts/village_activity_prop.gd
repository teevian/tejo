extends "res://scripts/village_architecture.gd"
const ATLAS = preload("res://assets/world/village/street-life.png")
const ART = preload("res://data/village/street-life-art.json")
var kind := ""
var opened := false
var life: Node2D
var hours := ""
var caption: Label
func setup(world: Node2D, spec: Dictionary) -> void:
	kind = spec.kind
	name = "StreetActivity_"+kind
	var r: Array = ART.data.props[kind]
	var at := Vector2(spec.at[0],spec.at[1])
	var bases: Array = []
	if kind=="icecream": bases.append(Rect2(at-Vector2(spec.width*.36,35),Vector2(spec.width*.72,35)))
	elif kind=="raffles": bases.append(Rect2(at-Vector2(spec.width*.35,22),Vector2(spec.width*.7,22)))
	elif kind=="concert":
		bases.append(Rect2(at+Vector2(-70,-16),Vector2(20,10)))
		bases.append(Rect2(at+Vector2(8,-18),Vector2(76,18)))
		bases.append(Rect2(at+Vector2(-3,-65),Vector2(57,15)))
	build(ATLAS,Rect2(r[0],r[1],r[2],r[3]),at,spec.width,bases,world.opaque_paint)
	for base: Rect2 in bases: world.blocked_rects.append(base)
	world.actors.add_child(self)
	if kind in ["raffles","icecream"]:
		caption = Label.new()
		caption.position = Vector2(-64,-123) if kind=="raffles" else Vector2(-73,-75)
		caption.size = Vector2(128,42) if kind=="raffles" else Vector2(146,30)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",10 if kind=="raffles" else 11)
		caption.add_theme_color_override("font_color",Color("365543"))
		caption.text = "RIFAS\nMinecraft\nAtividade do agrupamento" if kind=="raffles" else "11h–20h · Nannarella"
		if kind=="icecream": caption.add_theme_stylebox_override("normal",TejoPerson._box(Color("e8ddbc"),3))
		add_child(caption)
func refresh(value: bool) -> void:
	opened = value
	if caption!=null: caption.visible = kind=="raffles" or not opened
func available() -> bool: return visible
func interaction_prompt() -> String:
	if kind=="icecream": return "Pedir um gelado Nannarella" if opened else "Nannarella · abre às 11h"
	if kind=="raffles": return "Comprar uma rifa · atividade de Minecraft"
	return "Ouvir o concerto / aplaudir"
func interact(player: CharacterBody2D) -> String:
	return life.interact_role({"icecream":"gelato","raffles":"scout","concert":"musician"}[kind],player)
