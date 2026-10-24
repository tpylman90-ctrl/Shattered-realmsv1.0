# Field scene contract

Design a connected graph of compact locations before rendering. Proposed Ravenwood nodes: gate, market square, forge lane, inn, watch platform, forest exit.

Each scene must ship together: backdrop(s), camera transform and projection, walkmesh, collision, occluders, prop anchors, spawn points and exits. Use perspective depth for natural character scale; do not fake scale independently of the camera.

Background foreground layers or invisible depth occluders hide characters correctly. Add visible 3D geometry where interaction or movement requires it. Bake static detail and light. Validate character grounding/shadows and light matching on-device.

Keep key routes readable. Preserve movement direction through camera transitions until the input is released. Define a safe 16:9 composition, use letterboxing rather than unpredictable cropping on other aspect ratios, and keep UI in safe areas.

Acceptance: walk entire accessible area; no backdrop sliding, hidden exits or floating feet; stairs match; foreground overlap works; doorway return spawn does not immediately retrigger; measure memory/frame time on Android.

## First playable implementation

Three original Blender-rendered screens: gate courtyard, market square and army camp. Gate west ↔ market east; gate east ↔ camp west. Only central side passages transition. Return spawns sit inside the arrival scene and have a short transition lock.

Fixed perspective camera, floor collision mesh, transparent foreground render, touch joystick, tap-to-walk and WASD/arrows. MAP toggles a compact route guide. Character is a geometric movement placeholder with a simple motion bob, not final hero art or a walk animation. Interiors, upper town, NPCs, stairs, interactive props and campaign exits remain planned. Runtime movement plane is intentionally restricted to the open central street.

Backdrops are generated during CI instead of storing render binaries in Git. Keep camera metadata and PNGs together. The desktop smoke/test pass verifies scene loading and bidirectional transitions; Android performance and touch feel still require device review.
