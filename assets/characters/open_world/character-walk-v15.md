# Sprites Te / Jo — v15

Os atlas ativos são `te-walk-v15.png` e `jo-walk-v15.png`: cinco direções (sul, sudeste, este, nordeste e norte), pose parada e quatro passadas completas, mantidas durante os oito tempos do ciclo. Oeste e as diagonais ocidentais são espelhados pelo motor. A cabeça aprovada vem exclusivamente da pose parada de cada direção do atlas v9; mantém rosto, cabelo e maxilar, com redução uniforme. A cabeça ocupa 104 de 480 píxeis de altura, aproximadamente 22%. A escala no mundo passou de 156/153 para 164/161 unidades (Te/Jo).

Os corpos e as passadas foram repintados com a ferramenta integrada **image_gen**. Te tem ombros e braços ligeiramente mais atléticos; Jo tem o tronco mais estreito. O pescoço estreita para o maxilar e abre gradualmente até à gola pintada. A mesma cabeça, pescoço e gola são registados em todas as fases; o motor desenha um único sprite completo.

A normalização mede as faixas realmente pintadas no atlas e preserva os sapatos completos. O registo do cabelo, da gola e do chão é independente do balanço dos braços. Nenhum corpo de caminhada v9/v14 é composto nos resultados: as versões anteriores são apenas referências de identidade e de pose.

## Caminhada lateral

A oscilação contínua do sprite inteiro foi retirada após avaliação visual. As vistas laterais usam agora [oito poses pintadas v16](side-walk-v16.md), mantendo os rostos e pescoços aprovados estáveis. As restantes vistas continuam neste atlas v15.

## Fontes e reconstrução

- `sources/te-turnaround-v15.raw.png`, `sources/jo-turnaround-v15.raw.png`: novas proporções e pintura neutra.
- `sources/te-painted-walk-v15.raw.png`, `sources/jo-painted-walk-v15.raw.png`: novas passadas completas, segundo as poses de referência.
- `character-walk-v15.recipe.json`: recortes, registo, proporções e âncoras.
- `tools/pack_character_walk_v15.cjs`: reconstruir os dois atlas com Node e Sharp.
- `tools/preview_character_walk_v15.cjs`: grelhas, detalhes e GIF em `output/sprites-v15/`.
- `tools/preview_shared_characters.gd -- --motion-v15 --all-directions`: capturas no jogo; `tools/preview_character_walk_v15.cjs --scene` junta essas capturas numa animação das oito direções.

## Verificação

`tests/te_walk_consistency_test.gd` e `tests/jo_walk_consistency_test.gd` comparam os rostos com os pixels aprovados, verificam a continuidade opaca do pescoço/gola e quatro passadas completas por direção. `tests/character_direction_consistency_test.gd`, com janela gráfica, verifica o registo real nas oito direções. `tests/character_rendering_test.gd` verifica os personagens através do desenho usado no jogo.

## Pedidos finais de imagem

Foram usados dois pedidos por personagem: a nova referência de proporções e a repintura do mapa de poses, seguidos de uma reparação conjunta de pescoços e golas em `sources/neck-collar-v15.raw.png`. As cabeças aprovadas são recolocadas por cima dessa pintura, preservando os pixels faciais originais.

### Te — proporções

