# tejo

Uma aventura a dois na Serra de Sintra, em Godot 4.7. A cena principal é agora uma zona aberta com perspetiva semi-superior, movimento em oito direções e a pintura de floresta já desenvolvida para o jogo.

## Jogar

Abrir `project.godot` no Godot e carregar em **F5**. A cena principal é `scenes/garden.tscn`.

O jogo começa às **08:00** e tem um relógio no canto superior direito, junto aos retratos, com «Serra de Sintra», a hora, a fase e o número do dia. Cada segundo real equivale a um minuto do jogo (24 minutos por dia). As fases são madrugada (00:00–05:59), manhã (06:00–11:59), meio-dia (12:00–13:59), tarde (14:00–17:59), crepúsculo (18:00–19:59) e noite (20:00–23:59). A iluminação de todo o cenário e das personagens muda gradualmente, preservando a legibilidade da interface. A pausa e o mapa suspendem o relógio; as conversas decorrem com o tempo a avançar. A passagem da meia-noite incrementa o dia. O relógio central em `scripts/day_cycle.gd` fornece também a hora e a fase ao contexto das conversas.

Verificação do ciclo: `Godot --headless --path . --script res://tests/day_cycle_test.gd`.

| Ação | Teclado | Comando |
| --- | --- | --- |
| Explorar em todas as direções | WASD ou setas | Analógico esquerdo |
| Correr | Dois toques rápidos na mesma direção; manter o segundo | Dois impulsos na mesma direção; manter o segundo |
| Interagir / apanhar / sentar / levantar / saltar a ribeira | Espaço | X |
| Conversar / continuar | T ou botão continuar | A |
| Trocar de personagem | Tab ou avatar | Ombro direito |
| Mapa de exploração | M | Back / Select |
| Fechar conversa ou mapa | Esc | — |
| Pausa | Esc | Start |

## A zona aberta

O mundo tem **12000 × 7560 unidades**, incluindo a mata húmida a sul e os seis locais dispersos pela serra. Os trilhos são referências visuais: também se pode caminhar pela erva, entre árvores e por vegetação baixa. Só os troncos, pedras grandes, paredes e água bloqueiam os pés. A câmara segue ambos os eixos e para nos limites do mundo.

Há duas pontes realmente atravessáveis sobre a ribeira, uma de madeira e outra de pedra; é possível fazer um circuito por ambas. Entrada da mata, bosque de eucaliptos, vale dos fetos, fonte escondida, margem da ribeira, ruínas da capela, miradouro do granito e clareira do sobreiro têm ambientes e pontos de interesse próprios. O terreno é composto por quatro pinturas detalhadas, ligadas com transições suaves. A floresta usa árvores e objetos independentes sobre esse terreno. Copas e personagens partilham ordenação por profundidade e mantêm a opacidade. A vegetação baixa permite passar entre folhas, que se sobrepõem aos pés e pernas; os arcos e paredes das ruínas têm camadas sólidas para permitir passar por baixo ou por trás.

O personagem que segue procura um percurso entre os obstáculos e usa as pontes quando está na outra margem. **M** abre um mapa que revela terreno e identifica locais à medida que são explorados. O estado de descoberta e dos diálogos fica em memória nesta sessão; ainda não existe gravação em disco.

## Escalada até ao Penedo da Amizade

Nova cena independente, `scenes/rock_climbing.tscn`, de escalada cooperativa à volta de um maciço 3D. A subida alterna paredes, varandas largas, travessias horizontais e túneis entre blocos. Pode ser aberta diretamente com **F6**, pela placa junto ao **Miradouro do granito**, usando **Espaço**, ou em qualquer ponto da floresta através de **Esc → Escalar o Penedo da Amizade**. Ao regressar, posições, bolsas, descobertas, fauna, diálogos e relógio da floresta são preservados. A escalada também mantém o seu progresso nas visitas seguintes durante a mesma sessão.

Os personagens usam agora 128 sprites de ação próprios, com o rosto, cabelo e roupa atuais: 64 por personagem, distribuídos por 16 ações. Incluem salto, queda e reação à corda, aterragem, trepar e descer, subir/segurar/puxar a corda, empurrar, dar/receber pé, puxar/receber a mão, levar/subir às costas, fenda costas com costas e passagem de gatas. Os dois papéis das ajudas partilham a fase e os pontos de contacto; a corda acompanha as mãos. Na parede da pedra solta, a ajuda usa a subida às costas. As caminhadas aprovadas estão preservadas. Atlas, geometria e prompts: `assets/characters/climbing/ART.md`. `tests/climbing_sprites_test.gd`, com gráficos, verifica todas as poses e os dois papéis das ajudas; `tests/climbing_actions_preview.gd` mostra as ações na cena real.

**Esquerda/direita** caminham e empurram pedras ao encostar nelas. **Cima** salta com controlo no ar ou faz uma escalada rápida junto de uma face alcançável; também permite recuperar quando se fica suspenso pela corda. Não é preciso voltar a tocar na direção horizontal. **Baixo** desce uma face ou deixa cair para um apoio inferior. As entradas perto da aterragem ficam guardadas por um instante, e é possível trocar com **Tab** enquanto o outro está no ar. **Espaço** realiza a ajuda contextual e **T** permite aos dois conversar sobre o puzzle. **Esc** fecha a conversa ou abre a pausa. WASD e o comando continuam disponíveis.

**Q / E** rodam o penedo 90° para uma de quatro vistas 2D: frente, direita, trás e esquerda. A câmara ortográfica percorre um mundo 3D real, mantendo as posições e a profundidade. As saliências principais estendem-se também em profundidade, com pelo menos 280 unidades de largura nas vistas laterais; os apoios alternam de flanco e cinco varandas escondidas surgem ao contornar a montanha. A câmara acompanha os dois na horizontal e enquadra a distância entre eles. Os movimentos e as contagens dos apoios suspendem-se durante a transição; uma manobra de escalada termina antes de se poder rodar. Há também botões de rotação e um indicador da face na interface. A orientação mantém-se ao voltar à floresta e regressar.

