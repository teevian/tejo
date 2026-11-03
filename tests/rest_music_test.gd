extends SceneTree
var scene: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("run")
	create_timer(50,true,false,true).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func wait_for_lying() -> bool:
	var transition := false
	for i in 600:
		transition = transition or scene.people.any(func(p): return p.rest_transition=="lie")
		if scene.people.all(func(p): return p.is_sleeping() and p.rest_transition.is_empty()): return transition
		await frames(1)
	return false

func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	var dream = scene.rest_dream
	var data: Dictionary = dream.ANALYSIS.data
	check(FileAccess.file_exists("res://assets/audio/music/TEJO_vaporware.mp3") and not DirAccess.dir_exists_absolute("res://music"),"Music belongs with the game audio assets")
	check(FileAccess.get_sha256("res://assets/audio/music/TEJO_vaporware.mp3")==data.sha256,"Visual rhythm must match the exact supplied MP3")
	check(absf(dream.MUSIC.get_length()-float(data.duration))<0.05 and data.beats.size()>200,"The whole actual track must be decoded, with measured beat transients")
	var beat: Array = data.beats[50]
	check(dream.rhythm(float(beat[0])).w>=float(beat[1])*0.99,"Effects peak on a measured musical transient")
	check(dream.rhythm(float(beat[0])+0.12).w<dream.rhythm(float(beat[0])).w,"Beat light must decay smoothly between transients")
	check(not dream.player.playing and not dream.layer.visible,"Standing in daylight must keep the ordinary world and silence")
	scene._toggle_pause()
	check(paused and scene.sleep_button.visible and scene.sleep_button.text=="Dormir","Escape must expose Dormir")
	var original := [scene.people[0].position,scene.people[1].position]
	scene.sleep_button.pressed.emit()
	check(not paused and scene.sleep_requested,"Dormir must resume the world and request immediate rest")
	check(scene.people[0].position==original[0] and scene.people[1].position==original[1],"Dormir must not teleport either character")
	check(await wait_for_lying(),"Dormir must approach, sit and recline through the existing animation without a minute's wait")
	await frames(8)
	check(dream.player.playing and dream.wanted and dream.amount>0,"Both lying down in daytime starts the music and the progressive dream")
	check(dream.track_index==0 and dream.next_track==1,"The first daytime nap must use TEJO_vaporware")
	check(scene.people.all(func(p): return p.is_sleeping()),"Both resting characters must use their closed-eye sleep drawings")
	check(dream.layer.layer==4 and scene.hud.get_parent().layer==5,"The dream must transform the world beneath menus and UI")
	var starts: int = dream.starts
	scene._select_person(1)
	await frames(5)
	check(dream.starts==starts,"Changing selection while lying must not restart the song")
	scene._request_sleep()
	await frames(2)
	check(dream.track_index==0 and dream.starts==starts,"Pressing Dormir again during the same nap must not advance the playlist")
	scene._toggle_pause()
	await frames(3)
	var held: float = dream.music_time
	var depth_time: float = dream.elapsed
	var opacity: float = dream.amount
	await frames(15)
	check(dream.player.stream_paused and dream.music_time==held and dream.elapsed==depth_time and dream.amount==opacity,"Escape must freeze music, rhythm, colour growth and effects together")
	scene._toggle_pause()
	scene._toggle_map()
	await frames(4)
	held = dream.music_time
	await frames(12)
	check(dream.player.stream_paused and dream.music_time==held,"The map must suspend the audible song and its visual clock")
	scene._toggle_map()
	Input.action_press("walk_right")
	await frames(5)
	Input.action_release("walk_right")
	check(not dream.eligible(),"Beginning to get up must end the dream immediately")
	await frames(440)
	check(not dream.player.playing and not dream.layer.visible and dream.amount==0,"Standing must restore the ordinary world and stop the music after its short fade")
	scene.day_cycle.minutes = 22*60
	scene._request_sleep()
	check(await wait_for_lying(),"Dormir must still animate the rest at night")
	await frames(8)
	check(not dream.player.playing and not dream.layer.visible,"Night rest must not start the daytime vaporware dream")
	check(dream.next_track==1,"A night nap must not consume a daytime track")
	scene.day_cycle.minutes = 8*60
	await frames(6)
	check(dream.player.playing and dream.starts==starts+1,"A new daytime session must start the song cleanly")
	check(dream.track_index==1 and dream.player.stream is AudioStreamWAV,"The next daytime nap must play the supplied TEJO_vaporware2 WAV")
	check(dream.player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"The second song must loop inside its own nap")
	var second: Dictionary = dream.ANALYSIS2.data
	check(FileAccess.get_sha256("res://assets/audio/music/TEJO_vaporware2.wav")==second.sha256 and second.beats.size()>200,"The second animation must follow its own measured song")
	var second_beat: Array = second.beats[40]
	check(dream.rhythm(float(second_beat[0])).w>=float(second_beat[1])*0.99,"The second song's effects must pulse on its own beat times")
	scene._enter_walking_test()
	check(not dream.player.playing and not dream.layer.visible,"Leaving exploration must not leak music or dream effects into another scene")
	scene._return_from_walking_test()
	await frames(5)
	check(dream.track_index==1 and dream.next_track==0,"Returning to the same sleeping pair must preserve the chosen song")
	Input.action_press("walk_right")
	await frames(5)
	Input.action_release("walk_right")
	await frames(440)
	scene._request_sleep()
	check(await wait_for_lying(),"The third nap must still use the natural transitions")
	await frames(8)
	check(dream.track_index==0 and dream.next_track==1,"Daytime naps must alternate first, second, first")
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: daytime playlist 1/2/1, separate song analyses, closed-eye sleep, Dormir transitions, no playlist advance on night/pause/map/selection, same-nap resume, wake reset and scene cleanup")
	quit(1 if failed else 0)
