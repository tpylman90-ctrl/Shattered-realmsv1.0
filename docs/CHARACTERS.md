# Character runtime recovery

The approved male and female MPFB starters replace the earlier prototype meshes. Both use native 53-bone skeletons, embedded eye/hair textures, nine draw surfaces, and original Idle/Walk/Run clips. Male is 33,708 triangles; female is 35,016. Selection saves locally and is shared across all Ravenwood scenes. Field scale is 0.70; the touch Run toggle and speed-matched playback are enabled. Face animation and individual stair foot IK remain planned. Device review is still required.

The original editable Blender source is retained separately and omitted from this runtime-only publication. GLBs are self-contained. Restore the approved source to `art/characters/neutral-starters.blend` before rebuilding with pinned Blender/MPFB tools. Without that file the character workflow validates existing exports, while Android CI imports, tests and packages them normally.

## Elbow and hand clearance correction — 0.6.1

Walk and run now flex the elbows relative to the upper arms throughout the stride. Running maintains a bent elbow instead of letting the forearm aim down beside the thigh. Moderate shoulder swing remains. Both relaxed poses keep the hands further from the hips, with additional clearance for the fitted female tunic. GUT samples both sides of all three clips, checks wrist separation, and verifies changing elbow angles plus the sustained running bend.

## Shape and tailoring pass — 0.7.0

`tools/characters/style_starters.py` applies a smooth shared deformation to the approved source meshes and skeleton coordinates. The female has narrower shoulders, a defined waist, fuller hip contour, softer jaw, and coordinated eye/lid shaping. Both tunics fit closer at the sleeves; hems have less flare. The male has a stronger upper-torso taper, jaw and original chestnut eyebrows. Anatomical vertex colors add subtle lip, ear and nail definition with no extra skin texture. Existing hair/eye textures, fixed travel outfits and 53-bone locomotion are preserved.

Male is now 35,244 triangles / 11 surfaces, female 35,016 / 9. Shape is an art refinement toward the supplied references, not a finished match to their sculpting and hair quality. The same-camera exported-model comparison is in `docs/previews/starter-refinement-0.7.0.jpg`. Device lighting and performance still need phone review.