O percurso tem 39 apoios, incluindo três pedras móveis e uma ponte de laje desbloqueada por um puzzle. Algumas lajes estão inclinadas: a altura dos pés acompanha a superfície, subir custa mais e a mais íngreme faz escorregar para baixo. Cinco saliências fissuradas abanam e mostram a contagem antes de se soltarem entre 1,9 e 3 segundos após serem pisadas. Uma delas só suporta uma pessoa; juntar os dois faz ceder a placa. A colisão desaparece, o rochedo e o personagem caem; o apoio volta a ficar disponível para repetir a tentativa. Conversa, pausa e rotação suspendem estas contagens.

O **Dólmen das raízes** e o **Túnel dos fetos** passam sob grandes blocos inclinados e saem noutros flancos. Os dois aproximam-se da abertura marcada e entram com **Cima**; caminham por um trajeto contínuo em X/Y/Z, mantendo a corda dentro da passagem. **Baixo**, junto à saída, permite regressar pelo túnel. As entradas têm pedras laterais, uma abertura escura e um teto de granito contínuo. As saídas são pontos seguros para retomar a tentativa.

Na **volta do explorador**, um espera na varanda inferior enquanto o outro procura apoios na vista lateral, atravessa uma laje que só suporta um e chega a chão firme. **Espaço** mantém o explorador a segurar a corda; **Tab** troca para o que esperou, que trepa a corda com **Cima**. Só quando se reencontram podem seguir. No **reverso do penedo**, é necessário empurrar uma pedra na vista lateral: o movimento real em profundidade prende uma laje entre dois blocos, criando uma ponte que também serve de degrau. Rodar não repõe a pedra nem desfaz o apoio.

A corda tem um comprimento máximo real de **560 unidades / 7 m**, medido em três dimensões e partilhado pela simulação, pelos movimentos de escalada e pela linha desenhada. A profundidade continua a contar mesmo quando os personagens parecem próximos numa vista lateral. Impede afastamentos excessivos e pode travar uma queda quando o outro está apoiado. **Cima** recupera pela corda e **Espaço** permite ao companheiro puxar quem está suspenso. Se os dois caírem sem apoio, regressam ao último patamar seguro. O medidor da corda assinala a aproximação ao limite.

A cooperação continua necessária: dar pé e puxar de cima; soltar uma pedra para criar degraus; manter e prender uma laje basculante; escalar uma fenda de costas encostadas; e dar segurança pela corda. Há ainda uma parede que exige levar uma pedra móvel até à base e usá-la como degrau. Pode-se passar por cima da pedra com **Cima** para a empurrar pelo outro lado, e quem estiver sobre ela acompanha o movimento. O cume só é concluído quando **ambos** chegam.

A parede de granito cobre todo o fundo durante a escalada. A vista da serra, oceano e muralhas só se abre ao chegar ao cume. Os penedos são volumes 3D, com uma textura de granito própria, aplicada continuamente às formas curvas. Os personagens conservam todos os sprites e retratos já existentes, sem novas imagens. Inclinações, pedras móveis e quedas usam a mesma geometria em todas as vistas.

O maciço tem um corpo contínuo mais largo, grandes blocos arredondados parcialmente enterrados na rocha e três contrafortes laterais sob as galerias. As 33 saliências fixas crescem de raízes que penetram nesse corpo. Os bordos têm coroas curvas e pequenas irregularidades que a altura dos pés acompanha; as formas têm ombros erodidos, assimetrias e superfícies curvas, em vez de paralelepípedos. As cinco placas que caem conservam um apoio rochoso permanente por baixo. Pedras soltas, cunha, laje e marco do cume também são volumes 3D apoiados nas superfícies.

`tests/climbing_test.gd`, com `--headless --fixed-fps 60`, percorre a subida inteira por entradas reais de teclado, incluindo o novo puzzle da pedra móvel. `tests/climbing_motion_test.gd` verifica os saltos, o controlo no ar, a troca durante um salto, as entradas guardadas, inclinações, contagem/queda/recuperação dos apoios, corda limitada e recuperação de quedas, descida e pedras que transportam o companheiro. Executar com janela gráfica e `-- --preview` guarda capturas em `output/climbing-*.png`. `tests/climbing_transition_test.gd` verifica a suspensão e preservação do estado entre a floresta e a escalada.

`tests/climbing_expedition_test.gd` verifica a largura dos apoios nas quatro vistas, a descoberta das varandas, travessias contínuas e reversíveis nos túneis, pausa, pontos seguros, a espera do explorador, a subida pela corda e a pedra-ponte que se move em Z. Com gráficos e `-- --preview`, guarda `output/climbing-expedition-*.png`. O teste da subida completa também percorre estes puzzles por teclado, sem colocar as personagens no destino.

`tests/climbing_perspective_test.gd` verifica a órbita suave, quatro rotações reversíveis, a passagem lateral do explorador, conservação de posições/profundidade/pedras, suspensão de contagens, pausa durante a rotação e a corda limitada em 3D. Com gráficos e `-- --preview`, guarda as vistas frontal, lateral e intermédia em `output/climbing-perspective-*.png`.

`tests/climbing_geology_test.gd` verifica a interseção das raízes das 33 saliências fixas com o volume da montanha, os apoios permanentes das placas frágeis, contornos irregulares, normais para fora, centralização e contacto das pedras soltas com o chão. Com gráficos e `-- --preview`, guarda as quatro vistas na base, a meia altura, no troço superior e no cume em `output/climbing-natural-*.png`.

