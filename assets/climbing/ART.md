# Escalada — Serra de Sintra

Novas pinturas criadas com a ferramenta de imagem integrada, a partir das fotografias de referência fornecidas pelo utilizador: granito arredondado, fissuras escuras, líquenes, vegetação da serra, vista sobre a planície e muralhas do Castelo dos Mouros.

- `sintra-panorama.png`: pintura distante com paralaxe e vista que se abre durante a subida.
- `granite-atlas.png`: atlas original de seis penedos com transparência, preservado como referência da primeira versão.

Os originais gerados ficam preservados; o jogo consome estas cópias locais. A geometria de navegação é independente da pintura e está em `scripts/climbing_route.gd`. Os dois personagens conservam as pinturas e os retratos existentes.

## Revisão da escalada

O fundo agora é uma parede contínua de granito até ambos chegarem ao cume. `climbing_wall.gdshader` usa a textura de granito, com fissuras e variação de líquenes; o panorama só é revelado no final. As mesmas rochas são inclinadas, abanam, caem ou são empurradas de acordo com a simulação. Não foram criados nem alterados sprites dos personagens nesta revisão.

## Quatro perspetivas

`climbing_perspective.gd` desenha os volumes reais de granito num mundo 3D, com câmara ortográfica em órbita e quatro projeções jogáveis. `climbing_granite_3d.gdshader` aplica uma textura de superfície por projeção triplanar, sem esticar pinturas de pedras inteiras sobre as faces. Um passe de fundo mantém o maciço decorativo atrás das saliências jogáveis nas quatro vistas. As marcas e os objetos de cooperação acompanham a projeção. A pintura e os sprites dos personagens continuam a ser os existentes; não foram criadas imagens novas para esta mecânica.


## Maciço central e granito natural

A geometria em `scripts/climbing_geology.gd` forma um maciço contínuo centrado em X=640/Z=0. As 18 saliências têm contrafortes com a base enterrada nesse volume. Os contornos são amostrados em anéis irregulares com ombros arredondados, variação de espessura e bordos erodidos; as curvas do cimo são também usadas pela simulação para assentar os pés. As placas frágeis têm raízes permanentes por baixo. As normais das superfícies apontam para fora, respeitando a ordem dos triângulos do Godot.

`granite-surface.png` é uma nova textura de granito cinzento, com quartzo, feldspato, mica e líquenes discretos. Gerada com a ferramenta integrada **imagegen**, em modo de geração, e copiada para este projeto. A imagem original foi preservada em `/Users/tmvaz/.codex/generated_images/01a192b6-27ff-71a2-b534-db4bcb09d659/exec-0955a6dd-ca35-4efe-8fc8-0da0fdf894a6.png`. O mapa de cor é aplicado por projeção triplanar; iluminação, grão, relevo e fissuras são calculados no cenário 3D. O atlas antigo continua preservado. Os sprites das personagens não foram alterados.

Prompt final usado na ferramenta integrada:

> Use case: photorealistic-natural. Asset type: square seamless tileable PBR base-color texture for a realistic 3D rock climbing game in Serra de Sintra, Portugal. Create a flat orthographic close-up albedo scan of weathered natural pale gray Sintra granite, filling the entire square edge to edge. Fine irregular quartz and feldspar grains with tiny dark mica specks; subtle irregular gray and warm gray mineral mottling, very sparse muted olive-gray crustose lichen blended naturally into the rock. The surface is one continuous unpolished rough stone surface, not a collection of rocks. Realistic photographic mineral detail. Neutral flat diffuse lighting with no baked directional lighting, no shadows, no bevels, no 3D perspective, no raised boulders, no outlines, no large cracks, no deep holes, no recognizable repeated motifs. Seamless on both axes, stochastic non-repeating detail, balanced uniform brightness, not mirrored. High-resolution texture suitable for triplanar projection onto irregular 3D granite geometry. No borders, no text, no symbols, no objects, no people.


## Penedos e arvoredo das fotografias

Duas novas imagens foram criadas com a ferramenta integrada **imagegen**, usando diretamente como referências visuais estas fotografias fornecidas pelo utilizador:

- `/Users/tmvaz/Downloads/image_processing20250313-11-teqthh.jpg`
- `/Users/tmvaz/Downloads/PenedodaAmizade.jpg`
- `/Users/tmvaz/Downloads/serra-de-sintra-4.jpg`

Ficheiros finais no projeto:

