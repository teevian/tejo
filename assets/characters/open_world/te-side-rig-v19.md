# Te — caminhada lateral articulada v19

Apenas a lateral do Te foi substituída. O atlas v18 continua a fornecer a caminhada para baixo e as poses paradas. Jo e os outros ângulos não mudaram.

O ciclo lateral anterior combinava pinturas independentes com dimensões diferentes de cabelo, tronco e membros. O v19 usa um único conjunto de peças articuladas, com transformações rígidas, comprimentos constantes e movimentos contínuos. Não há redimensionamento por fase nem mistura dos bustos gerados anteriormente.

## Modelo e movimento

- A cabeça e o cabelo usam os pixels da pose lateral parada aprovada do v17, sempre a mesma textura e geometria.
- O tronco usa uma única pintura. A ferramenta integrada image_gen removeu os braços dessa referência para reconstruir o tecido oculto da t-shirt e dos calções, sem gerar novas poses de caminhada.
- Os braços e mãos vêm da referência aprovada. Mangas e braços rodam nos ombros, cotovelos articulam-se; a perspetiva do braço distante é constante.
- Coxa, perna e sapato têm comprimentos e tamanhos fixos. A cinemática inversa mantém a perna de apoio mais direita e o pé que passa baixo.
- Há duplo apoio, passagem, avanço e contacto contínuos. A bacia acompanha geometricamente os apoios com uma pequena deslocação vertical; não há inclinação nem abanão horizontal do boneco inteiro.
- A lateral usa144 unidades por ciclo; a caminhada para baixo mantém112. A amplitude abre/fecha com a velocidade no arranque e na paragem; as peças nunca são esticadas.
- A esquerda é o espelho exato da direita.

## Ficheiros

- `scripts/te_side_rig.gd`: modelo, articulações, trajetória dos pés e desenho.
- `shaders/te_side_rig.gdshader`: mantém o recorte opaco e exclui tecido residual das peças dos antebraços.
- `te-side-rig-v19-original.png`: referência aprovada, 400×560.
- `te-side-rig-v19-body.png`: pintura fixa dos tecidos e pernas sem braços a tapá-los, 400×560.
- `sources/te-side-rig-v19-clean.raw.png`: resultado original da ferramenta integrada de imagem.
- `tools/pack_te_side_rig_v19.cjs`: registo da única pintura e cópia da referência original; `te-side-rig-v19.recipe.json` documenta a origem.

## Validação

`tests/te_side_rig_test.gd` verifica os comprimentos dos membros em256 fases e em diferentes intensidades de arranque/paragem, a postura de apoio, o ciclo sem descontinuidades e a deslocação vertical limitada. Com gráficos, instancia o Te real e compara cabeça/cabelo com a mesma pintura original em32 fases, para ambos os lados. Não aceita diferenças de pintura como prova de uma nova pose.

Também passam a integração do personagem real, mudanças de direção/escala/chão, o desenho das interações e a geometria da caminhada frontal.

Pré-visualização real: `output/te-propostas-rpg/te-v19-lateral.gif`. O teste grava as32 fases em `/tmp/tejo-v19-side/`; `tools/preview_te_side_rig.cjs` empacota a animação com um fundo neutro.

## Pedido de imagem — ferramenta integrada, edição transparente

Use case: precise-object-edit. Edit the EXACT supplied Te side-facing idle sprite for use as a 2D skeletal animation texture. Preserve image dimensions 400x560, exact pose, head, hair, face, body proportions, shirt, shorts, legs, feet, colors, painted style and camera.
Remove ONLY BOTH ARMS, including upper arms, forearms and hands. Where those arms and hands hide the side of the shirt and shorts, reconstruct the hidden charcoal t-shirt and ivory shorts as a clean seamless continuation of the original garment. Make the shirt sleeve stubs end cleanly at the shoulder socket; no loose limbs or floating hands. Keep the whole original head/neck/torso/hips and BOTH LEGS AND SHOES in exactly the same locations, sizes and proportions. No redesign, no body slimming, no height change, no new pose, no shadows or text. The head and legs are NOT being removed. This is a technical underpainting so the original separate arms can swing over it.
Maintain genuine transparent alpha background and every empty space between legs. Clean shirt and shorts behind the removed arms, including the near hand that covered the outer hip/shorts. Exact same wide short sleeve shirt, narrow waist and original fabric hem, ordinary young adult body. Do not add wider shoulders or change head size.

