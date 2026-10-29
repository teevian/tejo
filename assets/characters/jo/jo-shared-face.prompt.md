# Jo — tentativa anterior de cabeça sobreposta

Esta tentativa foi substituída por jo-sprites-v6.png, com cabeças completas repintadas em cada ângulo. A cabeça frontal sobreposta não é usada pelo jogo. Ver jo-angled-faces.prompt.md.

As doze poses usam diretamente a imagem aprovada `jo-portrait.png`, sem regenerar o rosto. O jogo desenha a cabeça a partir dessa textura, recortando apenas os ombros durante a renderização, e liga-a ao pescoço de cada pose com pequenas inclinações. A mesma textura permanece no avatar. O corpo usa `jo-body-poses.png`, preparado com a ferramenta de imagem integrada a partir das poses anteriores.

## Prompt para preparar as poses do corpo

Use case: precise-object-edit.
Asset type: body-only animation atlas for a layered 2D game character.
Edit target: the supplied 1427x1102 transparent Jo sprite atlas.
Request: REMOVE ONLY the twelve heads and their hair, replacing those head/hair pixels with fully transparent pixels. This is a normal non-graphic modular animation asset: leave a short natural neck stump above each burgundy t-shirt collar, no blood, no injury. A separate already-approved head painting will be attached in the game; do not draw any replacement heads or facial features.
INVARIANTS: Keep exactly the original canvas dimensions 1427x1102 and exactly the existing 4-column x 3-row atlas layout. Retain EVERY body pose in its original pixel position, the original burgundy t-shirt, beige shorts, exposed arms and legs, grey sneakers, all limb positions and all painterly details, shadows and lighting. Do not move, resize, restyle or repaint the bodies. Keep the existing six-step walk animation, idle poses and jumping poses. Change only the areas occupied by heads and hair above the neck, leaving the bodies and collars unchanged. Retain true transparency outside all body silhouettes. No floor, text, guides, grid or labels. Output only the edited body-only atlas, no portraits or extra assets.
