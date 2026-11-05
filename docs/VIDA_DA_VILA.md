# Vida de rua na vila

A vila passa a ter 45 pessoas: os 35 habitantes e amigos anteriores, mais dez participantes novos. Os dois atlas direcionais aprovados do Te e Jo, a escala e a caminhada permanecem intactos.

## O que acontece

| Cena | Pessoas e local | Horário |
| --- | --- | --- |
| Visita guiada | Teresa com Oliver, Helena e, de manhã, Mariana; Palácio, Padarias, miradouro e República | 8h30–12h e 13h30–18h30 |
| Montras | Mariana alterna entre lojas reais de cerâmica, artesanato e padaria, com a orientação voltada para a fachada | 14h, 15h15 e 16h30 |
| Passeio em família | Daniel acompanha a Leonor e a Matilde, incluindo as deslocações, o almoço, o Palácio e o regresso a casa | 9h–18h45, com pausa de almoço |
| Rifas | Inês e Pedro, com a dirigente Joana; mesa na Praça da República | 9h–12h30 e 14h–17h45 |
| Nannarella | Enzo na banca do largo do Palácio | 11h–20h, pausa 14h30–15h |
| Concerto | Farid e Clara, guitarra e violino, no adro de São Martinho; visitantes juntam-se ao público | 18h–21h; montagem antes das 18h |
| Polícia | Agente Sofia circula entre Palácio, República, feira e adro; dá indicações e faz a ronda noturna | 8h–23h30, com pausa de almoço |

Os grupos fazem percursos reais e as pessoas mudam de atividade e local com o relógio. Os turistas acompanham a posição da guia; Daniel segue a família. As refeições e o descanso usam portas reais e as pessoas desaparecem no interior. O grupo de escuteiros recolhe antes da atividade de Minecraft do agrupamento.

Ao aproximar-se, **Espaço** permite cumprimentar, pedir indicações, comprar rifas ou gelados e aplaudir. Há comentários breves de quem está próximo, sem interromper o passeio. O concerto tem uma frase instrumental original; a música ouve-se junto aos músicos e perde volume com a distância.

A rifa entra na bolsa com número próprio e porte 1. Cada personagem pode comprar uma por dia; repetir a conversa não duplica o bilhete. Os cones de pistácio, morango e stracciatella alternam entre compras e também ocupam porte 1. Uma bolsa cheia impede a compra sem registar uma venda. Estas interações não acrescentam um sistema monetário ao jogo.

## Iluminação

Há 234 novos candeeiros de rua, colocados junto aos percursos com bases físicas pequenas e espaço de circulação livre. Acendem progressivamente ao fim da tarde e apagam ao amanhecer. Algumas centenas de vidros de janelas acendem em casas selecionadas; as cantarias e os caixilhos são preservados. Cada edifício tem horas de acender e apagar diferentes, com uma minoria de luzes durante a madrugada.

As fontes luminosas têm brilho quente depois do filtro noturno, conservando a posição, o espelhamento e a ocultação pelas fachadas da frente. A luz ambiente continua partilhada com a serra. Ao sair da vila, as novas pessoas, a música e as luzes ficam suspensas. Ao regressar, as atividades acompanham a hora atual; compras e cumprimentos permanecem na sessão. Mapa e pausa suspendem o relógio e a música.

## Personalidade e encontros autónomos

As 45 pessoas têm traços próprios de sociabilidade, curiosidade e inquietação, preferências por amigos, falas pessoais, comprimento de passada e durações de gestos. As sequências alternam preparação, ação, reação e descanso com tempos desiguais. A Matilde só salta durante a macaca; músicos alternam execução, afinação e pausas; leitores demoram-se numa página e levantam os olhos; comerciantes preparam os objetos e atendem clientes. Não se deformam partes dos desenhos.

Há 70 poses novas para 15 personagens, além dos atlas existentes: gestos de conversa e ciclos de aplauso dos cinco amigos, fotografia e revisão no telemóvel da Leonor, saltos e aterragem da Matilde, explicações da Teresa, gestos de guitarra e violino, cerâmica, rifas, gelados e rádio da polícia. Os aplausos alternam mãos abertas, contacto e pequenas pausas com ritmos diferentes para cada amigo. O gelado na mão dos amigos corresponde a uma compra concluída.

O sistema de encontros decide independentemente da posição do jogador e da câmara. Pessoas próximas podem aproximar-se, virar-se umas para as outras e conversar por turnos; os amigos têm preferência e reconhecem encontros anteriores. Há compras entre NPCs na Nannarella e nas rifas dos dois escuteiros, entregas do João a comerciantes, pedidos de indicações à Sofia, observações de montras em companhia, paragens explicadas da visita guiada e fotografias da família ou de outros adultos. O público aplaude e os músicos agradecem antes de continuar.

Os encontros reservam temporariamente os participantes, usam percursos reais e terminam libertando-os para o quotidiano. Só começam quando há tempo até ao próximo compromisso. Um novo compromisso ou uma interação do jogador cancela o encontro e liberta também os parceiros. Nada é comprado num encontro cancelado. Crianças permanecem no contexto da família; visitantes continuam ligados à guia.

As memórias de encontros, fotografias, rifas e gelados duram a sessão, com limites à repetição de compras e pausas entre conversas. Os cumprimentos podem referir o que acabou de acontecer. Saltos de hora e o regresso à vila limpam reservas e gestos temporários; mapa e pausa suspendem o conjunto. As falas próximas são desenhadas acima dos objetos da rua, por turnos e com separação para evitar sobreposição.

## Dados, arte e verificação

- `data/village/street-life.json`: elenco adicional, horários e objetos de atividade.
- `data/village/street-life-art.json`: regiões e apoios nativos dos atlas.
- `data/village/window-glass.json`: vidros nas pinturas existentes, incluindo fachadas espelhadas.
- `scripts/village_street_life.gd`: grupos, horários, compras e interação.
- `scripts/village_lighting.gd` e `village_light_overlay.gd`: luzes, horários e ocultação.
- `scripts/village_concert.gd`: frase original e volume pela distância.
- `data/village/npc-personalities.json`: 45 perfis, ritmos, amigos e falas.
- `data/village/social-art.json`: 70 regiões nativas com apoios, sem alterar os atlas aprovados.
- `scripts/village_character_motion.gd`: sequências e ritmos individuais.
- `scripts/village_social_life.gd`: encontros, reservas, aproximação, respostas e memória.
- [Ficheiros de arte e pedidos completos de ImageGen](../assets/world/village/LIFE_ART.md).

`tests/village_life_test.gd` verifica destinos, visitas guiadas, família, compras reais, limites da bolsa, concerto, luzes e suspensão. Os testes de rotinas, travessia da vila, transição entre mundos e profundidade visual continuam a verificar a integração. `tests/village_life_preview.gd` guarda oito capturas em `output/village-life-*.png`.

`tests/village_social_test.gd` verifica uma compra com deslocação real, oferta e memória, interrupção sem venda, conversas recíprocas, diversidade de gestos, 12 horas simuladas em quatro períodos com decisões autónomas, ausência de teletransporte e permanência na calçada. `tests/village_social_preview.gd` guarda cinco capturas de interações em `output/village-social-*.png`.
