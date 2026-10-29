extends Control
## Two paper cards retain the last line on each side; the current speaker is lit.
var initiator := 0
var speaker := 0
var texts: Array[Label] = []
var cards: Array[Panel] = []
var names: Array[Label] = []
var portraits: Array[TextureRect] = []
var advance_button: Button
signal advance_requested

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in 2:
		var card := Panel.new()
		card.position = Vector2(28 + side * 628, 536)
		card.size = Vector2(596, 172)
		var paper := TejoPerson._box(Color("eee4c9"), 12)
		paper.set_border_width_all(1)
		paper.border_color = Color("a4ab86")
		paper.shadow_color = Color(0.07, 0.15, 0.12, 0.4)
		paper.shadow_size = 6
		card.add_theme_stylebox_override("panel", paper)
		add_child(card)
		cards.append(card)
		var portrait := TextureRect.new()
		portrait.position = Vector2(10 if side == 0 else 458, 15)
		portrait.size = Vector2(128, 142)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(portrait)
		portraits.append(portrait)
		var title := Label.new()
		title.position = Vector2(150 if side == 0 else 22, 14)
		title.add_theme_color_override("font_color", Color("42644f"))
		title.add_theme_font_size_override("font_size", 15)
		card.add_child(title)
		names.append(title)
		var words := Label.new()
		words.position = Vector2(150 if side == 0 else 22, 43)
		words.size = Vector2(422, 115)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_theme_font_size_override("font_size", 20)
		words.add_theme_color_override("font_color", Color("2e493e"))
		card.add_child(words)
		texts.append(words)
	advance_button = Button.new()
	advance_button.position = Vector2(505, 498)
	advance_button.size = Vector2(270, 30)
	advance_button.text = "T · continuar     Esc · fechar"
	advance_button.add_theme_stylebox_override("normal", TejoPerson._box(Color("34594e"), 7))
	advance_button.add_theme_stylebox_override("hover", TejoPerson._box(Color("527461"), 7))
	advance_button.add_theme_color_override("font_color", Color("eee4c9"))
	advance_button.pressed.connect(func(): advance_requested.emit())
	add_child(advance_button)
	hide()

func show_line(line: Dictionary, first_speaker: int) -> void:
	if not visible:
		for label in texts:
			label.text = ""
	initiator = first_speaker
	speaker = int(line.speaker)
	for side in 2:
		var who := initiator if side == 0 else 1 - initiator
		names[side].text = "TE" if who == 0 else "JO"
		portraits[side].texture = TeArt.FACE_PORTRAIT if who == 0 else JoArt.FACE_PORTRAIT
		if who == speaker:
			texts[side].text = line.text
		cards[side].visible = not texts[side].text.is_empty()
		cards[side].modulate = Color.WHITE if who == speaker else Color(0.84, 0.87, 0.80, 0.94)
	show()
