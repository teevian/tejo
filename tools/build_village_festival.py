#!/usr/bin/env python3
"""Author fifty distinct residents, visitors and daily purposes; no image generation."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ZONES = {
 'palace':[9800,2390], 'republic':[9540,3300], 'padarias':[9970,4600],
 'martinho':[6650,4900], 'ferraria':[11600,6970], 'valencas':[13700,6630],
 'duche':[15580,5160], 'liberdade':[18400,7770], 'pipa':[8400,8500],
 'ferreira':[9950,9600], 'sassetti':[8470,12150], 'market':[11930,8030],
 'hortensias':[5250,10010], 'azulejos':[19000,4840], 'portadas':[18100,12980],
 'jardins':[13000,12500], 'byron':[4700,6750], 'lawrence':[3880,9200],
}
# id, name, age, role, district, appearance, purpose, personal lines
ROWS = [
 ('vera_cinema','Vera',39,'projectionist','hortensias','Portuguese woman, curly red bob, round glasses, purple dungarees over cream tee, film reel and clipboard','preparar e apresentar o cinema da vila',['Já confirmei o projetor três vezes. A quarta é por superstição.','Hoje há cinema debaixo das estrelas, mesmo sem teto de sala.']),
 ('goncalo_chamada','Gonçalo',34,'phone','valencas','slim olive-skinned man, shaved head, mustard rain jacket, navy jeans, phone to ear','combinar um encontro por telefone',['Estou mesmo ao pé da árvore. Qual árvore? Essa é a parte difícil.','Mãe, já almocei. Sim, também comi sopa.']),
 ('ana_fruta','Dona Ana',62,'fruit_vendor','portadas','stout older Black Portuguese woman, gray braids, green patterned dress, orange apron, basket of apples','vender fruta e guardar as melhores maçãs para os vizinhos',['Esta maçã estala só de olhar para ela.','A fruta não precisa de embrulho bonito, precisa de estar boa.']),
 ('quim_doces','Quim',51,'sweets_vendor','jardins','stocky man, salt-and-pepper mustache, white bakery cap, burgundy striped shirt, cream apron, tray of pastries','abrir a roulotte de doces e servir farturas',['Uma fartura resolve metade dos problemas. A outra metade pede canela.','Trouxe guardanapos a mais. Sei como isto acaba.']),
 ('rafa_toques','Rafa',27,'organizer','jardins','athletic brown-skinned man, short curls, coral sports jacket, black shorts, clipboard, whistle around neck','organizar o campeonato de toques e anunciar resultados',['Aqui conta a habilidade, mas também vale rir quando a bola foge.','Te e Jo, há sempre lugar para mais uma tentativa!']),
 ('to_tuktuk','Tó',56,'driver','palace','cheerful Portuguese man, gray mustache, flat cap, teal vest over pale shirt, tan trousers, car keys','guiar o tuk-tuk verde e meter conversa com o Te e o Jo',['Olhem quem são eles! Já vos contei a história desta curva?','Prometo que é só uma pergunta. Talvez duas.']),
 ('maya_tuktuk','Maya',32,'driver','duche','South Asian woman, dark braid, ochre utility jacket, blue scarf, black trousers, map and car keys','conduzir visitas de tuk-tuk e explicar os recantos da vila',['A melhor paragem nem sempre aparece no roteiro.','Hoje faço a volta das fontes e das histórias pequenas.']),
 ('joaquim_carruagem','Joaquim',68,'carriage_driver','liberdade','elderly man, silver beard, brown felt hat, tweed waistcoat, white shirt, brown trousers, coiled reins','conduzir a carroça turística e dar descanso ao cavalo',['O Castanho conhece este passeio melhor do que eu.','A próxima paragem também é para beber água.']),
 ('bea_cao','Bea',25,'dog_walker','sassetti','young white woman with freckles and auburn ponytail, blue denim overalls, yellow tee, green leash handle','passear a cadela Bolacha e deixá-la cheirar os jardins',['A Bolacha escolhe o percurso. Eu só seguro na trela.','Se houver um cheiro interessante, a nossa agenda muda.']),
 ('idalina_xadrez','Idalina',73,'chess','liberdade','older East Asian woman, silver bun, burgundy cardigan, linen skirt, chess knight in hand','desafiar visitantes para uma partida de xadrez',['A pressa é inimiga do cavalo. Do tabuleiro, claro.','Dizem que jogo devagar. Eu digo que estou a preparar uma surpresa.']),
 ('luz_cinefila','Luz',45,'cinema','hortensias','woman with deep brown skin, short natural hair, turquoise sweater, gray trousers, red film notebook','anotar os pormenores dos filmes e conversar depois da sessão',['Fico sempre até ao último nome dos créditos.','Um filme ao ar livre também tem grilos na banda sonora.']),
 ('kenji_visitante','Kenji',43,'cinema','lawrence','Japanese man, short black hair, sage overshirt, cream chinos, camera strap, folded cinema leaflet','fotografar a vila e ver cinema com a filha Emi',['A Emi já escolheu o melhor lugar para ver o ecrã.','Quero guardar a luz destas ruas, não apenas as fachadas.']),
 ('noor_visitante','Noor',29,'cinema','byron','young North African woman, terracotta hijab, blue long coat, beige trousers, small popcorn paper bag','descobrir os cafés e assistir à curta da noite',['O mapa dos cafés já está mais gasto do que o mapa da vila.','Se começar a chover, protejo primeiro as pipocas.']),
 ('artur_cinema','Artur',79,'cinema','hortensias','elderly white man, white hair, flat cap, green cardigan, brown corduroy trousers, walking cane','chegar cedo ao cinema e contar histórias de projeções antigas',['Antes também havia cinema sem teto. Chamávamos-lhe verão.','Não estou a dormir, estou a ouvir os diálogos de olhos fechados.']),
 ('emma_visitante','Emma',65,'cinema','sassetti','older white woman, short curly gray hair, lilac raincoat, dark slacks, reading glasses and folded program','passear pelos jardins e descobrir filmes portugueses',['Hoje dei férias ao relógio, mas não ao horário do cinema.','Trouxe um casaco para mim e outro para quem disser que não tem frio.']),
 ('camilo_cinema','Camilo',41,'cinema','ferreira','Latino father, dark wavy hair, green checked shirt, tan trousers, rolled picnic blanket','fazer um piquenique com a Yara antes da sessão',['A manta também serve de mesa, de capa e de reserva de lugares.','A Yara escolhe o lanche; eu escolho quem leva a mochila.']),
 ('emi_cinema','Emi',12,'cinema','lawrence','Japanese girl age twelve, straight black bob, sky blue hoodie, purple leggings, yellow trainers, small juice carton','desenhar os lugares visitados e ir ao cinema com o pai',['O meu desenho do palácio ficou com uma chaminé a mais.','Já perguntei ao pai se podemos ficar até ao fim. Três vezes.']),
 ('luca_visitante','Luca',23,'cinema','pipa','young Italian man, tousled dark hair, rust overshirt, navy trousers, cream canvas tote','descobrir fontes, provar doces e conhecer pessoas no cinema',['Vim procurar uma fonte e encontrei três lanches pelo caminho.','Ainda não sei dizer travesseiro sem pensar numa cama.']),
 ('deborah_visitante','Deborah',58,'cinema','lawrence','Black British woman, short silver curls, round red glasses, navy jacket, patterned orange scarf, travel journal','escrever um diário de viagem e escolher um filme pela conversa',['O melhor do diário são os nomes das pessoas que conheci.','A minha crítica do filme começa sempre pelo lanche.']),
 ('yara_cinema','Yara',11,'cinema','ferreira','brown-skinned girl age eleven, curly pigtails, pink sweatshirt, denim skirt over leggings, green shoes, popcorn bag','brincar com o pai e escolher o lugar no cinema',['Eu guardo os lugares. As pipocas guardam-se sozinhas na minha barriga.','Se houver um dragão no filme, vou precisar de mais pipocas.']),
 ('mateo_turista','Mateo',31,'tourist','azulejos','Latino man, long dark hair in bun, coral tee, blue hiking shorts, purple backpack, paper map','procurar padrões de azulejos fora das ruas mais visitadas',['Achei uma rua bonita por engano. Vou fingir que era o plano.','Cada azulejo tem uma pequena maneira de se repetir.']),
 ('zoe_turista','Zoé',26,'tourist','portadas','white woman with short ginger hair, green linen shirt, cream shorts, burgundy backpack, sketch map','seguir um roteiro de pátios e falar com moradores',['O meu roteiro diz para virar à esquerda. A curiosidade diz à direita.','A melhor fotografia ainda está depois da próxima esquina.']),
 ('chika_turista','Chika',35,'phone','jardins','Japanese woman, black ponytail, purple windbreaker, mustard trousers, white sneakers, phone','gravar mensagens de viagem para a irmã',['Estou a gravar só o som da vila. Sim, também se ouve a minha fome.','A minha irmã pediu fotografias e recebeu vinte minutos de áudio.']),
 ('omar_turista','Omar',47,'tourist','valencas','Arab man, neat black beard, round glasses, cream Panama hat, cobalt polo, olive trousers, guidebook','comparar as histórias das casas e partilhá-las com outros turistas',['A placa conta uma história, a varanda conta outra.','O meu guia pesa pouco. As perguntas pesam mais.']),
 ('greta_turista','Greta',63,'tourist','duche','older white woman, short gray hair, yellow rain hat, red hiking coat, gray trousers, binoculars','observar aves e os jardins da Volta do Duche',['Já vi três espécies de pássaros e quatro tipos de bolo.','Os pássaros não posam, mas eu tenho paciência.']),
 ('bruno_fotografo','Bruno',38,'camera','padarias','Black man, shaved head, ochre shirt, charcoal trousers, large camera and crossbody bag','fotografar portas e esperar que os turistas saiam do enquadramento',['A porta está perfeita. Só falta convencer a vila a ficar quieta.','Uma sombra pode fazer metade da fotografia.']),
 ('dora_turista','Dora',30,'tourist','liberdade','white woman, chestnut bob, red beret, denim jacket, green trousers, vintage compact camera','procurar bancos ao sol e aprender nomes de árvores',['Estou a fazer uma coleção de bancos com boa vista.','O meu passeio tem paragens obrigatórias para olhar para cima.']),
 ('salim_turista','Salim',71,'tourist','sassetti','elderly brown-skinned man, white beard, tan brimmed hat, pale blue shirt, brown trousers, carved walking stick','percorrer os jardins devagar e reconhecer plantas',['O caminho fica mais bonito quando temos tempo para o ver.','Esta planta lembra-me uma conversa antiga.']),
 ('eva_historia','Eva',28,'reader','ferraria','white woman, long dark braid, round glasses, maroon sweater, black trousers, history book with slips','ler histórias de Sintra junto ao miradouro',['Só vim confirmar uma data e já vou no terceiro capítulo.','Uma nota de rodapé também pode levar-nos a uma rua.']),
 ('inga_turista','Inga',52,'tourist','valencas','white woman, cropped blonde hair, teal hiking shirt, orange backpack, charcoal shorts, reusable water bottle','explorar ruas altas e fazer pausas para beber água',['Bebi água. Agora posso negociar mais uma subida.','O meu mapa tem estrelas nos lugares onde quero voltar.']),
 ('adelia_pombos','Adélia',76,'birds','pipa','older Portuguese woman, white bun, yellow knitted cardigan, long blue floral skirt, small seed pouch','dar sementes às aves e reconhecer os visitantes habituais',['Este pombo chega sempre antes de eu abrir o saco.','Os meus vizinhos com asas não faltam ao encontro.']),
 ('basilio_guarda_chuva','Basílio',64,'umbrella','byron','eccentric older man, wild white hair, blue bow tie, plum jacket, plaid trousers, oversized closed green umbrella','procurar um guarda-chuva que leva debaixo do braço',['Perdi o guarda-chuva. Este? Ah, este é o que eu estava a procurar!','Eu vim preparado para a chuva de amanhã.']),
 ('carolina_aguarela','Carolina',33,'painting','portadas','brown-skinned woman, black curls tied with red scarf, white paint-marked blouse, olive overalls, watercolor pad','pintar os pátios e trocar desenhos com quem passa',['A casa não se mexe. A luz é que não para quieta.','Posso trocar uma aguarela por uma história desta rua.']),
 ('oscar_bolas_sabao','Óscar',24,'bubbles','azulejos','slim white man, curly brown hair, red braces over striped tee, blue trousers, giant bubble wand','fazer bolas de sabão gigantes para surpreender visitantes',['Esta bolha tem mais espaço do que o meu quarto.','Se uma bolha subir até ao castelo, dou-lhe o meu nome.']),
 ('cris_magia','Cris',36,'magician','market','androgynous person, short violet hair, emerald velvet waistcoat, white shirt, black trousers, playing cards','fazer truques de cartas e pedir ao público que escolha uma carta',['Escolhe uma carta. Se eu falhar, dizemos que era uma surpresa.','O truque difícil é encontrar os meus bolsos todos.']),
 ('zeca_sapateiro','Zeca',59,'repair','ferreira','stocky man, dark mustache, navy work cap, brown leather apron over blue shirt, shoe and brush','reparar uma sola e conversar sobre os passos da vila',['Esta sola já sabe mais ruas do que eu.','Um bom passeio começa por sapatos que não protestam.']),
 ('susana_bicicletas','Susana',40,'repair','liberdade','athletic Black woman, short twists, red work bandana, blue coveralls, bicycle pump and wrench','afinar bicicletas e ajudar quem perdeu ar no pneu',['Só falta um bocadinho de ar e uma história para o caminho.','As subidas de Sintra também contam como ginásio.']),
 ('rita_flores','Rita',48,'flowers','azulejos','white woman, brown bun, green apron over pink shirt, cream trousers, bright bouquet and basket','vender ramos e oferecer uma flor aos aniversariantes',['Uma flor no bolso muda a cara do dia.','Este ramo já está a fazer amigos antes de sair da banca.']),
 ('nicolau_reparador','Nicolau',54,'repair','lawrence','brown-skinned man, salt-and-pepper curls, orange work vest, gray tee, navy trousers, small toolbox','reparar uma caixa de música e ajudar os comerciantes',['Se sobrar uma peça, ainda não acabei.','Esta caixa de música toca melhor depois de uma conversa.']),
 ('emmanuel_poeta','Emmanuel',44,'poet','duche','Black man, tall lean build, short beard, cream linen jacket, teal trousers, handwritten poetry booklet','ler poemas curtos a quem quiser parar',['Tenho poemas de três linhas para quem só tem um minuto.','A vila emprestou-me uma rima. Ainda estou à procura da outra.']),
 ('hugo_toques','Hugo',16,'footballer','jardins','teenage white boy, dark cropped hair, royal blue football jersey, white sports shorts, red trainers, football near foot','treinar toques para tentar superar o seu recorde',['O meu recorde cresce quando ninguém está a olhar.','Hoje conto os toques com testemunhas. Assim custa mais inventar.']),
 ('salma_toques','Salma',20,'footballer','sassetti','athletic North African woman, high dark ponytail, green sports tee, black leggings, orange trainers, football','competir no campeonato e ajudar os mais novos a treinar',['Olha para a bola, não para o número no quadro.','Se a bola cair, a próxima tentativa já está a começar.']),
 ('bento_toques','Bento',17,'footballer','ferreira','teenage brown-skinned boy, short curls, yellow football jersey, navy shorts, black trainers, football','experimentar toques de joelho e comparar técnicas',['De joelho é mais fácil. Digo isto só até a bola cair.','O segredo é respirar antes de tentar impressionar toda a gente.']),
 ('filipe_arbitro','Filipe',29,'referee','jardins','young man, fair skin, black hair, black-and-white referee shirt, black shorts, whistle and score card','arbitrar o campeonato com regras claras e boa disposição',['Eu conto os toques. As desculpas ficam para o intervalo.','A calçada não conta como um jogador extra.']),
 ('lia_comentadora','Lia',30,'announcer','jardins','young Black woman, short curly hair, orange bomber jacket, jeans, handheld microphone and notebook','comentar as tentativas e entrevistar os participantes',['Há talento, há suspense e há uma bola com muita vontade própria!','O público pede mais uma tentativa. O público sou eu, por enquanto.']),
 ('lucia_turista','Lucía',58,'tourist','republic','Latina woman, short black-and-gray curls, cobalt blouse, yellow skirt, red shoulder bag, paper fan','seguir os sons da vila e aprender uma canção portuguesa',['Eu sigo a música. O meu marido segue os cheiros da padaria.','Aprendi o refrão. As outras palavras ainda estão de férias.']),
 ('andres_turista','Andrés',47,'birds','ferraria','Latino man, short beard, beige safari vest, olive shirt, brown trousers, binoculars and tiny notebook','observar aves do miradouro e anotar o que encontra',['Vim ver o horizonte e fiquei a ver uma alvéola.','O meu caderno tem mais pássaros do que paisagens.']),
 ('valentina_turista','Valentina',36,'tourist','market','white woman, long red braid, purple blouse, cream linen trousers, wicker shopping bag','descobrir fruta, receitas e os sabores do mercado',['Anoto receitas com medidas muito precisas: um bocadinho e mais um pouco.','Esta viagem vai caber primeiro na memória e depois no livro de receitas.']),
 ('sam_gaita','Sam',66,'piper','byron','older white man, gray beard, green flat cap, brown waistcoat, blue shirt, dark trousers, small bagpipe','tocar uma gaita de foles e trocar melodias com músicos locais',['A gaita veio comigo. As notas ainda se estão a habituar a Sintra.','Se a melodia acordar um pombo, considero isso uma crítica.']),
 ('kaz_turista','Kaz',29,'cleanup','portadas','East Asian nonbinary tourist, short black hair, mint jacket, purple trousers, reusable tote and litter grabber','passear pelos pátios e apanhar pequenos papéis que encontra',['Quero deixar este lugar tão bonito como o encontrei.','O meu roteiro inclui fontes e caixotes do lixo.']),
]
def block(at, place, activity, inside=False, stroll=False):
 return dict(at=at,place=place,activity=activity,mode='inside' if inside else 'activity',stroll=stroll)
places={k:dict(at=v,name={'hortensias':'Largo das Hortênsias','jardins':'Largo dos Jardins','portadas':'Pátio das Portadas','azulejos':'Largo dos Azulejos'}.get(k,k.title())) for k,v in ZONES.items()}
places.update(cinema=dict(at=[5260,10040],name='cinema ao ar livre · Hortênsias'),fruit=dict(at=[18060,12850],name='banca de fruta da Dona Ana'),sweets=dict(at=[12950,12380],name='roulotte do Quim'),football=dict(at=[13040,12570],name='campeonato de toques · Jardins'),chess=dict(at=[18500,7820],name='mesa de xadrez do parque'),flowers=dict(at=[18900,4770],name='flores da Rita'))
nearby={'palace':'republic','republic':'padarias','padarias':'martinho','martinho':'byron','ferraria':'market','valencas':'duche','duche':'valencas','liberdade':'azulejos','pipa':'ferreira','ferreira':'pipa','sassetti':'ferreira','market':'ferraria','hortensias':'lawrence','azulejos':'liberdade','portadas':'portadas','jardins':'jardins','byron':'lawrence','lawrence':'hortensias'}
people=[]
for i,(id,name,age,role,zone,visual,purpose,lines) in enumerate(ROWS):
 x,y=ZONES[zone];column=i%5
 e=dict(id=id,name=name,age=age,role=role,festival_art=i//5+1,atlas=1,column=column,height=(112 if age<13 else 142 if age<18 else 153+(i%4)*3),home=[x+(column-2)*85,y+(i%3)*42],activity='a '+purpose,greeting=name+': '+lines[0],mirror=bool(i%2),route_offsets=([[-100,25],[90,45]] if role in ['tourist','dog_walker','umbrella','cleanup'] else []),speed=70+i%5*5,wait_seconds=8+i%6*1.7,purpose=purpose,appearance=visual,tourist=(role=='tourist' or role=='cinema' and id not in ['vera_cinema','luz_cinefila','artur_cinema','camilo_cinema','yara_cinema'] or id in ['chika_turista','bruno_fotografo','eva_historia','andres_turista','sam_gaita','kaz_turista']))
 style={'tourist':'map','phone':'phone','projectionist':'notes','fruit_vendor':'fruit','sweets_vendor':'bread','organizer':'notes','driver':'map','carriage_driver':'map','dog_walker':'dog','chess':'chess','cinema':'cinema','camera':'camera','reader':'reader','birds':'birds','umbrella':'umbrella','painting':'painting','bubbles':'bubbles','magician':'magic','repair':'repair','flowers':'garden','poet':'reader','footballer':'ball','referee':'notes','announcer':'notes','piper':'guitar','cleanup':'cleanup'}[role]
 e['personality']=dict(style=style,description=purpose,sociability=round(.35+(i%7)*.085,2),curiosity=round(.45+(i%5)*.1,2),restlessness=round(.14+(i%6)*.12,2),stride_length=40+i%15,idle_hold=[3.5+i%3,8+i%5],gesture_hold=[.55,1.3+i%4*.2],friends=[],lines=lines)
 e['plan']=[block('00:00','home','a dormir',True),block('07:15','home','a tomar o pequeno-almoço',True),block('08:30',zone,'a '+purpose,stroll=bool(e['route_offsets'])),block('12:30','meal','a almoçar',True),block('14:00',nearby[zone],'a explorar outro recanto da vila',stroll=True),block('17:00',zone,'a '+purpose,stroll=bool(e['route_offsets'])),block('20:00','home','a jantar e descansar',True),block('23:00','home','a dormir',True)]
 event={'projectionist':'cinema','fruit_vendor':'fruit','sweets_vendor':'sweets','organizer':'football','chess':'chess','flowers':'flowers'} .get(role)
 if event:
  e['plan'][2]=block('08:30',event,'a '+purpose)
  e['plan'][4]=block('14:00',event,'a '+purpose)
  e['plan'][5]=block('17:00',event,'a '+purpose)
 if role in ['footballer','referee','announcer']:
  e['plan'][5]=block('15:30','football','a participar no campeonato de toques')
 if role=='cinema':
  e['route_offsets']=[[-85,25],[80,35]]
  e['plan'][2]['stroll']=True
  e['plan'][5]=block('17:00','cinema','a chegar e escolher lugar para o cinema')
  e['plan'][6]=block('19:30','cinema','a ver a sessão de cinema ao ar livre')
  e['plan'].insert(-1,block('22:00','cinema','a conversar sobre o filme antes de regressar'))
 if role=='projectionist':
  e['plan'][6]=block('19:00','cinema','a projetar a curta da vila')
  e['plan'][-1]=block('22:30','home','a descansar depois de arrumar o cinema',True)
 if role in ['driver','carriage_driver']:
  e['vehicle']={'to_tuktuk':'tuk_green','maya_tuktuk':'tuk_yellow','joaquim_carruagem':'carriage'}[id]
  e['plan'][2]=block('08:30',zone,'a conduzir visitas pela vila')
  e['plan'][4]=block('14:00',zone,'a conduzir visitas pela vila')
  e['plan'][5]=block('17:00',zone,'a conduzir visitas pela vila')
 # Stagger real departures instead of emptying the whole town at one shared hour.
 if role not in ['cinema','projectionist','driver','carriage_driver','fruit_vendor','sweets_vendor','organizer','chess','flowers','footballer','referee','announcer']:
  def clock(n):return f'{n//60:02d}:{n%60:02d}'
  e['plan'][2]['at']=clock(480+(i%7)*12)
  e['plan'][3]['at']=clock(720+(i%6)*13)
  e['plan'][4]['at']=clock(840+(i%4)*9)
  e['plan'][4]['activity']='a continuar o passeio e '+purpose
  e['plan'][5]['at']=clock(1010+(i%5)*11)
  e['plan'][6]=block(clock(1150+(i%5)*15),'meal','a jantar sem pressa',True)
  e['plan'].insert(-1,block(clock(1260+(i%3)*15),zone,'a dar um último passeio antes de recolher',stroll=True))
  e['plan'][-1]['at']=clock(1365+(i%4)*10)
 if id in ['emi_cinema','yara_cinema']:
  e['guardian']={'emi_cinema':'kenji_visitante','yara_cinema':'camilo_cinema'}[id]
 if id=='bea_cao': e['dog']='bolacha'
 if role=='cinema': e['seated']=True
 people.append(e)
for e in people:
 if 'guardian' in e:
  adult=next(p for p in people if p['id']==e['guardian']);e['plan']=json.loads(json.dumps(adult['plan']))
  e['home']=[adult['home'][0]+70,adult['home'][1]+40]
 e['personality']['friends']=[p['id'] for p in people if p!=e and (p['role']==e['role'] or p['home'][0]==e['home'][0])][:3]
data=dict(description='50 novas identidades com quotidianos, propósitos, visitantes e atividades distribuídas pela vila.',places=places,people=people)
(ROOT/'data/village/festival-life.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
prompts=[]
for sheet in range(10):
 group=people[sheet*5:sheet*5+5]
 subjects='\n'.join(f'Column {j+1}: {p["name"]}, age {p["age"]}: {p["appearance"]}. Purpose: {p["purpose"]}.' for j,p in enumerate(group))
 seated=all(p['role']=='cinema' for p in group)
 rows=('Rows 1 and 2: each person sitting comfortably on an individual folding cinema chair, first attentive watching and then a different natural reaction (smile, lean forward, adjust glasses, enjoy popcorn). Draw complete chair and feet. Rows 3 and 4: THE SAME people standing and walking to the RIGHT, two distinct alternating leg/arm strides, no chair attached.' if seated else 'Rows 1 and 2: two distinct natural activity poses using their individual props (working, speaking, pointing, phone conversation, magic, ball practice or looking at map as appropriate), each a different authored gesture. Rows 3 and 4: the SAME five people walking toward the RIGHT, two alternating leg/arm strides, carrying their own small prop safely, no large scenery attached.')
 prompt='Use case: illustration-story. Asset type: production NPC sprite atlas for an existing Portuguese hand-painted 2D game. Input image is STYLE and SCALE reference only. Create FIVE NEW distinctly different identities; never duplicate an existing character. Transparent portrait sheet, exactly 5 equal columns by 4 rows, 20 separate COMPLETE full-body sprites, clean generous gutters and bottom margin.\n'+subjects+'\n'+rows+'\nPreserve each column identity perfectly across all four frames: identical face, hair, age, clothes, shoes, build and body proportions. Neutral daylight; warm textured gouache and pencil painting, subtle natural outlines and friendly believable human anatomy like reference. All body parts, footwear, canes and props must fit inside each cell. No cropped feet, overlapping columns, background, floor, frame, text, labels, watermark or Te/Jo. True alpha transparency. Portrait around 1536x2048, make figures small enough that all four full-body rows fit.'
 prompts.append(dict(file=f'festival-people-{sheet+1:02d}.png',prompt=prompt))
(ROOT/'data/village/festival-image-prompts.json').write_text(json.dumps(prompts,ensure_ascii=False,indent=2)+'\n')
print('Authored',len(people),'people,',sum(p['tourist'] for p in people),'tourists,',len(places),'places and ten art requests.')
