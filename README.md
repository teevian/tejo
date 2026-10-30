# tejo

Uma aventura a dois na Serra de Sintra, em Godot 4.7. A cena principal é agora uma zona aberta com perspetiva semi-superior, movimento em oito direções e a pintura de floresta já desenvolvida para o jogo.

## Jogar

Abrir `project.godot` no Godot e carregar em **F5**. A cena principal é `scenes/garden.tscn`.

O jogo começa às **08:00** e tem um relógio no canto superior esquerdo, com a hora, a fase e o número do dia. Cada segundo real equivale a um minuto do jogo (24 minutos por dia). As fases são madrugada (00:00–05:59), manhã (06:00–11:59), meio-dia (12:00–13:59), tarde (14:00–17:59), crepúsculo (18:00–19:59) e noite (20:00–23:59). A iluminação de todo o cenário e das personagens muda gradualmente, preservando a legibilidade da interface. A pausa e o mapa suspendem o relógio; as conversas decorrem com o tempo a avançar. A passagem da meia-noite incrementa o dia. O relógio central em `scripts/day_cycle.gd` fornece também a hora e a fase ao contexto das conversas.

Verificação do ciclo: `Godot --headless --path . --script res://tests/day_cycle_test.gd`.

| Ação | Teclado | Comando |
| --- | --- | --- |
| Explorar em todas as direções | WASD ou setas | Analógico esquerdo |
| Correr | Shift | B |
| Interagir / apanhar / sentar / levantar / saltar a ribeira | Espaço | X |
| Conversar / continuar | T ou botão continuar | A |
| Trocar de personagem | Tab ou avatar | Ombro direito |
| Mapa de exploração | M | Back / Select |
| Fechar conversa ou mapa | Esc | — |
| Pausa | Esc | Start |

## A zona aberta

O mundo tem **4800 × 3600 unidades**, cerca de 19 ecrãs de área. Os trilhos são referências visuais: também se pode caminhar pela erva, entre árvores e por vegetação baixa. Só os troncos, pedras grandes, paredes e água bloqueiam os pés. A câmara segue ambos os eixos e para nos limites do mundo.

Há duas pontes realmente atravessáveis sobre a ribeira, uma de madeira e outra de pedra; é possível fazer um circuito por ambas. Entrada da mata, bosque de eucaliptos, vale dos fetos, fonte escondida, margem da ribeira, ruínas da capela, miradouro do granito e clareira do sobreiro têm ambientes e pontos de interesse próprios. O terreno é composto por quatro pinturas detalhadas, ligadas com transições suaves. A floresta usa árvores e objetos independentes sobre esse terreno. Copas e personagens partilham ordenação por profundidade e mantêm a opacidade. A vegetação baixa permite passar entre folhas, que se sobrepõem aos pés e pernas; os arcos e paredes das ruínas têm camadas sólidas para permitir passar por baixo ou por trás.

O personagem que segue procura um percurso entre os obstáculos e usa as pontes quando está na outra margem. **M** abre um mapa que revela terreno e identifica locais à medida que são explorados. O estado de descoberta e dos diálogos fica em memória nesta sessão; ainda não existe gravação em disco.

Te e Jo têm cinco vistas pintadas, espelhadas para as oito direções, cada uma com uma pose parada e oito quadros de caminhada. São desenhados diretamente a partir das imagens existentes, sem deformar pernas ou pés. A escala de cada personagem é uniforme em todos os quadros e direções. Os pixels pintados dos personagens permanecem opacos. Te mantém t-shirt escura, calções cinzentos claros e ténis pretos; Jo, t-shirt bordeaux, calções bege e ténis claros. Os retratos aprovados continuam na interface.

As proporções partilham as medidas de `scripts/world_scale.gd`: personagens de 156/153 unidades, bancos com 240 unidades de largura e dois lugares separados por 104 unidades. Árvores, fetos, pedras, fontes e objetos no chão seguem a mesma referência. Os fetos ficam abaixo da altura dos personagens e os ramos próximos ocupam menos área do ecrã. O telemóvel e a mão no ombro acompanham a escala de caminhada; sentar baixa a cabeça e alinha os pés e ancas com o banco. As imagens mantêm a sua proporção original.

## Conversas e telemóvel

