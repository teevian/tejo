extends RefCounted
## Short contextual choices; all rewards/returns use the existing real inventory.
var director: Node2D
func panel(title: String,text: String,choices: Array,action: Callable) -> void:
	director.world.living_life.panel.show_choices(title,text,choices,action)
func open_person(a: CharacterBody2D,person: CharacterBody2D) -> void:
	a.greetings += 1
	a.greet_time = 2.5
	var role: String = a.entry.role
	var text: String = a.entry.story
	if a.entry.id=="ernesto_pombos": text = "O Engenheiro já entregou %d bilhetes e trouxe %d respostas. Quase todas são contas de bolos."%[int(director.state.get("pigeon_deliveries",0)),int(director.state.get("pigeon_receipts",0))]
	if a.entry.id=="odete_janela":
		if director.minute>=1100 and director.minute<1120: text = "Agora não. A novela só dura vinte minutos. Não façam nada interessante."
		elif not director.episodes.observations.is_empty():
			var seen: Dictionary = director.episodes.observations.values()[-1]
			text = "Vi %s passar às %02d:%02d. A primeira versão da história já está errada."%[seen.name,int(seen.minute)/60,int(seen.minute)%60]
	if a.appointment.get("place","")!=role:
		panel(a.entry.name,text+"\nAgora está "+a.activity_label()+". Podemos voltar ao encontro durante o seu horário.",["Continuar o passeio"],func(_i):pass)
		return
	open_scene({"queue":"queue","window":"window","pigeon":"pigeon","picnic":"picnic","foosball":"foosball","raffle":"raffle","papers":"papers"}[role],person,text)
func available_scene(kind: String) -> bool:
	var role: String = "picnic" if kind=="thermos" else kind
	return not director.episodes.ready_cast(role,1).is_empty() or (role=="window" and director.by_id.odete_janela.state=="window")
func open_scene(kind: String,person: CharacterBody2D,text := "") -> void:
	if not available_scene(kind): director.tell("Este encontro ainda não começou ou os vizinhos já foram para outra atividade."); return
	match kind:
		"picnic","thermos":
			panel("O piquenique da Rosário",text if text!="" else "Faltam sandes, sobram explicações e o termo continua fechado.",["Ajudar o Nelson a abrir o termo","Perguntar pelas sandes desaparecidas","Ouvir o plano do Léo para as formigas"],func(i):
				if i==0:
					director.objects.thermos.index = 2; director.objects.thermos.queue_redraw(); director.record("thermos_opened")
					director.episodes.express("nelson_termos",2,9); director.say("nelson_termos","Era preciso rodar para o outro lado. Eu estava a testar se vocês sabiam.")
				elif i==1:
					director.episodes.express("iris_merenda",1,7); director.say("iris_merenda","Não desapareceu nada. O desenho é que ainda não está atualizado.")
				else: director.say("leo_merenda","O pombo do Ernesto leva uma carta. As minhas levam o almoço todo."))
		"pigeon":
			panel("O correio do Ernesto",text if text!="" else "O pombo leva mesmo o bilhete à Olinda. A resposta costuma vir em papel de fatura.",["Sugerir uma rota sem pastelarias","Pedir para observar a próxima entrega"],func(i):
				director.episodes.express("ernesto_pombos",2 if i==0 else 0,6)
				director.say("ernesto_pombos","Já tentei. Ele acrescentou uma escala técnica." if i==0 else "Não o distraiam. Este funcionário já tem pouca produtividade."))
		"queue":
			panel("A fila ótima da Piriquita",text if text!="" else "Beatriz mede os tempos. Estela protege o lugar. Ricardo ainda não sabe quantos bolos pedir.",["Perguntar se recolheram os pedidos","Propor seguir a Estela","Ver os resultados da experiência"],func(i):
				if i==0:
					director.record("queue_orders_known"); director.episodes.express("beatriz_fila",2,7)
					director.say("ricardo_tempos","Era essa a variável que faltava. Dois travesseiros, Beatriz. Dois!")
				elif i==1:
					director.record("queue_estela"); director.episodes.express("estela_cliente",2,6)
					director.say("estela_cliente","A fornada sai às dez. Podiam ter-me perguntado antes de desenhar setas.")
				else: director.tell("Experiências concluídas: %d. O tempo está medido; o pedido continua por esclarecer."%int(director.state.get("episodes_queue",0))))
		"window":
			panel("Odete, à janela",text if text!="" else "A Odete anota quem passa. Das 18:20 às 18:40 a novela deixa a rua sem fiscalização.",["Perguntar quem passou por aqui","Perguntar pelo cabaz do Fausto"],func(i):
				if i==0:
					var list: Array = director.episodes.observations.values().map(func(s):return "%s às %02d:%02d"%[s.name,int(s.minute)/60,int(s.minute)%60])
					director.tell("Vi "+", ".join(list.slice(maxi(0,list.size()-4)))+"." if not list.is_empty() else "Ainda estou a abrir a janela. Dê-me um minuto.")
				else: director.say("fausto_merceeiro","É uma surpresa para a minha irmã. Às seis e vinte, até as laranjas andam em bicos de pés."))
		"foosball": _match_panel(person)
		"raffle":
			panel("Rifas para a atividade de Minecraft",text if text!="" else "Vasco exige três exemplares e uma caneta. Lia vende ao lado. Raul só queria ir almoçar.",["Comprar uma rifa à Lia","Preencher o requerimento do Vasco","Emprestar uma caneta ao Vasco"],func(i):
				if i==0: _ticket(person,"lia")
				elif i==1:
					if director.state.get("vasco_pen",false): _ticket(person,"vasco")
					else: director.tell("O requerimento está pronto. Falta a caneta. O Rúben talvez tenha uma na esplanada.")
				else:
					var index := -1
					for k in person.inventory.items.size():
						if person.inventory.items[k].type=="neighbour_pen": index = k; break
					if index<0: director.tell("Ainda não tens uma caneta emprestada. O Rúben costuma ter uma junto dos testes.")
					else:
						person.inventory.take(index); director.state.vasco_pen = true; director.record("pen_delivered")
						director.episodes.express("vasco_rifas",0,8); director.say("vasco_rifas","Excelente. Agora só falta uma segunda caneta para validar a primeira."))
		"papers":
			panel("Os testes da professora Margarida",text if text!="" else "As folhas levadas pelo vento podem ser apanhadas na rua. Sara reconheceu uma conta sua.",["Devolver as folhas que apanhámos","Pedir uma caneta ao Rúben","Perguntar à Sara pela conta"],func(i):
				if i==0:
					var count := 0
					for k in range(person.inventory.items.size()-1,-1,-1):
						if person.inventory.items[k].type=="neighbour_exam": person.inventory.take(k); count += 1
					if count>0:
						director.record("papers_returned",count); director.episodes.express("margarida_testes",3,8)
						director.tell("Devolveste %d folhas. Margarida promete rever a conta antes de publicar as notas."%count)
					else: director.tell("Ainda não tens folhas na bolsa. As que voaram ficam pousadas perto da esplanada.")
				elif i==1:
					if person.inventory.items.any(func(item):return item.type=="neighbour_pen"): director.tell("Já tens a caneta do Rúben.")
					elif person.inventory.try_add({"type":"neighbour_pen","name":"Caneta emprestada pelo Rúben","porte":1,"art":0}): director.record("pen_borrowed"); director.tell("O Rúben empresta uma caneta. Talvez resolva a burocracia das rifas.")
					else: director.tell("Liberta um espaço na bolsa para guardar a caneta.")
				else:
					director.episodes.express("sara_aluna",3,8); director.say("sara_aluna","Aqui tirou meio valor. Na página seguinte usou o meu resultado como exemplo."))
