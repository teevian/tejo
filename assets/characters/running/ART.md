# Corrida — Te e Jo

Sprites gerados com a ferramenta integrada `image_gen`, em modo de geração com referência, seguida de extração do fundo com transparência. Referências: as cinco vistas dos dois atlas direcionais aprovados, usados apenas para preservar rosto, fisionomia, proporções, cabelo, roupa e traço.

## Atlas finais

- `te-run.png`: Te, T-shirt carvão, calções cinzentos claros, ténis pretos.
- `jo-run.png`: Jo, T-shirt bordeaux, calções bege, ténis creme com símbolo Nike bordeaux.

Cada atlas tem 3456×2800, seis colunas e cinco linhas: sul, sudeste, este, nordeste, norte. As vistas para oeste são espelhadas no motor. São 60 desenhos completos, apresentados em 96 combinações de pose/direção. As seis colunas percorrem extensão, passagem e voo, alternando os apoios.

Células de 576×560, âncora (288,520), referência anatómica 438, passada de 176 unidades do mundo. Cada sequência mantém uma só escala; as poses comprimidas não são esticadas. A cabeça tem um registo horizontal estável com avanço próprio de cada direção; a fase de voo fica 20 píxeis acima do apoio. `animations.json` regista recortes, escala e apoios. `tools/pack_running_sprites.cjs` apenas isola a transparência, regista e empacota os desenhos, sem redesenhar personagens.

A corrida é ativada pelo duplo toque existente e acompanha a distância realmente percorrida. Soltar a direção recupera a caminhada; o companheiro usa estes desenhos quando acelera para acompanhar. As outras ações continuam a ter prioridade. A caminhada aprovada e o seu desenho não foram alterados.

## Prompts finais

### Vista sul

```text
Use case: stylized-concept. Make a transparent production RUN CYCLE sprite sheet for these TWO approved game characters. Reference image shows Te on LEFT and Jo on RIGHT; use only for identity, exact face, hair, clothes, drawing style and anatomical proportions.
Draw precisely 12 separate full-body figures in 6 columns and 2 rows. TOP ROW only Te: charcoal tee, light grey shorts, black shoes, broader friendly face with faint stubble, matte dark tousled fringe. BOTTOM ROW only Jo: burgundy tee, beige shorts, cream Nike shoes burgundy swoosh, slim longer face distinctive nose and matte dark quiff. Match the reference body/head proportions and painted cartoon drawing, simplify shading the same way, no photorealism. No added objects, labels, ground shadows or scenery. Pure transparent background.
EVERY figure uses this same view: front, SOUTH, approaching camera. No turning or rotating between frames. Same slightly elevated game camera as reference.
Six consecutive RUNNING keyframes across EACH row:
1 EXTENSION A: right leg reaches FORWARD; left foot kicked behind; left bent arm swings forward, right arm backward.
2 PASSING A: right foot supports UNDER hips, left KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
3 FLIGHT A: left knee LEADS HIGHER IN FRONT, right foot folds up behind; right arm swings forward.
4 EXTENSION B: LEFT leg reaches FORWARD; RIGHT foot kicked behind; RIGHT bent arm forward, LEFT arm backward. CLEARLY OPPOSITE limbs to column 1.
5 PASSING B: left foot supports UNDER hips, right KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
6 FLIGHT B: RIGHT knee LEADS IN FRONT, LEFT foot folds behind; left arm swings forward.
The passing poses MUST be visibly compressed, unlike the extended poses. Legs must overtake each other twice, arms must pump to opposite extremes. In a profile view the nearest arm must be forward for half of the cycle and back for the other half. Do not draw six variations of the SAME stride: preserve a complete alternating two-leg cycle suitable for animation. Moderate natural jog, not racing sprint, slight forward lean, bent elbows, easy focused friendly expressions, keep head stable and clothes softly draped. Fixed anatomical scale, fixed cell centers, subtle vertical bob. Complete bodies and shoes uncropped, spacious gutters.
```

### Vista sudeste

