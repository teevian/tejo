# Te RPG v18 — fases intermédias

A caminhada para baixo mantém este atlas. A lateral usa agora os sprites inteiros [v20](te-side-v20.md).

Atlas ativo: `te-rpg-v18.png` (2800×1120), chamado por `scripts/te_rpg_walk.gd`. Só altera a caminhada do Te para baixo/direita e o espelhamento para a esquerda.

Os seis desenhos da versão anterior incluíam contactos quase repetidos. O v18 conserva, sem alteração de pixels, a pose parada e os dois contactos opostos do v17, e substitui os outros quatro tempos de cada direção por pinturas de passagem e avanço.

## Ordem física do ciclo

1. Contacto A: pé A à frente, pé B atrás.
2. Passagem A: A suporta o peso, B aproxima-se do tornozelo de apoio.
3. Avanço B: B ultrapassa A e prepara o próximo contacto.
4. Contacto B: pé B à frente, pé A atrás.
5. Passagem B: B suporta o peso, A passa junto do apoio.
6. Avanço A: A prepara o contacto inicial.

Mantém o modelo escolhido, as poses paradas e os contactos aprovados. Os novos desenhos são personagens completos, sem copiar um busto fixo ou deformar partes do corpo. São recortados por transparência, redimensionados uniformemente e registados no chão. A esquerda espelha a direita. O avanço B frontal usa uma pintura completa espelhada para inverter corretamente a perna que vai liderar.

## Fontes e reconstrução

Ferramenta integrada image_gen, modo de edição com referências do próprio Te v17 e fundo transparente.

- `sources/te-rpg-v18-down-pass.raw.png`: dois apoios frontais com o pé de passagem próximo do outro; recebeu uma correção local das pernas/pés.
- `sources/te-rpg-v18-side-pass.raw.png`: duas passagens laterais com pés juntos sob a anca.
- `sources/te-rpg-v18-down-reach.raw.png`: dois avanços frontais antes do contacto.
- `sources/te-rpg-v18-side-reach.raw.png`: dois avanços laterais.
- `tools/pack_te_rpg_v18.cjs`: composição do atlas a partir destas pinturas completas e dos contactos v17; usa os utilitários de recorte de `pack_te_rpg_v17.cjs`.
- `te-rpg-v18.recipe.json`: fases, proveniência e registo de cada desenho.

## Verificação

`tests/te_gait_phases_test.gd` mede apenas a geometria dos sapatos. Exige apoios frontais opostos, menor diferença de profundidade na passagem frontal, pés próximos sob a anca na passagem lateral, e posições de avanço entre passagem/contacto. As diferenças na pintura do rosto não contam como novos passos. O v17 falha estes critérios; o v18 passa.

`tests/te_rpg_integration_test.gd` compara os pixels do Te real no motor com o atlas, nos seis passos, parado, direita/esquerda e baixo. `tests/character_direction_consistency_test.gd` verifica escala e chão.

Pré-visualização renderizada no motor: `output/te-propostas-rpg/te-v18-caminhada.gif`. Sequência completa: `output/te-propostas-rpg/te-v18-sequencia.png`.

## Pedidos — ferramenta integrada

### Base comum

Use case: precise-object-edit, identity-preserve. The supplied single Te character is the APPROVED visual model. Keep his face identity, head and hair size, exact slim young-adult physique, body proportions, short/slim forearms, charcoal t-shirt, ivory shorts, black trainers and painted RPG art style. Same camera, lighting and character height. Create EXACTLY TWO complete figures SIDE BY SIDE in a single row, two equal cells with generous transparent margins. They are TWO DIFFERENT specified intermediate WALKING PHASES of this same character, not an idle and not two copies. Every head/neck/collar/body/limb painted coherently together. No changes of physique, no cartoon, no photorealism, no added muscles, no elongated body. Do not draw a long spread-leg contact stride: these images MUST be intermediate silhouettes. Background genuinely transparent, no floor, shadows, text or decorations.

### down-pass

