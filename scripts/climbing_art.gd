extends RefCounted
## Authored action keys, registered to the same foot anchor as the approved walk.
const Walk = preload("res://scripts/open_world_art.gd")
const CELL := Vector2(576,560)
const ANCHOR := Vector2(288,520)
const SOURCE_HEIGHT := 438.0
const ACTIONS := ["jump","fall","land","mantle","rope","belay","haul","push","legup","boost","help","pulled","carry","ride","chimney","crawl"]
const CYCLES := ["rope","belay","haul","push","chimney","crawl"]
const PING_PONG := [0,1,2,3,2,1]
const ATLASES := [
	[preload("res://assets/characters/climbing/te-air-rock.png"),preload("res://assets/characters/climbing/te-rope-effort.png"),preload("res://assets/characters/climbing/te-cooperation.png"),preload("res://assets/characters/climbing/te-carry-passages.png")],
	[preload("res://assets/characters/climbing/jo-air-rock.png"),preload("res://assets/characters/climbing/jo-rope-effort.png"),preload("res://assets/characters/climbing/jo-cooperation.png"),preload("res://assets/characters/climbing/jo-carry-passages.png")]
]
static var contacts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/climbing/animations.json"))

static func frame_for(action: String, phase: float, time: float) -> int:
	if phase>=0: return clampi(int(phase*4),0,3)
	if action=="haul": return posmod(floori(time/0.14),4)
	return PING_PONG[posmod(floori(time/(0.20 if action=="belay" else 0.10)),6)]

static func region(action: String, frame: int) -> Rect2:
	var index := ACTIONS.find(action)
	return Rect2(Vector2(clampi(frame,0,3)*CELL.x,posmod(index,4)*CELL.y),CELL)

static func draw_action(canvas: CanvasItem, kind: int, action: String, frame: int, origin := Vector2.ZERO, facing := 1.0) -> void:
	var index := ACTIONS.find(action)
	if index<0: return
	var factor: float = Walk.HEIGHTS[kind]/SOURCE_HEIGHT
	canvas.draw_set_transform(origin,0,Vector2(facing,1))
	canvas.draw_texture_rect_region(ATLASES[kind][floori(float(index)/4.0)],Rect2(-ANCHOR*factor,CELL*factor),region(action,frame))
	canvas.draw_set_transform(Vector2.ZERO)

static func contact(kind: int, action: String, frame: int, point: String, facing := 1.0) -> Vector2:
	if not ACTIONS.has(action): return Vector2(0,-62)
	var character: Dictionary = contacts.characters[kind]
	var xy: Array = character.actions[action][clampi(frame,0,3)][point]
	var result := (Vector2(xy[0],xy[1])-ANCHOR)*Walk.HEIGHTS[kind]/SOURCE_HEIGHT
	result.x *= facing
	return result
