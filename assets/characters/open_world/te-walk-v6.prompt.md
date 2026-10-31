# Te v6 — consistent latest identity

Created with the built-in image_gen tool (imagegen skill). Final atlas: `te-walk-v6.png`.

Canonical identity is the latest slim Te contact in v5, front-right row, contact A: Rect2(255,327,97,213). The new profile uses the same adult face, brown hair, charcoal shirt, cream shorts and black sneakers in all three poses, in Jo's painted style. Jo v6 is retained.

The sheet has five views and three columns: neutral, contact A, contact B. `tools/pack_te_walk.cjs` packs complete sprites and registers the collar, shirt hem, crown and grounded sole. Each view has a single baked head/neck reused across all three poses, so hair, facial features and head direction cannot change during a step. No runtime limb deformation or independent scaling of frames. The profile is mirrored for left movement. Existing distance-based timing is retained.

Accepted source assets are in `sources/te-side-v6.png` (exec-1b64d00e-bae2-44f6-8c1f-af64ca3ba338) and `sources/te-rest-v6.png` (exec-5f0b9574-a092-47c0-a070-7ac3c8113960). Other contacts come from the latest v5 sheet. Rejected full-sheet drafts are not used.

Rebuild: run `node tools/pack_te_walk.cjs` with the sharp package available, then import assets in Godot. Checks: `tests/te_walk_consistency_test.gd`, `tests/walk_cycle_test.gd`, and `tests/character_rendering_test.gd`. Preview: `tools/preview_te_walk.gd`.

## Final profile edit prompt

Edit target image 1: three side-view Te game sprites on transparent background. This is an identity/ANATOMY CONSISTENCY repair. MIDDLE sprite is canonical for profile head, slim adult build, torso length, face and hair. Reference image 2 is latest Te identity, which matches middle.
Change LEFT neutral and RIGHT walking sprite to have EXACTLY THE SAME head and torso as MIDDLE sprite. Middle head copied identically into all three positions: same hair silhouette, eye/jaw/nose/ear, same small head, same right-facing profile. Same natural lean adult chest, narrow waist, shoulder size, slim limbs. No bulky/chibi proportions.
Keep three poses and layout: LEFT standing arms down and legs together. MIDDLE walking with NEAR LEFT LEG FORWARD and near left arm BEHIND. RIGHT walking with NEAR LEFT LEG BEHIND and near left arm FORWARD. Far limbs move in opposition, so these are genuinely opposite phases. Middle and right legs must not duplicate. Change ONLY arm and leg articulation between these three Te sprites. No head turns, no body twists, no different head size or hairstyle.
Charcoal tee, pale shorts, black sneakers with light gray soles exactly as middle. Painted semi-realistic game style. Identical crown-to-sole height, same neck and hip heights in all three, upright relaxed walk, no bob. Output one horizontal row 3 figures, fully visible, generous gaps, actual alpha transparency all around and between limbs, NO colored background, NO texture, NO labels, no shadow.

## Final rest edit prompt

Edit the four Te sprites in the input. ONLY change their arms and legs to NEUTRAL STANDING RESTING positions, relaxed arms straight down, legs straight naturally together, both shoes grounded. Keep EXACT same heads, faces, hairstyles, necks, torso/chest shape, shoulder width, waist and adult body proportions as the respective input figure. Same T-shirt shape/length. Do not enlarge heads, shorten legs, make muscular or chibi. Preserve their FOUR respective camera directions and their order: FRONT, front-right 3/4, rear-right 3/4, BACK. Each output figure has its own input figure's identical head and torso: keep those parts untouched. Entire figure upright, no leaning. Preserve charcoal T-shirt, cream shorts, black sneakers and slim adult style. The last Te input has identical build to first from rear. Output four full-body sprites horizontally spaced in ONE row. True alpha transparency behind all sprites, NO colored backdrop or gradient, NO shadow, NO labels. Opaque interiors and clean silhouette edges.
