extends RefCounted
## Small branching stories: choices change real routes, held objects and persistent flags.
var d: Node2D
var actor: CharacterBody2D
var person: CharacterBody2D
func open(a: CharacterBody2D,p: CharacterBody2D) -> void:
	actor = a
	person = p
	var options: Array = []
	var text: String = str(a.entry.greeting)
	var visits: int = int(a.memory.get("player_visits",0))
	a.memory.player_visits = visits+1
	d.dirty = true
	if a.memory.get("helped_by_player",0)>0: text += " Ainda agradece a ajuda que deste aos vizinhos."
	if a.memory.has("last_living_event"): text += " Ainda comenta: "+str(a.memory.last_living_event)+"."
	match str(a.entry.role):
		"window": options = ["O que está a acontecer?","Onde estão os vizinhos?","Tens algum boato?"]; text += " Já vos viu passar "+str(a.memory.get("passes",0))+" vezes."
		"post":
			text = ("Obrigado pela ajuda anterior. Agora… " if a.memory.has("helped_day") else "")+"Sabes onde fica "+str(d.addresses[d.post_target].name)+"?"
			if a.position.distance_to(d.addresses[d.post_target].at)<100: text += " A porta fica mesmo atrás dele."
			options = ["Não sei, desculpa","Vou procurar a morada e volto","Dar a indicação que confirmei","Acompanhar até à porta"]
		"lost":
			text += " Encontro "+str(visits+1)+": "+["Está convencido de que a padaria é a bilheteira.","O mapa tem uma nódoa precisamente na Pena.","Pergunta se a subida também tem elevador.","Já reconhece os vossos sapatos melhor do que o caminho."][visits%4]
			options = ["Apontar à esquerda","Apontar à direita","Explicar o caminho da serra","Devolver o chapéu"]
		"late": text += " "+["Perdeu o autocarro.","Vai chegar tarde ao próprio aniversário.","Confundiu terça-feira com uma morada.","Os sapatos só concordaram à segunda tentativa."][visits%4]; options = ["Dizer-lhe as horas","Devolver a encomenda","Mandar respirar antes de correr"]
		"sweep": options = ["Ver os achados e perdidos","Ajudar a limpar aqui","Perguntar por novidades da rua"]
		"cameo": text = "Participação ficcional de "+str(a.entry.name)+", sem associação oficial. A roda usa uma batida original do jogo."; options = ["Ouvir a batida original","Participar: bater no tempo","Conversar depois da roda"]
		"keys": options = ["Experimentar a chave na caixa comunitária","Perguntar por acessos públicos"]
		"steps": options = ["Contar esta escada com ele","Comparar com a contagem de ontem"]
		"prophecy": options = ["Ouvir uma previsão para hoje","Conferir a previsão anterior"]
		"houses": options = ["Ser apresentado à casa","Ouvir a fachada em silêncio"]
		"note": options = ["Procurar os três sons da vila","Tocar os sons recolhidos","Ouvir uma nota de referência"]
		"collector": options = ["Trocar uma pedrinha ou fragmento","Ouvir a história da coleção"]
		"cat_owner","cat_neighbor": options = ["Seguir o Sardinha","Propor uma escala de refeições"]
		"clock": options = ["Comparar os fusos","Reparar o mecanismo encontrado"]
		"painter": options = ["Examinar a pista do quadro","Contar o que encontrei no banco"]
		"info": options = ["Pedir roteiro com locais reais","Trazer um relato da Fonte Mourisca"]
		"jobs": options = ["Perguntar a profissão de hoje","Ajudar com uma entrega"]
		"photo": options = ["Posar para o retrato","Tentar evitar a interrupção"]
		"plants": options = ["Avisar antes de regar","Ajudar a orientar o vaso"]
		"barter": options = ["Trocar uma pedrinha por sementes","Trocar um postal por uma garrafa","Ver as propostas de troca"]
		"detective": options = ["Investigar as três taças do gato","Apresentar a observação"]
		"bench": options = ["Perguntar pelo banco","Combinar uma hora para o partilhar"]
		"echo": options = ["Gravar o eco desta rua","Comparar com os sons recolhidos"]
		"boxes": options = ["Levar a caixa ao estabelecimento","Confirmar a entrega"]
		"clean": options = ["Ajudar a limpar a montra","Esperar pelo reflexo"]
		"shutters": options = ["Ajudar a abrir a portada","Chamar a vizinha da janela"]
		"rug": options = ["Avisar quem passa por baixo","Examinar o padrão do tapete"]
		"postcards": options = ["Escrever um postal para o placard","Entregar o postal ao Augusto"]
		"hiker": options = ["Pedir o caminho real para a serra","Ouvir o conselho do dia"]
	d.panel.show_choices(str(a.entry.name),text,options,choose)
