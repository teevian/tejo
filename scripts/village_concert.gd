extends Node2D
## An original, quietly mixed acoustic phrase. The listener is the selected player.
var world: Node2D
var player: AudioStreamPlayer
var active := false
func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "OriginalStreetDuet"
	player.stream = _melody()
	player.volume_db = -80
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	world.visibility_changed.connect(func(): player.stream_paused = not world.is_visible_in_tree())
func step(_delta: float, cycle: RefCounted) -> void:
	active = cycle.minutes>=1080 and cycle.minutes<1260
	if active and not player.playing: player.play()
	if not active and player.playing: player.stop()
	var distance := INF
	for person in world.people:
		if person.controlled: distance = person.position.distance_to(position)
	player.volume_db = -15.0-linear_to_db(1.0+distance/180.0)*2 if active and distance<1200 else -80
func _melody() -> AudioStreamWAV:
	var rate := 16000
	var seconds := 16.0
	var data := PackedByteArray()
	data.resize(int(rate*seconds)*2)
	var notes := [64,67,69,67,62,64,67,71,69,67,64,62,60,62,64,67,69,72,71,67,64,67,69,64,62,65,67,69,67,64,62,60]
	var bass := [48,53,55,48]
	for i in int(rate*seconds):
		var time := float(i)/rate
		var beat := int(time/.5)
		var local := fposmod(time,.5)
		var hz := 440.0*pow(2.0,(notes[beat%notes.size()]-69)/12.0)
		var low := 440.0*pow(2.0,(bass[int(time/4)%4]-69)/12.0)
		var bow := (sin(TAU*hz*time)+.18*sin(TAU*hz*2*time))*sin(minf(1,local/.07)*PI*.5)*exp(-local*3)*.17
		var pluck := (sin(TAU*low*time)+.35*sin(TAU*low*2*time))*exp(-fposmod(time,.5)*7)*.18
		var value := clampi(roundi((bow+pluck)*24000),-32767,32767)
		data.encode_s16(i*2,value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(rate*seconds)
	return stream
