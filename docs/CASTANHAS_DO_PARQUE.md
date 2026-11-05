# Castanhas do Parque

Junto ao Parque da Liberdade, longe da Pastelaria do Largo, o Sr. Amílcar atende numa banca de castanhas entre as **10:00 e as 22:00**. O assador alterna entre preparar castanhas e encher cartuchos; uma compra mostra a pose de atendimento. Fora do horário, a banca fica tapada, sem vendedor nem brasas acesas. O carrinho tem colisão, entra na navegação e ganha uma marca no mapa quando descoberto.

| Dose | Preço no jogo | Saciedade |
|---|---:|---:|
| Castanhas assadas | 2,50 € | 28 |
| Castanhas com manteiga | 2,80 € | 32 |

É possível comprar logo com manteiga ou regressar à banca com uma dose simples na bolsa e **juntar manteiga por 0,30 €**. A melhoria mantém a mesma dose e o mesmo identificador, sem ocupar outro espaço, mesmo com a bolsa cheia. Uma dose que já tem manteiga não pode ser cobrada outra vez.

A compra vai para a bolsa da personagem que interage. Cada cartucho ocupa um espaço e pode ser comido, dado ao outro ou partilhado pelas opções habituais da bolsa. A partilha divide uma única dose e aumenta a ligação. O dinheiro só sai com a transação concluída; horário, proximidade, acesso, saldo e espaço são verificados novamente na confirmação. A variante com manteiga é guardada com o restante inventário.

## Arte

Criada com o **ImageGen integrado**, em correspondência com as referências da pastelaria, preservando os PNGs gerados:

- `assets/world/village/chestnut-stall-final.png`: assar, servir e banca fechada.
- `assets/items/chestnut-portions.png`: cartucho simples e com manteiga.
- `data/village/chestnut-image-prompts.json`: pedidos finais exatos e referências.
- `data/village/chestnut-art.json`: regiões e apoios medidos por `tools/measure_chestnut_art.py`, sem modificar os píxeis.

Os atlas aprovados do Te e do Jo não foram alterados.

## Validação

`tests/chestnut_stall_test.gd` verifica acesso, navegação, menu real, compras para ambos, preços, melhoria com bolsa cheia, ausência de cobranças repetidas, falta de saldo, distância, fecho durante a escolha, consumo, partilha e conservação da manteiga na gravação. `tests/chestnut_stall_preview.gd` gera capturas reais da banca, do menu e da banca tapada.

Validação final em 5 de novembro de 2026: passaram o teste da banca, a regressão da jornada e da pastelaria, caminhada, interações, renderização gráfica dos personagens e o verificador dos atlas aprovados. Capturas finais: `output/chestnuts-park.png`, `output/chestnuts-menu.png` e `output/chestnuts-closed.png`. A posição final reserva também espaço para os dois clientes, evitando compras junto de cantos de casas ou clientes escondidos por telhados.