func choose(index: int) -> void:
	var q: Dictionary = d.state.quests
	var role: String = actor.entry.role
	var reply := ""
	match role:
		"window":
			if index==0: reply = _news()
			elif index==1:
				var near: Array = d.by_id.values().filter(func(a):return a!=actor and a.available())
				near.sort_custom(func(a,b):return a.position.distance_squared_to(actor.position)<b.position.distance_squared_to(actor.position))
				for a in near.slice(0,4): reply += str(a.entry.name)+": "+d.world.area_at(a.position)+", "+a.activity_label()+".\n"
			else: reply = "Diz-se que o Sardinha tem três casas e nenhuma renda. A Alzira exige saber quem lhe trata da correspondência." if int(q.get("post_deliveries",0))<3 else "Boato raro: o Augusto encontrou uma porta à primeira. A Alzira ainda está a pedir testemunhas."
		"post":
			if index==0: reply = "O Augusto agradece a honestidade e volta a consultar o envelope."
			elif index==1: q.post_search = d.post_target; reply = "A morada fica assinalada na calçada e no mapa. Aproxima-te da campainha para confirmar o número e volta ao Augusto."
			elif index==2:
				if q.get("post_known_"+str(d.post_target),false): reply = "A indicação foi confirmada. O Augusto segue a pé para a porta." if d.start_delivery(false) else "Há uma passagem ocupada. Tentamos de novo quando ficar livre."
				else: reply = "Ainda não confirmaste a porta. Podes procurar primeiro ou acompanhá-lo."
			else: reply = "O Augusto segue para a porta e espera se ficares para trás." if d.start_delivery(true) else "Agora não há percurso livre. O carteiro guarda a carta."
		"lost":
			if index==3:
				reply = _return_item("living_hat","hat_returns","O Sven recuperou o chapéu. Agora o mapa perdeu toda a autoridade.")
				if reply.begins_with("O Sven"): q.hat_held = false
			else:
				var direction := Vector2.RIGHT if index==0 else Vector2.LEFT
				if index==2: direction = Vector2(0,1)
				var at: Vector2 = d.routines.clear_destination(actor.position+direction*450,[])
				actor._begin_walk(at,"walking")
				q.lost_hints = int(q.get("lost_hints",0))+1
				reply = "Indicas "+("a esquerda" if index==0 else "a direita")+"; ele vira para o outro lado, muito agradecido." if index<2 else "O Sven segue a indicação, mas distrai-se com uma montra pelo caminho."
				if int(q.lost_hints)>=8 and int(actor.memory.get("days",0))>=2 and index==2:
					if actor._begin_walk(d.world.forest_access,"walking"):
						actor.delivery_mode = "trail"
						q.lost_finale_pending = true
					reply = "Depois de tantos encontros, o Sven reconhece finalmente a saída para a serra. Ainda precisa de fazer o caminho até à Pena; desta vez leva as indicações confirmadas."
		"late":
			if index==0: reply = "São %02d:%02d. Dinis descobre que o encontro era amanhã, mas corre para avisar."%[int(d.minute)/60,int(d.minute)%60]
			elif index==1: reply = _return_item("living_box","dinis_helped","Dinis recuperou a encomenda. Pára para agradecer antes de voltar a correr.")
			else: actor.greet_time = 8; reply = "Ele respira, conta até três e lembra-se de perguntar onde era o encontro."
		"sweep":
			if index==0: d.open_lost(person); return
			elif index==1: reply = d.clean_near(person.position)
			else: reply = "Celso guardou "+str(d.state.lost.size())+" objetos. Os desenhos de giz duram até à chuva ou à próxima passagem da vassoura."
		"cameo":
			if index==0: d.play_sound(48,actor.position,true); reply = "Uma batida original enche a roda. Os vizinhos marcam o tempo."
			elif index==1: d.begin_beat(actor,person); return
			else: reply = "A cena termina com um agradecimento ao público. Sem letras, músicas ou gravações do artista."
		"keys":
			if index==0: q.chest_unlocked = true; d.play_sound(76,actor.position); reply = "À terceira chave, a caixa comunitária abre. Os objetos encontrados continuam disponíveis com o Celso."
			else: reply = "Serafim indica os quatro acessos públicos por escadas. Não abre portas de casas privadas."
		"steps":
			var closest: Dictionary = d.world.TERRACES.data.terraces[0]
			for spec in d.world.TERRACES.data.terraces:
				if d.world.stair_rect(spec).get_center().distance_to(actor.position)<d.world.stair_rect(closest).get_center().distance_to(actor.position): closest = spec
			var total: int = int(closest.steps)
			var key: String = "count_"+str(closest.id)
			if index==0: q[key] = total; reply = "Contam os "+str(total)+" degraus desenhados desta escada. A anotação fica guardada; nenhum degrau foi acrescentado."
			else: reply = "A contagem guardada é "+str(q.get(key,"ainda nenhuma"))+". Aníbal decide verificar a outra escada amanhã."
		"prophecy":
			if index==0: q.prediction = "hat" if d.wind else "sweep"; q.prediction_day = d.day; reply = "Ofélia prevê: "+("um chapéu vai tentar fazer turismo sem o dono." if d.wind else "o Celso vai encontrar um objeto que ninguém perdeu oficialmente.")
			else: reply = "Acertou! A previsão fica anotada." if (q.get("prediction")=="hat" and int(q.get("hat_day",-1))==int(q.get("prediction_day",-2))) or (q.get("prediction")=="sweep" and not d.state.lost.is_empty()) else "Ainda não aconteceu. Ofélia acrescenta um talvez a lápis."
		"houses": actor.social_pose = "listen"; actor.greet_time = 6; reply = "Baltasar apresenta-te a esta casa: tem a porta em "+str(d._address_near(actor.position).name)+". Ficam em silêncio; uma portada range."
		"note":
			if index==0: q.sound_quest = true; reply = "Ouve a Fonte Mourisca, o sino de São Martinho e os passos das Hortênsias. Os três pontos ficam assinalados no mapa."
			elif index==1:
				if ["mourisca","bell","steps"].all(func(k):return q.get("sound_"+k,false)): q.melody_complete = true; d.play_sound(67,actor.position,true); reply = "Água, sino, passos: Ema monta uma pequena frase original com os sons que recolheste."
				else: reply = "Faltam sons. A Ema conserva os que já ouviste."
			else: d.play_sound(64,actor.position); reply = "Uma nota limpa: mi. Podes voltar a ouvi-la."
		"collector":
			if index==0: reply = d.exchange(person,["pebble","shard"],"cap","Tampa de coleção")
			else: reply = "A coleção tem "+str(q.get("trades",0))+" trocas. Uma tampa marcou a primeira festa do bairro; a colher torta foi o prémio de uma corrida de sopa."
		"cat_owner","cat_neighbor":
			if index==0: q.cat_tracking = true; reply = "Acompanha o Sardinha: as taças das duas casas e o ponto de encontro ficam no mapa."
			else: q.cat_treaty = true; d.animals.food_until = d.animals.clock+20; reply = "Dário e Lurdes combinam as refeições. O Sardinha visita as duas casas na mesma."
		"clock":
			if index==0: reply = "Sintra %02d:%02d · Tóquio %02d:%02d. Horácio mostra os dois mecanismos, sem alterar o relógio do jogo."%[int(d.minute)/60,int(d.minute)%60,(int(d.minute)/60+9)%24,int(d.minute)%60]; d.play_sound(72,actor.position)
			else: reply = d.exchange(person,["living_clock"],"repaired_clock","Relógio reparado"); q.clock_repaired = reply.begins_with("Troca")
		"painter":
			if index==0: q.painting_hint = true; reply = "O quadro tem uma árvore azul inventada e um banco real junto ao Palácio Valenças. O pormenor fica no mapa."
			else: reply = "Amália reconhece o banco que encontraste e assina o teu relato." if q.get("painting_found",false) else "Ainda falta visitar o pormenor junto ao banco."
		"info":
			if index==0: reply = "Fonte Mourisca: Volta do Duche. Parque da Liberdade: jardins a nascente. Cinema: Largo das Hortênsias. Vitória usa os locais reais do mapa."
			else: q.info_verified = q.get("sound_mourisca",false); reply = "Vitória corrige o roteiro com a tua visita." if q.info_verified else "Primeiro é preciso ouvir a fonte, mesmo ali na Volta do Duche."
		"jobs":
			if index==0: reply = "Hoje trabalho em "+str(actor.memory.get("job","jornais"))+". Amanhã explico-te a promoção."
			else: reply = d.give(person,"parcel","Caixa de mercadoria"); q.delivery_target = d._address_near(actor.position+Vector2(500,300)).id
		"photo":
			if index==0: actor.memory.attempts = int(actor.memory.get("attempts",0))+1; actor.flash_until = actor.clock+.4; d.animals.flock[0].fly = 3; reply = "Um pombo levanta voo no enquadramento. Rute guarda a tentativa e pede outra."
			else:
				if actor.memory.get("attempts",0)>0 and person.velocity.length()<1: q.portrait_done = true; actor.flash_until = actor.clock+.4; reply = d.give(person,"photo","Retrato de Te e Jo")
				else: reply = "Fiquem parados primeiro. Rute ainda está a preparar o retrato."
		"plants": d.by_id.irene.frame = 1; q.water_warning = true; reply = "Irene avisa a rua antes de regar; a begónia recebe água e quem passa tem tempo para se desviar." if index==0 else "O vaso roda para o sol. Irene anota quem lhe deu uma mão."
		"barter":
			if index==0: reply = d.exchange(person,["pebble"],"grain","Sementes para pombos")
			elif index==1: reply = d.exchange(person,["living_postcard"],"bottle","Garrafa vazia")
			else: reply = "Pedrinha → sementes. Postal → garrafa vazia. Tampas podem trocar-se por giz na banca. As trocas só acontecem se houver espaço na bolsa."
		"detective":
			if index==0: q.cat_tracking = true; q.detective_case = true; reply = "Álvaro pede uma observação real: segue o Sardinha até uma das taças, em vez de adivinhar o culpado."
			else:
				if q.get("cat_seen",false): q.detective_solved = true; reply = "Mistério resolvido: ninguém roubou o gato. Ele tem uma rota de refeições por várias casas."
				else: reply = "Ainda falta observar o gato junto de uma taça. Álvaro não aceita rumores como prova."
		"bench": q.bench_shared = true; reply = "Teodoro combina partilhar o banco depois das 16h. Já esperou "+str(actor.memory.get("waits",0))+" vezes pelo seu lugar."
		"echo": q.echo_recorded = true; d.play_sound(60,actor.position); reply = "Milena grava a resposta curta desta rua e junta-a ao arquivo."
		"boxes":
			if index==0: q.delivery_target = d._address_near(actor.position+Vector2(500,0)).id; reply = d.give(person,"parcel","Caixa da Bia")+" Destino: "+str(d._address_near(actor.position+Vector2(500,0)).name)+"."
			else: reply = "A etiqueta só é confirmada ao tocar à campainha do destino com a caixa na bolsa."
		"clean": actor.social_pose = "work"; actor.greet_time = 5; q.window_cleaned = d.day; reply = "Joana passa o pano e o reflexo fica livre para a fotografia."
		"shutters": q.shutter_repaired = true; d.play_sound(71,actor.position); reply = "Joel abre a portada e chama a Alzira. Ela responde que já sabia."
		"rug": q.rug_warning = d.day; actor.greet_time = 5; reply = "Mónica espera pela passagem livre e só depois sacode o tapete." if index==0 else "Sven aproxima o mapa do tapete. As franjas continuam a não ser estradas."
		"postcards":
			if index==0: reply = d.give(person,"postcard","Postal escrito em Sintra"); d.ledger("Te e Jo deixaram um postal com uma história da vila.")
			else: reply = "O Augusto recebe o postal e fica a comparar o selo com o mapa."; q.postcard_delivered = true
		"hiker": q.serra_route = true; reply = "Olga indica a saída real para a Serra de Sintra, assinalada no mapa. Recomenda água e tempo para subir."
	d.dirty = true
	d.tell(reply)
func _return_item(type: String,flag: String,line: String) -> String:
	for i in person.inventory.items.size():
		if person.inventory.items[i].type==type: person.inventory.take(i); d.state.quests[flag] = int(d.state.quests.get(flag,0))+1; return line
	return "Ainda não tens esse objeto na bolsa. Se o Celso o recolheu, procura nos achados e perdidos."
func _news() -> String:
	var text := "Hoje: cinema às 19h30 nas Hortênsias; campeonato às 16h nos Jardins. "
	if d.hat.visible: text += "O chapéu do Sven está a passear sozinho. "
	if d.post_delivering: text += "O Augusto vai finalmente entregar uma carta. "
	if not d.events.history.is_empty(): text += "Última novidade: "+str(d.state.ledger.back())+"."
	return text