Use case: identity-preserve.
Create a new production character turn-around SPRITE SHEET from the supplied Te reference. Image 1 is identity and painting-style reference, not a layout to copy.
Output ONE wide image with EXACTLY FIVE complete full-body figures in ONE ROW, evenly spaced, transparent background, no text, no floor shadows. Direction order LEFT TO RIGHT: FRONT facing viewer/down, FRONT THREE-QUARTER facing down-right, TRUE RIGHT PROFILE, REAR THREE-QUARTER facing up-right, FULL BACK. Orthographic game camera slightly above like the reference. All five figures identical size, feet aligned along same baseline; each full figure has padding from crown to sole. High resolution.
These are relaxed NEUTRAL IDLE poses, no walking. Arms straight but relaxed with gentle elbow bend, hands open relaxed beside hips, small visible gap between arms and torso. Legs straight, feet slightly separated with a clean small gap. This neutral art will be articulated into animation.
Preserve Te's EXACT original face and hair identity, facial structure, eyes, nose, mouth, dark tousled hair and light stubble. His charcoal black short sleeved tee, ivory short shorts and black low top trainers remain.
REFORM THE BODY PROPORTIONS: clearly taller and SLIMMER than reference, adult stylized proportions 4.8 heads tall (crown to chin only 21% of total height). Lengthen thighs, calves and torso. Slim waist, narrow pelvis, longer arms, small relaxed hands, no bulky fists. Slightly athletic but lean shoulders and arms, NOT bodybuilder. Head smaller relative to shoulders and height. Fine natural narrow neck, slightly visible below jaw, shaded under chin; seamless anatomically integrated shoulders with a thin properly curved COMPLETE charcoal crewneck collar around the neck. No severed neck or notches, no wide trapezoid neck. Painted skin warm and compatible with face.
Style exact same detailed matte hand-painted storybook game art as the supplied faces, fine softly dark contours, subtle realistic fabric folds, NO plastic 3D shading, no pixelation.
No panels, no repeated extra characters, no weapons or accessories. EXACT 5 full-body neutral figures in one horizontal row.

### Jo — proporções

Use case: identity-preserve.
Create a production transparent hand-painted game character turn-around for Jo.
Image 1: Jo original reference, use his EXACT face identity, short brushed-up brown hair, clean-shaven face and gentle smile, warm skin. Clothing: BURGUNDY WINE RED crewneck short sleeved t-shirt, beige shorts, GREY low top trainers with pale soles.
Image 2: new Te body turn-around, match this image's layout, scale, camera and painted style and slender adult proportions. Jo is a little LESS muscular and slightly narrower in shoulders and arms than Te, not smaller-headed or cartoonish. Do not copy Te's face or black clothes.
OUTPUT ONE WIDE sheet with EXACTLY FIVE complete full-body figures in ONE horizontal ROW, evenly spaced transparent background. LEFT TO RIGHT: front facing down/viewer; front three-quarter facing down-right; true right profile; rear three-quarter facing up-right; full back/up. Orthographic game camera slightly above like Te. Identical figure height and foot baseline.
Neutral idle in every view: feet slightly apart, legs straight, arms relaxed at sides, gentle elbow bend, small open relaxed hands. Leave slight gaps between arms/torso and between legs to permit animation.
BODY: tall/slim stylized adult, 4.8 heads tall, head crown-to-chin only21% full height. Longer torso, thighs and calves than Jo original reference. Slim arms, waist and hips, no bulky fists or muscular biceps. Fine anatomically integrated NARROW NECK below the preserved jaw; complete thin curved wine-red crewneck collar, no angular cutouts, no skin-colored clothing trim. Smooth continuous shading from original face to neck and upper chest. Correct shoulders, pelvis and knees.
Style: detailed matte painted illustration, fine subtle dark contour, warm skin shading, subtle fabric folds, compatible with original face and with Te. No plastic 3D, no photorealistic skin, no pixel art. Maintain Jo identity in each view.
Genuinely transparent background, no text, no labels, no grid, no props, no floor shadows. Full crown and feet, plenty of padding. Five figures only in ONE row.

### Te — passadas

Use case: identity-preserve. Repaint a game SPRITE SHEET.
IMAGE1 is a POSE MAP of 5 rows x5 columns, with a green background. Keep the EXACT ANATOMICAL WALKING PHASE of EACH figure in this pose map, especially which arm is forward and which leg supports the body. The pose map has a complete alternating four-key walk after the idle.
IMAGE2 is the NEW BODY STYLE AND PROPORTIONS for Te. Use this tall slim complete painted body for EVERY pose in the pose map. Do NOT retain the squat short legs, large head, bulky fists or thick neck of image1. Te should have longer slimmer legs, torso and arms, small relaxed hands, slightly athletic lean build, a small head only21% full body height. Same black tee, ivory shorts, black trainers, dark messy hair. Narrow neck and clean continuous dark crewneck collar in every pose.
OUTPUT EXACTLY the SAME 5x5 GRID layout as image1 but on a GENUINELY TRANSPARENT background, no labels, no green background, no shadows. Five angles by five animation keys. Each full figure completely inside its cell, aligned to same head height and floor baseline, no overlapping figures.
Rows from top: front/down; front-three-quarter/down-right; true right profile; rear-three-quarter/up-right; full back/up.
Columns: idle; contact A; passing A; OPPOSITE LEG contact B; OPPOSITE LEG passing B. Keep limb assignments EXACTLY as corresponding pose-map cells. In column3 and5 lower lifted knees to a comfortable ordinary walking height, never beside waist. The SIDE and DIAGONAL contact in column4 must use the opposite leg from column2 and opposite arm swing. These are different anatomical poses; don't repeat one stride in all four columns.
Use the NEW neutral body proportions in image2 consistently across the whole sheet; only the pose changes. Complete clean continuous hand-painted figures, detailed matte storybook game style matching image2, fine subtle dark contours, warm skin, natural folded cloth, no 3D, no patchwork, no detached pieces or seams. Natural brisk walk, upright torso, relaxed elbows and hands.

