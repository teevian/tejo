# Jo — personagem pintada

Criado com a ferramenta de imagem integrada, usando as fotografias fornecidas pelo utilizador como referência de rosto, cabelo, compleição e roupa. O fundo de Sintra serve de referência para a pintura. A primeira versão é conservada em jo-sprites.png; jo-sprites-v2.png conserva o refinamento da caminhada. jo-sprites-v3.png conserva a revisão facial anterior. Atualmente o jogo utiliza jo-sprites-v6.png, com cabeças integradas e repintadas nos ângulos próprios de cada pose a partir das feições do retrato aprovado. A sobreposição da cabeça frontal foi retirada; jo-angled-faces.prompt.md documenta a revisão. O avatar utiliza jo-portrait.png; a revisão é documentada em jo-face-refinement.prompt.md.

## Prompt original

Use case: stylized-concept, identity-preserving character adaptation from reference photographs.
Asset type: production-ready transparent 2D sprite atlas for the playable character Jo, matching the intimate hand-painted Sintra forest game style.
Input images and roles: IMG_0527.jpg is the primary frontal face identity reference. IMG_0531.jpg is the full-body clothing and build reference. IMG_0528.jpg is the profile identity reference. IMG_0532.jpg is the burgundy t-shirt and face reference. sintra-trail.png is ONLY the painterly medium/color/light reference, not an environment to draw.
Primary request: portray this same young adult man as an original indie game character. Preserve recognizable thick dark eyebrows, dark brown eyes, long subtly angular face, prominent straight nose, small warm asymmetric smile, short dense tousled dark almost-black hair lifted above the forehead and short at the sides, warm light olive skin and very subtle stubble. Slim athletic adult build. No glasses. Wears the muted BORDEAUX/BURGUNDY short-sleeve crew-neck t-shirt from the photographs, loose BEIGE knee-above shorts, exposed calves and pale warm grey sneakers with subtle dark soles. No backpack or props.
Style/medium: match the supplied forest painting: matte hand-painted gouache, dry-brush broken pigment, delicate charcoal accents and softly irregular textured silhouette, restrained muted tones, olive-grey bounce light and warm cream highlights. A personal, tender, slightly melancholic illustrated game style. Simplify enough for gameplay but keep the face distinctive. Adult stylized proportions, about 5 heads tall, head only gently enlarged; not chibi, not vector, not pixel art, not realistic photo cutout, not plastic 3D.
COMPOSITION STRICT: a clean rectangular 4-COLUMN x 3-ROW sprite sheet: EXACTLY TWELVE full-body images of the SAME Jo. Every frame centered in its own equal-sized invisible cell, full hair and sneakers visible, ample transparent margins, feet on the same baseline within every cell, identical body height and head size across all cells. All twelve figures face RIGHT in a gentle THREE-QUARTER side view, both eyes still subtly visible, suited for a horizontal side-scroller. Keep the face and costume identical in all frames. No dividing lines, text or labels.
Frames, read left to right:
Row 1: four quiet idle breathing poses, hands loosely hanging, gentle relaxed smile, tiny natural shoulder/chest changes, feet planted.
Row 2: first four frames of a six-frame walking loop: left-foot forward contact; passing step; right-foot forward contact; next passing step. Arms counter-swing naturally. Short walking steps, no exaggerated action poses.
Row 3: remaining two walking-loop frames returning to left contact; then one compact rising-jump pose with softly bent knees; then one falling/landing-preparation pose with feet down and arms slightly out.
Lighting: same consistent soft diffuse upper-left forest daylight, no cast floor shadows, no ground.
Constraints: actual fully transparent background and empty inter-cell gutters, no background color, no fake checkerboard, no floor, no landscape, no typography, no labels, no diagram, no watermark, only the twelve Jo cutouts. Do not draw Te or any other person.

## Refinamento

Preservar a identidade, o vestuário, o estilo e os quatro repousos e dois saltos. Refinar as seis poses de caminhada para alternar passadas abertas e poses de passagem com os pés sob a bacia, com movimento contrário dos braços. Manter transparência verdadeira, margens entre poses e ausência de legendas.
