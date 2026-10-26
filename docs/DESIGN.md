# Design foundation

## Agreed

- Turn-based territory movement with armies, recruitment, capture and defense.
- Tactical army battles; dungeon exploration transitions to ATB character battles.
- Settlement exploration connects story, companions, shops and crafting.
- Dungeon results and army victories affect the same campaign state.
- Recipe crafting uses iron, wood, leather and other raw materials, with optional magical infusion.
- Entropic Forge hammering outcomes: underworked, reliable, masterwork, fractured. Exact balance remains open.
- Detailed 2D backdrops with matching 3D walk meshes, animated characters and selected interactive props.
- FF9 is a composition/quality reference, not an asset source.
- User-supplied short cutscenes, integrated with skipping, subtitles and story triggers.

## Proposed, awaiting story development

Ravenwood opening, Lyra Vane recruitment, regional isolation and the Devouring Deep. Protagonist identity, party size, roster, scaling and finale requirements remain undecided for this reboot.

## Milestone order

1. Ravenwood gate/street: matching camera and background, movement, stairs, occlusion and doorway transition on Android.
2. One dungeon route and ATB encounter.
3. Small territory board connecting town, dungeon, resource site and enemy position.
4. Complete resource → recipe → forge loop.

Ravenwood has an illustrated exploration layout with six exterior screens and six interiors, a connected town map and descriptive inspections. The town location pass is complete for review. Dungeons, NPC services, final character art and combat remain planned.

## Player appearance implementation

Male/female neutral starters share the same class access. The selection is saved on device and used in all town scenes. They have fixed travel outfits with no city affiliation. Planned class-specific outfits will replace the neutral outfit; armor changes stats without changing appearance. Only weapons/shields will change visibly when equipped. Player meshes now use the approved MPFB male/female human forms and tailored neutral clothing, with native MPFB skin weights and 53-bone skeletons. The selected character has idle, walk, and run clips; facial animation remains planned.

## First resident population

Ravenwood now has one conversational NPC per location. Tap-to-approach, nearby Talk, local topics and dialogue movement pause are implemented. Residents reuse the approved starter rigs with role palettes. Dedicated NPC art, shop services, recruitment and story/quest state remain future work.
