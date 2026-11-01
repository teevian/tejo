extends RefCounted
## Feet stand on authored granite shelves. Only graph links cross a rock face;
## walking, repeated direction presses and cooperative actions share these links.
const SOLO_REACH := 165.0
const BOOST_REACH := 245.0
const START_Y := 4160.0
const SUMMIT := 17
const ROCK_STEP := 18
const BALANCE_STEP := 19
const PUSH_STEP := 20
const TUNNEL_IN := 23
const TUNNEL_OUT := 24
const SCOUT_TOP := 28
const BRIDGE := 29
const FERN_IN := 30
const FERN_OUT := 31
const KEY_STONE := 33
const ROPE_LENGTH := 560.0
const HEIGHTS := [4160,3950,3830,3650,3470,3350,3230,2990,2870,2750,2510,2390,2270,2030,1910,1790,1550,1430]
const GATES := {0:"boost",2:"boulder",3:"rock",6:"balance",9:"chimney",12:"rope",15:"boost"}
const SLOPES := {5:0.12,8:-0.22,11:0.12,14:0.18}
const FRAGILE := {5:2.6,8:1.9,11:2.5,14:3.0}
const TITLES := {0:"Uma mão para começar",3:"Sob os penedos",6:"O peso da confiança",9:"A volta do explorador",12:"Na mesma corda",15:"A pedra que faz ponte"}
# Broad shelves wrap around four flanks instead of collapsing into a thin stack
# in the Z projection. Coordinates are persistent, including inside passages.
const BOUNDS := {
	0:[100,560,-200,200],1:[560,1120,100,580],2:[180,560,-420,20],3:[560,1100,100,600],
	4:[180,560,-460,-20],5:[870,1250,-520,-140],6:[180,620,-460,-80],7:[560,1120,-200,320],
	8:[180,560,-550,-80],9:[560,1100,20,540],10:[180,620,-320,160],11:[1040,1400,-500,-180],
	12:[180,560,100,500],13:[560,1120,80,520],14:[180,560,100,500],15:[560,1120,80,500],
	16:[180,560,60,500],17:[560,1120,-80,400],18:[560,700,-180,250],19:[420,560,-260,80],
	22:[450,920,-190,240],23:[820,1160,80,440],24:[900,1300,-560,-180],25:[1220,1660,-680,-240],
	26:[500,950,-360,-80],27:[720,1030,-160,240],28:[480,830,-240,200],29:[400,780,-300,120],
	30:[180,650,220,650],31:[200,680,-680,-280],32:[120,600,-720,-360],
	34:[750,1390,200,690],35:[140,700,180,700],36:[650,1350,-700,-190],
	37:[450,1140,250,740],38:[180,730,-700,-160]
}
const EXTRAS := {
	22:[3440,"Varanda das raízes"],23:[3420,"Dólmen das raízes"],24:[3420,"A outra encosta"],25:[3380,"Varanda escondida"],
	26:[2490,"O caminho do explorador"],27:[2290,"A laje de um só"],28:[2200,"O seguro do miradouro"],
	29:[1830,"A pedra-ponte"],30:[1880,"Túnel dos fetos"],31:[1880,"O reverso do penedo"],32:[1850,"Bolsa de granito"],
	34:[3920,"Varanda dos medronheiros"],35:[2960,"Jardim suspenso"],36:[2720,"A face escondida"],
	37:[2000,"Miradouro dos pinheiros"],38:[1530,"Última varanda"]
}
const TUNNELS := [
	{"from":23,"to":24,"view":0,"title":"Dólmen das raízes","path":[Vector3(990,3420,120),Vector3(1080,3420,0),Vector3(1100,3420,-180),Vector3(1010,3420,-340)]},
	{"from":30,"to":31,"view":1,"title":"Túnel dos fetos","path":[Vector3(435,1880,440),Vector3(470,1880,180),Vector3(480,1880,-150),Vector3(450,1880,-610)]}
]

static func platforms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in HEIGHTS.size():
		var bounds: Array = BOUNDS[i]
		result.append({"id":i,"x":float(bounds[0]),"end":float(bounds[1]),"y":float(HEIGHTS[i]),"art":i%4,"enabled":true,"slope":float(SLOPES.get(i,0)),"fragile":float(FRAGILE.get(i,0)),"timer":-1.0,"fall":0.0,"reset":0.0})
	result.append({"id":ROCK_STEP,"x":560.0,"end":700.0,"y":3590.0,"art":4,"enabled":false})
	result.append({"id":BALANCE_STEP,"x":420.0,"end":560.0,"y":3110.0,"art":2,"enabled":false})
	for i in range(20,39):
		var stone: Dictionary = {}
		for item in boulders():
			if item.id==i: stone = item
		if not stone.is_empty():
			var y := float(HEIGHTS[stone.parent]) if stone.parent<18 else float(EXTRAS[stone.parent][0])
			result.append({"id":i,"x":stone.x-stone.radius,"end":stone.x+stone.radius,"y":y-stone.height,"art":4,"enabled":true,"boulder":true})
		else:
			var bounds: Array = BOUNDS[i]
			result.append({"id":i,"x":float(bounds[0]),"end":float(bounds[1]),"y":float(EXTRAS[i][0]),"art":i%4,"enabled":i!=BRIDGE,"title":EXTRAS[i][1],"slope":0.0,"fragile":2.8 if i==27 else 0.0,"timer":-1.0,"fall":0.0,"reset":0.0,"capacity":1 if i==27 else 2})
	for id in [34,35,37]: result[id]["views"] = [1,2]
	for id in [36,38]: result[id]["views"] = [2,3]
	return result

