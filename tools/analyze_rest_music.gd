extends SceneTree
## Rebuild the small visual envelope from the actual MP3 using Godot's decoder.
const SOURCE := "res://assets/audio/music/TEJO_vaporware.mp3"
const OUTPUT := "res://assets/audio/music/TEJO_vaporware.analysis.json"
const FPS := 50

func percentile(values: Array[float], portion: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return maxf(0.00001,sorted[mini(sorted.size()-1,int(sorted.size()*portion))])

func _initialize() -> void:
	var source := SOURCE
	var output := OUTPUT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source="): source = argument.trim_prefix("--source=")
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	var stream: AudioStream = AudioStreamWAV.load_from_file(source) if source.get_extension()=="wav" else AudioStreamMP3.load_from_file(source)
	var playback := stream.instantiate_playback()
	playback.start()
	var rate := AudioServer.get_mix_rate()
	var block := int(rate/FPS)
	var energy: Array[float] = []
	var bass: Array[float] = []
	var air: Array[float] = []
	var low := 0.0
	var alpha := 1.0-exp(-TAU*160.0/rate)
	for i in ceili(stream.get_length()*FPS):
		var samples := playback.mix_audio(1.0,block)
		var e := 0.0
		var b := 0.0
		var a := 0.0
		for sample in samples:
			var mono: float = (sample.x+sample.y)*0.5
			low += alpha*(mono-low)
			e += mono*mono
			b += low*low
			a += (mono-low)*(mono-low)
		energy.append(sqrt(e/block))
		bass.append(sqrt(b/block))
		air.append(sqrt(a/block))
	var e_max := percentile(energy,0.96)
	var b_max := percentile(bass,0.96)
	var a_max := percentile(air,0.96)
	var frames: Array = []
	var flux: Array[float] = []
	for i in energy.size():
		frames.append([clampi(roundi(energy[i]/e_max*255),0,255),clampi(roundi(bass[i]/b_max*255),0,255),clampi(roundi(air[i]/a_max*255),0,255)])
		flux.append(maxf(0,bass[i]-(bass[maxi(0,i-2)]+bass[maxi(0,i-3)])*0.5)+maxf(0,energy[i]-energy[maxi(0,i-1)])*0.25)
	var f_max := percentile(flux,0.97)
	var beats: Array = []
	var previous := -1.0
	for i in range(5,flux.size()-5):
		var strength := minf(1,flux[i]/f_max)
		if strength<0.25 or energy[i]/e_max<0.05 or float(i)/FPS-previous<0.24: continue
		var peak := true
		for j in range(i-4,i+5):
			if flux[j]>flux[i]: peak = false
		if peak:
			previous = float(i)/FPS
			beats.append([snappedf(previous,0.001),snappedf(strength,0.001)])
	var digest := FileAccess.get_sha256(ProjectSettings.globalize_path(source))
	var data := {"source":source.get_file(),"sha256":digest,"duration":stream.get_length(),"fps":FPS,"channels":["energy","bass","air"],"frames":frames,"beats":beats}
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(data)+"\n")
	print("PASS: decoded %.2f seconds, %d envelope frames, %d beat transients, peak RMS %.3f"%[stream.get_length(),frames.size(),beats.size(),e_max])
	quit(0 if e_max>0.001 and beats.size()>50 else 1)
