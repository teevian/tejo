# Te walk v8 — resolved incoming gait and selected local identity

Historical version, superseded by `te-walk-v9.prompt.md`: v9 repairs the sleeve/
arm cutouts, lowers the passing knee and darkens the hair. The current runtime
uses v9; `pack_pulled_te_walk.cjs` now delegates to the v9 builder. The v8 builder
is preserved separately as `tools/pack_pulled_te_walk_v8.cjs`.

Runtime Te atlas: `te-walk-v8.png`. Jo keeps the incoming `jo-walk-v5.png`.
This supersedes the local v7 shared-body experiment.

The body and four-key walk come from incoming commit `10593d9`. The original
renderer is preserved in `tools/pulled_walk_reference.gd`; the offline baker
`tools/bake_pulled_te_walk.gd` captures its 25 complete poses into
`sources/te-pulled-10593d9.png` at 4x native resolution. The original 112-unit
stride, eight ticks, two ticks per key, mirrored directions, heights 156/153,
and ground anchors are retained.

The user-selected local identity remains in `sources/te-heads-v7.png`, unchanged
(SHA256 `ecb33f65cfd123e1861acb2b1f34719ea7f6e1f7478bee37185b5d862e02d3a7`).
`sources/te-heads-painted-v8.png` is its subtle painted adaptation, made with the
built-in image_gen tool to match the body. The packer matches its detail scale
to the original body resolution, removes red/yellow cutout flecks, and fits each
head to the incoming neutral cranial dimensions. Each viewpoint reuses exactly
the same head across all its gait keys. Incoming collar/neck fabric is retained
and the jaw/nape join is repaired before packing.

At the user's subsequent request, the body is 5% narrower, without a height
change. The horizontal adjustment is centered on the original foot axis and
eases continuously from an unchanged head through the neck to the body. The
same transform applies to every pose. There is no new limb pose or gait timing.
`sources/te-pulled-slim-10593d9.png` records this independent body reference.
Every final body pixel below the repair region must match this reference.

`tools/pack_pulled_te_walk.cjs` produces the atlas, recipe and runtime pose table.
Its older `pack_shared_walk.cjs` / `pack_te_walk.cjs` entry points delegate here.
Each cell contains a whole character with the head already attached. Runtime
draws exactly one texture region; it never renders a separate head or limb.
Raw RGBA blits preserve the incoming body without alpha-compositing roundoff.

Validation: `te_walk_consistency_test.gd` verifies the original identity source,
all 25 refined body references, fixed heads, four distinct gait keys, phase
mapping, scale and anchors. The four original gait tests exercise the preserved
incoming renderer. `character_rendering_test.gd` exercises the actual complete
sprites for both people, eight directions, walking and interaction poses.
Visual checks use all eight directions and all four gait keys inside the game:
`tools/preview_shared_characters.gd -- --all-directions`, followed by
`tools/preview_character_necks.cjs`. The final preview is
`output/character-neck-walk.gif`.

## Painted-head edit prompt — built-in image_gen

Use case: identity-preserve / style-transfer. Edit target image 1: five-view strip of the EXACT same adult man Te. Supporting style reference images 2 and 3: the small hand-painted game bodies. Return ONLY the five head-and-neck views of image 1 on genuinely transparent background, same horizontal order, same equal-width five panels, same scale and positions as image 1, no labels. Preserve the man's exact identity, face shape, brown eyes, stubble, dark tousled hairstyle, expression, head angles, distinctive facial proportions and original silhouettes. Apply a SUBTLE painterly game-sprite finish matching the bodies: simplify photographic pores and tiny hair highlights into clean painted shadow masses, cohesive warm skin shading and soft dark contour, same warm light as the arms. Do not turn him into the younger cartoon man in image 3; image 3 is ONLY a painted shading reference. Keep the mature features of image 1. Hair remains dark brown with no halo or bright flecks along its outline. No yellow or red background residue. Keep natural neck and a little dark charcoal T-shirt collar. All five head views must be consistent painted illustrations. No complete bodies, no extra faces, no layout changes. The output remains faithful to image 1, only more like the subtly painted game bodies rather than a photographed head pasted onto them.