func _ticket(person: CharacterBody2D,seller: String) -> void:
	var key: String = "ticket_"+str(director.day)+"_"+str(person.kind)
	if director.state.has(key): director.tell("Já tens a rifa n.º "+str(director.state[key])+" de hoje."); return
	var number: int = director.day*1000+int(director.state.get("tickets",0))+1
	if not person.inventory.try_add({"type":"raffle_ticket","name":"Rifa Minecraft n.º "+str(number),"number":number,"porte":1,"id":key}): director.tell("A bolsa está cheia. A venda fica por concluir."); return
	director.state[key] = number; director.record("tickets"); director.record(seller+"_player_sales")
	director.tell("Rifa n.º %d guardada na bolsa. A atividade de Minecraft ganhou mais um apoio."%number)
func _match_panel(person: CharacterBody2D) -> void:
	var e: Node2D = director.episodes
	if e.player_match.is_empty(): e.player_match = {"player":person.kind,"goals":0,"opponent":0,"turn":0,"defence":0}
	if int(e.player_match.player)!=person.kind: director.tell("O outro protagonista está a jogar. A Dora guarda o lugar."); return
	var m: Dictionary = e.player_match
	m.defence = (int(m.turn)+director.day)%3
	var lane: String = ["esquerda","centro","direita"][int(m.defence)]
	panel("Matraquilhos · primeira pessoa a três golos","Tu %d — Dora %d. A Dora está a tapar a %s. O Tóni está a preparar uma objeção."%[m.goals,m.opponent,lane],["Rematar à esquerda","Rematar ao centro","Rematar à direita","Terminar o jogo"],func(i):
		if i==3: e.player_match.clear(); director.tell("Jogo interrompido. A mesa fica livre para os vizinhos."); return
		e.shoot_ball(0,i-1); m.turn += 1
		if i!=int(m.defence): m.goals += 1; e.express("simao_marcador",1); director.say("toni_matraquilhos","Entrou, mas eu teria defendido. Com a outra mão.")
		else: m.opponent += 1; e.express("dora_matraquilhos",2); director.say("dora_matraquilhos","Viram para onde eu estava virada. A bola também.")
		if int(m.goals)>=3 or int(m.opponent)>=3:
			director.record("player_matches"); director.record("player_wins" if int(m.goals)>=3 else "dora_wins")
			director.world.get_parent().record_shared_activity("foosball",str(director.state.get("player_matches",0)),6 if int(m.goals)>=3 else 2,director.places.foosball,200 if int(m.goals)>=3 else 50)
			director.tell("Resultado registado pelo Simão: %d — %d. O Tóni mantém a sua própria classificação."%[m.goals,m.opponent]); e.player_match.clear()
		else: director.tell("%d — %d. Volta à mesa para escolher o próximo remate."%[m.goals,m.opponent]))
