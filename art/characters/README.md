# Approved neutral starters

Packed editable Blender source from the user-reviewed MPFB form and clothing
passes. Male uses the plain linen tunic; female uses the fitted sage tunic.
Armor is stat-only; weapons and shields will be separate visible equipment.

Body and garment provenance, macro parameters, anatomical target values and
CC0 asset credits are in `provenance.json`. User-supplied shape-reference images
were used as visual guidance only and are not distributed here.

The body/garment assets are CC0; MPFB authoring code stays in the ignored tool
extension directory and is not bundled into Android. Rebuild exported game
models using the pinned bootstrap and `tools/characters/rig_starters.py`.
The export removes studio subdivision, retains original native weights,
limits each vertex to four influences, and caps packed texture size at 1024.

Face and finger performance animation are not part of this locomotion pass.

The editable `neutral-starters.blend` is retained separately from this runtime-only recovery commit. The checked-in GLBs are complete and do not require Blender at runtime or during APK export. Authoring regeneration requires restoring that source to `art/characters/neutral-starters.blend`; the character workflow validates committed exports when it is absent.
