# Character runtime recovery

The approved male and female MPFB starters replace the earlier prototype meshes. Both use native 53-bone skeletons, embedded eye/hair textures, nine draw surfaces, and original Idle/Walk/Run clips. Male is 33,708 triangles; female is 35,016. Selection saves locally and is shared across all Ravenwood scenes. Field scale is 0.70; the touch Run toggle and speed-matched playback are enabled. Face animation and individual stair foot IK remain planned. Device review is still required.

The original editable Blender source is retained separately and omitted from this runtime-only publication. GLBs are self-contained. Restore the approved source to `art/characters/neutral-starters.blend` before rebuilding with pinned Blender/MPFB tools. Without that file the character workflow validates existing exports, while Android CI imports, tests and packages them normally.
