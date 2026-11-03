extends Node
## Visual rhythm comes from the decoded track, sampled at the audible playback time.
const MUSIC: AudioStreamMP3 = preload("res://assets/audio/music/TEJO_vaporware.mp3")
const ANALYSIS = preload("res://assets/audio/music/TEJO_vaporware.analysis.json")
const MUSIC2: AudioStreamWAV = preload("res://assets/audio/music/TEJO_vaporware2.wav")
const ANALYSIS2 = preload("res://assets/audio/music/TEJO_vaporware2.analysis.json")
const TRACKS := [MUSIC,MUSIC2]
const ANALYSES := [ANALYSIS,ANALYSIS2]
static var next_track := 0
var track_index := 0
var session_track_chosen := false
var resume_at := 0.0
var scene: Node2D
var player: AudioStreamPlayer
var layer: CanvasLayer
var screen: ColorRect
var material: ShaderMaterial
var amount := 0.0
var volume := 0.0
var elapsed := 0.0
var music_time := 0.0
var wanted := false
var starts := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.name = "RestMusic"
	set_track(0)
	player.volume_db = -80
	add_child(player)
	layer = CanvasLayer.new()
	layer.name = "Daydream"
	layer.layer = 4 # Above the day lighting, below every HUD and menu.
	add_child(layer)
	var capture := BackBufferCopy.new()
	capture.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	layer.add_child(capture)
	screen = ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/rest_dream.gdshader")
	screen.material = material
	layer.add_child(screen)
	layer.hide()

func eligible() -> bool:
	if not is_instance_valid(scene) or not scene.visible or scene.dialogue.is_active(): return false
	if scene.day_cycle.minutes<360 or scene.day_cycle.minutes>=1200: return false
	return scene.people.size()==2 and scene.people.all(func(person): return person.is_sleeping())

func _process(delta: float) -> void:
	if not is_instance_valid(scene) or not scene._initialization_complete: return
	if not scene.people.all(func(person): return person.is_sleeping()):
		session_track_chosen = false
		resume_at = 0
	step(delta,eligible(),get_tree().paused or scene.exploration_map.visible)

func set_track(index: int) -> void:
	track_index = index
	var stream: AudioStream = TRACKS[index].duplicate()
	if stream is AudioStreamMP3: stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
	player.stream = stream

func step(delta: float, should_play: bool, frozen := false) -> void:
	player.stream_paused = frozen
	if frozen: return
	if should_play and not wanted:
		player.stop()
		if not session_track_chosen:
			set_track(next_track)
			next_track = 1-next_track
			session_track_chosen = true
			resume_at = 0
		player.play(resume_at)
		starts += 1
		elapsed = resume_at
		music_time = resume_at
	wanted = should_play
	amount = move_toward(amount,1.0 if wanted else 0.0,delta/(1.2 if wanted else 0.8))
	volume = move_toward(volume,0.65 if wanted else 0.0,delta*(0.45 if wanted else 1.5))
	player.volume_db = linear_to_db(maxf(volume,0.0001))
	if wanted:
		elapsed += delta
		music_time = maxf(0,player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
	if not wanted and volume<=0: player.stop()
	layer.visible = amount>0.0001
	apply_visuals(music_time,elapsed,amount)
	if not layer.visible:
		elapsed = 0
		music_time = 0

func rhythm(at: float) -> Vector4:
	var data: Dictionary = ANALYSES[track_index].data
	var song := fposmod(maxf(0,at),float(data.duration))
	var frame := song*float(data.fps)
	var index := mini(int(frame),data.frames.size()-1)
	var next := mini(index+1,data.frames.size()-1)
	var a: Array = data.frames[index]
	var b: Array = data.frames[next]
	var blend := fposmod(frame,1.0)
	var pulse := 0.0
	# Binary search the last actual transient; its decay is tied to the song clock.
	var low := 0
	var high: int = data.beats.size()
	while low<high:
		var middle := (low+high)/2
		if float(data.beats[middle][0])<=song: low = middle+1
		else: high = middle
	if low>0:
		var beat: Array = data.beats[low-1]
		pulse = float(beat[1])*exp(-(song-float(beat[0]))*9.0)
	return Vector4(lerpf(a[0],b[0],blend)/255.0,lerpf(a[1],b[1],blend)/255.0,lerpf(a[2],b[2],blend)/255.0,pulse)

func apply_visuals(at: float, depth_time: float, opacity: float) -> void:
	var sound := rhythm(at)
	material.set_shader_parameter("dream",opacity)
	material.set_shader_parameter("depth",smoothstep(0,35 if track_index==0 else 45,depth_time+3.0))
	material.set_shader_parameter("track_variant",float(track_index))
	material.set_shader_parameter("dream_time",depth_time)
	material.set_shader_parameter("energy",sound.x)
	material.set_shader_parameter("bass",sound.y)
	material.set_shader_parameter("air",sound.z)
	material.set_shader_parameter("beat",sound.w)

func stop_immediately(end_session := true) -> void:
	if not end_session and player.playing: resume_at = music_time
	if end_session:
		session_track_chosen = false
		resume_at = 0
	wanted = false
	amount = 0
	volume = 0
	elapsed = 0
	music_time = 0
	player.stop()
	player.stream_paused = false
	layer.hide()
	material.set_shader_parameter("dream",0.0)
