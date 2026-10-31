# Jo walk v8 — photo-based five-view facial identity

Final head strip: `sources/jo-heads-v8.png` (2172×724, transparent).
Final complete sprite atlas: `jo-walk-v8.png` (4000×5600, five views × five poses).
Generated with the built-in image_gen tool, using the approved Te dark-head strip
as style/angle/scale template and the user's Jo photographs as identity sources.
The original generation is kept in `sources/jo-heads-v8.raw.png`.

Identity references used for generation: the neutral front screenshot at 13.56.22,
IMG_0536.jpg for three-quarter likeness, the profile screenshot at 13.55.59,
and the rear screenshot at 13.56.10. The other supplied photos, including the
HEIC nape photograph, were inspected as additional visual references. Personal
photographs are not copied into the project. Jo keeps his longer nose, leaner
face/jaw, brown eyes, strong brows, lifted dark wavy hair and faint closed-mouth
smile, in the same painted finish as Te rather than the older cartoon rendering.

Body source `sources/jo-body-v8.png` is an offline 4× capture of Jo's approved v5
complete body poses, produced by `tools/bake_jo_walk.gd`. Body, clothes, limb
articulation, pose order, ground contacts and eight-tick 112-unit stride remain
unchanged. Display heights remain Te 156 / Jo 153.

`tools/pack_jo_walk.cjs` removes matte residue, fits one consistent head per view,
and bakes it into every complete pose. Its scale and facial appearance remain
fixed; the head follows the original torso's horizontal lean. A shaded neck
bridge meets each pose's existing collar, replacing the entire old jaw/neck
rather than leaving fragments of the old face. Small collar side gaps receive
fabric sampled from the same body pose. Every pixel below the neck repair band
is preserved from the approved body capture. Runtime draws one complete texture
region with no separate head, neck, arm or body layers.

Te's approved v9 PNG is unchanged (SHA256
`f3536d224b6e786e39ccbfb76f1c2ff5fa4c2e35e5eb1f950bfab1ae3a1d98ba`).
Rebuilding Te through the older active packers also reapplies Jo v8, preventing
an accidental return to his old face. To rebuild only Jo from saved inputs,
run `tools/pack_jo_walk.cjs` with Node and sharp.

Validation: `jo_walk_consistency_test.gd` checks the registered same face/size in
all 25 poses, unmodified bodies/clothes/feet below the neck, original timing,
anchors and unchanged Te PNG. `walk_cycle_test.gd` checks the planted feet.
`sources/jo-identity-mask-v8.png` is a test-only mask of the portrait's opaque
pixels. It verifies the complete facial paint, including nose, lips and jaw,
while excluding antialiased edges that blend with the moving collar. It is not
drawn by the game.
`character_rendering_test.gd` exercises both characters and interaction poses.
Visual checks include all four walk keys in all eight directions in the game.

## Final generation prompt — built-in image_gen, transparent background

Use case: identity-preserve / style-transfer. Asset: Jo's FIVE-VIEW head strip for the same painted game as Te. Image 1 is ONLY the style, five-panel layout, head scale, lighting and camera-angle template (Te). Images 2 through 5 are identity references of ONE different real man, Jo. Replace the template man's facial identity and hairstyle with Jo from those photographs. Do NOT copy Te's face, stubble, jaw or fringe. Preserve the precise five equal-width panels and the template's head/neck positions and visible cranial scale. Order: FRONT, FRONT-RIGHT THREE-QUARTER, RIGHT PROFILE, REAR-RIGHT THREE-QUARTER, BACK. Same slight game-view elevation and same angles as image1. Jo should be recognizable from the photographs: lean longer oval/angular face, his distinctive longer straight/slightly convex nose and tip in profile, natural almond-shaped brown eyes (not large cartoon eyes), strong dark eyebrows, slender jaw/chin, natural ears, mostly clean-shaven with only the very faint stubble visible in the photos. His hair is dense near-black/dark brown, short at the sides and nape, wavy and voluminous swept UP at the front rather than Te's forward tousled fringe. Use the front neutral portrait as primary proportions, the side photograph for nose/jaw/ear geometry, rear photos for his exact hair/nape shape; other photos corroborate likeness. Expression calm, friendly and closed-mouth with a very slight natural smile, identical across visible front/side views, no teeth. Match Te template's high-fidelity hand-painted illustration: realistic recognizable facial structure translated into clean painted shading, subtle texture, not a photograph, not chibi or generic cartoon, no beautification or enlarged eyes. Hair DARK with subdued diffuse lighting, no overhead golden shine, luminous flecks, rimlight or halo. Skin shading coherent across all five views and with the painted game. Show full head, naturally attached complete neck and ONLY a little burgundy/maroon crew-neck collar at the bottom matching Jo's game shirt, no full bodies. Background genuine alpha transparency, no text, borders, labels, extra heads or red/yellow matte residue. Return only the exact five-head strip, at the same size/aspect/layout as image1, 2172 by 724 if possible. Every view must depict Jo's same identity and same hairstyle, not five different interpretations.