```text
Use case: stylized-concept. Make a transparent production RUN CYCLE sprite sheet for these TWO approved game characters. Reference image shows Te on LEFT and Jo on RIGHT; use only for identity, exact face, hair, clothes, drawing style and anatomical proportions.
Draw precisely 12 separate full-body figures in 6 columns and 2 rows. TOP ROW only Te: charcoal tee, light grey shorts, black shoes, broader friendly face with faint stubble, matte dark tousled fringe. BOTTOM ROW only Jo: burgundy tee, beige shorts, cream Nike shoes burgundy swoosh, slim longer face distinctive nose and matte dark quiff. Match the reference body/head proportions and painted cartoon drawing, simplify shading the same way, no photorealism. No added objects, labels, ground shadows or scenery. Pure transparent background.
EVERY figure uses this same view: front three-quarter SOUTHEAST, approaching diagonally DOWN-RIGHT. No turning or rotating between frames. Same slightly elevated game camera as reference.
Six consecutive RUNNING keyframes across EACH row:
1 EXTENSION A: right leg reaches FORWARD; left foot kicked behind; left bent arm swings forward, right arm backward.
2 PASSING A: right foot supports UNDER hips, left KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
3 FLIGHT A: left knee LEADS HIGHER IN FRONT, right foot folds up behind; right arm swings forward.
4 EXTENSION B: LEFT leg reaches FORWARD; RIGHT foot kicked behind; RIGHT bent arm forward, LEFT arm backward. CLEARLY OPPOSITE limbs to column 1.
5 PASSING B: left foot supports UNDER hips, right KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
6 FLIGHT B: RIGHT knee LEADS IN FRONT, LEFT foot folds behind; left arm swings forward.
The passing poses MUST be visibly compressed, unlike the extended poses. Legs must overtake each other twice, arms must pump to opposite extremes. In a profile view the nearest arm must be forward for half of the cycle and back for the other half. Do not draw six variations of the SAME stride: preserve a complete alternating two-leg cycle suitable for animation. Moderate natural jog, not racing sprint, slight forward lean, bent elbows, easy focused friendly expressions, keep head stable and clothes softly draped. Fixed anatomical scale, fixed cell centers, subtle vertical bob. Complete bodies and shoes uncropped, spacious gutters.
```

### Vista este

```text
Use case: stylized-concept. Make a transparent production RUN CYCLE sprite sheet for these TWO approved game characters. Reference image shows Te on LEFT and Jo on RIGHT; use only for identity, exact face, hair, clothes, drawing style and anatomical proportions.
Draw precisely 12 separate full-body figures in 6 columns and 2 rows. TOP ROW only Te: charcoal tee, light grey shorts, black shoes, broader friendly face with faint stubble, matte dark tousled fringe. BOTTOM ROW only Jo: burgundy tee, beige shorts, cream Nike shoes burgundy swoosh, slim longer face distinctive nose and matte dark quiff. Match the reference body/head proportions and painted cartoon drawing, simplify shading the same way, no photorealism. No added objects, labels, ground shadows or scenery. Pure transparent background.
EVERY figure uses this same view: true side profile EAST, moving RIGHT. No turning or rotating between frames. Same slightly elevated game camera as reference.
Six consecutive RUNNING keyframes across EACH row:
1 EXTENSION A: right leg reaches FORWARD; left foot kicked behind; left bent arm swings forward, right arm backward.
2 PASSING A: right foot supports UNDER hips, left KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
3 FLIGHT A: left knee LEADS HIGHER IN FRONT, right foot folds up behind; right arm swings forward.
4 EXTENSION B: LEFT leg reaches FORWARD; RIGHT foot kicked behind; RIGHT bent arm forward, LEFT arm backward. CLEARLY OPPOSITE limbs to column 1.
5 PASSING B: left foot supports UNDER hips, right KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
6 FLIGHT B: RIGHT knee LEADS IN FRONT, LEFT foot folds behind; left arm swings forward.
The passing poses MUST be visibly compressed, unlike the extended poses. Legs must overtake each other twice, arms must pump to opposite extremes. In a profile view the nearest arm must be forward for half of the cycle and back for the other half. Do not draw six variations of the SAME stride: preserve a complete alternating two-leg cycle suitable for animation. Moderate natural jog, not racing sprint, slight forward lean, bent elbows, easy focused friendly expressions, keep head stable and clothes softly draped. Fixed anatomical scale, fixed cell centers, subtle vertical bob. Complete bodies and shoes uncropped, spacious gutters.
```

### Vista nordeste

