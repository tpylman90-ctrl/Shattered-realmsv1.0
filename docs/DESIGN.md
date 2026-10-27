# Design foundation

## Agreed

- Territory exploration uses independently loaded fully 3D areas, connected by roads and entrances (FFX-inspired structure). This replaces turn-based territory-board movement. Army recruitment, capture and defense remain planned systems.
- Tactical army battles; dungeon exploration transitions to ATB character battles.
- Settlement exploration connects story, companions, shops and crafting.
- Dungeon results and army victories affect the same campaign state.
- Recipe crafting uses iron, wood, leather and other raw materials, with optional magical infusion.
- Entropic Forge hammering outcomes: underworked, reliable, masterwork, fractured. Exact balance remains open.
- Cities stay lightweight: detailed 2D backdrops with matching 3D walk meshes, animated characters and selected interactive props. Wilderness uses fully 3D terrain and scenery.
- FF9 is a composition/quality reference, not an asset source.
- User-supplied short cutscenes, integrated with skipping, subtitles and story triggers.

## Proposed, awaiting story development

Ravenwood opening, Lyra Vane recruitment, regional isolation and the Devouring Deep. Protagonist identity, party size, roster, scaling and finale requirements remain undecided for this reboot.

## Milestone order

1. Ravenwood gate/street: matching camera and background, movement, stairs, occlusion and doorway transition on Android.
2. One dungeon route and ATB encounter.
3. Connected 3D territory areas linking lightweight towns, future dungeons and points of interest.
4. Complete resource → recipe → forge loop.

Ravenwood has an illustrated exploration layout with six exterior screens and six interiors, a connected town map and descriptive inspections. The town location pass is complete for review. Dungeons, NPC services, final character art and combat remain planned.

## Player appearance implementation

Male/female neutral starters share the same class access. The selection is saved on device and used in all town scenes. They have fixed travel outfits with no city affiliation. Planned class-specific outfits will replace the neutral outfit; armor changes stats without changing appearance. Only weapons/shields will change visibly when equipped. Player meshes now use the approved MPFB male/female human forms and tailored neutral clothing, with native MPFB skin weights and 53-bone skeletons. The selected character has idle, walk, and run clips; facial animation remains planned.

## First resident population

Ravenwood now has one conversational NPC per location. Tap-to-approach, nearby Talk, local topics and dialogue movement pause are implemented. Residents reuse the approved starter rigs with role palettes. Dedicated NPC art, shop services, recruitment and story/quest state remain future work.

## Connected wilderness — 0.11.0

Ravenwood now opens Oldwood Road, a fully rendered woodland area connected in
both directions to Briar Crossing. The world map is still the overview. The
previous hex-board prototype is retained as source but is no longer the Ravenwood
entry. Existing city scenes stay lightweight. Exploration corridors, touch/keyboard
movement, walk/run, a following camera and town entry are implemented; wilderness
combat, enemies, loot and dungeon exploration are not implemented yet.

## Ravenwood territory expansion — 0.12.0

The connected wilderness now has ten rooms and two branching loops around the
crossroads, with a territory route map and exploration checkpoints. Town and
wilderness walking are 35% faster; running is 30% faster. Local landmark names
and geometry are a first territory layout. Dungeons, battle encounters, loot,
recruitment and territory-capture rules remain future work.

## Equipment and full-game target — 0.13.0

The user approved building toward a full game with a 3.5 GB maximum. The current
milestone adds the territory-by-family weapon matrix, 3D weapon previews/travel
mounts, image-based other gear, inventory persistence, equipment stats, local
material caches and Ravenwood base forging. See EQUIPMENT.md for scope and
RELEASE_PLAN.md for the size budget and unfinished full-game release gates.
This is equipment foundation work, not a completed campaign or battle system.

## User-authorized campaign fill — 0.20.0

The user authorized filling the remaining game while preserving the established
area direction, with revision afterward. Open details are now an explicitly
draft first-pass campaign in `campaign.json`: nonlinear neighboring-region travel,
level-scaled ATB encounters, 18 recruit/defender pairs, one recruit per region,
three companions alongside the avatar, and a nine-companion/three-front finale.
These are editable implementation choices, not a claim that all draft narrative
or new character designs were previously approved. Established area themes,
settlement corrections, named old heroes and Hollow Oak chambers remain intact.
See CAMPAIGN_FIRST_PASS.md for implemented features and production limitations.

## Content expansion — 0.21.0

User authorized continuing the remainder of the game. The first connected
campaign now has editable regional quest arcs, survey sites, guardian dialogue,
recorded supply pledges, a camp-side alpha wolf squad tutorial, cleared-room
camping, role skills, boss patterns and save-slot recovery. Existing map, no-city
rules, approved hero GLBs and lightweight city art are preserved. These new
quests use shared mechanics with original regional text; bespoke art and deeper
mechanical variety remain open. See CONTENT_EXPANSION.md for exact scope.
