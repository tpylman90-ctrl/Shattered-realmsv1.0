# Full-game direction and release gates

Target: an original Shattered Realms campaign using the established world and
area themes. FF9 guides party/ATB composition and progression; FFX guides connected
area exploration. Cities stay lightweight; territories are independently loaded
3D areas. Only weapons use 3D equipment models; other gear/items use inventory art.

## Hard size budget

Maximum target: 3.5 GB decimal for installed content and working data. Shipped
content ceiling: 3.0 GB, reserving 0.5 GB for saves/caches/runtime headroom.
CI checks the sum of uncompressed APK entries after export. It is a packaging
guard, not proof of each Android device's filesystem overhead. No runtime-download
allowance is added outside this ceiling. Share geometry/materials and load rooms
independently. Budget detail and scope are in CAMPAIGN_FIRST_PASS.md.

## Implemented first-pass campaign — 0.20.0

- [x] Preserved Blackthorn scenes, hero models, movement and NPC conversations.
- [x] Nineteen territory records with nonlinear adjacent travel and level scaling.
- [x] Ten existing Ravenwood outdoor rooms and five named Hollow Oak chambers.
- [x] Regional outdoor/dungeon templates, lightweight settlements and biome themes.
- [x] ATB party commands, enemies, statuses, victory/defeat, recovery, EXP/gold/loot.
- [x] Eighteen recruit/defender pairs and party selection.
- [x] Three final fronts using nine distinct companions, ending and postgame travel.
- [x] Weapon bases, item images, inventory, equipment stats and Oath Chest disciplines.
- [x] Weapon mastery, quality forging, infusion and single-use fractured weapons.
- [x] Inns, shops, company hiring and tactical secure/defend battles with discounts.
- [x] Journal/objectives, autosaves, three manual slots and persistent music muting.
- [x] Original synthesized music, signed Android packaging and content-size guard.
- [x] Automated whole-campaign state simulation and real scene-flow smoke checks.

## Required for a polished release

- [ ] Manual start-to-ending playthrough on Android with touch controls.
- [ ] Phone frame-time, memory, thermal and installed-size measurements.
- [ ] Bespoke companion/enemy art, portraits, complete battle animation/effects.
- [ ] Individually authored regional geometry and settlement-art refinement.
- [ ] Expanded narrative, dialogue, side quests, item economy and balance passes.
- [ ] Accessibility, graphics/input settings, save-recovery and migration polish.
- [ ] Audio/music expansion and any user-supplied cinematics.

The first pass is connected and testable; it is not claimed to be a polished
commercial release. New unassigned story/guardian content is marked draft and
can be revised without replacing the underlying systems. See
CAMPAIGN_FIRST_PASS.md for exact scope and production boundaries.
