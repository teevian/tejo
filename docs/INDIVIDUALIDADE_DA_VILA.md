# Expressões, movimento e refeições na vila

A revisão substitui a representação habitual dos **125 NPCs**. Os sorrisos permanentes deram lugar a expressões neutras, concentradas, curiosas, cansadas ou impacientes. As identidades, roupas e linguagem de gouache e lápis foram preservadas. Te e Jo mantêm integralmente os atlas e a caminhada aprovados.

## Desenhos e orientação

Cada pessoa tem duas poses de atividade próprias e dois pares de passadas: vista frontal a três quartos e vista traseira a três quartos. O sentido real do percurso escolhe o par; as figuras são espelhadas quando se deslocam para o outro lado. Cada par mantém o ângulo durante a alternância dos pés. As pessoas a conversar orientam-se para o interlocutor.

As poses especiais anteriores continuam a servir ações concretas: comer um gelado comprado, fotografar, tocar música, servir ou aplaudir. Uma expressão alegre pode aparecer nesses momentos, em vez de acompanhar todas as deslocações e esperas.

## Ritmos pessoais

- Crianças com menos de 13 anos correm, com braços opostos às pernas e passadas desenhadas para corrida. Mantêm as regras de acompanhamento dos adultos.
- Pessoas de 65–74 anos têm passos mais curtos e um ritmo inferior ao dos adultos; acima de 75 anos, o andar é ainda mais lento. Os percursos dos mais velhos concentram-se na vizinhança, em vez de compensar distâncias enormes com uma aceleração.
- António, Helena, Artur e Salim têm ciclos próprios de bengala, com oito desenhos por pessoa entre frente e costas. A fase de pousar inclui uma pausa real; seguem-se apoio, passo curto e avanço da bengala. Não recebem uma aceleração ao desviarem-se do jogador.
- Dinis mantém a corrida apressada; os carregadores têm passadas contidas. Duarte permanece na cadeira de rodas, com vistas próprias e movimento das mãos nos aros, sem o salto vertical comum de um peão.
- A duração das esperas e dos gestos continua a variar por pessoa e por atividade. Os sorrisos, poses e movimentos de Te e Jo não foram alterados.

## Refeições visíveis

Foram acrescentadas **seis esplanadas junto de cafés existentes**, com mesas, cadeiras, guarda-sóis e ementas ilustradas, e **cinco bancos de jardim**. As mesas têm uma base física representada na navegação. Os lugares de aproximação ficam em calçada acessível; os conjuntos de mesas procuram espaço livre da pintura das fachadas para os ocupantes não ficarem escondidos.

Lurdes, António, Celeste, Manuel, Matilde, Tomás, Leonor, Miguel, Gil, Tiago, Alexandre, Martim e Afonso têm pequeno-almoço e almoço no exterior. As reservas são independentes para cada refeição: o pequeno-almoço é escolhido perto da residência ou alojamento, o almoço perto da atividade da manhã. Matilde/Leonor e Tomás/Miguel partilham a mesa e os horários.

As pessoas caminham até ao lugar, aproximam-se devagar, sentam-se, levantam a chávena ou o sumo, comem e baixam a colher para ouvir os outros. Retomam a atividade seguinte quando a refeição termina. Há falas próprias durante as refeições, sem bloquear a circulação nem depender da presença dos protagonistas. Não foi acrescentada uma animação completa de transição entre estar de pé e sentar.

## Arte final e fontes de autoria

Foi utilizada a ferramenta **ImageGen integrada**, com os NPCs e objetos existentes como referências de identidade e estilo. Os PNGs finais foram copiados para o projeto sem edição de píxeis por scripts. A ferramenta de medição apenas lê o alpha, os limites e os apoios dos pés.

- `assets/characters/villagers/individual-{residents,street,festival,living}-*.png`: 26 folhas de atividades, duas poses por pessoa.
- `assets/characters/villagers/locomotion-{residents,street,festival,living}-*.png`: 26 folhas de passadas, quatro poses por pessoa.
- `assets/characters/villagers/individual-canes-*.png`: duas folhas com os quatro utilizadores de bengala.
- `assets/characters/villagers/individual-meals-*.png` e `individual-lunch-*.png`: seis folhas com 52 poses de refeição.
- `assets/characters/villagers/individual-teodoro.png` e `individual-prumo.png`: espera/leitura no banco e substituto original da aparição ficcional.
- `assets/world/village/individual-terraces.png`: oito elementos de mobiliário e refeições.

Os prompts finais completos estão em [atividades](../data/village/individuality-activity-prompts.json), [passadas](../data/village/individuality-walk-prompts.json), [bengalas, refeições e objetos](../data/village/individuality-extra-prompts.json) e [correção de transparência](../data/village/individuality-alpha-prompt.json). O recorte e os apoios finais estão em `data/village/individuality-art.json`; `tools/measure_village_individuality.py` volta a medi-los sem modificar as imagens.

## Verificação

`tests/village_individuality_test.gd` verifica os 125 elencos de poses, a escolha de vistas traseiras, a distância real percorrida por criança/adulto/utilizador de bengala, a pausa de apoio, os percursos até aos lugares e as 13 rotinas de pequeno-almoço e almoço, incluindo a saída para a atividade seguinte. Os testes de rotinas incluem agora o estado de refeição no exterior.

`tests/village_individuality_preview.gd` guarda cinco vistas reais do jogo em `output/village-individuality-*.png`. Mantêm-se os testes de personagens aprovadas, caminhada, interações, cinema, veículos e acontecimentos da comunidade.

Verificação concluída em 4 de novembro de 2026:

- Passaram o teste de individualidade e as 13 rotinas reais de ambas as refeições, sem reposicionamentos instantâneos.
- Passaram os 35 quotidianos originais, o dia completo das 50 personagens da expansão, cinema, cão e veículos.
- Passaram as conversas e compras autónomas, as entregas a portas reais, o banco de Teodoro e os 24 episódios ao longo de oito dias.
- Passaram a renderização gráfica dos protagonistas, a caminhada, as interações e a verificação dos hashes, geometria e escala dos atlas aprovados de Te e Jo.

As conversas ocasionais e os desvios de espera deixam agora intactos os destinos de entregas e da aproximação ao banco. O teste do carteiro confirma também que passar junto do jogador não substitui a morada por um desvio.
