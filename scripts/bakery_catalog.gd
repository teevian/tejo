extends RefCounted
## Prices are integer cents; one peach iced tea entry despite its repeated mention.
const PRODUCTS := [
	{"type":"bakery_carrot","name":"Bolo de cenoura","price":280,"satiety":30.0,"art":0,"drink":false},
	{"type":"bakery_red_velvet","name":"Bolo red velvet","price":320,"satiety":32.0,"art":1,"drink":false},
	{"type":"bakery_blue_velvet","name":"Bolo blue velvet","price":320,"satiety":32.0,"art":2,"drink":false},
	{"type":"bakery_nata","name":"Pastel de nata","price":140,"satiety":18.0,"art":3,"drink":false},
	{"type":"bakery_travesseiro","name":"Travesseiro de Sintra","price":180,"satiety":24.0,"art":4,"drink":false},
	{"type":"bakery_peanuts","name":"Amendoins","price":120,"satiety":20.0,"art":5,"drink":false},
	{"type":"bakery_peach_tea","name":"Iced tea de pêssego","price":180,"satiety":6.0,"art":6,"drink":true},
	{"type":"bakery_water","name":"Água","price":100,"satiety":0.0,"art":7,"drink":true}]
static func euro(cents: int) -> String: return "%d,%02d €"%[cents/100,cents%100]
static func product(type: String) -> Dictionary:
	for item in PRODUCTS:
		if item.type==type: return item
	return {}
static func food(item: Dictionary) -> bool:
	return not product(str(item.get("type",""))).is_empty() or not preload("res://scripts/chestnut_catalog.gd").product(str(item.get("type",""))).is_empty() or str(item.get("type","")) in ["gelato","festival_fruit","festival_sweets"]
static func nutrition(item: Dictionary) -> float:
	var known := product(str(item.get("type","")))
	if known.is_empty(): known = preload("res://scripts/chestnut_catalog.gd").product(str(item.get("type","")))
	return float(known.satiety) if not known.is_empty() else float({"gelato":16,"festival_fruit":18,"festival_sweets":24}.get(item.get("type",""),0))
static func item(index: int) -> Dictionary:
	var result: Dictionary = PRODUCTS[index].duplicate(true); result.porte = 1; return result
