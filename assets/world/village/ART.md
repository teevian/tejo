# Vila de Sintra — arte final

3 novembro 2026. Ferramenta: **image_gen integrada**, modo de bitmap, sem CLI/API externo. Referências de estilo: capturas atuais do jogo produzidas por `tests/open_world_preview.gd`, sobretudo a capela, e `assets/world/heritage/convento_capuchos.png`. Estas referências orientam pintura, cor e materiais; os personagens nelas visíveis não foram redesenhados. Referências arquitetónicas reais e limitações: `docs/VILA_DE_SINTRA.md`.

A ampliação com fachadas altas, mercado e calçada de losangos está documentada em [URBAN_ART.md](URBAN_ART.md), incluindo os três assets adicionais e os pedidos completos. O atlas `houses.png` permanece como referência de estilo da geração; as fachadas atuais usam `urban-frontages.png`.

Assets iniciais no projeto:

| Ficheiro | Dimensões | Aplicação |
|---|---:|---|
| `national-palace.png` | 1536×1024, RGBA | Palácio completo e três arcadas com alfa |
| `landmarks.png` | 1536×1024, RGBA | Seis silhuetas: igreja, Valenças, Lawrence’s, Piriquita, Sassetti, Fonte Mourisca |
| `houses.png` | 1774×887, RGBA | Oito famílias de fachadas, sem fundos de terreno |
| `pavement.png` | 1254×1254 | Calçada com grão pintado; cor e escala ajustadas no material do terreno |
| `stone-stairs.png` | 1254×1254 | Degraus de granito; um recorte finito por cada novo lanço curto |

Os pedidos indicavam dimensões/grades de produção; a ferramenta devolveu as dimensões acima. Os recortes foram medidos no alfa dos ficheiros finais e são consumidos no Godot através de `data/village/art-regions.json`, sem redimensionar nem voltar a pintar as imagens. `landmarks.png` teve uma passagem de remoção de fundo: o primeiro resultado tinha um mate claro semitransparente. O resultado final tem fundo com alfa zero, verificado antes da integração. As superfícies dos edifícios usam o mesmo material opaco da serra; ficam transparentes apenas os intervalos das silhuetas. Não foi alterado nenhum atlas de personagem.

## Pedidos usados

### Palácio Nacional (`stylized-concept`)

Create a final production transparent-background game architecture sprite, landscape 1536x1024 or larger. References are STYLE REFERENCES ONLY, never edit or include their characters. Match Tejo's rich crisp hand-painted gouache brushwork, fine terracotta tiles, limestone blocks, natural muted emerald shadows, warm chalk whites and aged ochre, detailed expressive stylized geometry. ONE complete Palácio Nacional de Sintra exterior: recognisable asymmetric long white Portuguese royal palace, red terracotta pitched roofs, TWO very tall tapered white conical kitchen chimneys behind central wing, crenellated left wing and ornate Manueline double windows, THREE open broad ground-floor arched loggia bays in middle, low wide stairs. Faithful silhouette, no invented castle spires. Strict orthographic steep three-quarter overhead adventure-game view, front south-facing facade horizontally aligned, see considerable roof area, no isometric diamond foundation, horizon or sky. Building centered, complete with transparent padding. Only building and attached stone steps, no plaza, ground plane, trees, people, text or exterior shadows. Opaque architecture with real alpha outside and in arch openings. Clean cutout for foot-depth sorting.

### Seis locais (`stylized-concept`)

