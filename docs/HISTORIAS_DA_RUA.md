# Vizinhos, pequenas comédias e ruas habitadas

Esta expansão acrescenta **20 personagens com história própria**, elevando o elenco narrativo de 125 para 145. Existem ainda **229 figurantes de circulação**: 211 moradores/visitantes diurnos e 18 turnos noturnos. Estes figurantes reutilizam o guarda-roupa pintado do elenco anterior; não são apresentados como 229 novos retratos autorais. As vinte personagens das histórias têm desenhos novos e exclusivos.

## As sete situações

| Situação | Personagens novas | O que acontece no mundo |
|---|---|---|
| Piquenique em Sassetti | Rosário, Nelson, Íris e Léo | Rosário distribui sandes e encontra a caixa vazia; Íris come enquanto desenha uma merenda intacta; Nelson luta com o termo; Léo acompanha formigas. Ajudar a abrir o termo muda o objeto e as poses do Nelson. O grupo reúne-se às 11:20 e volta para a merenda às 16:10. |
| Correio de pombo na Fonte da Pipa | Ernesto e Olinda | Um pombo identificado por uma anilha leva o bilhete fisicamente até à Olinda e regressa com uma fatura. Os contadores só avançam à chegada. A entrega é interrompida se os participantes saírem para outra tarefa. |
| Fila da Piriquita | Beatriz, Ricardo e Estela | Beatriz desenha e reorganiza, Ricardo cronometra, Estela defende o lugar. Beatriz entra realmente na Piriquita, sai e percebe que não recolheu os pedidos. O jogador pode esclarecer os pedidos ou sugerir que oiçam a Estela. |
| A janela e a novela | Odete e Fausto | Odete observa personagens que passam e refere nomes e horas reais. Das 18:20 às 18:40 recolhe para ver televisão; Fausto aproveita para entregar um cabaz numa porta e regressa. A janela pertence a um prédio real nas Portadas. |
| O antigo campeão dos matraquilhos | Tóni, Dora e Simão | Dora e Tóni disputam jogadas; Simão regista o resultado e o avô contesta os golos. A mesa tem colisão real. O jogador pode jogar até três golos, escolhendo o remate conforme a defesa anunciada da Dora. |
| As rifas demasiado sérias | Vasco, Lia e Raul | Vasco carimba e procura uma caneta; Lia vende sem burocracia; Raul só quer ir almoçar. Uma caneta emprestada pelo Rúben pode ser levada ao Vasco. A rifa numerada entra na bolsa e não pode ser duplicada por repetir a conversa. O objetivo é a atividade de Minecraft do agrupamento. |
| Os testes na esplanada | Margarida, Sara e Rúben | Margarida corrige e intervém nas conversas; Rúben tenta servir uma bica entre os papéis. Uma rajada espalha cinco folhas acessíveis. Podem ser apanhadas e devolvidas; Sara reconhece uma conta sua. A posse e a devolução são reais, usando a bolsa existente. |

Cada pessoa tem voz, idade, propósito, horários, passadas frontais/traseiras e quatro poses de atividade/reação. As durações dos gestos estão escritas individualmente em `beats`, em vez de todos partilharem uma alternância. As reações à rajada e ao jogo têm causa própria; Nelson só usa as poses de servir café depois de o termo abrir. As deslocações e entradas nas lojas seguem os caminhos e portas existentes. Os compromissos seguintes libertam os participantes.

## Presença entre os largos

A cobertura usa **516 amostras da rede pública** e não depende da posição da câmara. A circulação é criada uma vez, com identidades estáveis, circuitos locais, portas, pausas e turnos. Há visitantes que conversam, param e entram em lojas, em vez de surgirem por teletransporte ao virar a esquina.

Cinquenta compromissos de personagens móveis anteriores foram distribuídos por percursos menos ocupados, preservando refeições, cinema, famílias, comerciantes, cães e veículos. Os figurantes complementam esses percursos. Os 18 turnos noturnos mantêm presença nos núcleos da vila enquanto a população diurna descansa; a noite tem menos circulação. As visitas a lojas só se iniciam entre as 09:00 e as 19:00.

Foram ligados **86 pontos adicionais de janela** às portas efetivamente usadas pelos moradores. Um rosto só aparece se a pessoa estiver dentro daquele edifício, durante um período acordado. Uma pessoa não tem simultaneamente corpo na rua e rosto à janela. A ocupação é arbitrada por vão: vários hóspedes não se sobrepõem na mesma janela, e as personagens permanentes à janela têm prioridade.

