# Te + Jo: ligação, fome, cansaço e pastelaria

As barras fazem parte da exploração da serra e da vila. A **ligação é partilhada**, de 0 a 100; **fome e cansaço são individuais**, de 0 a 100. O painel ao lado das bolsas mostra os dois personagens e uma carteira comum. O botão «Momentos e desbloqueios» explica as atividades e os requisitos.

## Progressão conjunta

A ligação aumenta ao caminharem e descobrirem lugares juntos, terminarem conversas, ouvirem música no concerto, no Lord Byron ou durante o descanso, assistirem ao cinema, partilharem lanches e concluírem jogos ou ajudas pela vila. A proximidade dos dois é verificada. Uma conversa cancelada, um jogo começado sem resultado ou um clique repetido não dão a mesma recompensa várias vezes.

As descobertas e conversas dão a sua primeira recompensa uma única vez. Outras atividades têm limites diários por categoria; música exige 45 segundos de escuta conjunta, cinema 15 segundos dentro das sessões de 24 minutos de jogo. Há ligação por resultados reais dos matraquilhos e dos toques de futebol, pela roda de ritmo, pelas ajudas aos vizinhos e pelo cume da escalada.

| Ligação | Desbloqueio real |
|---|---|
| 20 · nível 1 | Entrada na escalada do Penedo da Amizade |
| 40 · nível 2 | Minijogo da roda de ritmo |
| 60 · nível 3 | Conversa nova no Miradouro da Ferraria |
| 80 · nível 4 | Conversa nova durante a noite |
| 100 · nível 5 | Barra de ligação completa |

A caminhada, o mapa, a compra de comida e os jogos de futebol e matraquilhos continuam disponíveis desde o início. São formas de começar a progressão.

## Fome e descanso

O relógio mantém a relação existente: um segundo real corresponde a um minuto no jogo. A fome sobe 0,075 pontos por minuto de jogo. O cansaço sobe 0,045 quando estão parados, 0,065 a caminhar e 0,10 a correr ou durante a escalada.

- **Dormir no chão: ×1**, recupera 0,32 pontos de cansaço por minuto.
- **Estar sentado num banco: ×0,25**, recupera 0,08 pontos por minuto.
- A recuperação começa na pose de sono ou quando já estão efetivamente sentados, sem acrescentar cansaço ao mesmo tempo.
- O botão «Dormir» do menu pode usar uma zona livre de calçada. Os dois aproximam-se a pé e há uma verificação de espaço para os corpos deitados. A espera automática continua a preferir os jardins.
- A fome continua a aumentar durante o descanso. Bolos, bebidas e amendoins não substituem o sono.
- A pausa e o mapa suspendem as necessidades. Durante a escalada o relógio comum e as necessidades continuam; a serra e os seus animais ficam suspensos.

As barras não causam morte nem alteram os sprites ou as passadas aprovadas dos protagonistas.

## Pastelaria do Largo

A pastelaria está junto de uma padaria real da Rua das Padarias, tem montra, balcão com colisão e uma marca no mapa quando descoberta. O Luís trabalha junto ao balcão durante o seu horário. Abre das **07:00 às 21:30**.

| Produto | Preço no jogo | Saciedade |
|---|---:|---:|
| Bolo de cenoura · fatia | 2,80 € | 30 |
| Bolo red velvet · fatia | 3,20 € | 32 |
| Bolo blue velvet · fatia | 3,20 € | 32 |
| Pastel de nata | 1,40 € | 18 |
| Travesseiro de Sintra | 1,80 € | 24 |
| Amendoins | 1,20 € | 20 |
| Iced tea de pêssego | 1,80 € | 6 |
| Água | 1,00 € | 0 |

O iced tea aparece uma única vez na montra. A água refresca, sem substituir uma refeição ou reduzir cansaço. Cada produto ocupa um lugar de porte na bolsa. A carteira começa com **24 €**; jogos concluídos e ajudas dão pequenas recompensas, com limites diários.

A compra escolhe a bolsa do Te ou do Jo. O dinheiro só sai se a loja estiver aberta, a pessoa estiver ao balcão e houver espaço. Clicar numa comida da bolsa abre as opções de comer/beber, dar ao outro para comer, partilhar ou pousar. O botão direito continua a pousar no chão. Partilhar consome um único produto e divide a saciedade pelos dois; exige proximidade. Fruta, doces e gelados das bancas existentes também podem ser comidos ou partilhados.

## Continuidade e arte

A banca [Castanhas do Parque](CASTANHAS_DO_PARQUE.md), junto ao Parque da Liberdade, também alimenta os dois: vende doses simples ou com manteiga e permite acrescentar manteiga a uma dose já comprada. Usa a mesma carteira, bolsas, fome, partilha e gravação.

`user://tejo-journey-v1.json` guarda ligação, as quatro necessidades, dinheiro, recompensas já atribuídas, relógio comum, bolsas completas e memória das conversas. A gravação é atómica e automática. A gravação anterior da comunidade continua a guardar os vizinhos e as histórias; não repõe uma segunda cópia das bolsas já carregadas pela jornada. Os testes usam ficheiros temporários e não leem nem escrevem a gravação do jogador.

Foram criados com o **ImageGen integrado**, sem alterar os PNGs gerados:

- `assets/items/bakery-food.png`: oito produtos individuais, usados nas bolsas e na montra de compra.
- `assets/world/village/bakery-counter.png`: balcão pintado, nome e horário.

Os pedidos exatos e a referência de estilo estão em `data/village/bakery-image-prompts.json`. `tools/measure_bakery_art.py` mede apenas as regiões e apoios para `data/village/bakery-art.json`. Os dois atlas finais do Te e do Jo e o seu desenho de caminhada permanecem preservados.

## Verificação

`tests/journey_needs_test.gd` verifica o aumento das necessidades, a razão exata de recuperação 4:1, transações reais sem cobranças falhadas, oito produtos, consumo individual e partilha, distância, limites das barras, recompensas sem duplicação, resultados reais dos matraquilhos, requisitos de ligação e gravação/carregamento completos. Verifica também o pedido real de sono na calçada e o consumo de fruta das bancas existentes.

`tests/journey_preview.gd` produz capturas reais da pastelaria, montra, partilha e progressão. A transição da escalada verifica o bloqueio aos 19 pontos, a entrada aos 20 e o relógio durante o minijogo. As regressões de caminhada, interação, descanso, conversas, viagens e renderização complementam estes testes.

Validação concluída em 5 de novembro de 2026: passaram os testes de necessidades e compras, os intervalos reais de escuta e cinema, caminhada conjunta com colisões, partilha, gravação/carregamento, transição da escalada, viagens entre regiões, diálogos, sequência de descanso, caminhada, interações e renderização gráfica. O verificador dos atlas aprovados do Te e do Jo passou. Capturas finais: `output/journey-bakery.png`, `output/journey-menu.png`, `output/journey-share.png` e `output/journey-progress.png`.