static func boulders() -> Array[Dictionary]:
	return [{"id":20,"parent":2,"x":355.0,"start_x":355.0,"z":-20.0,"radius":42.0,"height":74.0,"velocity":0.0,"locked":false},
		{"id":21,"parent":32,"x":355.0,"start_x":355.0,"z":-540.0,"radius":34.0,"height":61.0,"velocity":0.0,"locked":false},
		{"id":KEY_STONE,"parent":FERN_OUT,"x":450.0,"start_x":450.0,"z":-500.0,"radius":40.0,"height":74.0,"velocity":0.0,"locked":false,"lock_axis":"z"}]

static func surface(platform: Dictionary, x: float) -> float:
	return height_at(int(platform.id),float(platform.x),float(platform.end),float(platform.y),float(platform.get("slope",0)),x)

static func height_at(id: int, left: float, right: float, y: float, slope: float, x: float, z := 0.0) -> float:
	var plane := y+slope*(x-(left+right)*0.5)
	if id>=18: return plane
	var t := clampf((x-left)/maxf(1,right-left),0,1)
	var seed := id*1.731
	var crown := -14*pow(maxf(0,sin(t*PI)),0.8)
	var weathering := sin(t*TAU*2+seed)*4+sin(t*TAU*4.5+seed*0.37)*2
	return plane+crown+weathering+sin(z*0.028+seed)*3

static func links() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in HEIGHTS.size()-1:
		if i in [4,10,11,14]: continue
		result.append({"from":i,"to":i+1,"dir":1 if i%2==0 else -1,"mode":GATES.get(i,"solo")})
	# Long horizontal excursions, with a real sheltered passage to the far flank.
	result.append_array([
		{"from":4,"to":22,"dir":1,"mode":"solo"},
		{"from":22,"to":23,"dir":1,"mode":"solo"},
		{"from":24,"to":5,"dir":1,"mode":"solo","views":[1,3]},
		{"from":24,"to":25,"dir":1,"mode":"solo","views":[0,2]},
		{"from":25,"to":24,"dir":-1,"mode":"solo","views":[0,2]},
		{"from":10,"to":26,"dir":1,"mode":"solo","single":true},
		{"from":26,"to":11,"dir":-1,"mode":"solo","single":true,"views":[1,3]},
		{"from":11,"to":27,"dir":1,"mode":"solo","single":true,"views":[1,3]},
		{"from":27,"to":28,"dir":1,"mode":"solo","single":true},
		{"from":10,"to":28,"dir":1,"mode":"belay"},
		{"from":28,"to":12,"dir":1,"mode":"reunite","views":[1,3]},
		{"from":14,"to":30,"dir":1,"mode":"solo"},
		{"from":31,"to":29,"dir":1,"mode":"bridge","views":[1,3]},
		{"from":33,"to":29,"dir":1,"mode":"solo","views":[1,3]},
		{"from":29,"to":15,"dir":1,"mode":"solo","views":[1,3]},
		{"from":31,"to":32,"dir":-1,"mode":"solo","views":[0,2]},
		{"from":32,"to":31,"dir":1,"mode":"solo","views":[0,2]}
	])
	for pair in [[1,34,1],[7,35,1],[9,36,3],[13,37,1],[16,38,3]]:
		result.append({"from":pair[0],"to":pair[1],"dir":1,"mode":"solo","views":[pair[2]],"optional":true})
		result.append({"from":pair[1],"to":pair[0],"dir":-1,"mode":"solo","views":[pair[2]],"optional":true})
	# Alternate routes physically appear when a puzzle changes the rock face.
	result.push_front({"from":ROCK_STEP,"to":4,"dir":-1,"mode":"solo"})
	result.push_front({"from":3,"to":ROCK_STEP,"dir":-1,"mode":"solo"})
	result.push_front({"from":BALANCE_STEP,"to":7,"dir":1,"mode":"solo"})
	result.push_front({"from":6,"to":BALANCE_STEP,"dir":1,"mode":"solo"})
	result.push_front({"from":PUSH_STEP,"to":3,"dir":1,"mode":"solo"})
	return result

static func stage(platform: int) -> int:
	if platform in [22,23,24,25]: return 3
	if platform in [26,27,28]: return 9
	if platform in [29,30,31,32,33]: return 15
	if platform>=34: return [0,6,9,12,15][platform-34]
	if platform==ROCK_STEP: return 3
	if platform==BALANCE_STEP: return 6
	return mini(15,(platform/3)*3)