```text
Use case: stylized-concept. Make a transparent production RUN CYCLE sprite sheet for these TWO approved game characters. Reference image shows Te on LEFT and Jo on RIGHT; use only for identity, exact face, hair, clothes, drawing style and anatomical proportions.
Draw precisely 12 separate full-body figures in 6 columns and 2 rows. TOP ROW only Te: charcoal tee, light grey shorts, black shoes, broader friendly face with faint stubble, matte dark tousled fringe. BOTTOM ROW only Jo: burgundy tee, beige shorts, cream Nike shoes burgundy swoosh, slim longer face distinctive nose and matte dark quiff. Match the reference body/head proportions and painted cartoon drawing, simplify shading the same way, no photorealism. No added objects, labels, ground shadows or scenery. Pure transparent background.
EVERY figure uses this same view: rear three-quarter NORTHEAST, receding diagonally UP-RIGHT. No turning or rotating between frames. Same slightly elevated game camera as reference.
Six consecutive RUNNING keyframes across EACH row:
1 EXTENSION A: right leg reaches FORWARD; left foot kicked behind; left bent arm swings forward, right arm backward.
2 PASSING A: right foot supports UNDER hips, left KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
3 FLIGHT A: left knee LEADS HIGHER IN FRONT, right foot folds up behind; right arm swings forward.
4 EXTENSION B: LEFT leg reaches FORWARD; RIGHT foot kicked behind; RIGHT bent arm forward, LEFT arm backward. CLEARLY OPPOSITE limbs to column 1.
5 PASSING B: left foot supports UNDER hips, right KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
6 FLIGHT B: RIGHT knee LEADS IN FRONT, LEFT foot folds behind; left arm swings forward.
The passing poses MUST be visibly compressed, unlike the extended poses. Legs must overtake each other twice, arms must pump to opposite extremes. In a profile view the nearest arm must be forward for half of the cycle and back for the other half. Do not draw six variations of the SAME stride: preserve a complete alternating two-leg cycle suitable for animation. Moderate natural jog, not racing sprint, slight forward lean, bent elbows, easy focused friendly expressions, keep head stable and clothes softly draped. Fixed anatomical scale, fixed cell centers, subtle vertical bob. Complete bodies and shoes uncropped, spacious gutters.
```

### Vista norte

```text
Use case: stylized-concept. Make a transparent production RUN CYCLE sprite sheet for these TWO approved game characters. Reference image shows Te on LEFT and Jo on RIGHT; use only for identity, exact face, hair, clothes, drawing style and anatomical proportions.
Draw precisely 12 separate full-body figures in 6 columns and 2 rows. TOP ROW only Te: charcoal tee, light grey shorts, black shoes, broader friendly face with faint stubble, matte dark tousled fringe. BOTTOM ROW only Jo: burgundy tee, beige shorts, cream Nike shoes burgundy swoosh, slim longer face distinctive nose and matte dark quiff. Match the reference body/head proportions and painted cartoon drawing, simplify shading the same way, no photorealism. No added objects, labels, ground shadows or scenery. Pure transparent background.
EVERY figure uses this same view: straight back NORTH, receding UP. No turning or rotating between frames. Same slightly elevated game camera as reference.
Six consecutive RUNNING keyframes across EACH row:
1 EXTENSION A: right leg reaches FORWARD; left foot kicked behind; left bent arm swings forward, right arm backward.
2 PASSING A: right foot supports UNDER hips, left KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
3 FLIGHT A: left knee LEADS HIGHER IN FRONT, right foot folds up behind; right arm swings forward.
4 EXTENSION B: LEFT leg reaches FORWARD; RIGHT foot kicked behind; RIGHT bent arm forward, LEFT arm backward. CLEARLY OPPOSITE limbs to column 1.
5 PASSING B: left foot supports UNDER hips, right KNEE moving FORWARD; feet nearly together horizontally, flexed knees, lower pelvis.
6 FLIGHT B: RIGHT knee LEADS IN FRONT, LEFT foot folds behind; left arm swings forward.
The passing poses MUST be visibly compressed, unlike the extended poses. Legs must overtake each other twice, arms must pump to opposite extremes. In a profile view the nearest arm must be forward for half of the cycle and back for the other half. Do not draw six variations of the SAME stride: preserve a complete alternating two-leg cycle suitable for animation. Moderate natural jog, not racing sprint, slight forward lean, bent elbows, easy focused friendly expressions, keep head stable and clothes softly draped. Fixed anatomical scale, fixed cell centers, subtle vertical bob. Complete bodies and shoes uncropped, spacious gutters.
```

### Extração de fundo — aplicada às cinco vistas

