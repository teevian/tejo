# Te RPG v17 — integração da proposta escolhida

Substituído pelo [ciclo v18 com fases intermédias reais](te-rpg-v18.md). Esta versão é conservada como referência da proposta e dos contactos aprovados.

Fonte aprovada: `output/te-propostas-rpg/te-escolhido-antebracos-laterais-v2.png` (corpo ligeiramente mais magro, antebraços laterais discretamente mais finos).

Aplicação: só Te, direções baixo e direita, com esquerda por espelhamento. Outros ângulos e animações de interação conservam as imagens existentes. Jo não foi alterado. Acesso ao teste: Esc → Testar caminhada · só chão.

- Atlas ativo: `te-rpg-v17.png`, 2800×1120, sete colunas (parado + seis passos), duas linhas (baixo/direita).
- Fontes transparentes: `sources/te-rpg-v17-walk.raw.png` e `sources/te-rpg-v17-idle.raw.png`.
- Renderer: `scripts/te_rpg_walk.gd`, chamado por `scripts/open_world_art.gd`.
- Empacotador: `tools/pack_te_rpg_v17.cjs`; registo: `te-rpg-v17.recipe.json`.

Preparação: ferramenta integrada image_gen para remover o fundo da sugestão e criar as duas poses paradas correspondentes. O empacotador elimina resíduos desligados, recorta transparência, redimensiona uniformemente cada personagem completo e regista o chão. Usa uma escala comum por direção nas seis passadas, preservando pequenas diferenças naturais entre desenhos. Não há cabeças, bustos ou membros recolocados, alongamento de tronco/pernas, malhas ou inclinação adicional do sprite.

Os seis passos avançam por distância percorrida, mantendo o ciclo de112 unidades do jogo. Ao parar, o Te usa a pose neutra correspondente ao novo desenho. A escala do mundo mantém-se em164 unidades. As imagens aprovadas foram integradas para avaliação jogável, sem uma nova revisão das poses.

Verificação: `tests/te_rpg_integration_test.gd` compara o personagem real com o novo atlas, incluindo parado, seis fases, ambos os lados e transparência. `tests/character_rendering_test.gd` cobre os dois personagens e as interações. `tests/walking_test.gd` verifica o acesso pelo menu, controlos e regresso ao jogo.

## Pedido de recorte transparente — ferramenta integrada

Use case: background-extraction. Remove ONLY the dark background from this exact approved Te game sprite sheet, replacing it with genuine transparent alpha. Preserve the twelve complete painted characters EXACTLY: faces, hair, slimmer forearms, all silhouettes and internal colors, walking poses, clothes, necks, proportions and shoes unchanged. No repaint, no redesign, no new pose. Remove background also from gaps between arms and torso and between legs, preserving fingers and hair edges. Keep the exact original image dimensions 1584×993, composition, all six columns and two rows, exact placement and scale of each figure, complete crowns and soles with same margins. Top row walking toward viewer/down, bottom row walking right. No shadows, labels, matte halos, ground or objects. This is solely alpha cutout preparation for game integration; do not change the approved artwork.

## Pedido de poses paradas — ferramenta integrada

Use case: identity-preserve. Create ONLY TWO complete NEUTRAL IDLE RPG sprites of the EXACT Te character in the provided approved walking sheet. This is the standing/rest state for that walk, so match his face identity, hair, young adult age about20, body HEIGHT-TO-WIDTH proportions, slim athletic physique, slightly thinner side forearms, head size, shoulder width, shirt, shorts, shoes, skin colors, painterly style and slightly elevated RPG camera precisely. Do not make the body taller, slimmer or more muscular than the reference. The reference is approved, don't redesign it.
Layout: ONE ROW of TWO equal cells with generous padding, exactly2 full characters. LEFT is FRONT/down-facing toward viewer with same slight overhead game view; RIGHT is facing RIGHT in the SAME lateral angle as reference bottom row. Both stand naturally on TWO FEET, both soles flat on same ground line, knees relaxed but nearly straight, feet beside each other separated by a small gap, arms down relaxed beside hips with slight natural elbow bend, hands loose not clenched. No walking/lifting legs, no dramatic pose. Draw each complete character coherently from crown through collar to soles, no separated layers or body pieces.
Exact same recognisable approved face, dark tousled hair, charcoal short-sleeved crewneck tee, ivory above-knee shorts, black low trainers with light soles. Anatomically continuous slim neck and collar, complete sleeves. Genuinely transparent background, no ground, no shadows, no text, no frames or decorations. Keep the compact balanced adult proportions as supplied, not elongated limbs or trunk.

