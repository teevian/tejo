# Jo movement — photo-led rebuild

Built-in image generation, using photographs as the primary identity references:
IMG_0527 (front), IMG_0539 and IMG_0528 (profile), IMG_0471.HEIC (crown/front
from above), IMG_0549.HEIC (rear hairline). HEIC references were decoded for viewing.

Create 45 transparent full-body painted game sprites, nine columns and five rows:
front, front-right diagonal, right profile, rear-right diagonal, rear. Each row
contains idle and eight walking phases. Reproduce the photographed man's long
narrow adult face, prominent projecting convex nose, triangular thick eyebrows,
small dark eyes, narrow lips and longer chin. Reproduce near-black fine, slightly
wavy hair, compact shorter sides and back, gradually longer naturally tousled top,
crown whorl and low natural nape hairline. Avoid generic childlike facial proportions,
brown sculpted curls and round bouffant hair. Burgundy T-shirt, warm beige chino
shorts, grey/white sneakers. Elevated game camera, transparent isolated silhouettes.

The first edit of v3 was rejected during visual review because it retained too much
of the old head. This final atlas was rebuilt directly from photos. Output size:
1330 x 1182. All 45 silhouette bounds were measured from alpha and integrated in
scripts/open_world_art.gd. The portrait, Te, phone and interaction art are unchanged.
Visual verification: tools/preview_jo_movement.gd renders all 45 runtime frames to
output/jo-movement-v4-preview.png. The prior atlas remains available as v3.
