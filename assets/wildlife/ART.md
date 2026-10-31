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

## Fauna noturna — 31-10-2026

Criados com a ferramenta integrada **image_gen**, com transparência real, usando `bird-directions.png` como referência de estilo: penas e pelo pintados, anatomia naturalista, tons terrosos, perspetiva oblíqua elevada e luz neutra. Os PNG originais são preservados e consumidos diretamente pelo projeto. Os pirilampos usam pontos e halos suaves desenhados no motor, adequados à escala dos insetos; a emissão é aplicada acima da iluminação noturna, abaixo da interface, e consulta a ocultação do mundo.

### `bat-flight.png`

Pedido usado (referência apenas para estilo):

> Use case: stylized-concept. Asset type: transparent sprite atlas for the existing painted Sintra forest game. Reference images are STYLE ONLY: match the naturalistic hand-painted robin feathers, textured organic fur, restrained earth palette and elevated oblique 45 degree camera. Create a NEW BAT sprite sheet, exactly 4 columns by 2 rows, eight isolated poses with generous transparent gutters and NO overlap. Same small European brown forest bat, fine chestnut fur, anatomically correct delicate charcoal brown membranous wings, small ears, no cartoon. Top row: bat flying to the right, four animation phases: wings raised, fully extended, lowered, partially folded upward. Bottom row: bat flying toward viewer slightly right, same four phases. Consistent body size and cell centering, evenly spaced regular grid. Neutral painted light so game applies night tint. Actual transparent background, no scenery, no ground shadow, no lettering or grid lines. Sprite edges clean. Do not include any robin or people. The sprite sheet must remain beautifully readable at 35 pixels wingspan.

Os oito recortes e pontos centrais do corpo estão em `scripts/nocturnal_art.gd`. As asas batem a quinze poses por segundo, com fases individuais e duas vistas de voo, espelhadas conforme o sentido.

### `owl-modules.png`

Pedido usado (referência apenas para estilo):

> Use case: stylized-concept. Asset type: transparent modular OWL sprite sheet for the existing hand-painted Sintra woodland game. Input robin sheet is STYLE REFERENCE ONLY; match naturalistic hand-painted feather texture, warm tawny earth tones, fine brushwork, elevated oblique 45 degree camera. Create exactly FIVE COLUMNS and TWO ROWS with ten separate isolated cutout components, centered in evenly spaced cells with transparent gutters. A single European tawny owl, realistic anatomy, dark warm eyes, no ear tufts, no cartoon. TOP ROW from left to right: (1) perched front-facing owl TORSO ONLY from neck opening to talons, head completely absent for separate animation, closed folded wings and tail; (2) same headless perched torso back view; (3) complete owl flying right with wings raised; (4) complete owl flying right with wings fully spread; (5) complete owl flying right with wings lowered. BOTTOM ROW: five isolated HEADS ONLY with identical scale and neck pivot: front view facing camera, turned 45 degrees toward right, right side profile at 90 degrees, three-quarter rear at 135 degrees, full back of head at 180 degrees. Rounded tawny feathered head with facial disc, tiny natural beak, keep head scale consistent. No bodies in bottom row. No branches or ground shadows. Neutral diffuse lighting for in-game night grading. True transparent background, no text, no cell borders, no overlap. No robins.

A cabeça é composta à parte do tronco, usando cinco vistas e os seus espelhos, com transições suaves. O corpo não roda nem oscila durante a vigia. Os recortes de voo têm caixas parcialmente sobrepostas no atlas; o desenho usa o contorno da maior silhueta de cada recorte para excluir penas de poses vizinhas, preservando os pixels e a transparência originais. Os pontos de pouso seguem ramos concretos nas duas pinturas de árvores, em coordenadas de origem (305,468) e (340,265), transformadas com a escala de cada árvore.

Verificado no motor gráfico: vistas frontais/laterais/traseiras, batimento das asas, ausência de fragmentos, corpo da coruja imóvel, contacto das patas com o ramo, escala no bosque noturno e emissão/oclusão dos pirilampos. Capturas em `output/nocturnal-*.png`.

## Serpentes ribeirinhas e luzes no chão

`snake-slither.png` foi criado com a ferramenta integrada **image_gen**, usando `bird-directions.png` apenas como referência da pintura, textura e paleta. O original transparente foi copiado para o projeto. Os quatro recortes e pontos centrais estão em `scripts/nocturnal_art.gd`; a pose acompanha a distância percorrida e a orientação acompanha o caminho no chão.

Pedido usado:

> Use case: stylized-concept. Asset type: transparent 2D wildlife sprite strip for the existing hand-painted Sintra forest game. Reference image is STYLE ONLY, not subject: match its naturalistic hand-painted textures, restrained earthy palette, fine organic detail and elevated oblique camera. Create a NEW single horizontal row of FOUR isolated grass-snake poses, facing RIGHT, each centered in its own equally sized cell with very generous transparent gutters. Same slender olive-brown European grass snake, subtly patterned scales, small natural dark eyes and understated cream collar. No viper fangs, no raised cobra hood, no attack pose. Flat on the ground, camera nearly overhead so the sprites can rotate along the ground plane. Four phases of smooth slithering: gentle S curve, extended shallow curve, opposing S curve, transitioning shallow curve. Entire tapered tail and small head visible in EVERY pose, same body length and scale. Clean realistic anatomy, grounded painterly game art; readable as a small 55-pixel-long creature. Soft neutral illumination so the game can apply night grading. True transparent background, no scenery, no floor or cast shadows, no other animals, no text, no borders. Do not overlap cells or crop tails.

Os pirilampos passaram a ser pontos fixos ao nível do chão, entre a vegetação, com frequências de brilho individuais. Os reflexos dos olhos das corujas seguem a rotação da cabeça, duram uma fração de segundo e têm um intervalo para evitar cintilação contínua. Ambos são desenhados no motor e respeitam a ocultação do cenário.