- `assets/climbing/sintra-botany-atlas.png`: pinheiro, arbusto perene, urzes/fetos e hera pendente, com transparência real. A leitura das regiões respeita as silhuetas completas e as raízes. A textura usa mipmaps e bordos alfa preservados.
- `assets/climbing/sintra-escarpment.png`: escarpa contínua de grandes blocos de granito fendidos e inclinados, com manchas de líquenes, mato e pinheiros entre as rochas. Sem céu nem vista da planície, para conservar a revelação do cume. O fundo tem paralaxe suave durante a subida e a rotação.

Os originais estão preservados na pasta de geração: `exec-8c8e9e56-d932-4ba8-9f94-769cc62c30f3.png` e `exec-c53bfa07-974c-44f2-90a2-6698e790a119.png`, em `/Users/tmvaz/.codex/generated_images/01a192b6-27ff-71a2-b534-db4bcb09d659/`.

`climbing_habitat.gd` coloca 164 grupos de vegetação no mundo 3D. As raízes são obtidas por interseção com a malha real da montanha e dos seus grandes penedos. A vegetação mantém as coordenadas durante a rotação; apenas as copas e os recortes se orientam para a câmara. As plantas da face traseira ficam ocultas. A folhagem desenha-se por cima do maciço distante e por baixo dos apoios e personagens. Os grandes penedos têm planos de clivagem, tonalidades diferentes e líquenes mais visíveis. Os sprites das personagens continuam intactos.

Prompt do atlas, com fundo transparente:

> Transform the vegetation visible in the three reference photos of Sintra's granite outcrops into a game-ready botanical cutout atlas. Input photos are habitat, species, color and realism references; do not include their rocks, scenery, people, castles or sky. Asset type: photorealistic isolated vegetation for a 3D climbing game, TRUE transparent RGBA background, no contact shadow, crisp natural alpha edges. One square atlas in a strict 2 by 2 grid of FOUR separate specimens with wide empty transparent gutters, no overlap between cells, no labels or borders. Upper-left cell: a complete mature Mediterranean maritime pine tree, crooked reddish gray bark trunk, irregular spreading crown of dark olive green pine needle clusters, full trunk to its root base visible, natural asymmetry. Upper-right cell: a dense irregular evergreen strawberry-tree shrub with many small leathery dark green leaves and fine woody twigs, wider than tall, like the bushes between the boulders in the references. Lower-left cell: a low patch of Sintra heather, bracken fern and silvery-green scrub with fine irregular shoots and a few subdued pale purple heath flowers. Lower-right cell: a downward trailing clump of ivy, moss and small fern fronds growing out of a rock fissure, roots at its upper center, foliage hanging down. Soft neutral outdoor lighting and subdued natural greens matching the reference photos, realistic photographic leaf and needle detail, no glossy plastic, no cartoon shapes. Keep each entire specimen inside its own grid cell with transparent margin on every side. The first three specimens have their visible root base at the bottom of their cell; the trailing ivy has its attachment point at its top. No grass ground plane, no flower pots, no soil blocks, no people, no text.

Prompt da escarpa:

> Reinterpret these three reference photographs into a photorealistic environment backdrop for a Serra de Sintra rock climbing game. Preserve the distinctive Sintra granite geology and vegetation: huge irregular tilted gray and warm gray granite boulders with broad oblique cleavage planes, rounded weathered edges, deep dark fissures separating the boulders, pale crustose lichen patches, dense dark olive evergreen scrub, bracken ferns, ivy and maritime pine foliage growing in the channels between the rock masses. Wide landscape image, full frame edge-to-edge a steep rocky mountainside viewed straight on. The rocks dominate roughly 70 percent of the composition; connected ribbons of real dense vegetation weave between them and along both flanks, like the references. A few crooked pine trunks and branches emerge from cracks, pine crowns frame the far sides. This is the mountainside itself, with a convincing continuous mass and natural deep crevices, not floating rocks or a collection of isolated assets. Soft natural daylight, restrained contrast and atmospheric depth, realistic rough mineral surfaces. No sky, no horizon, no sea, no city, no distant panorama, no castle, no people, no climbers, no ropes, no paths, no artificial platforms, no flat shelves repeated at regular heights, no bowls or carved concrete shapes, no text, no border. The image will sit behind actual 3D climbing geometry, so avoid strong focal objects, keep the middle slightly darker and less detailed than the flanks. Consistent detail across the full frame; natural believable irregularity, no decorative repeating patterns.
