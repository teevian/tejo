extends CanvasLayer
const Catalog = preload("res://scripts/bakery_catalog.gd")
const ItemArt = preload("res://scripts/item_art.gd")
var journey: Node2D
var bakery: Node2D
var opened := false
var selected := 0
var panel: PanelContainer
var header: Label
var notice: Label
var people_buttons: Array[Button] = []
var buy_buttons: Array[Button] = []
class FoodIcon:
	extends Control
	var item: Dictionary
	func _draw() -> void: ItemArt.draw_item(self,item,Rect2(3,3,76,64))
func _ready() -> void:
	layer = 18
	panel = PanelContainer.new(); panel.position = Vector2(170,95); panel.custom_minimum_size = Vector2(940,490)
	panel.add_theme_stylebox_override("panel",TejoPerson._box(Color("f0e4c8"),14)); add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	panel.add_child(margin)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation",12); margin.add_child(content)
	header = Label.new(); header.add_theme_font_size_override("font_size",23); header.add_theme_color_override("font_color",Color("2e5148")); content.add_child(header)
	var sub := Label.new(); sub.text = "07:00–21:30 · Comprar para levar. Na bolsa podes comer, dar ou partilhar."; sub.add_theme_color_override("font_color",Color("486255")); content.add_child(sub)
	var owners := HBoxContainer.new(); content.add_child(owners)
	for i in 2:
		var button := Button.new(); button.text = "Bolsa de "+("Te" if i==0 else "Jo"); style(button); button.pressed.connect(func():selected = i; refresh()); owners.add_child(button); people_buttons.append(button)
	var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation",16); grid.add_theme_constant_override("v_separation",8); content.add_child(grid)
	for i in Catalog.PRODUCTS.size():
		var row := HBoxContainer.new(); row.custom_minimum_size = Vector2(440,75); grid.add_child(row)
		var icon := FoodIcon.new(); icon.item = Catalog.item(i); icon.custom_minimum_size = Vector2(82,70); icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(icon)
		var labels := VBoxContainer.new(); labels.custom_minimum_size.x = 212; row.add_child(labels)
		var name_label := Label.new(); name_label.text = Catalog.PRODUCTS[i].name; name_label.add_theme_color_override("font_color",Color("2e5148")); labels.add_child(name_label)
		var effect := Label.new(); effect.text = "Saciedade %d · porte 1"%int(Catalog.PRODUCTS[i].satiety) if Catalog.PRODUCTS[i].satiety>0 else "Refresca · não substitui uma refeição"; effect.add_theme_font_size_override("font_size",12); effect.add_theme_color_override("font_color",Color("69785e")); labels.add_child(effect)
		var buy := Button.new(); buy.text = Catalog.euro(int(Catalog.PRODUCTS[i].price)); style(buy); buy.custom_minimum_size.x = 114; buy.pressed.connect(purchase.bind(i)); row.add_child(buy); buy_buttons.append(buy)
	notice = Label.new(); notice.custom_minimum_size = Vector2(890,38); notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; notice.add_theme_font_size_override("font_size",14); notice.add_theme_color_override("font_color",Color("476052")); content.add_child(notice)
	var close := Button.new(); close.text = "Esc · Continuar o passeio"; style(close); close.pressed.connect(finish); content.add_child(close)
	journey.changed.connect(refresh); panel.hide()
func style(button: Button) -> void:
	button.add_theme_stylebox_override("normal",TejoPerson._box(Color("d1dbc5"),5)); button.add_theme_stylebox_override("hover",TejoPerson._box(Color("ddcb9b"),5)); button.add_theme_stylebox_override("disabled",TejoPerson._box(Color("dfdece"),5)); button.add_theme_color_override("font_color",Color("315346")); button.focus_mode = Control.FOCUS_NONE
func open(shop: Node2D,person: CharacterBody2D) -> void:
	if journey.controls_blocked(): return
	bakery = shop; selected = person.kind; opened = true; panel.show(); notice.text = "Escolhe o produto. O preço é descontado apenas se houver espaço na bolsa."
	for p in journey.scene.people: p.in_dialogue = true; p.path.clear(); p.cancel_sand_drawing(); p._finish_phone()
	refresh()
func refresh() -> void:
	if not opened: return
	header.text = "Pastelaria do Largo · "+Catalog.euro(journey.coins)
	for i in 2: people_buttons[i].text = ("✓ " if i==selected else "")+"Bolsa de "+journey.scene.people[i].name+" · %d/5"%journey.scene.people[i].inventory.used_porte()
	for i in buy_buttons.size():
		buy_buttons[i].disabled = not bakery.opened(journey.scene.day_cycle.minutes) or journey.coins<int(Catalog.PRODUCTS[i].price) or not journey.scene.people[selected].inventory.can_add(Catalog.item(i))
func purchase(index: int) -> void:
	if not opened: return
	notice.text = bakery.buy(journey,selected,index); refresh()
func finish() -> void:
	opened = false; panel.hide()
	for p in journey.scene.people: p.in_dialogue = false
func handle_input(event: InputEvent) -> bool:
	if not opened: return false
	if event is InputEventMouse or event is InputEventScreenTouch: return false
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: finish()
	return true