### Jo — passadas

Use case: identity-preserve. Repaint a game SPRITE SHEET.
IMAGE1 is a POSE MAP of 5 rows x5 columns, with a green background. Keep the EXACT ANATOMICAL WALKING PHASE of EACH figure in this pose map, especially which arm is forward and which leg supports the body. The pose map has a complete alternating four-key walk after the idle.
IMAGE2 is the NEW BODY STYLE AND PROPORTIONS for Jo. Use this tall slim complete painted body for EVERY pose in the pose map. Do NOT retain the squat short legs, large head, bulky fists or thick neck of image1. Jo should have longer slimmer legs, torso and arms, small relaxed hands, slender less muscular build than Te, a small head only21% full body height. Same burgundy wine red tee, beige shorts, grey trainers, brown brushed-up hair, clean-shaven gentle face. Narrow neck and clean continuous dark crewneck collar in every pose.
OUTPUT EXACTLY the SAME 5x5 GRID layout as image1 but on a GENUINELY TRANSPARENT background, no labels, no green background, no shadows. Five angles by five animation keys. Each full figure completely inside its cell, aligned to same head height and floor baseline, no overlapping figures.
Rows from top: front/down; front-three-quarter/down-right; true right profile; rear-three-quarter/up-right; full back/up.
Columns: idle; contact A; passing A; OPPOSITE LEG contact B; OPPOSITE LEG passing B. Keep limb assignments EXACTLY as corresponding pose-map cells. In column3 and5 lower lifted knees to a comfortable ordinary walking height, never beside waist. The SIDE and DIAGONAL contact in column4 must use the opposite leg from column2 and opposite arm swing. These are different anatomical poses; don't repeat one stride in all four columns.
Use the NEW neutral body proportions in image2 consistently across the whole sheet; only the pose changes. Complete clean continuous hand-painted figures, detailed matte storybook game style matching image2, fine subtle dark contours, warm skin, natural folded cloth, no 3D, no patchwork, no detached pieces or seams. Natural brisk walk, upright torso, relaxed elbows and hands.


### Reparação de pescoços e golas

Use case: precise-object-edit. Edit this exact 2-row by5-column board of character busts. Top row is Te, bottom row is Jo. Keep the EXACT same five head angles, facial identity, hair, eyes, nose, mouth, jaw, expressions, head positions and sizes, shirt colors, body pose, column spacing and framing. Do not redesign or move the faces.
ONLY REPAIR THE NECK AND COLLAR PAINTING. The current image has visible rectangular steps, angular missing bits of neck, square edges at the shoulder/neck, tiny floating dark fragments, and abrupt joins under the original pasted heads, especially the front three-quarter and profile views. Repaint the area FROM UNDER THE JAW TO THE TOP OF THE SHIRT so each of the10 busts has a smooth continuous anatomically natural relatively slender neck, softly shaded under the jaw, connected shoulders, and a clean COMPLETE THIN ROUND CREWNECK COLLAR following the curve of the neck. No sharp squared steps, no missing triangles, no spiky shirt points, no rectangular blocks of skin, no holes, no floating pixels. Make the painted face, neck and body look authored together in one coherent illustration.
Keep Te's black charcoal shirt and Jo's burgundy red shirt, original matte painted game style and all original facial details. Keep their faces absolutely unchanged as closely as possible. Preserve the same two horizontal rows of five busts and SAME crop/framing. Transparent background, no text or additional elements.
