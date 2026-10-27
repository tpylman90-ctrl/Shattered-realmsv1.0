# Full-game direction and release gates

Target: a complete original Shattered Realms campaign, using FF9 as a composition,
party/ATB and equipment reference and FFX as a connected-area exploration reference.
Cities remain lightweight illustrated scenes. Territories use independently loaded
3D areas. Weapons are 3D; other equipment/items use inventory images. References
are design guidance, not copied game assets or stories.

## Hard size budget

Total installed content and working-data target: at most 3.5 GB (decimal).
Shipped content ceiling: 3.0 GB, leaving 0.5 GB for saves, caches and runtime headroom.
CI checks the sum of uncompressed APK entries against the content ceiling after
export. This is a packaging guard, not a measurement of every Android device's
filesystem overhead. Runtime downloads and large caches must remain within the
same total; no future feature gets an independent extra budget. Share textures,
materials, environment pieces and rigs; stream rooms rather than the entire world.

## Verified foundations

- [x] Twelve lightweight Blackthorn town scenes with movement and NPC conversation.
- [x] World overview and approved territory/settlement naming.
- [x] Ten connected Ravenwood wilderness areas, route loops and checkpoints.
- [x] Faster walk/run and native animated male/female heroes.
- [x] Regional weapon-base matrix and starter gear/item catalog.
- [x] Owned inventory, equipment stats, 3D travel weapons and image-only other gear.
- [x] One-time Ravenwood material caches and exact-cost base-weapon forging.
- [x] Persistent Android signing, regression tests and a content-size guard.

## Required before calling this a full game

- [ ] One complete dungeon with exploration → ATB battle → rewards → town return.
- [ ] ATB party combat, enemy behavior, skills, status effects, victory/defeat and retry.
- [ ] Weapon/discipline ability learning, level growth and balanced equipment upgrades.
- [ ] Shops, lodging, resource economy, full forge quality outcomes and infusion.
- [ ] Companions, recruitment, party management and army/capture systems.
- [ ] Story/quest state, dialogue choices, campaign objectives and finale requirements.
- [ ] All planned territories with distinct environments, enemies, dungeons and bosses.
- [ ] The Devouring Deep finale, ending and complete start-to-finish progression.
- [ ] Save slots, settings, input/accessibility polish, audio and recovery/migration checks.
- [ ] Phone frame-time/memory/thermal checks and full-campaign playthrough QA.

The campaign roster, protagonist and finale details marked open in DESIGN.md remain
open. This checklist does not silently establish them. Next playable milestone:
a Ravenwood dungeon encounter that makes weapon choice, stats, consumables and
rewards matter. Equipment previews do not count as completed territories.
