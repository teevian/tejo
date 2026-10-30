extends RefCounted
signal changed
const CAPACITY := 5
var items: Array[Dictionary] = []

func used_porte() -> int:
	var total := 0
	for item in items:
		total += int(item.porte)
	return total

func can_add(item: Dictionary) -> bool:
	var porte := int(item.get("porte",0))
	return porte>=1 and porte<=3 and used_porte()+porte<=CAPACITY

func try_add(item: Dictionary) -> bool:
	if not can_add(item):
		return false
	items.append(item.duplicate(true))
	changed.emit()
	return true

func take(index: int) -> Dictionary:
	if index<0 or index>=items.size():
		return {}
	var item: Dictionary = items[index]
	items.remove_at(index)
	changed.emit()
	return item