O arvoredo usa as fotografias fornecidas como referência direta: pinheiros de tronco torto, arbustos perenes, urzes, fetos e hera pendente. Há 164 grupos de vegetação com raízes amostradas sobre a geometria real do maciço; pequenas bolsas de rocha seguram os arbustos. A vegetação acompanha a rotação, conserva a posição no mundo e mantém as personagens e os apoios legíveis. Grandes penedos têm faces de fratura oblíquas e manchas de líquenes; uma escarpa com granito e mato preenche o fundo, com paralaxe suave, até o panorama se abrir no cume.

`tests/climbing_habitat_test.gd` verifica as 164 plantas, as quatro famílias de vegetação, transparência, contacto das raízes, persistência das posições e reinício sem duplicações. Com gráficos e `-- --preview`, confirma também pixels de folhagem nas quatro vistas e guarda `output/climbing-sintra-*.png`, da base ao cume.

Os sprites direcionais finais do Te e do Jo estão aprovados. A pasta `assets/characters/open_world/` contém apenas dois atlas completos e os respetivos ficheiros de importação do Godot:

- [Te](assets/characters/open_world/te-walk-friendly-painted-face.png): rosto mais amistoso, cabelo escuro/despenteado com volume no topo, camisola escura, calções cinzentos e ténis pretos.
- [Jo](assets/characters/open_world/jo-walk-south-painted-face.png): rosto com traço pintado, cabelo volumoso em cima, camisola bordeaux, calções bege e ténis creme.

Cada atlas tem 2000×2800 píxeis: cinco vistas (sul, sudeste, direita, nordeste e norte), com pose parada e quatro passadas completas, espelhadas para as oito direções. Os oito tempos de caminhada, escala e apoios mantêm o resultado aprovado. Não há recortes separados de cabeça, braços ou pernas durante o desenho.

As versões antigas, fontes, prompts e material de trabalho das revisões foram eliminados a pedido do utilizador. As poses de interação ainda necessárias estão separadas em `assets/characters/interactions/interaction-poses.png`. O [manifesto de aprovação](assets/characters/approved-directions.json) guarda os SHA-256 e a geometria; `node tools/check_approved_characters.cjs` confirma a preservação. Alterações aos sprites exigem pedido direto do utilizador, conforme `AGENTS.md`.

As proporções partilham as medidas de `scripts/world_scale.gd`: personagens de 156/153 unidades, bancos com 240 unidades de largura e dois lugares separados por 104 unidades. Árvores, fetos, pedras, fontes e objetos no chão seguem a mesma referência. Os fetos ficam abaixo da altura dos personagens e os ramos próximos ocupam menos área do ecrã. O telemóvel acompanha a escala de caminhada e o Te tem uma animação própria sentado a desenhar na areia; sentar baixa a cabeça e alinha os pés e ancas com o banco. As imagens mantêm a sua proporção original.

## Conversas e telemóvel

**T** inicia o assunto a partir do personagem selecionado. Quem inicia aparece à esquerda; quem responde, à direita. As conversas dependem da cena, do local próximo, do personagem e de descobertas anteriores. Os assuntos em `data/dialogue/sintra.json` usam `scene`, `location`, `near`, `initiator`, `priority`, `require_flags`, `forbid_flags` e `set_flags`. Os efeitos só são registados ao terminar a conversa. O sinal `flag_changed` permite ligar uma descoberta a mecanismos futuros. A inspeção da ponte por Te continua como exemplo de efeito narrativo; atravessar as pontes é livre nesta primeira zona.

Quando Te está selecionado e ambos ficam parados durante 7–10 segundos, Jo tira o telemóvel e continua a ler até ser selecionado ou Te avançar em qualquer direção. As oito poses do telemóvel usam o rosto, roupa e traço atuais, com o perfil e nariz revistos pelas fotografias do Jo, inclinação moderada de leitura e cabelo no mesmo castanho escuro da caminhada; pés e escala mantêm-se fixos ao tirar, ler e guardar. Conversar guarda o telefone. Pausar suspende a simulação e abrir o mapa segura o movimento.

Quando Jo está selecionado, Te espera os mesmos 7–10 segundos, escolhe um pequeno espaço livre e senta-se no chão a desenhar na areia com o dedo. Quatro desenhos animam subtilmente a mão e os traços. Movimento do Jo, seleção do Te, conversa ou outra interação levantam-no; pausa e mapa suspendem a animação. Após mais 10–15 segundos dessa animação, um único temporizador inicia o descanso conjunto.

## Interações e bolsas

**Espaço** interage com o objeto próximo: o contorno dourado identifica o objeto ao alcance. O jogo não apresenta barra de comandos, textos de apresentação, capítulo, estado do companheiro, notificações de ação ou botão de pausa no cenário; Esc continua a pausar. Há pedrinhas, pinhas, ramos e fragmentos soltos para apanhar. Árvores permitem examinar a casca e encontrar uma pinha caída; rochedos, fetos e ruínas têm observações próprias e a fonte permite beber água. Os bancos são de dois lugares: Espaço faz ambos aproximarem-se por percursos livres e sentarem-se lado a lado, cada um no seu lugar. No banco, alternam em conjunto a cada 30 segundos entre conversa sentados, Te recostado e Jo recostado, com espaço e apoios próprios para ambos. A pausa suspende esta alternância e voltar a sentar reinicia o ciclo. A troca de personagem mantém ambos sentados. Espaço ou movimento levantam os dois, incluindo se ainda estiverem a aproximar-se. A câmara acompanha o jogador enquanto o companheiro chega e enquadra ambos quando estão sentados. Fora do banco, o companheiro inicia a espera após 7–10 segundos. Passados mais 10–15 segundos dessa animação, procuram dois pontos livres e iniciam a sentada no mesmo instante, depois de ambos chegarem e de Jo guardar o telefone. Quando ambos estão sentados, cada um espera 15–20 segundos para ficar semi-recostado; só quando ambos chegam a essa postura começam as esperas individuais de 5–15 segundos para se deitarem, ainda de olhos abertos. Só depois de ambos deitados começa a espera individual de 5–10 segundos para fechar os olhos.

