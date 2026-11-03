# Vila de Sintra — região de exploração

Implementação e investigação: 3 de novembro de 2026. Godot 4.7.2, Compatibility, macOS.

## Entrar e rever

A cena principal continua a ser `scenes/garden.tscn`. O menu **Esc → Explorar a Vila de Sintra** permite entrar diretamente; a primeira chegada pelo menu faz-se no largo do Palácio. Na vila, **Esc → Regressar à Serra de Sintra** devolve a dupla ao ponto de onde saiu, mantendo o estado da sessão. Na entrada da mata, caminhar para sul até à placa **Vila de Sintra · Pela Vila Sassetti** e carregar em **Espaço**. A chegada faz-se no caminho superior dos jardins; a descida passa pela Sassetti e pelo Largo Ferreira de Castro até às ruas comerciais e ao Palácio. A placa **Serra de Sintra** permite regressar. Objetos aos pés têm prioridade sobre a placa.

`scenes/sintra_village.tscn` abre a mesma região diretamente, junto ao Palácio, para revisão no editor/F6. Usa o mesmo controlador de exploração, sem construir a serra. Controlos: setas/WASD, duplo toque para correr, Tab para trocar, T para conversar, Espaço para interagir, M para o mapa e Esc para pausa. O botão de escalada continua associado à serra.

O retângulo da região tem **22 400 × 16 000 unidades**: 358 400 000 unidades quadradas, **exatamente dez vezes a área anterior** de 6400 × 5600. A escala dos personagens mantém-se. A vila contém **547 construções**, incluindo sete peças emblemáticas e 540 fachadas de comércio/habitação, **78 percursos** e **13 largos, praças e jardins públicos**, além do piso das arcadas. Há dez bancos de dois lugares, catorze observações e dezassete conversas. O novo Largo da Feira tem bancas de fruta, loiça, azulejos, tecidos e lembranças; os pátios de habitação, esplanadas, vasos, balaustradas, pelourinho, fontes, candeeiros e bandeirinhas dão identidade aos bairros.

## Continuidade da sessão

O controlador mantém os mesmos dois personagens e as suas bolsas, o mesmo diretor de diálogo e um único relógio. Cada mundo conserva a sua instância: objetos recolhidos, objetos largados, descobertas de interação e encontros não são reconstruídos. O mapa mantém dois conjuntos de terreno explorado e locais descobertos. Seleção e efeitos narrativos acompanham os personagens.

Ao sair, ficam reservadas duas posições livres junto ao acesso. O mundo inativo fica oculto e suspenso, incluindo os filhos com processamento explícito. Os seus corpos saem do espaço físico através de `CollisionObject2D.DISABLE_MODE_REMOVE`; os personagens são transferidos antes dessa suspensão. A entrada da escalada conserva a sua suspensão anterior e continua disponível depois de visitas à vila. O relógio avança apenas no mundo ativo; mapa e pausa continuam a suspendê-lo. Não há gravação em disco.

`scripts/exploration_navigation.gd` e `scripts/exploration_props.gd` extraem as regras já existentes de navegação, mobiliário e vegetação. O controlador, o mapa, os diálogos e as interações são partilhados. A vila não instancia a floresta, o cachorro dos Capuchos nem a sua população de fauna. Nesta versão não há fauna urbana própria.

## Geografia e fontes

As posições relativas e ligações foram verificadas antes da construção com um extrato público da API OpenStreetMap e fontes municipais/Parques de Sintra. `data/village/osm-reference.json` guarda os troços, identificadores e coordenadas consultados. Os identificadores `source_way` de `layout.json` relacionam o núcleo adaptado com essa referência. A ampliação usa também as **42 fotografias fornecidas pelo utilizador**: praças do centro, calçada de losangos, fachadas altas encostadas, azulejos, varandas de ferro, bifurcação Lord Byron, montras, bancas e escadas com vasos. Estas fotografias orientam a composição e a arte original, sem as transformar em texturas. Os bairros e pátios adicionais são interpretação jogável; não constituem um levantamento cadastral nem uma reprodução exata das lojas ou da quantidade de ruas reais.

