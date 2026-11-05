# Pessoas da Vila de Sintra

A vila contém **35 personagens de fundo diferentes**: os 30 habitantes e visitantes iniciais e cinco amigos do Te e do Jo, sem contar os dois protagonistas. São moradores, famílias, comerciantes e visitantes: três crianças, cinco idosos e adultos com diferentes aparências, corpos e estilos de roupa. Duarte desloca-se em cadeira de rodas. Harry Kane, Rogério Colaço, Arlindo Oliveira e Inês Lynce aparecem em **participações fictícias**, com atividades próprias; as mensagens do jogo são texto narrativo original, não declarações reais dessas pessoas.

Entram na mesma visita à vila, pelo menu Esc ou pelo caminho da Sassetti. **Espaço**, de perto, permite cumprimentar cada pessoa e descobrir o que está a fazer. **T** continua a servir para as conversas entre o Te e o Jo. Não há novos botões nem seleção destes personagens.

## Elenco e atividades

| Pessoa | Atividade | Zona aproximada |
|---|---|---|
| Harry Kane | a fotografar o Palácio | Largo do Palácio |
| Rogério Colaço | a consultar o mapa | Largo do Palácio |
| Arlindo Oliveira | a ler à sombra | Miradouro da Ferraria |
| Inês Lynce | a tomar notas | Miradouro da Ferraria |
| Teresa · guia da vila | a orientar visitantes | Largo do Palácio |
| Dona Lurdes | a tricotar | Largo do Palácio |
| Senhor António | a passear de bengala | Largo das Hortênsias |
| Dona Celeste | a ler no largo | Largo dos Azulejos |
| Senhor Manuel | a ler o jornal | Largo do Palácio |
| Dona Emília | a regar os gerânios | Pátio das Portadas |
| Matilde | a jogar à macaca | Praça da República |
| Tomás | a brincar com a bola | Largo Ferreira de Castro |
| Aisha | a fazer bolas de sabão | Parque da Liberdade |
| Leonor | a fotografar a família | Praça da República |
| Miguel | a desenhar o largo | Largo Ferreira de Castro |
| Fátima · fruta | a escolher laranjas | Largo da Feira |
| Nuno · cerâmica | a limpar uma jarra | Largo da Feira |
| Sílvia · azulejos | a pintar cerâmica | Largo da Feira |
| Luís · padaria | a preparar pão | Piriquita |
| Samira · tecidos | a dobrar tecidos | Largo da Feira |
| Yuki | a fotografar azulejos | Fonte Mourisca |
| Amadou | a descobrir o caminho | Casas do Duche |
| Ingrid | a observar aves | Parque da Liberdade |
| Ravi | a comparar os mapas | Casario da Biquinha |
| Camila | a alongar antes da corrida | Caminhos da Sassetti |
| Duarte | a ler e passear no pátio | Pátio das Portadas |
| Beatriz | a desenhar as fachadas | Recanto Lord Byron |
| Farid | a tocar guitarra | Praça da República |
| Rosa · jardins | a varrer o passeio | Largo das Hortênsias |
| João · entregas | a procurar uma morada | Casario da encosta |
| Gil | a provar um travesseiro | Piriquita |
| Tiago | a combinar o percurso | Praça da República |
| Alexandre | a fotografar o jardim | Largo dos Jardins |
| Martim | a beber um café | Adro de São Martinho |
| Afonso | a escolher um azulejo | Largo da Feira |

## Amigos a partir das fotografias

Gil, Tiago, Alexandre, Martim e Afonso são amigos dos dois protagonistas. A associação às imagens foi indicada pelo utilizador: 1 → Gil, 2 → Tiago, 3 e 6 → Alexandre, 4 → Martim, 5 → Afonso. Existem cinco pessoas novas; as duas referências do Alexandre alimentam a mesma identidade. Os retratos originais não são distribuídos no jogo. As roupas visíveis nos retratos orientam a paleta de cada personagem; as atividades e as mensagens são cenas ficcionais da vila.