Acordados, cada um olha à volta a cada 1,5–3,5 segundos, com intermédios. Movimento acorda primeiro o selecionado, que se senta, se espreguiça e chama o outro. Depois de o companheiro acordar e se sentar, levantam-se os dois juntos. Um toque breve conclui a sequência; manter a direção retoma a caminhada no fim. Espaço cancela o repouso. Selecionar o outro conserva-o; pausa e mapa congelam todas as fases. [Sequência, atlas, prompts e testes](assets/characters/interactions/REST_SEQUENCE.md).

O Te sentado apoia a mão esquerda no chão, mantendo o outro antebraço no joelho. No descanso deitados existem também poses totalmente de lado sobre cada ombro, com cabeça apoiada no braço. Durante o sono, cada um pode mudar de postura entre 20 e 35 segundos, com transições através da posição de costas e regresso animado ao levantar. O único telefone permanece no mesmo ponto do chão. [Sprites e prompts](assets/characters/interactions/REST_SIDE.md).

**Esc → Dormir** inicia já a aproximação, o sentar e o deitar, usando as animações existentes e procurando espaço livre. Cada novo sono durante o dia alterna entre **TEJO_vaporware** e **TEJO_vaporware2**. A primeira acompanha um sonho rosa/ciano com auroras e ondulações; a segunda tem animação própria azul/violeta/pêssego, com ondas concêntricas e cortinas de luz. Os efeitos respondem às batidas e energia medidas na respetiva gravação. Movimento ou Espaço fazem-nos levantar e restauram o ambiente e o silêncio; pausa e mapa suspendem tudo em conjunto, conservando a faixa atual. A música está organizada em `assets/audio/music/`. [Funcionamento, sincronização e testes](assets/audio/music/README.md).

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

## Testar a caminhada

Carregar **Esc → Testar caminhada · só chão** abre um cenário apenas com chão neutro, uma grelha discreta de referência e os sprites reais de Te e Jo. **WASD / setas** movem o personagem selecionado, **dois toques rápidos na mesma direção**, mantendo o segundo, fazem correr e **Tab** troca entre Te e Jo. O outro personagem fica parado, sem gestos automáticos. **Esc** abre as opções **Continuar teste**, **Repor posições** e **Voltar ao jogo**. A floresta fica suspensa durante o teste; posições, inventário e progresso são preservados ao regressar. O cenário também pode ser aberto diretamente em `scenes/walking_test.tscn`.

Te e Jo usam animações próprias de corrida nas oito direções: seis desenhos completos por vista, com impulso, passagem das pernas, braços alternados e fases no ar. A cadência acompanha a distância percorrida. O companheiro também usa a corrida quando acelera para acompanhar. Os novos atlas estão em `assets/characters/running/`; os sprites aprovados de caminhada mantêm-se preservados. Pré-visualização em `output/running-preview.gif` e referências/prompts em `assets/characters/running/ART.md`.

`tests/walking_test.gd`, com `--headless --fixed-fps 60`, verifica a entrada pelo menu, o movimento real nas oito direções, pausa, reposição, regresso, reentrada e preservação da partida. Com janela gráfica guarda `output/walking-test-menu.png` e `output/walking-test-ground.png`. `tests/rest_sequence_test.gd` verifica os sorteios, as barreiras entre etapas e o despertar dos dois personagens. `tests/rest_sequence_rendering_test.gd`, com gráficos, verifica as novas poses e olhares. `tests/idle_running_test.gd` verifica o duplo toque real, o acompanhamento e as transições para as restantes animações. `tests/running_sprites_test.gd`, com gráficos, verifica os 96 quadros de corrida nas oito direções. `tests/running_preview.gd` captura uma sequência de revisão no motor.

## Verificação

Executar Godot com `--headless --fixed-fps 60 --path . --script res://tests/open_world_test.gd`. O teste cobre movimento nos dois eixos, velocidade diagonal, orientação, ligação entre locais, colisões com água, ambas as pontes, procura de travessia pelo companheiro, copas opacas, passagem sob o arco, telemóvel, conversas, descoberta, mapa, troca e pausa.

Os testes anteriores `dialogue_test.gd`, `phone_idle_test.gd` e `world_exploration_test.gd` apontam para a cena lateral preservada, para continuarem a verificar essa versão.

`Godot --headless --fixed-fps 60 --path . --script res://tests/startup_input_test.gd` reproduz eventos de rato, teclado e comando antes e durante a construção das três cenas, incluindo quando o Godot já indica que estão prontas mas o mapa e a interface ainda não existem. Verifica que os eventos e as atualizações aguardam pelo fim da inicialização, sem erros nem alterações ao estado inicial, e confirma os controlos após o arranque.

`Godot --headless --fixed-fps 60 --path . --script res://tests/interactions_test.gd` verifica as combinações de porte, bolsas separadas, apanhar/largar/recuperar, árvores, pedras, fetos, fonte, ruínas, bancos e ocupação, o gesto do Te e a sua interrupção, saltos e acompanhamento, distâncias de partida, aterragens bloqueadas e bloqueio de ações em pausa/mapa/conversas. Pode também ser executado sem `--headless` para validar a integração com o motor gráfico.