Production transparent game sprite atlas, requested 3072x2048 landscape, strict regular 3 columns x 2 rows. Six complete architecture sprites, each isolated with transparent padding, nothing crossing cells. Match existing Tejo detailed gouache painting, visible brush texture, expressive painted stones, terracotta roofs, muted emerald shadows, warm whites and soft daylight. Orthographic steep semi-top-down adventure camera, roofs and south-facing facades, horizontal front edge, no diamond foundation, surrounding ground or sky. Top-left: Igreja de São Martinho, compact pale cream church, pediment, rectangular bell tower, round upper opening, arched portal, grey stone trim and red roof. Top-middle: Palácio Valenças, salmon pink Italianate palace, white stone three-arch loggia, pointed finials, coat of arms and three stories. Top-right: Lawrence's Hotel, long pale peach ochre two-storey facade, grey window frames, green shutters, dormer roof, iron balcony, red lettering “LAWRENCE'S HOTEL”. Bottom-left: Piriquita, narrow two-storey house, yellow ochre ceramic shop tiles, dark lettering “PIRIQUITA”, white shop doors, plaster and green shutters above, red roof. Bottom-middle: Vila Sassetti, rustic terracotta villa with large round Lombard Romanesque crenellated tower, granite walls, arches, lower red-roofed wing and a little ivy. Bottom-right: Fonte Mourisca, grey stone facade, large scalloped horseshoe arch surrounding three smaller horseshoe arches, red geometric arabesque tiles, municipal shield, basin. No scenery, people, cast ground shadows or other labels. Clean isolated depth-sorted game cutouts.

### Remoção do mate do atlas (`background-extraction`)

Edit target: attached 1536x1024 six-building 3-column 2-row atlas. Remove the white/light grey background AND thin grey cell divider lines completely. Set background alpha to zero: real fully transparent background, no matte, semitransparent haze or painted checkerboard. Preserve all six buildings, exact cell layout/dimensions, architecture, colours and text. Keep all building paint including WHITE plaster fully opaque. Only exterior background becomes alpha zero; no white rectangles behind cells, no ground shadows. Complete isolated clean production sprites.

### Fachadas (`stylized-concept`)

Final game architectural assets, requested 3072x1536 transparent regular atlas, strict 4 columns x 2 rows, eight complete distinct historic Sintra Portuguese houses. Each within its cell, complete roof and base, alpha padding and no crossing cells. References are style only: precise rich gouache, crisp brushwork, warm whites, muted mustard, salmon, grey stone, burgundy, green, red roofs. No photo, flat vector or pixel art. Consistent orthographic steep overhead adventure camera: horizontal facade, pitched roof and a little right side, no diamond base. Two or three storeys, for 156px humans beside 400–520px buildings. Top row: cream bakery with burgundy awning, limestone frame, green shutters and iron balcony; blue azulejo antiques shop, three bays and blue shutters; mustard three-storey corner house with irregular roof, side stairs and granite quoins; dusty rose cafe with striped cream awning, balcony and white climbing flowers. Bottom row: smaller whitewashed stone cottage with twin green doors; sage tiled grocer with recessed window and green shutters; elegant ochre mansion with pilasters, central arch and balcony; ivory bookshop with maroon doors, dormer and irregular chimney. Opaque architecture, real alpha outside. No paving rectangles, ground, people, trees, separate furniture, ground shadows, text or frames. A coherent painted historical neighbourhood.

### Calçada (`stylized-concept`)

One square seamless 1024x1024 texture of traditional Portuguese historic village limestone and granite cobblestone paving. Reference is style only; do not copy forest or characters. Fine crisp hand-painted gouache, orthographic straight top-down ground. Small irregular warm pale grey and beige cobbles, occasional darker slate cobble, thin brown mossy joints, worn stone, neutral palette, delicate brush strokes and speckles. Even soft daylight; no shadow, vignette, perspective, buildings, people, objects, text, crossing paths or black-white wave motif. Tiny moss only in joints. Dense homogeneous stones to all edges. Opaque painting.

### Escadas (`stylized-concept`)

One production seamless painted ground texture, square 1024x1024, straight overhead. A continuous straight run of traditional aged grey granite stone stairs filling the image, twelve horizontal parallel treads from left edge to right, repeated top to bottom. Broad worn grey limestone, fine gouache grain, occasional warm mottling and moss at joints. Thin subtle dark riser shadow, thin rounded pale nosing; shallow depth and no railings. Horizontal treads, ascent vertically up, slight chipped irregularity. Match reference Tejo painted stone style, cooler granite rather than ochre round cobbles. No perspective, sides, walls, plants, people, text, sky, borders, ladders, planks or empty background. Texture covers a walkable stair segment.
# Fachadas laterais — revisão de 3 de novembro de 2026