**T** inicia o assunto a partir do personagem selecionado. Quem inicia aparece à esquerda; quem responde, à direita. As conversas dependem da cena, do local próximo, do personagem e de descobertas anteriores. Os assuntos em `data/dialogue/sintra.json` usam `scene`, `location`, `near`, `initiator`, `priority`, `require_flags`, `forbid_flags` e `set_flags`. Os efeitos só são registados ao terminar a conversa. O sinal `flag_changed` permite ligar uma descoberta a mecanismos futuros. A inspeção da ponte por Te continua como exemplo de efeito narrativo; atravessar as pontes é livre nesta primeira zona.

Quando Te está selecionado e ambos ficam parados durante sete segundos, Jo tira o telemóvel e continua a ler até ser selecionado ou Te avançar em qualquer direção. Conversar guarda o telefone. Pausar suspende a simulação e abrir o mapa segura o movimento.

Quando Jo está selecionado, Te espera os mesmos sete segundos, aproxima-se por um percurso livre e pousa a mão no ombro dele. O gesto mantém-se enquanto Jo descansa. Movimento, troca de personagem, conversa ou outra interação interrompem o gesto; obstáculos podem impedir a aproximação e a pausa suspende a animação.

## Interações e bolsas

**Espaço** interage com o objeto próximo: o contorno dourado identifica o objeto ao alcance. O jogo não apresenta barra de comandos, textos de apresentação, capítulo, estado do companheiro, notificações de ação ou botão de pausa no cenário; Esc continua a pausar. Há pedrinhas, pinhas, ramos e fragmentos soltos para apanhar. Árvores permitem examinar a casca e encontrar uma pinha caída; rochedos, fetos e ruínas têm observações próprias e a fonte permite beber água. Os bancos são de dois lugares: Espaço faz ambos aproximarem-se por percursos livres e sentarem-se lado a lado, cada um no seu lugar. A troca de personagem mantém ambos sentados. Espaço ou movimento levantam os dois, incluindo se ainda estiverem a aproximar-se. A câmara acompanha o jogador enquanto o companheiro chega e enquadra ambos quando estão sentados.

Nos troços estreitos da ribeira a sul é possível saltar para a outra margem, com arco visível e aterragem em terreno livre. É preciso estar junto à margem. Água larga e aterragens bloqueadas impedem o salto. O companheiro procura o mesmo ponto de partida e salta a seguir, para um local próximo na outra margem. As pontes continuam disponíveis.

Cada personagem tem a sua bolsa. Só a bolsa do personagem selecionado aparece sob os retratos; trocar de personagem substitui o inventário visível no mesmo lugar. Cada objeto tem `porte` **1, 2 ou 3**, com capacidade total **5 por personagem**. Cabem cinco objetos de porte 1, dois de porte 2 e um de porte 1, ou um de porte 3 e um de porte 2. Os cinco lugares visuais mostram os ícones e o porte de cada objeto; a barra e o contador mostram o total ocupado. A bolsa cheia deixa o objeto no chão. **Clicar num objeto da bolsa pousa-o em terreno acessível**, permitindo voltar a apanhá-lo com qualquer personagem. Pausa, mapa e conversas bloqueiam as interações. Inventários e objetos apanhados mantêm-se durante esta sessão, tal como as descobertas; ainda não existe gravação em disco.

## Organização

- `scripts/garden.gd`: cena principal, câmara, controlos, seleção, mapa e diálogo.
- `scripts/sintra_open_world.gd`: terreno, água e pontes, colocação determinística da floresta, colisões e navegação.
- `scripts/open_world_prop.gd`: objetos sólidos ordenados pelo contacto com o chão.
- `scripts/painted_occluder.gd`: pedras e arcos da pintura sobrepostos aos personagens conforme a profundidade.
- `scripts/open_world_body.gd` e `shaders/opaque_cutout.gdshader`: desenho dos personagens e vegetação sem efeito de fantasma.
- `scripts/open_world_person.gd`: movimento livre, acompanhamento com procura de caminho e telemóvel.
- `scripts/world_interactions.gd`: objetos interativos, observações, bancos, recolha e travessias a salto.
- `scripts/inventory.gd` e `scripts/inventory_panel.gd`: bolsas individuais, portes, capacidade e interface.
- `scripts/world_scale.gd`: referência comum das proporções dos personagens, objetos, árvores e bancos de dois lugares.
- `scripts/interaction_art.gd` e `scripts/item_art.gd`: novas poses e objetos pintados; prompts em `assets/INTERACTIONS_ART.md`.
- `scripts/open_world_art.gd`: sprites direcionais com escala uniforme.
- `scripts/exploration_map.gd`: descoberta e mapa.
- `scripts/dialogue_director.gd` e `scripts/dialogue_panel.gd`: regras e apresentação das conversas.
- `scripts/hud.gd` e `scripts/avatar_button.gd`: interface e retratos.
- `assets/world/ART.md`: imagens finais, referências e prompts de geração.