- [OpenStreetMap, centro de Sintra](https://www.openstreetmap.org/#map=18/38.7960/-9.3890): ruas, cruzamentos, escadas, edifícios e limites do parque. **© OpenStreetMap contributors**, [ODbL 1.0](https://www.openstreetmap.org/copyright). Extrato obtido em 03/11/2026 na caixa −9.397,38.792,−9.381,38.801.
- [Roteiro municipal do Centro Histórico](https://cm-sintra.pt/sintra/cultura/roteiros-culturais/roteiro-do-centro-historico-de-sintra): núcleo da Vila Velha, património e relação entre ruas, comércio e antigos hotéis.
- [Roteiro Medieval](https://cm-sintra.pt/sintra/cultura/roteiros-culturais/roteiro-medieval): malha urbana e escadinhas Félix Nunes.
- [Vila Sassetti, Parques de Sintra](https://www.parquesdesintra.pt/pt/parques-monumentos/vila-sassetti/), [acessos](https://www.parquesdesintra.pt/pt/planear-a-visita/como-chegar/) e [percurso pedestre](https://www.parquesdesintra.pt/pt/programacao/percurso-pedestre-vila-sassetti/): entrada no Largo Ferreira de Castro, vertente norte, caminho sinuoso de piso regular e ligação à Pena/Castelo. Torre circular lombarda e relação entre arquitetura, rocha e jardim.
- [Roteiro municipal das Fontes](https://cm-sintra.pt/sintra/cultura/roteiros-culturais/roteiro-das-fontes-de-sintra): Fonte Mourisca na Volta do Duche, arco de ferradura e três arcos menores.
- [Parque da Liberdade, Visit Sintra](https://visitsintra.travel/pt/visitar/parques-e-jardins/parque-da-liberdade): acesso pela Volta do Duche.
- [Palácio Valenças, Paisagem Cultural de Sintra](https://paisagemcultural.sintra.pt/patrimonio/zona-especial-de-protecao/arquitetura-aulica/palacio-municipal-de-valencas.html) e [Roteiro Romântico municipal](https://cm-sintra.pt/sintra/cultura/roteiros-culturais/roteiro-romantico): volumes, loggias, cantarias e implantação junto ao parque.
- [Piriquita, Comércio com História](https://www.comerciocomhistoria.gov.pt/listings/piriquita-antiga-fabrica-de-queijadas-3708/): identificação na Rua das Padarias. Fotografias de rua consultadas mostram azulejos amarelos, portas brancas e letreiro escuro.
- [Lawrence’s, Paisagem Cultural de Sintra](https://paisagemcultural.sintra.pt/patrimonio/zona-especial-de-protecao/arquitetura-publica/hotel-lawrence-s.html) e [documentação do hotel](https://www.lawrenceshotel.com/media/pdfs/lh_event_esp.pdf): Rua Consiglieri Pedroso, reboco ocre/rosa, cantarias, portadas e telhados.
- Fotografias de referência consultadas: [Palácio Nacional, Parques de Sintra](https://www.parquesdesintra.pt/en/maps/), [Piriquita na Rua das Padarias](https://portugaletcetal.blogspot.com/2019/01/piriquita-doces-portugueses-em-sintra.html), [São Martinho](https://www.brasilianatrilha.com/igreja-de-sao-martinho-sintra-portugal/) e as fotografias municipais nas páginas anteriores. As fotografias orientam silhuetas e materiais; não são texturas do jogo.

O PDF turístico municipal de 2019 encontrado na pesquisa devolveu 404 na abertura direta. Foi substituído pelos dados OSM e pelas páginas municipais. O mapa Sassetti da Parques de Sintra foi consultado através da sua página, mas a leitura automática da segunda página do PDF falhou. Não foi obtido um levantamento altimétrico nem uma ortofoto/satélite utilizável; as cotas são uma interpretação visual das fontes de percurso e da encosta, sem alegar exatidão topográfica.

## Simplificações deliberadas

O norte fica aproximadamente para cima. O Palácio está a norte do núcleo comercial; São Martinho e Lawrence’s ficam a oeste; Valenças, Duche e Liberdade a leste; Ferreira de Castro e Sassetti a sul, na subida da encosta.

Preservam-se as ligações Padarias–Ferraria, Costa do Castelo–Ferreira de Castro, Fonte da Pipa–Navarro–acesso Sassetti, Biquinha/Gil Vicente/Consiglieri Pedroso, Terreirinho/Audiência e o ramo oriental Duche/Visconde de Monserrate. As curvas pequenas e sequências de escadas foram reduzidas a troços legíveis. A ampliação prolonga as ligações do núcleo e acrescenta circuitos de habitação a poente, no Duche e na encosta sul. Os lotes fecham-se em filas de fachadas, com ruas laterais e pátios; o terreno mineral dos quarteirões substitui as antigas faixas de floresta entre lojas. As praças mantêm dimensões próprias, sem aumentar todos os seus elementos na proporção do mapa. Os números de portas e a quantidade de fachadas não reproduzem um cadastro.

O Parque da Liberdade liga os seus acessos; os jardins da Sassetti conservam uma bifurcação e uma escadaria. A vegetação concentra-se nestes jardins e nos limites da vila. A aproximação à Sassetti contorna a base do edifício, em vez de a atravessar. O percurso além da placa superior é comprimido até à mata já existente: não representa um acesso real direto a todos os locais dispersos da serra. Nenhum monumento anterior foi deslocado. Regaleira, Seteais, Monserrate, Castelo e Pena são apenas sugeridos por observações/indicações; os locais já existentes na serra mantêm-se.

O Largo da Feira, Largo das Hortênsias, Largo dos Azulejos, Pátio das Portadas e Largo dos Jardins dão destinos aos novos circuitos; as designações dos espaços adicionais identificam a interpretação do jogo. A passagem Lord Byron chega à fachada cor-de-rosa por um pequeno recanto próprio.

As silhuetas dos edifícios são interpretações pintadas, sem interiores visitáveis. As três arcadas do Palácio têm chão, aberturas e pilares físicos separados. Outros portais representados como fechados permanecem sólidos. Escadas são chão contínuo, sem plataformas nem física de escalada. O perímetro navegável corresponde aos caminhos e espaços públicos representados; os intervalos de vegetação e propriedades ficam fora da circulação.

## Organização e arte

`layout.json` separa ruas, escadas, jardins, largos, bairros, monumentos, mobiliário e posições de chegada; `frontages.json` identifica cada fachada e a sua base física; `art-regions.json` regista os recortes nativos dos atlas. `tools/build_village_layout.py` guarda as coordenadas de referência e as regras determinísticas de autoria, para regenerar esses dois ficheiros. Não se sorteiam edifícios durante a partida. `sintra_village.gd` coordena arquitetura, objetos e bases; terreno, arquitetura e pequenos elementos têm scripts separados e nós nomeados. Todas as construções são corpos independentes na ordenação pelos pés; árvores e muros têm bases próprias. A física e a procura de caminho usam as mesmas bases, com perímetro físico dos caminhos.

A navegação e as colisões consultam índices espaciais locais. A grelha tem 350 000 células; o cálculo do piso e do perímetro físico percorre apenas as ruas e espaços públicos rasterizados. Isto evita comparar cada célula com as centenas de edifícios. O cenário inativo continua suspenso.

As capturas atuais da serra foram observadas no motor antes da implementação. Os pedidos e referências da arte inicial constam de `assets/world/village/ART.md`; os três novos assets, dimensões, referências das fotografias e pedidos finais completos constam de `assets/world/village/URBAN_ART.md`. As novas fachadas têm dois a quatro pisos e escala de portas própria, sem aumentar os personagens. Bancos, árvores, fetos e objetos de inventário reutilizam a arte existente. As placas são elementos de interface do cenário, ao estilo das indicações anteriores. A iluminação passa pelo mesmo filtro de dia/noite, incluindo personagens. O descanso/desenho no chão só começa em terra dos jardins ou caminhos florestais, com espaço disponível; nunca na calçada ou em escadas. Os contornos da calçada são desenhados antes de todos os pisos, para não surgirem costuras a atravessar cruzamentos ou praças.

Os dois atlas direcionais aprovados, o manifesto, `world_scale.gd` e `open_world_art.gd` foram preservados. A única alteração de comportamento do personagem é consultar a superfície antes de procurar um lugar para desenhar. A espera do Te continua a ser sentar-se a desenhar.

## Verificação

- `village_test.gd`: área exatamente 10×, mais de 500 edifícios, inicialização isolada, todos os vértices da rede e aproximações dos locais, bases físicas, superfícies, conversas do Palácio e da feira com efeitos, mapa e pausa.
- `village_transition_test.gd`: entrada normal, três revisitas, identidades e bolsas, seleção, narrativas, mapas independentes, objetos recolhidos/largados, passagem da meia-noite, suspensão da fauna, posições de regresso e escalada após visitas.
- `village_walking_test.gd`, com `--headless --fixed-fps 60`: travessia por entradas reais com Te até à Sassetti e regresso conduzido pelo Jo por Pipa, São Martinho, Lawrence’s, Valenças, Duche, Liberdade, feira, bairro poente, azulejos, Portadas, Jardins e recanto Byron; acompanhamento, dez bancos, três arcadas e sentar a dupla.
- `village_rendering_test.gd`, com gráficos: comparação de píxeis atrás/à frente da fachada opaca e iluminação de dia/noite. Capturas `output/village-depth-*.png`.
- `village_menu_test.gd`: entrada pelo Esc junto ao Palácio, seleção preservada e regresso seguro ao ponto de saída.
- Regressões: `open_world_test.gd`, `walking_test.gd`, `interactions_test.gd`, `day_cycle_test.gd`, `dialogue_test.gd`, `climbing_transition_test.gd`, `scenery_depth_test.gd`, `rest_sequence_test.gd`, `startup_input_test.gd`; `character_rendering_test.gd` com gráficos.
- `node tools/check_approved_characters.cjs`: SHA-256, dimensões, pasta final, geometria e escala dos sprites aprovados.

Exemplo: `Godot --headless --path . --fixed-fps 60 --script res://tests/village_walking_test.gd`. Para capturas: `Godot --path . --script res://tests/village_preview.gd`. As revisões usam cenas descartáveis: não alteram a partida. O plano mais aberto do Palácio muda temporariamente o zoom só nessa revisão.
