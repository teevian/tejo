# Quiet, consistent complete-sprite walk

This atlas replaces the previous high-knee four-key cycle with three complete poses: contact A, neutral passing position, contact B, neutral passing position. The neutral pose is shared with rest. Every key lasts two distance-phase ticks. No separate limb drawing or runtime deformation is used.

Jo diagonal A is the user-selected exec-54a4013d-afb4-4f5f-9e3a-fc33339b3c21.png. Diagonal B is exec-3a34d82c-e52e-4edf-89c4-42f60b47923a.png, edited to swap the leading legs while preserving the upper body. Te counterparts are exec-efa6725d-7bfd-4266-953e-8f5c733b985c.png and exec-8a5da0d8-1ab1-41f4-8bf2-a0fbd77c6e23.png. Other contact and resting poses derive from Jo v5 and Te v4.

Complete silhouettes were extracted through connected alpha components. Per-view torso width is calibrated against the slimmer Jo reference using shirt-colour measurements, excluding skin/arms. Te is 2.5% wider before the existing 156/153 height ratio. Frame anchors use the shirt centre rather than the silhouette bounding-box centre, so swinging feet do not move the body sideways. Character heights and portraits are preserved.

Validation: rendered phase sheets in all eight directions; walk_cycle_test checks that the lowest planted shoe changes side between opposite contact poses in front, rear and both diagonals for both characters. Character rendering tests expect three distinct full-body walk poses; phone animation still requires four.