A versão lateral anterior está preservada em `scenes/side_trail.tscn` e `scripts/garden_lateral.gd`. As respetivas imagens e scripts de movimento não foram apagados.

## Verificação

Executar Godot com `--headless --fixed-fps 60 --path . --script res://tests/open_world_test.gd`. O teste cobre movimento nos dois eixos, velocidade diagonal, orientação, ligação entre locais, colisões com água, ambas as pontes, procura de travessia pelo companheiro, copas opacas, passagem sob o arco, telemóvel, conversas, descoberta, mapa, troca e pausa.

Os testes anteriores `dialogue_test.gd`, `phone_idle_test.gd` e `world_exploration_test.gd` apontam para a cena lateral preservada, para continuarem a verificar essa versão.

`Godot --headless --fixed-fps 60 --path . --script res://tests/startup_input_test.gd` reproduz eventos recebidos antes de o mapa existir, verifica que não causam erros e confirma os controlos após o arranque.

`Godot --headless --fixed-fps 60 --path . --script res://tests/interactions_test.gd` verifica as combinações de porte, bolsas separadas, apanhar/largar/recuperar, árvores, pedras, fetos, fonte, ruínas, bancos e ocupação, o gesto do Te e a sua interrupção, saltos e acompanhamento, distâncias de partida, aterragens bloqueadas e bloqueio de ações em pausa/mapa/conversas. Pode também ser executado sem `--headless` para validar a integração com o motor gráfico.

`tests/interactions_preview.gd`, com janela gráfica e `--fixed-fps 60`, guarda imagens de revisão das bolsas, mão no ombro, banco e salto em `output/interactions/`. Pode receber `-- --output-dir=CAMINHO` para guardar noutro local.

Verificação gráfica dos personagens: executar Godot **sem `--headless`**, com `--path . --script res://tests/character_rendering_test.gd`. O teste verifica os pixels realmente desenhados dos dois personagens nas oito direções, a pose parada, todos os quadros de caminhada e as oito poses do telemóvel. Falha se os corpos estiverem invisíveis, incompletos ou se as animações não apresentarem quadros diferentes. Os testes sem janela verificam a lógica do jogo, mas não detetam falhas de desenho.

Pré-visualizações: executar `tests/open_world_preview.gd` com janela gráfica. Guarda a entrada, ambas as pontes, ruínas, mapa com descoberta e uma vista geral de revisão totalmente revelada em `output/`; esta última usa apenas uma cena de teste descartável e não altera o estado de uma partida.

A interface superior direita mostra apenas os retratos e nomes, com contorno verde e dourado no personagem selecionado. `tests/depth_preview.gd`, com janela gráfica, guarda a aproximação, passagem e saída do arco, vegetação e ambas as seleções dos avatares em `output/`.

### Bosque húmido e extensão sul

A zona aberta tem agora 4800×5400 unidades (mais 50% de área). A entrada foi repintada com chão húmido, hera e musgo. A sul encontram-se o Bosque da hera, o Passadiço da ravina, a Escadaria dos musgos e a Encosta da muralha, com descoberta e conversas locais. Troncos altos e galhos próximos com paralaxe enquadram a exploração; a névoa fica abaixo dos personagens, que permanecem opacos. As versões e os prompts estão em `assets/world/ART.md`.

Verificação da extensão: `Godot --headless --fixed-fps 60 --path . --script res://tests/humid_world_test.gd`.

### Fauna autónoma

A floresta tem uma população persistente de pássaros, esquilos, três raposas, rãs e borboletas, distribuída pelas árvores, clareiras e margens reais do mapa. Os animais continuam a agir fora da câmara; aproximar-se deles altera o comportamento, e correr aumenta a distância a que os personagens os assustam.

