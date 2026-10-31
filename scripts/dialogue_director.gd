extends RefCounted
## Topics are selected by context and priority; equally ranked topics rotate.
## Effects are committed only after the last line, never when cancelled.
signal line_changed(line: Dictionary, initiator: int)
signal ended
signal flag_changed(flag: String, value: bool)

var topics: Array = []
var flags: Dictionary = {}
var visits: Dictionary = {}
var active_topic: Dictionary = {}
var line_index := 0
var initiator := 0

func _init() -> void:
	for path in ["res://data/dialogue/sintra.json","res://data/dialogue/sintra_banter.json"]:
		var content = JSON.parse_string(FileAccess.get_file_as_string(path))
		if content is Dictionary:
			topics.append_array(content.get("topics", []))

func is_active() -> bool:
	return not active_topic.is_empty()

func matches(topic: Dictionary, context: Dictionary) -> bool:
	for key in ["scene", "location", "initiator", "day_phase", "puppy_mood"]:
		if topic.has(key) and topic[key] != context.get(key):
			return false
	if topic.has("near") and not topic.near in context.get("near", []):
		return false
	for flag in topic.get("require_flags", []):
		if not flags.get(flag, false):
			return false
	for flag in topic.get("forbid_flags", []):
		if flags.get(flag, false):
			return false
	return not topic.get("lines", []).is_empty()

func start(context: Dictionary) -> bool:
	if is_active():
		return false
	var chosen: Dictionary = {}
	for topic in topics:
		if not matches(topic, context):
			continue
		if chosen.is_empty() or int(topic.get("priority", 0)) > int(chosen.get("priority", 0)):
			chosen = topic
		elif int(topic.get("priority", 0)) == int(chosen.get("priority", 0)) and int(visits.get(topic.id, 0)) < int(visits.get(chosen.id, 0)):
			chosen = topic
	if chosen.is_empty():
		return false
	active_topic = chosen
	initiator = int(context.initiator)
	line_index = 0
	_emit_line()
	return true

func advance() -> void:
	if not is_active():
		return
	line_index += 1
	if line_index < active_topic.lines.size():
		_emit_line()
		return
	visits[active_topic.id] = int(visits.get(active_topic.id, 0)) + 1
	for flag in active_topic.get("set_flags", []):
		flags[flag] = true
		flag_changed.emit(flag, true)
	cancel()

func cancel() -> void:
	if not is_active():
		return
	active_topic = {}
	ended.emit()

func _emit_line() -> void:
	var line: Dictionary = active_topic.lines[line_index].duplicate()
	if line.speaker is String:
		line.speaker = initiator if line.speaker == "initiator" else 1 - initiator
	line_changed.emit(line, initiator)
