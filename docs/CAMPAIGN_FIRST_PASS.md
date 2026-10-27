# Complete playable campaign first pass — 0.20.0

This build connects the existing foundations into a start-to-ending campaign.
It is a first pass for editing, not final production art, story or balance.
Missing regional assignments were filled with original draft content; the
catalog is marked `draft_content: true`. Established names, map corrections,
regional themes and recovered hero pairs are retained.

## Play flow

New Campaign → prologue → hero appearance → Blackthorn. Explore Ravenwood,
enter the Hollow Oak from Thornwatch Outer Ruins, clear the five named chambers,
and choose Lyra Vane or Garrick Thornward. The other guardian stays as defender.
The world map opens neighboring regions without a forced campaign order.
Enemies scale to level. Regions can be explored before their neighbors' bosses
are defeated. The Devouring Deep alone requires nine recruited companions.

Each other territory has two outdoor areas and three dungeon chambers. Regional
road names, city/village names, dungeon names, objectives, bosses and guardian
pairs are data in `campaign.json`. With Ravenwood's ten existing outdoor areas,
its five Hollow Oak chambers, and the other regional templates, there are 105
room definitions. A city/service backdrop is separate from these room counts.
All cities stay lightweight; the fourteen new settlement backdrops and nineteen
battle backdrops are baked original Godot renders. Blackthorn keeps its approved
illustrated scenes. Eldergrove, Shadowfen Forest and Cursed Mire have no cities
or villages: their rest interface is explicitly a trail respite.

Frostpeaks uses snow/pines and Icehelm; Ashenreach uses black stone, flat stepped
roofs and a lava channel; marshes use bog colors, water and raised timber at
Wickermoor; coastal settlements have shore water and lighthouse/dock elements;
Iron Plains has farms; deserts use sand/stone and an observatory; Hollow Isles
uses spectral ruins; the Deep uses void colors. New regional geometry and city
art are deliberately reusable first-pass forms, not individually finished art.

## Battles and progression

Dungeon encounters use wait-mode ATB: meters fill, commands pause time when a
party member is ready, and enemies act automatically between commands. The
Wayfarer can travel with three recruited companions. Attack, weapon skill,
guard/focus, healing, potions, retreat and a mastered weapon art are available.
Weapon families have different ATB rates. Infusion has elemental advantage and
resistance modifiers. Poison, KO, victory, defeat, recovery/retry, EXP, levels,
gold and material rewards are implemented. A cleared encounter cannot pay its
reward again. Battle commands and outcomes operate on persistent inventory.

Each of the eighteen non-final regions offers a pair of guardians; recruit one,
leave the other as defender. The original pairs are retained where established;
newly separated/unassigned territories use draft guardians. Recruiting grants
an image-based Oath Chest. Equipping it records its discipline; three victories
with a weapon family master its art for use after changing weapons. Guardian
and enemy visuals are shared/procedural stand-ins. The approved hero models and
outfits are not resculpted or overwritten. Bespoke companion armor/portraits,
full attack animations, voice acting and cinematic production remain art work.

The finale has three battles. Each uses three different recruited companions,
plus the Wayfarer. Nine companions are recorded as used, with no repeats across
fronts. Completing the third front shows the ending and allows postgame travel.
The narrative is an editable anchor-restoration first pass, not a final script.

## Cities, armies and forge

Town Services adds inns, provisions/gear shops, smithy access, company hiring,
journal/party management and manual secure/defend encounters. Army combat is a
separate 6×4 tactical grid: one hero plus up to four companies, movement/actions,
melee/archer/mage ranges, enemy turns, obstacles and victory/withdrawal. A first
capture grants gold and records security; secure regions discount local services.
It is not an autonomous world-invasion simulation. Tactical units currently use
readable tokens; this is not final 3D army presentation.

All visited regions unlock their weapon-base recipes. The forge has a hidden
strike limit and a moving timing marker. Finishing underworked, reliable,
masterwork or fractured produces separate inventory variants. Masterwork boosts
stats; underworked weapons have reduced durability (12 attacks), while fractured
weapons break after one attack. Optional essence infusion adds
magic power, elemental behavior and emissive weapon fittings. Armor, accessories,
consumables and materials stay image-based. The starter practice pack and all
prices/reward numbers remain provisional balance.

## Saves, audio, size and boundaries

Campaign progression, inventory/equipment, appearance and Ravenwood exploration
are autosaved independently. Three manual save slots capture those files. The
new-campaign page explicitly warns before replacing autosaves; manual slots stay
intact. Music muting is persistent. Four quiet original synthesized loop tracks
adapt between exploration, town, battle and ending.

The 3.5 GB target remains: CI rejects uncompressed APK content above 3.0 GB,
reserving 0.5 GB for runtime/user-data headroom. This is a packaging budget, not
proof of every Android device's installed filesystem overhead. No paid assets,
external provider jobs, video cinematics or runtime downloads were introduced.

Known first-pass limits: shared/procedural companion/enemy art; reusable regional
room and city architecture; sparse authored narrative/side quests; short original
music loops; simple tactical AI; placeholder combat motion/effects; provisional
reward and difficulty balance; basic settings rather than a full accessibility
suite. Phone frame time, memory, thermal behavior and a manual end-to-end UI
playthrough remain separate from automated checks. Do not call this a polished
release merely because the campaign-state simulation reaches the ending.

## Verification

Tests cover the regional canon/no-city rules, reciprocal world adjacency,
nonlinear travel and finale gate, paused ATB, command resources, defeat without
rewards, an automated full campaign with every chamber and all three final
fronts, one-per-pair recruitment, nine unique final companions, reward idempotence,
shops/equipment, quality/infusion/fragility, army rules/security rewards, and
regional room construction/dungeon bypass blocking. Existing town, movement,
hero, NPC, recipe, equipment and world-map checks remain in the full suite.
Actual Godot captures review battles, services, armies, journal and major biomes.

Regenerate content data with `python3 tools/campaign/build_campaign.py`; music
with `python3 tools/campaign/make_audio.py`. Backdrops can be regenerated on a
Godot 4.5.2 GPU/display using `tools/campaign/bake_backdrops.gd`. Assets are shipped
prebaked; Android CI does not need a renderer to regenerate them. File hashes and
sources are in `tools/campaign/asset_provenance.json`.

A second integration check (`tools/campaign/run_flow.py`) uses an isolated user
profile and actual scene/button callbacks: Ravenwood → Hollow Oak battles →
recruitment → world travel → Icehelm shop → forging/equipping → manual save/load
→ a seeded final-front scenario → ending. The seeded finale check verifies UI
routing; the separate campaign-state test earns all regional victories and
recruits before the finale. Neither substitutes for a manual phone playthrough.