Cada amigo tem quatro desenhos completos: duas poses de atividade e duas passadas. Gil, Martim e Afonso fazem também passeios curtos. Os cumprimentos reconhecem o Te e o Jo e mantêm memória do encontro.

## Vida na cidade

As 35 pessoas têm agora horários próprios: pequeno-almoço, deslocações, atividades de manhã e à tarde, almoço, jantar e recolher. Não se deslocam instantaneamente quando muda a hora: partem do ponto onde estão e usam as ruas da vila. A chegada inicia a atividade ou a entrada no edifício. O ritmo de viagem tem em conta os percursos mais lentos do senhor António e de Duarte.

Os comerciantes regressam ao trabalho depois de pausas desencontradas. Os visitantes percorrem locais diferentes ao longo do dia. As três crianças deslocam-se com um adulto; os cinco amigos convergem num encontro ao fim da tarde. As refeições e o descanso acontecem em interiores representados por entradas reais de casas, cafés e alojamento. Quem está dentro não aparece como alvo de cumprimento.

O mesmo relógio controla a luz e as rotinas. Mapa e pausa suspendem ambos. A vila inativa não continua a simular movimentos, mas a revisita atualiza o quotidiano para a hora presente, preservando identidades e encontros. A sessão continua sem gravação em disco. Consultar [Quotidianos da Vila](ROTINAS_DA_VILA.md) para os 35 horários completos.

## Organização

- `data/village/residents.json`: trinta e cinco identidades, aparência/altura, atividade, mensagem, posição e passeio local.
- `data/village/daily-routines.json`: horários individuais, destinos, refeições, recolher e acompanhantes.
- `scripts/village_routines.gd`: destinos públicos, entradas reais e atualização após tempo fora da vila.
- `data/village/resident-art.json`: recortes nativos, apoios e proporções de pose.
- `scripts/village_population.gd`: criação única, posições livres e circulação/cedência de passagem.
- `scripts/village_resident.gd`: estados e movimento local de cada pessoa.
- `scripts/village_resident_art.gd`: pintura dos atlas com o material e a escala do jogo.
- `assets/characters/villagers/ART.md`: oito ficheiros finais, referências institucionais, ferramenta integrada e pedidos completos.

Não foram alterados os atlas aprovados do Te e do Jo, a sua escala ou `open_world_art.gd`. Os sprites novos estão numa pasta própria.

## Verificação e capturas

`tests/village_population_test.gd` confirma 35 identidades e recortes diferentes, variedade de idades, quatro participações conhecidas, acesso às posições, animação das atividades, movimento real pelos percursos locais, cumprimento e memória, suspensão no mapa/pausa e persistência após sair e regressar. `tests/village_walking_test.gd` faz a travessia física da vila povoada com a dupla e verifica bancos e arcadas. As regressões de desenho, interações e personagens mantêm-se separadas.

`tests/village_population_preview.gd`, com gráficos, guarda `output/village-people-palace.png`, `market.png`, `families.png` e `patio.png` com o mesmo prefixo. A galeria completa é `output/village-people-cast.png`, renderizada pelo Godot com os mesmos recortes e proporções usados no cenário. São cenas de revisão descartáveis.

`tests/village_friends_preview.gd` guarda uma galeria dos cinco amigos em `output/village-friends-cast.png` e uma captura no jogo de cada um com o prefixo `output/village-friends-`. O teste de população verifica também a associação dos seis retratos às cinco identidades, os cumprimentos de todos os amigos e a sua persistência na revisita.

`tests/village_routines_test.gd` simula o dia inteiro, incluindo a madrugada seguinte, com os percursos reais e os horários dos 35 personagens.

Há também dez novos participantes de grupos e atividades, elevando o total da vila a 45 pessoas. Ver [Vida da Vila](VIDA_DA_VILA.md).