`tests/interactions_preview.gd`, com janela gráfica e `--fixed-fps 60`, guarda imagens de revisão das bolsas, desenho na areia, banco e salto em `output/interactions/`. Pode receber `-- --output-dir=CAMINHO` para guardar noutro local; `--sand-only` captura os quatro momentos do Te a desenhar no cenário. `tests/seated_preview.gd` captura as três posturas no banco real e as duas posturas de chão, com a vegetação ocultada apenas para revisão; recebe o mesmo argumento de destino.

Verificação gráfica dos personagens: executar Godot **sem `--headless`**, com `--path . --script res://tests/character_rendering_test.gd`. O teste verifica os pixels realmente desenhados dos dois personagens nas oito direções, a pose parada, todos os quadros de caminhada e as oito poses do telemóvel. Falha se os corpos estiverem invisíveis, incompletos ou se as animações não apresentarem quadros diferentes. Os testes sem janela verificam a lógica do jogo, mas não detetam falhas de desenho.

Pré-visualizações: executar `tests/open_world_preview.gd` com janela gráfica. Guarda a entrada, ambas as pontes, ruínas, mapa com descoberta e uma vista geral de revisão totalmente revelada em `output/`; esta última usa apenas uma cena de teste descartável e não altera o estado de uma partida.

A interface superior direita reúne o relógio com «Serra de Sintra» e os retratos e nomes, com contorno verde e dourado no personagem selecionado. `tests/depth_preview.gd`, com janela gráfica, guarda a aproximação, passagem e saída do arco, vegetação e ambas as seleções dos avatares em `output/`.

### Bosque húmido e extensão sul

A zona aberta tem agora 4800×5400 unidades (mais 50% de área). A entrada foi repintada com chão húmido, hera e musgo. A sul encontram-se o Bosque da hera, o Passadiço da ravina, a Escadaria dos musgos e a Encosta da muralha, com descoberta e conversas locais. Troncos altos e galhos próximos com paralaxe enquadram a exploração; a névoa fica abaixo dos personagens, que permanecem opacos. As versões e os prompts estão em `assets/world/ART.md`.

Verificação da extensão: `Godot --headless --fixed-fps 60 --path . --script res://tests/humid_world_test.gd`.

### Fauna autónoma

A floresta tem uma população persistente de pássaros, esquilos, seis raposas, rãs e borboletas, distribuída pelas árvores, clareiras e margens reais do mapa. Os animais continuam a agir fora da câmara; aproximar-se deles altera o comportamento, e correr aumenta a distância a que os personagens os assustam.

- **Pássaros:** seis bandos de quatro e oito aves solitárias. Voam entre árvores, evitam sobrepor-se em voo, pousam, procuram alimento no chão e recolhem-se à noite. Um alarme faz levantar o bando.
- **Esquilos:** exploram o chão, param para comer, fazem um pequeno salto de susto e fogem rapidamente de raposas e personagens, trepam ao tronco e desaparecem em cavidades visíveis. Só voltam a sair quando a ameaça se afasta; de noite ficam abrigados.
- **Raposas:** alternam corridas rápidas, farejar e descanso. Ao ver um esquilo acessível, perseguem-no imediatamente, independentemente da fome; a aproximação dos personagens tem prioridade e provoca fuga. Ao arrancar de paradas para uma corrida, fazem um salto curto de mudança de direção. A sede continua a levá-las à margem para beber. São seis no mundo; a curiosidade pode levá-las a observar brevemente o jogador num canto visível do ecrã, a distância segura, antes de fugirem novamente.
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


### Serra dispersa e cachorro dos Capuchos — 30 outubro

O mapa tem **12000×7560 unidades**, exatamente o dobro da área da versão de 8400×5400. Os seis locais ficam separados por mais de 2400 unidades: **Pedras Irmãs** no noroeste, **Mata Relíquia dos Capuchos** nos bosques do norte, **Gruta de Adrenunes** no extremo nordeste, **Convento dos Capuchos** nos bosques centrais, **Tholos do Monge** a sudoeste e **Pedra Amarela** nas encostas do sudeste. Cada um tem descoberta, conversa, pintura própria, recortes de profundidade e bases sólidas com entradas livres. O mapa mantém descoberta progressiva e afasta as legendas para evitar sobreposições.

As seis pinturas individuais têm 1254×1254 px para áreas de 1600×1600 (1400×1400 nas Pedras Irmãs): pelo menos 0,784 px por unidade, comparados com os 0,603 do terreno original. Foram criadas com a ferramenta de imagem integrada, usando a pintura original e as fotografias já consultadas. [Arte, referências e prompts](assets/world/heritage/ART.md). A organização do mundo está em `scripts/sintra_heritage.gd` e `scripts/sintra_expansion.gd`.

Entre os locais há floresta com árvores independentes, hera, fetos, clareiras e caminhos, mais urzes e granito nas encostas expostas, pequenos charcos com rãs, folhas flutuantes e flores, bancos e objetos soltos. Novos bandos, esquilos, raposas e borboletas residem nas novas regiões e usam os mesmos comportamentos da floresta anterior. A vegetação próxima e a névoa acompanham os bosques húmidos.

Junto ao Convento dos Capuchos vive um **cachorro pequeno, fofo e desconfiado**. Ladra e guarda um território limitado. Ração pode ser encontrada nos caminhos e junto aos bancos, incluindo uma pequena reserva a sul do convento. Ocupa porte 1 na bolsa. **Espaço**, com ração e a alguma distância do cachorro, deixa comida no chão; clicar na ração da bolsa perto do convento também funciona. Ambos devem recuar e ficar quietos. Ele só se aproxima para comer quando se sente seguro.

