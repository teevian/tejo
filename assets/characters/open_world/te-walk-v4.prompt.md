# Complete-sprite walk cycle

Five authored views, mirrored for eight directions. Atlas columns: rest, contact A, passing A, contact B, passing B. Each walk key is held for two ticks of the distance-driven eight-tick cycle. Complete silhouettes are extracted by connected alpha components so adjacent source frames cannot leak into a crop. No runtime limb meshes or deformations.

Jo retains his original v4 resting sprites and body height for each view. Additional whole-body key poses were generated from his v4 appearance. Te uses the same per-view height reference with a 156/153 display-height ratio; chest width is normalized to Jo plus 2% before the height ratio. Te has charcoal clothing, brown hair, stubble and black shoes.

Source images: Jo v4, exec-4c36360a-9a83-4e22-b496-c5a01e366cda.png, exec-4785625e-8473-4a50-be62-c4212faf087f.png, exec-70fe257b-6c53-4035-9f47-281777f7d9c5.png; Te exec-d8ef66b3-5390-4550-be47-4063cad3e174.png, exec-6961abcf-2999-4c70-aa4d-9cbc4304c1d3.png, exec-a4e59bfb-7f94-46f1-b9a7-669d8a37075e.png, exec-aac6b590-0424-4b38-929d-3042dc86c689.png, exec-f71a5e44-68f5-458c-9d5d-59ab12ad3bf4.png.

Image-edit instructions preserved identity/clothing and requested separate left/right contact and passing poses. Full frames were cropped, resized and packed; frontal/back contact opposites use complete-sprite horizontal mirroring. Portrait assets are unchanged.

## Front-facing consistency correction — 31 October 2026

The source painting is unchanged. Its front contact drawings have smaller faces and different torso proportions from the passing drawings. `scripts/te_front_gait.gd` now composes the front walk from the same painted resting head/shirt in every tick, retaining each original frame below source row 117 for the moving arms and legs. The original foot anchors, four key poses, two-tick holds, 112-unit stride and 156-unit display height remain unchanged. No new bitmap was generated or repainted. `tests/te_front_gait_test.gd` compares actual rendered pixels against the resting core and the original moving limbs.

## North-facing consistency correction — 31 October 2026

`scripts/te_north_gait.gd` applies the same composition to the north walk. Its head, shoulders and shirt use the north resting painting, anchored at source (90, 1285). The original north keys below source row 1148 provide the moving arms and legs, preserving their exact foot anchors, scale, four poses and cadence. The raster atlas remains unchanged. `tests/te_north_gait_test.gd` checks the rendered head/back against rest and the lower limbs/hands against the original north frames.

## Left/right consistency correction — 31 October 2026

`scripts/te_side_gait.gd` uses the same resting side-facing head, shoulders and shirt for all four side-walk keys. The idle arm covers part of the shirt, so that small area is filled with exposed cloth from the existing contact painting. The original painted arms move as rigid cutouts, anchored to consistent shoulders, with the far arm behind the torso and the near arm in front. Only the top waistband bridges the source poses' different shirt lengths; the original leg articulation, shoes, foot anchors, stride and two-tick holds remain intact. The complete composition is mirrored for leftward movement. No bitmap was generated or changed. `tests/te_side_gait_test.gd` verifies rendered head/torso consistency, rigid hand painting, original feet and left/right symmetry.

## Diagonal consistency correction — 31 October 2026

`scripts/te_diagonal_gait.gd` fixes both diagonal viewpoints using their respective resting heads, shoulders and torsos, anchored at source (90, 505) and (90, 1025). The original lower frames below source rows 420/944 and separate arm cutouts retain the exact painted articulations and foot anchors. The arm roots are trimmed beneath the fixed sleeves so the old, differently sized shirt silhouettes cannot protrude. Each composition mirrors for its western diagonal. The raster atlas, scale, stride, four keys and two-tick holds are unchanged. `tests/te_diagonal_gait_test.gd` checks the rendered head/torso against rest and the hands/lower limbs against independent original frame coordinates in all four diagonals. Jo retains complete-sprite rendering.
