# Te walk v9 — continuous sleeves, grounded steps and dark hair

Final runtime asset: `te-walk-v9.png` (4000×5600, 5 views × 5 whole poses).
This supersedes v8. Jo's approved v5 body is now preserved in `jo-walk-v8.png`,
with photo-based facial identity documented in `jo-walk-v8.prompt.md`.

V8 inherited a fixed neutral T-shirt with separate moving limb cutouts. Those
cutouts could slice the side/diagonal upper arms and kept the sleeves frozen.
The repaired source `sources/te-natural-body-v9.raw.png` redraws complete poses:
shoulder, sleeve, upper arm and forearm join continuously; sleeves turn with the
arms, shirt folds respond, and the passing knees stay below the shorts rather
than lifting toward the waist. All views retain neutral/contact A/passing A/
contact B/passing B order and the approved slim build.

`tools/prepare_te_natural_sources.cjs` removes saturated matte keys and detached
residue, then registers every complete pose to the approved per-view height,
head position and ground baseline. It produces `sources/te-natural-body-v9.png`.
Warm skin shadows are retained; they are not mistaken for the red matte key.

The hair edit is in `sources/te-heads-dark-v9.raw.png`. The same preparation step
copies only its connected dark-hair region onto the approved painted v8 head
strip, protecting face/forehead/eyes/brows/stubble. The resulting
`sources/te-heads-dark-v9.png` keeps the selected facial appearance and original
silhouettes while removing the bright crown lighting. Original v7 and v8 head
sources remain intact.

`tools/pack_natural_te_walk.cjs` fits this one head per view to all five complete
poses, preserves the moving shirt/collar, and bakes continuous jaw/nape joins.
No separate head, arm or sleeve is drawn at runtime: `open_world_art.gd` draws a
single complete sprite. Display heights 156/153, 112-unit stride, eight ticks,
two-tick key holds, five authored views mirrored to eight directions and planted
ground anchors are retained. All active compatibility packers delegate here.
The historical v8 packer is explicitly named `pack_pulled_te_walk_v8.cjs`.

Rebuild from the saved inputs: run `tools/prepare_te_natural_sources.cjs`, then
`tools/pack_natural_te_walk.cjs` with Node and sharp. No new image generation is
needed to reproduce these assets.

Validation: `te_walk_consistency_test.gd` checks 25 complete bodies against the
corrected source, fixed facial appearance, four distinct gait keys, timing,
scale and ground anchors. The side nape ends at head row 51; the shirt below it
is intentionally allowed to move. `walk_cycle_test.gd` checks the foot contacts
against their projected source poses. `character_rendering_test.gd` exercises
both characters in all eight directions and interaction poses. Visual review
uses all four keys × eight directions in the actual game. The focused continuous
comparison is `output/te-natural-walk-v9.gif` (front diagonal, side, rear diagonal,
left), produced by `tools/preview_character_necks.cjs` after the scene capture.

## Body repair prompt — built-in image_gen, transparent edit

Use case: precise-object-edit. Asset: production 5x5 full-body walk sprite atlas for Te. EDIT THE PROVIDED ATLAS, retain its exact 5 columns and 5 rows, equal cell grid, camera views, cell positions, foot baselines, scale, body proportions, slim build, face identity, clothes and shoes. Rows front, front-right diagonal, right side, rear-right diagonal, back. Columns neutral, contact A, passing A, contact B, passing B. Fix only these animation defects while preserving the same character: (1) shoulders, sleeves and upper arms must join continuously and anatomically, no clipped off upper arms, no rectangular cutouts, skin or shirt slices floating beside the body. (2) T-shirt sleeves MUST rotate and deform naturally with the WHOLE upper arm swinging from the shoulder. Draw the shirt and moving arm together as one continuous pose, with natural sleeve folds and slight chest/hem response, rather than a frozen shirt with pasted bare forearms. This is especially important in the right-facing side row and both diagonal rows. (3) ALL walking frames should be a calm grounded normal walk, NOT a high-knee marching/run cycle. Reduce the excessive knee lift in the LAST column and any diagonal passing pose: keep the knee clearly BELOW the shorts hem, foot only slightly above the ground, a slight backward knee bend on the rear passing leg. Keep alternate leading legs and opposite natural arm swing. Contacts have modest stride length. No lifted knee up toward the waist. Maintain limb thickness, torso height and shoulder width across all columns. Complete intact arms and hands with natural elbow bends; continuous shorts and legs. Do not remove a limb to conceal defects. Do not make the character taller, more muscular, younger or change his outfit. Face, head size and hairstyle stay as provided. Keep hand-painted game illustration style, colors and soft lighting. Exactly 25 full character sprites, transparent background, no labels, no gridlines, no extra sprites, no cropping. Every pose has ONE single head already joined to its full body, arms, legs and feet.

Edit target: `te-walk-v8.png`.

## Hair prompt — built-in image_gen, transparent edit

Use case: precise-object-edit, identity-preserve. Edit ONLY THE HAIR COLOR/LIGHTING of this exact five-view Te head strip. Keep the exact image dimensions, five equally spaced views in this same order, all silhouettes, face pixels, expression, facial identity, skin, eyebrows, eyes, stubble, neck and collar unchanged. His hair must be DARK very deep brown, nearly black, with even subdued diffuse light and subtle dark painted strand detail. REMOVE all the strong golden/brown highlights and top lighting on the crown in every view. No bright highlights on top, no rimlight, no glowing strand edges, no yellow flecks. The hairstyle itself and all contours remain exactly the same. This is a limited local recolor, NOT a redesign or new face. Keep genuine alpha transparency and remove red/yellow stray matte pixels around the cutout. Output exactly the same five heads strip with only darker unlit hair.

Edit target: `sources/te-heads-painted-v8.png`.
