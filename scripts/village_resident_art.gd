extends Node2D
## Native atlas regions and measured foot anchors; no puppet deformation or recolouring.
const MANIFEST = preload("res://data/village/resident-art.json")
const STREET_ART = preload("res://data/village/street-life-art.json")
const SOCIAL_ART = preload("res://data/village/social-art.json")
const LIVING_ART = preload("res://data/village/living-art.json")
const FESTIVAL_ART = preload("res://data/village/festival-art.json")
const INDIVIDUAL = preload("res://data/village/individuality-art.json")
static var textures: Dictionary = {}
var resident: CharacterBody2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	material = resident.population.world.opaque_paint
	if resident.entry.get("neighbour",false): material = resident.population.sprite_paint

func _draw() -> void:
	var entry: Dictionary = resident.entry
	var night_pose: Dictionary = resident.get_meta("nightlife_pose",{})
	if not night_pose.is_empty():
		paint_pose(night_pose.path,night_pose)
		return
	if entry.has("ambient_source"):
		var pose: Dictionary = ambient_pose()
		paint_pose(pose.path,pose)
		return
	if entry.get("neighbour",false):
		var pose: Dictionary = resident.population.pose_for(resident)
		if not pose.is_empty(): paint_pose(pose.path,pose)
		return
	if INDIVIDUAL.data.characters.has(entry.id):
		var personal: Dictionary = individual_pose()
		paint_pose(personal.path,personal)
		return
	var sheet: Dictionary = STREET_ART.data.atlases[str(int(entry.street_art))] if entry.has("street_art") else MANIFEST.data.atlases[str(int(entry.atlas))]
	if entry.has("festival_art"): sheet = FESTIVAL_ART.data.atlases[str(int(entry.festival_art))]
	if entry.has("living_art"): sheet = LIVING_ART.data.atlases[str(int(entry.living_art))]
	var key: String = sheet.path
	if not textures.has(key): textures[key] = load(key)
	var person: Dictionary = sheet.people[int(entry.column)]
	var pose: Dictionary = person.frames[resident.frame]
	if entry.get("seated",false) and resident.frame<2 and resident.appointment.get("place","")!="cinema": pose = person.frames[2]
	if entry.get("living_fallback",false) and LIVING_ART.data.has("fallback"):
		pose = LIVING_ART.data.fallback.frames[resident.frame]
		key = LIVING_ART.data.fallback.path
		if not textures.has(key): textures[key] = load(key)
	if entry.id=="teodoro" and LIVING_ART.data.has("teodoro") and (resident.bench_sitting or (resident.bench_waiting and resident.state=="activity")):
		pose = LIVING_ART.data.teodoro.frames[(0 if resident.bench_sitting else 2)+int(resident.clock/3)%2]
		key = LIVING_ART.data.teodoro.path
		if not textures.has(key): textures[key] = load(key)
	var extra: int = resident.motion.extra
	if extra>=0 and SOCIAL_ART.data.characters.has(entry.id):
		var social: Dictionary = SOCIAL_ART.data.characters[entry.id]
		if extra<social.frames.size():
			pose = social.frames[extra]
			key = pose.get("path",social.path)
			if not textures.has(key): textures[key] = load(key)
	var region := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = float(entry.height)*float(pose.height_ratio)/region.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	var bob := Vector2.ZERO
	if resident.motion.phase=="hop": bob.y = -resident.motion.hop
	draw_set_transform(bob,0,Vector2(-1 if resident.facing_left else 1,1))
	draw_texture_rect_region(textures[key],Rect2(-foot,region.size*factor),region)
	draw_set_transform(Vector2.ZERO)

func individual_pose() -> Dictionary:
	var entry: Dictionary = resident.entry
	if entry.has("ambient_source"): return ambient_pose()
	if entry.get("neighbour",false): return resident.population.pose_for(resident)
	if resident.motion.extra>=0 and SOCIAL_ART.data.characters.has(entry.id) and resident.motion.phase in ["enjoy","clap","play","tune","capture","offer"]:
		var social: Dictionary = SOCIAL_ART.data.characters[entry.id]
		if resident.motion.extra<social.frames.size():
			var action: Dictionary = social.frames[resident.motion.extra].duplicate()
			action.path = action.get("path",social.path)
			return action
	var personal: Array = INDIVIDUAL.data.characters[entry.id].frames
	var backwards: bool = resident.travel_direction.y<-absf(resident.travel_direction.x)*.35
	var walking: bool = resident.motion.phase=="walk"
	var slot: int = (4 if backwards else 2)+posmod(resident.frame-2,2) if walking else mini(resident.frame,1)
	if not walking and resident.encounter_id>=0 and backwards: slot = 4
	var pose: Dictionary = personal[slot]
	if resident.gait.kind=="cane" and walking and INDIVIDUAL.data.canes.has(entry.id):
		pose = INDIVIDUAL.data.canes[entry.id]["back" if backwards else "front"][resident.gait.support_phase(resident.clock)]
	if entry.get("living_fallback",false) and not INDIVIDUAL.data.prumo.is_empty(): pose = INDIVIDUAL.data.prumo[slot]
	if entry.id=="teodoro" and not INDIVIDUAL.data.bench.is_empty() and (resident.bench_sitting or (resident.bench_waiting and resident.state=="activity")):
		pose = INDIVIDUAL.data.bench[(0 if resident.bench_sitting else 2)+int(resident.clock/3)%2]
	if resident.meal_seated and INDIVIDUAL.data.meals.has(entry.id): pose = INDIVIDUAL.data.meals[entry.id][resident.meal_frame]
	return pose
func ambient_pose() -> Dictionary:
	var frames: Array = INDIVIDUAL.data.characters[resident.entry.ambient_source].frames
	var back: bool = resident.travel_direction.y<-absf(resident.travel_direction.x)*.35
	var slot: int = (4 if back else 2)+posmod(resident.frame-2,2) if resident.motion.phase=="walk" else mini(resident.frame,1)
	return frames[slot]
func paint_pose(key: String,pose: Dictionary) -> void:
	if not textures.has(key): textures[key] = load(key)
	var region := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = float(resident.entry.height)*float(pose.height_ratio)/region.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	var bob := Vector2(0,-resident.motion.hop) if resident.motion.phase=="hop" else Vector2.ZERO
	draw_set_transform(bob,0,Vector2(-1 if resident.facing_left else 1,1))
	draw_texture_rect_region(textures[key],Rect2(-foot,region.size*factor),region)
	draw_set_transform(Vector2.ZERO)