Uma refeição não basta: depois de pelo menos duas ofertas, o cachorro passa a escolher aproximar-se de alguém parado. É ele que faz o caminho e cheira durante alguns segundos; avançar para ele interrompe a aproximação. Após encontros repetidos, fica junto da pessoa e pede contacto. **Espaço** aceita esse pedido com uma festa suave. Só a combinação de comida, aproximações voluntárias, cheiro e festas estabelece amizade. Um painel aparece apenas nas proximidades e indica o que ele comunica. A confiança e as descobertas mantêm-se durante a sessão, tal como o resto da partida.

Aproximar-se à pressa provoca um recuo na confiança e uma reação defensiva. Quando tenta morder, o cachorro **persegue sempre Jo**, independentemente de quem está selecionado ou de quem se aproximou; Te nunca é o alvo. A investida fica limitada aos arredores do convento. Jo recua perante o pequeno puxão à bota. Depois de confiar nos dois, o cachorro mantém-se nos Capuchos e aceita festas.

O relógio fica no canto superior direito, à esquerda dos retratos, com **Serra de Sintra**, hora, fase e dia. Pausa e mapa suspendem também o cachorro.

Verificação: `tests/heritage_world_test.gd` cobre área duplicada, distância entre os locais, detalhe nativo, fauna e flora residentes, percursos seguros, descoberta, conversas e entradas. `tests/puppy_test.gd` percorre a sequência de comida/espera/cheiro/festas, testa as investidas só ao Jo e a suspensão no mapa e na pausa. Executar com `Godot --headless --path . --script res://tests/NOME.gd`. `tests/heritage_preview.gd` e `tests/puppy_preview.gd`, com gráficos, guardam capturas em `output/`. As cenas de revisão são descartáveis e não alteram uma partida.

### Pequenas descobertas e rostos do cachorro

As juntas do chão foram corrigidas para evitar faixas vazias entre pinturas. As zonas repetitivas da expansão têm agora três clareiras abertas: um descampado com uma bola de futebol antiga, uma clareira de descanso e um recanto de pedras redondas. Seis placas de madeira envelhecida indicam locais reais do mapa; seis bancos adicionais mantêm dois lugares utilizáveis. Flores brancas de campainha, plantas de folhas prateadas e flores violetas, troncos com cogumelos, um regador enferrujado, um abrigo de insetos e um portão esquecido marcam outros pontos do caminho. As reservas de vegetação deixam cada encontro visível e os percursos livres. Alguns recantos têm descoberta no mapa e conversas próprias.

**Espaço junto à bola**, com qualquer dos dois, levanta-a com o pé e inicia uma ronda de toques. As **setas** posicionam o personagem sob a bola; **Espaço no momento do contacto** dá um novo toque. O Jo usa pé, joelho ou cabeça conforme a altura e a posição da bola, com três desenhos diferentes de cada tipo, além da recuperação. A precisão e a direção do movimento influenciam o novo arco: a bola também deriva para os lados. O Te tem três desenhos próprios e consegue apenas dois toques depois de levantar a bola: cada toque muda o rumo aleatoriamente e o segundo manda a bola para longe, terminando a ronda. É preciso ir buscá-la no chão para recomeçar. Carregar cedo ou longe falha; ao cair no chão termina também a contagem. Mapa, conversa e pausa suspendem o movimento.

[Sprites e prompt dos toques](assets/characters/football/ART.md). `tests/football_test.gd` verifica levantamento, gravidade, nove contactos, falhas de timing e profundidade, deslocação pelas setas, contagem e suspensão. `tests/football_preview.gd` mostra os contactos no motor.

[Três desenhos e prompt do Te](assets/characters/football/TE_ART.md). `tests/te_football_test.gd` verifica os dois contactos, a variedade de ângulos, a impossibilidade de um terceiro toque e uma ronda completa com setas e Espaço. `tests/te_football_preview.gd` mostra os apoios e contactos; `tests/football_motion_preview.gd -- --te` grava o movimento dos dois toques e da bola a escapar.

O cachorro apresenta três rostos pintados conforme a confiança, mesmo quando está simplesmente parado: **zangado e defensivo**, **cauteloso**, e finalmente **fofo e confiante**. O painel próximo inclui um retrato ampliado da mesma expressão para tornar o olhar legível. A alimentação, o cheiro e as festas continuam a estabelecer a amizade; as investidas continuam sempre dirigidas a Jo.

[Arte e prompts](assets/world/discoveries/ART.md). `tests/discoveries_test.gd` verifica percursos, descobertas, indicações, plantas, pontapé e suspensão da bola, e a seleção de rostos pela confiança. `tests/discoveries_preview.gd`, com gráficos, guarda os novos recantos e os três rostos em `output/discoveries-*.png`.

### Profundidade e volumes do cenário

O chão e a névoa ficam abaixo da camada ordenada pelos pés dos personagens. Pedras, troncos, ruínas e construções partilham essa ordenação: ocultam quem passa por trás e ficam por baixo de quem passa à frente. As copas e os fetos podem esconder parte do corpo; só os troncos e as bases sólidas bloqueiam a passagem. Galhos próximos continuam num primeiro plano separado.

Os recortes reutilizam os pixels das pinturas à resolução original. `scripts/terrain_scenery.gd` define os contornos e as bases das pedras do terreno original, da expansão, das clareiras e dos monumentos; `scripts/sintra_heritage.gd` define árvores e arquitetura. A física, a grelha de navegação, os percursos do companheiro e a fauna consultam as mesmas bases poligonais, com pesquisa espacial por regiões. A expansão respeita o espelhamento das texturas; o rio respeita a deformação usada pela pintura. Portas, arcos e pórticos têm peças separadas e aberturas utilizáveis.

`tests/scenery_depth_test.gd`, sem janela, verifica as bases na física real e na navegação, colisões do personagem e desvios do companheiro. `tests/scenery_rendering_test.gd`, com janela gráfica, compara os pixels de corpos e cenário nas duas ordens de profundidade e verifica a ocultação parcial pelos fetos. `tests/scenery_preview.gd` guarda capturas de revisão em `output/scenery-*.png`.