- **Pássaros:** seis bandos de quatro e oito aves solitárias. Voam entre árvores, evitam sobrepor-se em voo, pousam, procuram alimento no chão e recolhem-se à noite. Um alarme faz levantar o bando.
- **Esquilos:** exploram o chão, param para comer, fazem um pequeno salto de susto e fogem rapidamente de raposas e personagens, trepam ao tronco e desaparecem em cavidades visíveis. Só voltam a sair quando a ameaça se afasta; de noite ficam abrigados.
- **Raposas:** alternam corridas rápidas, farejar e descanso. Ao ver um esquilo acessível, perseguem-no imediatamente, independentemente da fome; a aproximação dos personagens tem prioridade e provoca fuga. Ao arrancar de paradas para uma corrida, fazem um salto curto de mudança de direção. A sede continua a levá-las à margem para beber. São apenas três no mundo; a curiosidade pode levá-las a observar brevemente o jogador num canto visível do ecrã, a distância segura, antes de fugirem novamente.
- **Rãs:** saltam entre a margem e pequenas folhas flutuantes, mergulham perante uma ameaça e emergem quando há segurança. Reagem às borboletas próximas; o intervalo entre saltos é menor à noite.
- **Borboletas:** alternam voo irregular e repouso nas flores, afastam-se dos personagens, raposas e tentativas de captura das rãs, e pousam durante a noite.

É uma simulação de comportamentos com população estável: as perseguições não removem animais e não há reprodução ou mortalidade. Árvores, água, rotas e refúgios são partilhados com o mundo jogável. Os mamíferos usam a navegação existente para evitar água e obstáculos. O relógio e a fauna param juntos no mapa e na pausa; durante conversas, o mundo continua vivo.

Os sprites pintados transparentes, poses e registo de criação estão em `assets/wildlife/`. A simulação está em `scripts/wildlife.gd` e `scripts/wildlife_animal.gd`; desenho e elementos de habitat em `scripts/wildlife_art.gd` e `scripts/wildlife_habitat.gd`.

Verificação: `Godot --headless --path . --script res://tests/wildlife_test.gd`. Cobre perseguição/refúgio, sede, mergulho/regresso às folhas, alarme de bando, reação das borboletas, ritmos diários, estabilidade da população, água e suspensão da simulação. `tests/wildlife_preview.gd`, com janela gráfica, grava capturas em `output/wildlife-*.png` e exercita as poses; as composições aproximadas são preparadas numa cena descartável de revisão.

### Agilidade, curiosidade e oito direções

As raposas correm a 530 unidades/s na fuga e a 465 na perseguição, com aceleração rápida; os esquilos fogem a 490. A raposa reage aproximadamente a cada décimo de segundo, atualiza a perseguição a cada 0,22 s e escolhe corredores de fuga que se afastem do jogador. Os percursos são simplificados para evitar ziguezagues de grelha e o movimento é verificado em passos curtos para não atravessar obstáculos a alta velocidade.

O salto de arranque da raposa dura 0,28 s, com mudança de orientação e elevação de 21 unidades. Não se aplica ao início de uma caminhada. O susto do esquilo dura 0,24 s e eleva-o 16 unidades antes da fuga. Passadas e saltos de corrida acompanham a distância percorrida.

A observação curiosa dura 3–6 segundos e usa pontos nas margens da vista, afastados dos personagens e da interface. A escolha verifica o terreno, a linha de visão e a transparência real das copas e galhos que poderiam tapar a cabeça e o corpo. Aproximar-se ou correr na direção da raposa interrompe a observação; depois da fuga existe um intervalo de 24–50 segundos antes de uma nova aproximação curiosa. Os pontos são alcançados por movimento normal no mundo.

Cinco atlas adicionais contêm 100 poses pintadas: cinco vistas por espécie e quatro poses por vista. Norte, nordeste, este, sudeste e sul têm anatomia própria; as vistas ocidentais correspondentes são espelhadas. Todas as cinco espécies se orientam em oito direções. Foram preservadas as poses específicas da raposa a beber e enrolada a dormir.

Verificações adicionais:

- `Godot --headless --path . --script res://tests/wildlife_agility_test.gd`: velocidade, salto de arranque, caminhada sem salto, fuga segura, observação visível na periferia, intervalo entre encontros, perseguição imediata, susto do esquilo e seleção direcional.
- `Godot --path . --script res://tests/wildlife_direction_rendering_test.gd` (com gráficos): verifica pixels realmente desenhados para todas as espécies e direções e diferenças entre poses. Guarda as grelhas em `output/wildlife-directions-*.png`.
- `Godot --path . --script res://tests/wildlife_agility_preview.gd` (com gráficos): prepara, numa cena descartável, capturas da observação no canto, salto de mudança de direção, corrida e susto em `output/fox-*.png`.
