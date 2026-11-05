extends RefCounted
## Separate from the bakery menu; prices are integer cents.
const PRODUCTS := [
	{"type":"chestnuts_roasted","name":"Castanhas assadas","price":250,"satiety":28.0,"art":0,"drink":false,"butter":false,"porte":1},
	{"type":"chestnuts_butter","name":"Castanhas com manteiga","price":280,"satiety":32.0,"art":1,"drink":false,"butter":true,"porte":1}]
const BUTTER_PRICE := 30
static func product(type: String) -> Dictionary:
	for entry in PRODUCTS:
		if entry.type==type: return entry
	return {}
static func item(butter: bool) -> Dictionary: return PRODUCTS[1 if butter else 0].duplicate(true)
