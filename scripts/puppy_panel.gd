extends Control
var world: Node2D
var scene: Node2D
var title: Label
var message: Label
var milestones: Label
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(24,512)
	size = Vector2(515,184)
	title = Label.new()
	title.position = Vector2(16,10)
	title.add_theme_font_size_override("font_size",19)
	add_child(title)
	message = Label.new()
	message.position = Vector2(16,43)
	message.size = Vector2(365,90)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size",16)
	add_child(message)
	milestones = Label.new()
	milestones.position = Vector2(16,154)
	milestones.add_theme_font_size_override("font_size",13)
	add_child(milestones)
func _process(_delta: float) -> void:
	var pup = world.puppy
	visible = not scene.exploration_map.visible and not scene.dialogue.is_active() and not get_tree().paused
	visible = visible and scene.people[scene.selected].position.distance_to(pup.position)<850
	if not visible: return
	title.text = "O pequeno guardião dos Capuchos" if not pup.friendly else "Um amigo nos Capuchos"
	message.text = pup.hint()
	milestones.text = "%s Comida   ·   %s Aproximação e cheiro   ·   %s Festas"%["✓" if pup.meals>=2 else "○","✓" if pup.sniffs>=2 else "○","✓" if pup.pets>=1 else "○"]
	queue_redraw()
func _draw() -> void:
	draw_style_box(TejoPerson._box(Color("233e3e"),14),Rect2(Vector2.ZERO,size))
	draw_style_box(TejoPerson._box(Color("526950"),3),Rect2(16,141,480,5))
	draw_style_box(TejoPerson._box(Color("e8d19c"),3),Rect2(16,141,maxf(2,480*world.puppy.trust),5))

	draw_style_box(TejoPerson._box(Color("3d5848"),10),Rect2(402,43,96,90))
	preload("res://scripts/puppy_art.gd").draw_portrait(self,world.puppy,Rect2(406,46,88,84))
