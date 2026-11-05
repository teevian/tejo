extends CanvasLayer
## Readable choices; world keeps its clock, only protagonists stop during a conversation.
var director: Node2D
var panel: PanelContainer
var content: VBoxContainer
var callback := Callable()
var opened := false
func _ready() -> void:
	layer = 18
	panel = PanelContainer.new()
	panel.position = Vector2(240,220)
	panel.custom_minimum_size = Vector2(800,0)
	panel.add_theme_stylebox_override("panel",TejoPerson._box(Color("f2e5c9"),12))
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	margin.add_child(content)
	panel.hide()
func show_choices(title: String,text: String,choices: Array,action: Callable) -> void:
	for child in content.get_children(): content.remove_child(child); child.queue_free()
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color",Color("304e45"))
	label.add_theme_font_size_override("font_size",24)
	content.add_child(label)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 750
	body.add_theme_color_override("font_color",Color("35463d"))
	content.add_child(body)
	for i in choices.size():
		var button := Button.new()
		button.text = str(i+1)+" · "+str(choices[i])
		_style_button(button)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(choose.bind(i))
		content.add_child(button)
	var close := Button.new()
	close.text = "Esc · Continuar o passeio"
	_style_button(close)
	close.pressed.connect(finish)
	content.add_child(close)
	callback = action
	opened = true
	panel.show()
	for person in director.world.people: person.in_dialogue = true; person.path.clear()
func handle_input(event: InputEvent) -> bool:
	if not opened: return false
	# Mouse events must reach Godot GUI after the scene input guard.
	if event is InputEventMouse or event is InputEventScreenTouch: return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE: finish()
		elif event.keycode>=KEY_1 and event.keycode<=KEY_9: choose(event.keycode-KEY_1)
	return true
func choose(index: int) -> void:
	if not opened or index<0 or index>=content.get_child_count()-3: return
	var fn := callback
	finish()
	if fn.is_valid(): fn.call(index)
func finish() -> void:
	opened = false
	callback = Callable()
	panel.hide()
	for person in director.world.people: person.in_dialogue = false

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal",TejoPerson._box(Color("d5dbc8"),5))
	button.add_theme_stylebox_override("hover",TejoPerson._box(Color("dfc98e"),5))
	button.add_theme_stylebox_override("pressed",TejoPerson._box(Color("b4c6ad"),5))
	button.add_theme_color_override("font_color",Color("314e44"))
	button.add_theme_color_override("font_hover_color",Color("283e37"))
	button.custom_minimum_size.y = 34
