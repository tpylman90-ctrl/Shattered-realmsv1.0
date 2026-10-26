# Ravenwood field scene contract

## Current locations

- Gate courtyard: user-approved detailed illustration, market lane to the left, camp lane to the right and raised upper-town steps.
- Market square: timber inn, smithy, market stalls and well; right-hand alley returns to the gate. Traced paths lead around the well's front and to the inn steps.
- Army camp: command tent, muster path, barracks and training area; left palisade opening returns to the gate.

- Upper town connects the gate to the great hall, watch platform and forest approach.
- The Green Hart inn, Iron & Ember forge and provisioner open from the market.
- Command tent and barracks open from the camp.
- Great hall, watch platform and forest approach return to upper town. The forest's northern road is an inspectable campaign boundary, not a territory-map transition yet.

All twelve use original high-detail generated background art with foreground sections and a fitted 3D floor. None uses the earlier procedural render at runtime. Existing gate artwork and cameras remain unchanged. The approved MPFB neutral starters replace the prototype meshes. Field scale is now 0.70 (previously 0.55), consistent across all twelve screens and pending device review.

The canonical location registry is `game/data/ravenwood_locations.json`: 12 locations and 11 paired connections (22 directional doorways). MAP shows these connections and highlights the current screen; it does not teleport. Tap walking targets only the chosen doorway, avoiding unintended shop entry when crossing another entrance. Joystick and keyboard movement enter a doorway by walking into its trigger. The A/Inspect button opens nearby descriptive details and pauses movement while the dialogue is open. These descriptions do not grant items or execute transactions.

## Shared runtime

Every location defines its image, fixed camera, navigation outline/heights, foreground polygons, depth-sensitive occluders, spawns, exits, route hint and closed areas in `game/data/ravenwood_*.json`. `field.gd` loads the same format for each location; `field_surface.gd` projects the traced floor into 3D and routes taps around the nonwalkable scenery. The camera/floor fit approximates painted perspective, not an exact reconstructed Blender camera.

Near roofs, trees, awnings and supplies sample the same backdrop with matching UVs to overlap the character without repainting the artwork. The gate fence and market well change draw order based on the character's floor position. The selected starter retains the same scale setting across locations. Touch joystick, tap-to-walk and WASD/arrows share the same floor constraints.

The project renders a fixed 1280×720 viewport with aspect-preserving letterboxing, keeping image composition, input coordinates, occluders and camera projection aligned on different screen shapes. Camera movement remains fixed. Scene returns spawn clear of exit triggers, with a brief transition lock; held directional input remains consistent.

## Production and validation

Art is stored as high-quality WebP copies; source generation hashes and processing history are in `assets/catalog/`. CI packages these images directly and does not regenerate them. Blender tools and the calibration workflow remain available for future meshes, props and animation.

Checks cover packaged assets, both directions of every connection, safe arrival points, tap routes around obstacles, camera projection, raised steps and actual simulated travel to each exit. In-engine captures review each scene with controls and the character visible. Android touch feel and frame time still need device review.

## Remaining

The town layout and indoor location pass is ready for device review. NPCs, story dialogue, lodging, transactions, crafting, recruitment, combat and campaign integration remain planned. Inspectable counters and stations mark their intended functions without implementing those services. Character art now uses the approved fitted outfits, 1K eye/hair textures and native skin weights. Locomotion has authored stance/swing foot targets, matched cadence, and a touch Run toggle. Animation is in place; stair placement still follows the shared fitted floor rather than individual foot IK on each stair. Further deformation polish and device performance review remain. Painted depth and floor projection are approximations and still need phone review around doors and stairs.

## Camp-side post correction

The camp connection activates on the clear approach before the near fence post, rather than requiring the player to steer around the tight fence corner. Returning from camp places the character on the town side of this trigger. Regression coverage starts at the position reported in the phone screenshot and checks that the return does not bounce back into camp.

## Starter animation pass — 0.6.0

`art/characters/neutral-starters.blend` is the approved packed art source. The
pinned MPFB tool reconstructs its original posed skeleton and preserves the
native weights, UVs and alpha hair. Exports contain 53 bones, nine draw surfaces,
and about 34–35k triangles each. Textures are capped at 1024 pixels. Procedural
studio fabric bump is not exported as a runtime shader.

Idle, Walk and Run are original looping clips. Walk/Run use analytic two-bone
leg poses with stance travel and swing clearance; idle has restrained body and
arm motion. Playback cadence tracks actual world movement. The Run toggle is
available beside the existing A/B controls; ordinary tap/joystick travel walks.
No character pose changes the traced navigation or doorway layout.

The complete source can be rebuilt with `tools/characters/rig_starters.py` after
`tools/characters/bootstrap.py`, using Blender 4.5.3. Export validation checks
native joint indices, normalized four-influence weights, embedded textures,
loop closure, and the mesh budget. GUT also checks model switching, speed-aware
clip changes, and all 22 directional doors. In-engine visual and Android phone
review remain separate from these automated checks.

The editable `neutral-starters.blend` is retained separately from this runtime-only recovery commit. The checked-in GLBs are complete and do not require Blender at runtime or during APK export. Authoring regeneration requires restoring that source to `art/characters/neutral-starters.blend`; the character workflow validates committed exports when it is absent.

## Ravenwood resident pass — 0.8.0

`game/data/ravenwood_npcs.json` places one stationary resident in each of the
12 existing locations. These residents use the approved male/female rigs with
per-instance clothing palettes and modest height/idle variation; they are a
first population pass, not twelve unique character sculpts. Shared player
materials and the packaged hero GLBs remain untouched.

Tap a visible resident to approach and begin a conversation, or use A / E when
nearby. A name/role marker and A • Talk prompt identify an available speaker.
Conversation requires proximity and a clear segment on the fitted floor. The
new conversation panel offers a greeting, two local topics, and Goodbye; B or
Escape also closes it. Player travel pauses and pending routes are cleared
while speaking. Residents turn toward the player when addressed.

Existing navigation outlines, occluders, exit triggers and return spawns are
unchanged. Residents are nonblocking in this initial pass, preserving the
movement routes under phone review. Shopkeepers and camp staff currently offer
conversations only: transactions, lodging, recruitment, quests and campaign
progress are not implemented by this pass. The new resident names/dialogue are
local flavor and do not establish a final campaign opening or companion roster.

## Character readability calibration — 0.8.1

`game/data/ravenwood_character_presentation.json` controls the shared visual
scale for heroes and residents across all twelve locations. A 25% larger
baseline is combined with gentle screen-depth compensation so characters no
longer become tiny near the camp entrance and command tent. Actual perspective
still reduces their size into the distance. Personal NPC height differences
remain relative to the same shared presentation at their floor position.

The player model and contact shadow scale independently of the movement body.
Navigation outlines, doorway triggers, spawn points and movement speed stay in
the original gameplay units. Locomotion cadence uses the displayed model scale
to keep stride speed appropriate. NPC tap bounds and name-marker positions use
their displayed height. Device review of the scene proportions remains needed.
