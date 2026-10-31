# Jo walk v9 — painted face and continuous neck/collar

Final atlas: `jo-walk-v9.png`, 4000×5600, five views × five complete poses.
Final reference: `sources/jo-heads-v9.png`.
Generation: built-in image_gen, two transparent image edits. No API/CLI fallback.

The v8 facial identity is retained with slightly broader painted shading, reduced
photographic skin detail, and the brush/detail scale of Te and the game. The first
style edit is saved in `sources/jo-heads-v9.raw.png`. The second edit supplies an
intact neck, curved crewneck collar and sufficient fabric beneath it, saved in
`sources/jo-busts-v9.raw.png`. Both prompts are reproduced below.

The packer fits one portrait per view, keeps its scale fixed and follows the
approved torso lean in every gait key. It replaces the old head/neck opening,
uses the authored collar rather than a sampled trapezoid of skin, and blends
only nearby fabric into the moving shirt. The fabric blend is feathered sideways
and downward; the previous collar and any remaining skin below the new neckline
are removed from that transition. A profile contour limit keeps the source bust
from projecting past the walking torso. Small bounded gaps within the collar
are closed, without filling the open spaces around the limbs.

The approved body, outfit, movement, ground anchors, 112-unit stride and eight-tick
cycle remain. Pixels below the neck repair bands (84/84/88/84/84 native pixels)
are identical to `sources/jo-body-v8.png`. Runtime uses one draw of a complete
sprite: the head, neck, shirt, arms and legs are in the same PNG region. The source
portrait and identity mask are offline production/validation inputs only.

Te v9 remains byte-for-byte unchanged (SHA256
`f3536d224b6e786e39ccbfb76f1c2ff5fa4c2e35e5eb1f950bfab1ae3a1d98ba`).
The active Te build entry points also reapply Jo v9 so a rebuild retains this face.
Rebuild Jo with `tools/pack_jo_walk.cjs` using Node and sharp.

Validation: `jo_walk_consistency_test.gd` checks facial/cranial consistency,
unchanged lower bodies, gait keys and foot anchors, opaque neck-to-shirt joins,
a stable front/rear skin boundary and the absence of old skin blocks over the
collar. `te_walk_consistency_test.gd`, `walk_cycle_test.gd` and the graphics-based
`character_rendering_test.gd` check regressions. Visual review covers 25 baked
poses and the four walking keys in all eight directions in the actual garden.

## Style edit prompt

Use case: style-transfer, identity-preserve.
Asset: five-view painted character head reference strip for the existing Tejo game.
Input image 1 is the EDIT TARGET: Jo's approved almost-perfect head strip. Input image 2 is Te, STYLE REFERENCE ONLY.
Make a subtle style refinement ONLY to Jo in image 1: move his rendering a little closer to Te's hand-painted adventure-game illustration. Preserve Jo's exact identity, longer slim face, long nose and profile, brown eyes, thick eyebrows, lifted dark wavy quiff, ears, light stubble and faint closed-lip smile. Do not turn Jo into Te. Keep all five views, order, head silhouette, viewpoint, scale, spacing, neck length and burgundy shirt neckline exactly as in image 1.
The change should be modest: simplify photographic pores and tiny stubble into soft painted shading planes; make hair locks and facial shadows slightly more deliberately brushed, with the same restrained painted edge definition as Te. Retain natural anatomy and recognizable facial features, no cartoon exaggeration or cel shading. Dark hair, soft diffuse lighting, no shiny highlights or top light halo. Keep detailed eyes but remove photographic skin texture. No accessory, no text, no watermark.
Return the same wide five-head strip (front, front-right, right profile, rear-right, rear) on genuine transparent background. Include intact necks and small burgundy round-neck collar/shoulder bases, with smooth natural painted skin-to-collar transitions and no geometric blocks.

## Neckline/chest extension prompt

Use case: precise-object-edit, identity-preserve.
EDIT TARGET is this five-view Jo reference strip. Preserve EXACTLY all five heads, hair, facial drawings, expressions, angles, skin and neck rendering, positions and sizes. They are approved. Do not redesign, move, rescale or repaint the heads.
Repair and extend ONLY the maroon T-shirt/collar base underneath each neck. Each collar should be a complete naturally curved round-neck burgundy T-shirt collar joined smoothly to the neck, with an uninterrupted maroon upper chest and shoulders beneath it. Currently the chest is cut off too close to the neckline. Extend the canvas DOWN by about 140 pixels and extend the painted maroon fabric downward into that new area, giving a substantial band of plain painted shirt below every collar. Keep each head and neck at exactly the same location and pixel size in the original portion of the image. Do not crop any collar or neck at the bottom. The front collar must be smoothly curved and painted, not a straight horizontal cut; the back collar naturally follows the nape. Same hand-painted adventure game style and soft shading, dark burgundy crewneck shirt. Five separate busts remain on transparent background, no text, no shadow, no frame.