### Recortes das árvores e conversas com humor

As três árvores da Mata Relíquia usam máscaras vetoriais próprias para distinguir madeira, folhagem e aberturas. Os intervalos entre os ramos e a terra ficam transparentes na camada elevada; os troncos continuam opacos e sólidos. A pintura original é preservada, e a visibilidade da fauna consulta a mesma máscara. `tests/tree_cutout_rendering_test.gd`, com gráficos, verifica os pixels de chão e madeira nas três árvores.

`data/dialogue/sintra_banter.json` acrescenta **51 conversas, com 207 falas**, em português, sobre monumentos, descobertas, lanche, orientação, fotografias e o cachorro. Os temas alternam conforme o personagem que inicia, o local, a fase do dia e a confiança do cachorro. As conversas e os efeitos anteriores continuam disponíveis. **T** inicia e avança a conversa.

Ao examinar um objeto com **Espaço**, as «Notas do caminho» mostram agora o resultado e um comentário breve. `data/world_comments.json` contém variantes para evitar repetir sempre o mesmo texto. As notas respeitam mapa, pausa e conversas; não cobrem o painel do cachorro. `tests/banter_test.gd` verifica a disponibilidade e rotação de todas as conversas novas, os filtros e os comentários visíveis. `tests/banter_preview.gd`, com gráficos, guarda exemplos em `output/banter-*.png`.

### Ecossistema ao anoitecer — 31 outubro

A fauna acompanha o relógio partilhado. Durante o dia predominam pássaros, esquilos e borboletas; ao crepúsculo começam a aparecer os residentes noturnos, com atividade e luz a diminuir ao amanhecer. A madrugada continua a ter vida, incluindo depois da passagem da meia-noite.

- **Morcegos:** 28 residentes em sete colónias de quatro, abrigados nas cavidades das árvores. Saem periodicamente em grupo, com partidas ligeiramente desfasadas e separação em voo, fazem circuitos junto à vegetação, perseguem insetos e desviam-se das corujas. Regressam ao abrigo entre saídas e ao amanhecer.
- **Corujas:** catorze residentes distribuídas pela floresta, um aumento moderado de quatro. Voam entre árvores desocupadas e pousam em pontos definidos sobre os ramos pintados. Enquanto vigiam, os pés, o corpo e a orientação mantêm-se fixos; só a cabeça acompanha Te ou Jo, até 180° para cada lado. Cinco vistas pintadas, com transição entre elas e espelhamento lateral, mostram a frente, o perfil e a nuca. Os olhos amarelos sobressaem na noite e apanham ocasionalmente um reflexo breve quando a cabeça cruza a direção da luz, com um intervalo entre reflexos. Também fazem voos curtos de caça a morcegos, serpentes e rãs expostas; os pássaros afastam-se de uma coruja próxima, alertando o bando.
- **Pirilampos:** 80 pontos fixos no chão em vinte manchas de vegetação, flores e margens, incluindo a entrada e a expansão. Cada ponto tem fase e frequência próprias: o brilho aumenta e diminui sem deslocação nem altura de voo, mesmo quando é perturbado. Aparecem aqui e ali entre as plantas, com núcleo pequeno e halo suave; respeitam os recortes das copas, fetos e galhos.
- **Serpentes:** oito residentes noturnas nas margens do rio, com quatro poses pintadas de rastejar. Percorrem territórios pequenos, respeitam água e obstáculos, perseguem rãs expostas em terra e recuam ou escondem-se perante personagens e predadores. As rãs mergulham e as corujas podem aproximar-se em caça. Abrigam-se ao amanhecer e acompanham o alternador Dia/Noite.

As perseguições mantêm a população estável, como no resto da fauna. Os animais existem também fora da câmara, partilham os habitats anteriores e recolhem-se durante o dia. Mapa e pausa suspendem movimentos, saídas, rotação das cabeças e pulsos de luz.

Os novos atlas pintados foram criados com a ferramenta integrada image_gen e estão em `assets/wildlife/bat-flight.png` e `assets/wildlife/owl-modules.png`; os pedidos e referências estão em `assets/wildlife/ART.md`. Os contornos das poses de voo da coruja excluem fragmentos de poses vizinhas sem alterar a pintura original. A lógica está em `scripts/nocturnal_animal.gd`, o desenho em `scripts/nocturnal_art.gd` e a emissão em `scripts/firefly_glow.gd`.

Verificação: `Godot --headless --path . --script res://tests/nocturnal_wildlife_test.gd` cobre crepúsculo/amanhecer, colónias, seguimento a 180° com corpo imóvel, pouso em árvores reais, encontros entre espécies, limites dos habitats, população e suspensão. `Godot --path . --script res://tests/nocturnal_rendering_test.gd`, com gráficos, compara pixels do corpo e das vistas da cabeça, verifica as poses dos morcegos, a luminosidade após a iluminação noturna, o alinhamento com a câmara e a ocultação pela vegetação. Guarda `output/nocturnal-poses.png`, `output/nocturnal-forest.png`, `output/nocturnal-owl.png` e `output/nocturnal-fireflies.png`, usando apenas uma cena descartável de revisão.

As corujas têm íris amarelas discretas, com um pequeno reflexo visível à noite. Piscam em intervalos individuais e, por vezes, mantêm os olhos fechados brevemente; pálpebras e cor preservam a textura pintada. Em execuções de debug, o botão **Dia / Noite** junto à hora alterna diretamente entre dia (08:00) e noite (23:00), atualizando de imediato a luz e a fauna e mantendo a partida e o progresso. A opção não aparece em versões de distribuição.