FRONT VIEW: Both figures face DOWN toward viewer, matching the elevated view of reference. These are MID-PASSING frames, with FEET CLOSE BESIDE EACH OTHER BELOW THE HIPS and at almost the SAME VERTICAL LEVEL. One foot planted, other only slightly lifted about one quarter shoe height, almost side by side — no long forward leg, no raised knee near shorts. LEFT FIGURE: stance leg on SCREEN RIGHT stays nearly straight and bears weight; SCREEN LEFT foot passes beside its ankle, only slightly above floor with relaxed small knee bend. RIGHT FIGURE: opposite stance leg on SCREEN LEFT nearly straight and planted, SCREEN RIGHT foot passes beside its ankle slightly above ground. Both arms near the middle of their swing, gently alternating with legs; normal relaxed hands beside hips. The frontmost shoe must not be far below the other shoe as in a contact stride. The two silhouettes should be almost like standing with one heel slightly lifted, but anatomically a passing step.

### side-pass

RIGHT-FACING VIEW: Both figures face RIGHT at EXACT reference side/RPG camera angle. These are MID-PASSING frames. In each figure, BOTH SHOES are very close horizontally UNDER THE HIP: no spread stride. One leg supports body almost vertical with sole flat; the other knee bends gently forward and its lifted foot is NEXT TO OR JUST BEHIND the supporting ankle, only a quarter shoe height off floor. LEFT FIGURE: the NEAR/visible leg is the vertical planted leg and the FAR leg passes beside it slightly lifted; near arm nearly vertical in mid-swing with relaxed elbow. RIGHT FIGURE: the FAR leg is the vertical planted leg, NEAR leg passes beside it slightly lifted; near arm is in the opposite mid-swing. Preserve two complete legs and arms, even if overlapping. There must NOT be one shoe stretched far forward and another far back. The compact feet-under-hips silhouette is ESSENTIAL.

### down-reach

FRONT VIEW: Both figures face DOWN toward viewer at same elevated camera angle. These are SHORT REACHING steps, halfway between feet-together passing and full contact. LEFT FIGURE: SCREEN LEFT/anatomical right foot has just passed support ankle and is extending forward toward viewer, toe slightly lifted, heel about to land; SCREEN RIGHT/anatomical left leg supports behind nearly straight with heel beginning to lift. RIGHT FIGURE: inverse — SCREEN RIGHT/anatomical left foot extends toward viewer, SCREEN LEFT/anatomical right leg supports. Use only HALF the normal contact stride: the two soles differ in vertical image position by about half one shoe length, not a whole long extended leg. Low knee, casual RPG walk. Arms halfway toward opposite contact swing, not stiff. Do not draw full contact, no wide knee lift. This is forward reach before landing, with modest compact leg separation.

### side-reach

RIGHT-FACING VIEW: Both figures face RIGHT at exact reference camera angle. These are SHORT REACHING steps, after passing but BEFORE full heel contact. LEFT FIGURE: NEAR leg remains back supporting almost straight, FAR leg has passed it and reaches a SHORT distance forward with knee still slightly relaxed and toe gently lifted; NEAR arm swings gently forward. RIGHT FIGURE: NEAR leg reaches a SHORT distance forward, FAR leg remains back supporting, NEAR arm swings gently back. Only HALF the normal spread contact stride: front and rear shoe centres separated roughly ONE SHOE LENGTH, not two or three shoe lengths. The lifted/front heel is just above floor, no running, no crouch, no high knee. Preserve slim forearms. These should visually sit between a feet-together passing pose and a fully extended contact pose. Near and far leg assignments must be reversed between the two figures.

### Correção final da passagem frontal

PRECISE LOCAL LEG EDIT. Keep this exact two-character Te image, both full figures, same faces/hair/shirts/shorts/arms/colors/proportions. Correct ONLY the LOWER LEGS AND FEET to make the intended MIDDLE PASSING STEP, not a contact stride.
In BOTH figures the bottoms of the TWO SHOES must be at ALMOST THE SAME HORIZONTAL HEIGHT in the image, differing by only about 1/5 of a shoe height. Currently one shoe is much higher behind; LOWER THAT SHOE until it is close beside the other ankle, just barely above the floor. Do not extend the lower/front shoe further forward. Both feet should sit next to one another, nearly like the original relaxed neutral standing pose, except the swinging heel is slightly lifted. One support leg straight, the other relaxed with only a tiny knee bend. No long stride, no front-versus-back foot split, no high bent knee. Left figure support leg SCREEN RIGHT, SCREEN LEFT foot slightly lifted beside it; right figure support SCREEN LEFT, SCREEN RIGHT foot slightly lifted beside it. Maintain exactly the same young adult Te and head-to-body ratio. Keep entire upper body unchanged. Transparent background, exactly two full figures side by side, no ground or text.

