# Te / Jo v11 — animated faces, stable direction changes, slim Jo profile

Runtime assets: `te-walk-v11.png` and `jo-walk-v11.png`, 7200 × 5600. Each of the five views has one idle pose and eight distinct walking head/neck/collar angles. The four approved complete leg/arm poses retain their two-tick order. The views mirror to eight movement directions.

## Face motion

The approved v9 facial paint and hair are reused under rigid rotations of at most 2.6 degrees. All eight gait phases have different angles, including consecutive phases that share a leg drawing. The head, neck and collar move together. A small shared bob and sway follows the phase; the crown's position is registered after rotation so direction changes retain the same head placement. The original identity/body atlases remain unchanged and are checked by SHA-256.

## Directional size and registration

Previously every direction used the front view's 876-pixel denominator, although the source view heights were 876, 852, 848, 848 and 928 pixels. A northward sprite consequently grew by about 9% relative to the rear diagonal. `open_world_art.gd` now uses each view's source height to draw Te at 156 units and Jo at 153 units in every direction. Whole poses receive a horizontal registration, recorded as `sourceShift`, aligning the cranial center without repainting/deforming the legs or shoes. The ground baseline stays fixed. Upper-chest paint settles into the authored moving shoulders; all lower pixels remain exact after this recorded translation.

## Jo's right-facing shirt

The previous donor bust had a three-quarter torso beneath a profile head. That broad upper-shirt silhouette produced the hump when it joined the slim side-view walking body. The built-in image_gen edit `sources/jo-profile-shirt-v11.raw.png` redraws that shirt in side profile using `sources/jo-body-v8.png` as the clothing/orientation reference. Its generated face is not used. The same repair mirrors to the left-facing view. Other neckline inputs remain the saved v10 paintings.

## Rebuild and review

With Node and sharp available, run `node tools/pack_character_necks.cjs`, then `node tools/preview_character_motion.cjs`. The older active packers also reapply the latest repair. For scene captures, run Godot with `--script res://tools/preview_shared_characters.gd -- --all-directions --motion-v11`, then `node tools/preview_character_motion.cjs --scene`.

The previews are `output/character-motion-v11-walk.gif`, `output/character-motion-v11-game.gif` and `output/character-motion-v11-turns.gif`, plus one contact sheet for each character. The turn preview alternates northeast/north/northwest while the gait progresses.

Validation: `te_walk_consistency_test.gd` and `jo_walk_consistency_test.gd` check approved identity, all eight angles, crown alignment, equal directional heights, opaque joins and unchanged registered limb paint. `character_direction_consistency_test.gd` independently measures actual rendered head position, height and ground baseline in all eight directions and nine phases, and rejects held head frames. `walk_cycle_test.gd` checks the registered source foot contacts. `character_rendering_test.gd` checks the walking and interaction poses.

## Image-generation prompt — built-in transparent edit

Use case: precise-object-edit, identity-preserve. Image 1 is the edit target: Jo's painted RIGHT-FACING PROFILE bust. Image 2 is a BODY ORIENTATION AND SHIRT SILHOUETTE REFERENCE ONLY; ignore its face. Fix ONLY the burgundy T-shirt, shoulder and upper torso in image 1: the existing garment is mistakenly in three-quarter view and makes a large artificial bump at the shoulder/back/chest when attached to a walking side-profile body. Repaint this garment in a STRICT RIGHT SIDE PROFILE like image 2, slim relaxed torso, naturally rounded single near shoulder, ordinary close-fitting burgundy crewneck T-shirt, narrow chest and back, smooth shallow contour from nape to shoulder and down the back. No broad frontal chest, no inflated upper arm, no hump, no pointed shoulder, no raised flap behind the neck, no protruding chest at the neckline. The neck must join the curved collar anatomically and smoothly. Keep the exact head/face/hair/ears/nose/jaw, his identity and expression, orientation and proportions from image 1. Keep the head in the exact same position, same size and camera angle. Match image 1's painted style and lighting. Keep the canvas and ample transparent space around the bust. Include continuous shirt down to its existing bottom edge, genuine alpha transparency, no text, no other characters or views.