### Vila de Sintra

A região da Vila de Sintra tem **22 400 × 16 000 unidades (10× a área anterior)**, com mais de 500 construções, ruas de comércio e habitação, largos e uma feira de cerâmica, tecidos e fruta, inspirados nas fotografias de Sintra. Entra pelo menu **Esc → Explorar a Vila de Sintra**, junto ao Palácio, e regressa pelo mesmo menu. A rede liga o largo do Palácio Nacional às Padarias/Piriquita, Ferraria, São Martinho, Lawrence’s, Valenças, Volta do Duche e aos jardins da Vila Sassetti. A placa **Vila de Sintra** a sul da entrada da mata abre o percurso reversível; **Espaço** permite seguir juntos. Os mesmos personagens, bolsas, conversas, mapas e relógio atravessam as regiões, com objetos e encontros preservados durante a sessão. A cena principal mantém-se `garden.tscn`; `scenes/sintra_village.tscn` permite revisão direta junto ao Palácio.

[Integração, fontes, simplificações e verificações](docs/VILA_DE_SINTRA.md). [Arte e pedidos de geração](assets/world/village/ART.md). Os testes `village_test.gd`, `village_transition_test.gd`, `village_walking_test.gd` e `village_rendering_test.gd` cobrem os novos percursos, transições, superfícies e profundidade. `village_preview.gd` produz capturas no motor em `output/village-*.png`.

A vila tem **145 personagens no elenco narrativo**, além de circulação ambiente de moradores e visitantes, com atividades animadas e quotidianos próprios: crianças, idosos, comerciantes, turistas, os amigos Gil, Tiago, Alexandre, Martim e Afonso, e quatro participações fictícias conhecidas. Aproxima-te e carrega em **Espaço** para cumprimentar. O elenco inicial está em [Pessoas da Vila](docs/PESSOAS_DA_VILA.md); as novas atividades e os cinquenta nomes adicionais estão em [Cidade viva](docs/CIDADE_VIVA.md).

Cada uma das 35 pessoas tem um quotidiano ligado às horas: trabalho e passeios, refeições em casas/cafés, deslocações por ruas livres e recolher. As crianças são acompanhadas por um adulto; os cinco amigos têm um encontro ao fim da tarde. [Rotinas e horários completos](docs/ROTINAS_DA_VILA.md).

A calçada de todos os quarteirões urbanos é transitável. A vila inclui fachadas de lado, quatro patamares com escadas curtas e 112 casas adossadas em 60 aglomerados. As ruas distinguem uma faixa central de granito e passeios claros; a pedra acompanha as curvas dos percursos. [Revisão da circulação e arquitetura](docs/VILA_DE_SINTRA.md).

A vila inclui agora visitas guiadas, montras, passeios em família, rifas dos escuteiros para a atividade de Minecraft, banca Nannarella, patrulha policial e concerto de guitarra e violino. Candeeiros e janelas respondem à noite. [Atividades, horários e iluminação](docs/VIDA_DA_VILA.md).

As primeiras 45 pessoas têm personalidade, ritmos e gestos próprios. Conversam por turnos, compram entre si, tiram fotografias, pedem indicações e reagem ao concerto sem depender da presença do jogador. Setenta poses adicionais dão expressão a estes encontros; memórias e compromissos do dia orientam o que fazem a seguir.

A expansão anterior levou a vila a **95 pessoas**, incluindo mais 50 vidas individuais e 21 turistas adicionais. Há cinema ao ar livre com público sentado, fruta da Dona Ana, roulotte de doces, campeonato de toques jogável, xadrez, magia, poesia, uma cadela a passear, dois tuk-tuks e uma carroça. O Tó reconhece-nos na rua e pára para meter conversa. [Atividades, elenco e funcionamento da cidade viva](docs/CIDADE_VIVA.md).


### Comunidade e pequenas histórias

A expansão [Sintra Living Open World](docs/SINTRA_LIVING_OPEN_WORLD.md) acrescenta trinta identidades (125 no total), dez moradores associados a janelas reais, o carteiro com doze moradas, 28 pombos reativos, o gato Sardinha, chapéu ao vento, campainhas, giz, fonte, trocas, escolhas e memória gravada. Há 24 episódios adicionais ligados aos horários e dias da vila. A documentação distingue o que está funcional e os limites das mecânicas.

A revisão [Individualidade da vila](docs/INDIVIDUALIDADE_DA_VILA.md) dá aos 125 NPCs expressões e vistas de caminhada próprias, ritmos por idade, quatro ciclos de bengala com apoio real e crianças a correr. Seis novas esplanadas e cinco bancos recebem treze pessoas com rotinas visíveis de pequeno-almoço e almoço.

A expansão [Histórias da rua](docs/HISTORIAS_DA_RUA.md) acrescenta vinte personagens desenhadas de novo: um piquenique, correio de pombo, a fila da Piriquita, a janela da Odete, matraquilhos jogáveis, rifas burocráticas e os testes espalhados na esplanada. A circulação ambiente cobre os percursos secundários e responde aos turnos do dia; há entradas nas lojas e rostos apenas nas janelas realmente ocupadas.

A vila tem também [vida noturna no Lord Byron](docs/VIDA_NOTURNA.md), das 20:30 à 01:30: os mesmos habitantes chegam depois do jantar, conversam, dançam, pedem música e regressam a casa em horários diferentes.

A [ligação e as necessidades do Te e do Jo](docs/LIGACAO_E_NECESSIDADES.md) acompanham as atividades, desbloqueiam a escalada, a roda de ritmo e conversas novas, e ligam a fome à Pastelaria do Largo. As bolsas permitem comer ou partilhar, e o cansaço recupera a dormir no chão (×1) ou num banco (×0,25).