```text
Use case: background-extraction. Edit THIS EXACT IMAGE. Remove ONLY the brown background completely, make it genuinely transparent alpha=0. Keep ALL twelve game-character sprites unchanged, including their precise pixel positions, scale, silhouettes, faces, clothing, colors, six-column two-row layout and full bodies. Remove background inside gaps between arms/legs too. Do not redraw, relight, move, add or omit ANY figure or change ANY pose. No floor shadows. Output transparent PNG with the same layout and canvas.
```

## Refinamento da roupa na corrida

A pedido do utilizador, as T-shirts e os calções receberam dobras mais naturais, costuras, bainhas e volume de tecido semelhantes à caminhada. Edição feita com a ferramenta integrada `image_gen` nas cinco vistas, usando três poses de caminhada de cada personagem como referência da roupa.

A pintura gerada foi composta apenas no interior das peças originais, com margem nas bordas. Os atlas conservam integralmente a transparência, as silhuetas, as cabeças, os apoios, a escala e a disposição das poses. A geometria de `animations.json` e todos os sprites de caminhada permanecem iguais.

### Prompt do refinamento — aplicado às cinco vistas

```text
Use case: precise-object-edit.
Image 1 is the EDIT TARGET: an existing running sprite sheet with exactly twelve figures in six columns and two rows, Te at top and Jo at bottom. Image 2 is ONLY a clothing rendering reference from their approved walking sprites.
USER REQUEST: make ONLY the T-shirts and shorts of the running sprites a little more realistic and detailed, matching the natural fabric treatment of the walking sprites. They should clearly feel made by the same artist at the same time.
Paint visibly richer but restrained cotton drape: softer overlapping angular fabric fold planes across the torso and back, small compression wrinkles under the arms and near waist, diagonal tension folds from shoulder to hem, slightly loose weighted T-shirt fabric rather than flat tight surfaces. Add subtle crew-neck ribbing and sleeve/hem stitching, side seams. Shorts should show the same cotton/chino structure as the reference: waistband, pocket opening seams, fly seam where visible, stitched rolled hems, natural small hip and crotch creases that follow each running leg position. Preserve exact existing garment colors: Te charcoal T-shirt and light grey shorts; Jo burgundy T-shirt and beige shorts.
Keep the illustrated painted game style and same dark contour thickness, warm muted palette and readable broad shading. A modest increase in fabric realism, not photorealism or photographic fabric texture. Details must read at small game sprite size, avoid noise or shiny material.
CRITICAL INVARIANTS: preserve EVERY running pose, limb position, silhouette, cell spacing, scale and original 1536x1024 canvas. Do NOT change any face, eyes, expression, hair, head shape, neck, skin, muscles, hands, legs, footwear, shoe colors or Nike swoosh. No change to identity, proportions or body shape. Do NOT move or rotate figures, enlarge clothing or introduce new accessories. Keep all twelve sprites at their exact original locations, so this is a clothing paint-detail pass only.
Background stays genuinely transparent; remove all background paint between figures and limbs. No text, labels, shadows or scenery.
```

## Correspondência com a caminhada — revisão de 3 de novembro de 2026

Os atlas finais usam agora as próprias cabeças dos atlas de caminhada aprovados, recortadas na primeira coluna de cada vista e compostas à escala nativa. Conservam-se o rosto, olhos, nariz, maxilar, desenho e volume do cabelo de cada personagem. A translação acompanha a posição do pescoço em cada uma das seis fases; a ligação ao colar foi revista sem alterar as poses dos membros ou os apoios.

As cores dos calções e ténis foram calibradas pela distribuição de tons das mesmas peças na caminhada: cinzento claro e preto/carvão no Te, bege e creme discreto com símbolo bordeaux no Jo. As dobras e costuras da corrida mantêm-se. Foram corrigidas também pequenas contaminações de pele e contornos dentro do tecido.

`identity.json` regista as referências aprovadas, a posição das cabeças e a paleta por vista. `node tools/check_running_identity.cjs` compara os pixels das feições e do cabelo nas sessenta poses com os desenhos aprovados. A montagem final desta revisão reutiliza a arte existente; não substitui os rostos por novas interpretações da geração de imagem. Os prompts acima continuam a documentar a geração integrada dos corpos e o refinamento do tecido.

Depois de qualquer novo empacotamento, verificar também a identidade com esse comando e a preservação dos atlas aprovados com `node tools/check_approved_characters.cjs`. Comparação direta em `output/running-identity-comparison.png` e sequência no motor em `output/running-identity-preview.gif`.