A medição de um dia contínuo encontrou atividade nas 18 áreas de referência em todos os horários auditados. Entre 512 e 516 das 516 amostras tinham alguém a menos de 1050 unidades nas medições realizadas. Isto é uma verificação de distribuição; não significa que cada enquadramento tenha permanentemente uma pessoa visível, sobretudo durante entradas em lojas e mudanças de turno.

## Arte e integração

Foi usada a ferramenta **ImageGen integrada**, com o elenco e o mobiliário existentes como referências de estilo. Os PNGs finais foram copiados sem edição de píxeis por scripts. A medição de alpha só escreve recortes, apoios e escalas no manifesto. Um material específico limpa o alpha residual das novas figuras sem alterar os PNGs nem os materiais dos protagonistas.

- `assets/characters/villagers/neighbours-activity-*.png`: cinco folhas, 40 poses de ação.
- `assets/characters/villagers/neighbours-reaction-*.png`: cinco folhas, 40 reações.
- `assets/characters/villagers/neighbours-walk-*.png`: cinco folhas, 80 passadas/vistas.
- `assets/world/village/neighbours-objects.png`: oito objetos, incluindo toalha, termo fechado/aberto, mesa de matraquilhos, balcão de rifas e testes.
- `assets/world/village/neighbours-pigeon.png`: oito poses do pombo, incluindo os voos com bilhete e fatura.
- [Pedidos completos de ação e reação](../data/village/neighbourhood-image-prompts.json), [passadas](../data/village/neighbourhood-walk-prompts.json) e [objetos e correções finais](../data/village/neighbourhood-extra-prompts.json).
- `data/village/neighbourhood-art.json` e `tools/measure_village_neighbours.py`: geometria de recorte e apoios, sem manipulação dos desenhos.

Os atlas, proporções e caminhada aprovados de Te e Jo mantêm-se intactos. A população antiga e as suas histórias continuam disponíveis.

## Participação e memória

Aproximar e usar **Espaço** mantém o sistema habitual de interação. Os diálogos têm escolhas; **Esc** fecha-os e liberta os protagonistas. O mundo continua a avançar durante a conversa. Rifas, caneta e folhas usam a bolsa de cinco lugares, com verificação de capacidade antes da transação.

As entregas, resultados, empréstimos e devoluções são guardados na memória comunitária existente. As folhas apanhadas não reaparecem ao voltar à vila. As que ficaram por apanhar podem ser reconstruídas no mesmo dia sem duplicar as que já estão na bolsa. Uma partida interrompida de matraquilhos não conta como vitória. Os testes nunca leem ou substituem a gravação do jogador.

Os matraquilhos são uma pequena partida por decisões de remate, com bola visível e resultado, e não um simulador físico completo de todas as varetas. O material original dá quatro vistas de caminhada a cada nova personagem por espelhamento dos pares frontais e traseiros; não são oito vistas autorais distintas. A conversa da Odete resume observações reais da vizinhança, sem seguir cada pessoa pela vila inteira.

## Verificação

- `tests/village_neighbourhood_test.gd`: dia contínuo das vinte pessoas sem teletransporte; sete histórias autónomas; cobertura por zona e rua; entradas nas lojas; novela da Odete; correio de pombo; partida jogável; rifas, caneta, recolha e devolução de testes; limpeza dos alvos de interação ao mudar a hora.
- `tests/village_neighbourhood_preview.gd`: oito capturas reais do jogo em `output/village-neighbours-*.png`.
- `tests/village_neighbourhood_audit.gd`: diagnóstico da cobertura por hora, das portas e dos quotidianos.
- As regressões de refeições, bengalas, conversas e comunidade mantêm-se separadas dos novos testes.

Em 5 de novembro de 2026 passaram o dia/noite contínuos e as interações das sete histórias, as regressões de comunidade, conversas, refeições e bengalas, cinema/veículos/cão/campeonato, a caminhada e as interações dos protagonistas e a renderização gráfica dos atlas aprovados. A verificação de hashes, dimensões e geometria de Te e Jo também passou.

A verificação do descanso também corrigiu a projeção de portas estreitas ao sincronizar a hora. Helena, que usa bengala, passou a ter alojamento numa porta real perto do seu circuito, em vez de atravessar a vila de madrugada para chegar ao hotel distante. A velocidade e o ciclo apoiado de bengala mantêm-se.
