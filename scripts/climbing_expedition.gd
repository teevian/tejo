extends RefCounted
## Spatial puzzles that join the four rock faces into one traversable mountain.
const Route = preload("res://scripts/climbing_route.gd")
var scene: Node2D

func passage_for(person) -> Dictionary:
	if not person.grounded: return {}
	for tunnel in Route.TUNNELS:
		var reverse: bool = person.shelf==int(tunnel.to)
		if person.shelf!=int(tunnel.from) and not reverse: continue
		var path: Array = tunnel.path.duplicate()
		if reverse: path.reverse()
		return {"from":person.shelf,"to":int(tunnel.from) if reverse else int(tunnel.to),"path":path,"view":int(tunnel.view),"title":tunnel.title,"reverse":reverse}
	return {}

func near_passage(person, passage: Dictionary) -> bool:
	return not passage.is_empty() and scene.space.world_point(person).distance_to(passage.path[0])<145

func enter_passage(person, reverse_allowed := true) -> bool:
	var passage := passage_for(person)
	if not near_passage(person,passage): return false
	if passage.reverse and not reverse_allowed: return false
	if posmod(scene.space.view-int(passage.view),2)!=0:
		scene.hud.message("A entrada fica entre estes penedos. Roda para veres a abertura de frente.")
		return true
	var friend = scene.people[1-person.kind]
	if not friend.grounded or friend.shelf!=person.shelf or friend.busy() or scene.space.world_point(person).distance_to(scene.space.world_point(friend))>190:
		scene.hud.message("A passagem contorna o interior do penedo. Juntem-se à entrada para a corda acompanhar os dois.")
		return true
	for climber in [person,friend]:
		scene.release_anchor(climber)
		var path: Array = [scene.space.world_point(climber)]
		for point in passage.path:
			path.append(point+Vector3(-27 if climber.kind==0 else 27,0,0))
		var target: Vector3 = path[-1]
		climber.travel(scene.space.project(target),int(passage.to),"tunnel",3.6 if int(passage.from) in [30,31] else 2.9)
		climber.traversal["world_path"] = path
	scene.visited[str(passage.from)+":"+str(passage.to)] = true
	scene.flags["tunnel_"+str(mini(int(passage.from),int(passage.to)))]=true
	scene.hud.message("%s · Entre os blocos, a passagem leva à outra encosta. Depois, roda para encontrar a saída."%passage.title,6)
	return true

func belay_ready(person) -> bool:
	var friend = scene.people[1-person.kind]
	return person.shelf==10 and friend.grounded and friend.shelf==Route.SCOUT_TOP and friend.anchor=="belay"

func hold_belay(person) -> bool:
	if person.shelf!=Route.SCOUT_TOP: return false
	var friend = scene.people[1-person.kind]
	if friend.shelf==person.shelf: return false
	person.anchor = "belay"
	person.pose = "support"
	scene.flags.scout_belay = true
	scene.hud.message("%s firma os pés no granito e segura a corda. Tab para o companheiro; ↑ para trepar até aqui."%person.name,7)
	return true

func climb_rope(person) -> bool:
	if not belay_ready(person): return false
	var friend = scene.people[1-person.kind]
	var world: Vector3 = scene.space.world_point(friend)+Vector3(-45 if person.kind==0 else 45,0,0)
	var box: Dictionary = scene.space.boxes[Route.SCOUT_TOP]
	world.x = clampf(world.x,float(box.left)+25,float(box.right)-25)
	world.y = scene.space.surface_world(box,world.x,world.z)
	if not scene.rope_allows(person,scene.space.project(world),Route.SCOUT_TOP): return false
	var start: Vector3 = scene.space.world_point(person)
	person.travel(scene.space.project(world),Route.SCOUT_TOP,"rope",2.25)
	person.traversal.world_from = start
	person.traversal.world_to = world
	scene.visited["10:28"] = true
	scene.hud.message("Mãos na corda, pés na rocha. O explorador mantém o seguro até o companheiro chegar.",5)
	return true

func prompt(person) -> String:
	var passage := passage_for(person)
	if near_passage(person,passage):
		if passage.reverse: return "← → · explorar esta encosta    ↓ · regressar pelo túnel"
		return "↑ · entrar juntos entre os penedos" if posmod(scene.space.view-int(passage.view),2)==0 else "Q / E · descobrir a boca do túnel"
	if person.shelf in [23,30]: return "Procura a abertura escura entre os penedos · ↑ para entrar juntos"
	if belay_ready(person): return "↑ · trepar a corda até ao companheiro"
	if person.shelf==Route.SCOUT_TOP and scene.people[1-person.kind].shelf!=Route.SCOUT_TOP: return "Espaço · firmar os pés e segurar a corda"
	if person.shelf==31 and not scene.flags.get("bridge_braced",false): return "Q / E · ver a pedra de lado    Andar contra ela · empurrar"
	if person.shelf in [26,11,27]: return "Um explora os apoios; o outro espera na varanda. No alto, segura a corda."
	if person.shelf>=34: return "Varanda escondida · roda para descobrir a encosta seguinte"
	return ""

func hints(person) -> Array:
	if person.shelf in [4,22,23,24,25]: return ["Por cima parece não haver caminho. Mas estes blocos deixam uma passagem por baixo.","Seguimos pela varanda até à boca escura. Juntemo-nos e usamos Cima para entrar. Do outro lado, rodamos o penedo."]
	if person.shelf in [10,11,26,27,28]: return ["Aquela laje estreita só aguenta um de nós. Um espera no rebordo direito da varanda; o outro contorna o penedo, rodando para ver os apoios.","No alto há chão firme. Espaço para segurar a corda, Tab para trocar; o que esperou trepa com Cima. Só depois seguimos os dois."]
	if person.shelf in [14,29,30,31,32,33]: return ["O túnel dos fetos sai atrás deste penedo. A laje seguinte está solta e precisa de um travão.","Roda para a ver de lado. Empurrar a pedra nessa vista move-a para dentro da fenda e segura a laje. Depois atravessamos os dois."]
	return []
