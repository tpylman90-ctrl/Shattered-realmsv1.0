# Field scene contract

Design a connected graph of compact locations before rendering. Proposed Ravenwood nodes: gate, market square, forge lane, inn, watch platform, forest exit.

Each scene must ship together: backdrop(s), camera transform and projection, walkmesh, collision, occluders, prop anchors, spawn points and exits. Use perspective depth for natural character scale; do not fake scale independently of the camera.

Background foreground layers or invisible depth occluders hide characters correctly. Add visible 3D geometry where interaction or movement requires it. Bake static detail and light. Validate character grounding/shadows and light matching on-device.

Keep key routes readable. Preserve movement direction through camera transitions until the input is released. Define a safe 16:9 composition, use letterboxing rather than unpredictable cropping on other aspect ratios, and keep UI in safe areas.

Acceptance: walk entire accessible area; no backdrop sliding, hidden exits or floating feet; stairs match; foreground overlap works; doorway return spawn does not immediately retrigger; measure memory/frame time on Android.
