# Fauna pintada

`forest-fauna-atlas.png` foi criado com a ferramenta integrada image_gen em 29-10-2026, com transparência real. O original foi preservado; o PNG é consumido diretamente pelo jogo, com recortes e pontos de apoio definidos em `scripts/wildlife_art.gd`. Não depende de ficheiros fora do projeto.

O atlas tem cinco linhas: pisco, esquilo-vermelho, raposa, rã e borboleta. Cada linha contém quatro poses. Os limites dos recortes são explícitos porque a disposição gerada não corresponde a uma grelha perfeita. A arte usa tons naturais, textura pintada de pelo e penas, vista ligeiramente de cima e iluminação neutra; a iluminação diária é aplicada pelo jogo. As asas alternam poses; os mamíferos alternam passadas; comer, trepar, beber, dormir, saltar e pousar usam poses próprias.

## Pedido de geração

Atlas transparente de 4 colunas × 5 linhas para uma floresta pintada vista de cima em perspetiva oblíqua. Animais naturalistas com anatomia realista, textura orgânica, paleta de terra, sem texto, cenário ou sombras de chão, todos orientados à direita. Pisco: pousado e três posições de asas em voo. Esquilo-vermelho: duas passadas, a comer uma bolota e a trepar. Raposa europeia: duas passadas, focinho baixo para beber e enrolada a dormir. Rã verde: agachada, salto esticado, cabeça à superfície e garganta estendida. Borboleta ocre e creme: asas abertas, intermédias, quase fechadas e repouso.

## Verificação

Revisto no motor gráfico com o cenário, oclusão da vegetação, iluminação e escala dos personagens. Recortes também inspecionados num fundo uniforme. As flores, cavidades, folhas flutuantes, sombras de contacto e ondulações são desenhadas no jogo. As capturas de `tests/wildlife_preview.gd` são apenas artefactos de revisão.

## Atlas direcionais

Adicionados `fox-directions.png`, `squirrel-directions.png`, `bird-directions.png`, `frog-directions.png` e `butterfly-directions.png`, criados com image_gen, com transparência, sem substituir o atlas original. Cada um contém 20 poses: colunas norte, nordeste, este, sudeste e sul; quatro linhas de animação. As direções de oeste são espelhamentos das vistas orientais equivalentes, mantendo vistas frontais e traseiras reais.

Os JSON com o mesmo nome registam os recortes e pontos de apoio de cada pose. Os recortes foram inspecionados a partir dos componentes de opacidade, porque a grelha gerada não é perfeitamente regular. `tools/inspect_wildlife_atlas.gd` permite repetir essa inspeção sem modificar os PNG. Os pontos de apoio foram ajustados às patas ou ao corpo conforme o tipo de movimento. A seleção dos sprites está em `scripts/wildlife_art.gd`.

Pedido comum: grelha transparente de cinco colunas e quatro linhas, câmara ortográfica elevada a 45 graus, anatomia e texturas pintadas naturalistas, sem texto, cenário ou sombras; vistas traseira, traseira de três quartos, lateral, frontal de três quartos e frontal. Manter identidade, escala e perspetiva entre poses, sem rodar simplesmente uma imagem lateral.

- Raposa: alerta, passada de corrida recolhida, passada estendida e salto de arranque/mudança de direção.
- Esquilo: sentado alerta, corrida recolhida, corrida estendida e salto de susto com patas erguidas e cauda arqueada.
- Pássaro: pousado, asas erguidas, asas abertas e asas baixas.
- Rã: agachada, salto estendido, aterragem e natação.
- Borboleta: asas abertas, a meio do batimento, quase fechadas e repouso.

Validação: grelhas renderizadas em todas as oito direções, testes de pixels visíveis e mudança de pose, e capturas no cenário real. Os movimentos de voo, corrida, salto e reação usam as poses novas; as poses de beber e dormir da raposa continuam a usar os recortes próprios do atlas original.
