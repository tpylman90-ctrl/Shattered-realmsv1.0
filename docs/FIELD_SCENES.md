# Ravenwood field scene contract

## Current locations

- Gate courtyard: user-approved detailed illustration, market lane to the left, camp lane to the right and raised upper-town steps.
- Market square: timber inn, smithy, market stalls and well; right-hand alley returns to the gate. Traced paths lead around the well's front and to the inn steps.
- Army camp: command tent, muster path, barracks and training area; left palisade opening returns to the gate.

All three use original high-detail generated background art with foreground sections and a fitted 3D floor. None uses the earlier procedural render at runtime. The gate artwork, camera and character scale remain unchanged. Character size/animation improvements are explicitly deferred until locations are established.

## Shared runtime

Every location defines its image, fixed camera, navigation outline/heights, foreground polygons, depth-sensitive occluders, spawns, exits, route hint and closed areas in `game/data/ravenwood_*.json`. `field.gd` loads the same format for each location; `field_surface.gd` projects the traced floor into 3D and routes taps around the nonwalkable scenery. The camera/floor fit approximates painted perspective, not an exact reconstructed Blender camera.

Near roofs, trees, awnings and supplies sample the same backdrop with matching UVs to overlap the character without repainting the artwork. The gate fence and market well change draw order based on the character's floor position. The geometric character retains the same scale setting across locations. Touch joystick, tap-to-walk and WASD/arrows share the same floor constraints.

The project renders a fixed 1280×720 viewport with aspect-preserving letterboxing, keeping image composition, input coordinates, occluders and camera projection aligned on different screen shapes. Camera movement remains fixed. Scene returns spawn clear of exit triggers, with a brief transition lock; held directional input remains consistent.

## Production and validation

Art is stored as high-quality WebP copies; source generation hashes and processing history are in `assets/catalog/`. CI packages these images directly and does not regenerate them. Blender tools and the calibration workflow remain available for future meshes, props and animation.

Checks cover packaged assets, both directions of every connection, safe arrival points, tap routes around obstacles, camera projection, raised steps and actual simulated travel to each exit. In-engine captures review each scene with controls and the character visible. Android touch feel and frame time still need device review.

## Remaining

Shop/inn/tent/barracks interiors, upper town, NPCs, interactions, recruitment, combat and campaign integration are planned. Visible shop and tent entrances do not yet open interiors. The market and camp illustrate their future functions without implementing them. Character art and animation remain temporary.

## Camp-side post correction

The camp connection activates on the clear approach before the near fence post, rather than requiring the player to steer around the tight fence corner. Returning from camp places the character on the town side of this trigger. Regression coverage starts at the position reported in the phone screenshot and checks that the return does not bounce back into camp.