Ficheiro final novo: `side-frontages.png`, 1536 × 1024 RGBA, oito edifícios pintados de esquina e de lado. Gerado com **ImageGen integrada**, usando `urban-frontages.png` e uma captura do jogo como referências de estilo. Origem: `exec-9ee4b117-864c-4f21-b17a-39261dd84827.png`. Copiado sem alterar os píxeis; os recortes nativos estão em `data/village/art-regions.json`. A implantação conserva as bases sólidas e orienta os novos acessos para as ruas próximas. Os 206 edifícios laterais incluem prédios, casas e lojas.

As quatro novas escadas são construídas na geometria do jogo: cada lanço é curto e finito, com patamares, degraus de granito, muros de suporte e desnível de 72 unidades. O atlas anterior de granito é usado uma única vez por lanço, sem repetir a textura ao longo de ruas curvas. Não foram recriadas as antigas escadarias.

## Pedido usado nas fachadas laterais

Use case: stylized-concept.
Asset type: final 2D environment building sprite atlas for the existing Tejo game, historic Sintra Portugal.
Primary request: EIGHT genuinely SIDE-VIEW and CORNER buildings. The current game has only flat frontal facades. New buildings must clearly show deep long side elevations facing the narrow street to the LEFT or RIGHT, with shop doors and windows along those side faces. These are NEW buildings in the same painted village, not edits of the existing atlas.
Input 1 existing building atlas STYLE ONLY (warm gouache, terracotta roofs, Portuguese stone window frames, stucco/azulejo, visible brushwork). Input 2 actual game screenshot for lighting, detail and game camera. Do not copy people or scenery.
Composition: transparent PNG landscape sheet requested 2400x1600, EXACTLY FOUR COLUMNS by TWO ROWS = eight isolated complete buildings, all on the SAME elevated orthographic/axonometric game camera, no vanishing point. Each entire building inside its own cell, transparent gutters. Roof, walls and foundation all visible and complete. No ground, streets, steps, plants outside footprint, shadows on floor, people, backdrop, captions or labels.
Crucial architectural change: each building has a dominant long SIDE elevation at 30–45 degrees to screen plane and a narrow secondary END elevation. Not flat front-facing facades with a tiny strip of side. The dominant side must have 3–4 window bays and multiple storeys; corners visibly recede. Ground storefronts turn the corner. Do not rotate a flat front image. Equal overall building scale, natural structural perspective, roofs over both faces.
TOP ROW, LEFT TO RIGHT:
1. Three-storey ochre apartment and small ground-floor bakery, dominant side facing screen RIGHT, narrow end face on left. Terracotta ridge roof recedes deeply, cream limestone frames, dark green doors and side-facing shop windows with bread. No readable signs.
2. Three-storey pale blue tiled corner apartment over pottery shop, dominant side facing screen LEFT, narrow end on right. Deep long side with balconies, blue-white azulejos, dark-blue framed side shop windows containing ceramic vases.
3. Two-storey cream residential house, almost PROFILE facing screen RIGHT: long side with four shuttered windows, small recessed doorway on long side and a clearly visible short gable end. Steep orange tiled roof receding diagonally, green shutters, real depth.
4. Three-storey dusty pink corner cafe, dominant side facing screen LEFT, narrow end on right. Long side with green shopfront windows, cafe tables visible INSIDE only, stone door lintels, simple small burgundy awnings attached to side.
BOTTOM ROW, LEFT TO RIGHT:
5. Four-storey narrow golden-yellow apartment, dominant side facing RIGHT, narrow gable end on left. Long wall with several windows on each floor, wrought iron balcony, green entrance door along the side. Tall believable town apartment proportions.
6. Two-storey pale mint grocery shop and home, dominant side facing LEFT, narrow end on right. Long side with open display windows and recessed dark green door, upper white-framed windows, terracotta roof.
7. Three-storey warm ivory bookshop and home, almost PROFILE facing RIGHT, dominant deep side elevation with side shop door and glass windows containing shelves of books, narrow end on left, green shutters above.
8. Three-storey blue-and-white tiled corner house, dominant side facing LEFT with long wall and stone-framed windows, narrow end on right, dark blue entry along side, orange tiled roof and chimney.
All eight as detailed hand-painted opaque architectural sprites with TRUE fully transparent alpha around each silhouette. No brown matte, no checkerboard, no borders, no decorative cards, no scenery or typography. Match game style, no pixel art, no photorealism, no flat vector.
