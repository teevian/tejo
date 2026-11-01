# Caminhada lateral v16

Correção limitada a esquerda/direita de Te e Jo. A deformação global rejeitada foi removida. Cada personagem usa um atlas lateral com pose parada e oito poses completas diferentes; os ombros e mangas já não são copiados do busto parado. O rosto e a parte superior do pescoço até y145 são os pixels aprovados do v15, na mesma posição. Só a pequena união à gola é composta entre y145 e y159. O motor desenha uma textura completa, sem malha, rotação, inclinação ou balanço adicional. Direita e esquerda usam os mesmos desenhos espelhados.

## Ficheiros

- `te-side-walk-v16.png` e `jo-side-walk-v16.png`: atlas ativos, células 400×560, nove colunas, âncora (200,520).
- `sources/te-side-walk-v16.raw.png` e `sources/jo-side-walk-v16.raw.png`: pinturas transparentes, oito poses numa grelha 4×2.
- `side-walk-v16.recipe.json`: registo e limites das poses.
- `../../../tools/pack_side_walk_v16.cjs`: composição dos rostos e alinhamento dos desenhos.

Reconstruir com o empacotador e importar as texturas no Godot. `tests/side_walk_motion_test.gd` captura as personagens reais nos dois sentidos. `tools/preview_side_walk.cjs` produz a comparação com as poses v15 sem deformação e a pré-visualização v16. Os testes verificam identidade, continuidade e registo; a naturalidade da passada precisa de avaliação visual.

## Geração e pedidos

Modo: ferramenta integrada image_gen, fundo transparente. Uma chamada por personagem; referências: guia de oito poses e neutral lateral v15. A segunda chamada corrigiu os membros de cor do guia. Os rostos gerados não são consumidos pelo jogo: o empacotador repõe os originais aprovados.

### Pedido das oito poses

Use case: sketch-to-render and identity-preserve. Produce a production transparent game sprite sheet. Image 1 is the EXACT eight-phase animation POSE MAP (four columns, two rows, read left to right). Image 2 is the CHARACTER IDENTITY, proportions and painted art style reference. Replace EVERY pose-map puppet with the reference character in that EXACT joint pose. Absolutely follow the individual near and far arm and leg positions of all eight pose cells: orange is the NEAR limb and blue is the FAR limb; these colors are guide only and MUST NOT appear in result. Do not reuse arm poses from earlier cells. Frame 1 near arm BACK, frame 3 near arm DOWN, frame 5 near arm FORWARD, frame 7 near arm DOWN, frame 8 near arm BACK. Keep the same eight full bodies in a regular 4x2 grid with equal cell sizes. Relaxed natural walking, low feet, no running. All face RIGHT in identical side profile. Paint supporting leg nearly straight, smoothly bent swing knee, articulated subtle shoulders/sleeves following arm swing. Keep head and neck stable, torso stable upright. Preserve exact reference face hair size slender adult proportions, exact shirt shorts shoes. Same crown level and hip horizontal position within each cell, same supporting ground baseline in each row; no overall body wobbling, no torso tilting. Coherent continuous neck collar shirt and connected limbs in each pose. Transparent background, no floor, no shadows, no text, no guide lines. Output only 8 matching complete sprites; generous cell margins.

Te: Te wears charcoal shirt, ivory shorts, black sneakers; slightly athletic.
Jo: Jo wears burgundy shirt, beige shorts, grey sneakers; slim.

### Correção final das pinturas

Edit this exact 4 columns by 2 rows walking sprite sheet. Make two precise corrections only: (1) replace ALL flat blue placeholder FAR arms and FAR legs with the character's natural realistic painted skin anatomy (warm skin matching near limbs) and shirt sleeves / beige shorts where appropriate. There must be no blue anywhere in the final character. Paint complete anatomically coherent limbs, matching existing painted shading and outlines. (2) Correct the crouched knees: make the WEIGHT-BEARING leg substantially straighter in every pose, natural upright adult walking stance with hips higher relative to feet, while preserving the foot placements, both alternating limb sequences and the head and torso registration. The swing leg may bend, the stance leg should NOT look crouching or sitting. Preserve all eight distinct poses in exact layout, same face, hair, clothes and paint style. Keep background truly transparent. No text, lines, shadows or ground. Do not repeat or reorder frames.

