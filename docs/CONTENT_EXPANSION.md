# Regional content expansion — 0.21.0

This pass expands the connected 0.20 campaign rather than replacing its world,
character models, cities or connected wilderness structure. It is still draft
content, not a claim of finished production art or a fully balanced release.

## Playable additions

- 111 journal missions: six in each of 18 recruitable regions, plus three final
  front milestones. The six regional missions cover two surveys, a material
  delivery, an approach encounter, the first dungeon chamber, the anchor boss,
  and the recruit/defender oath. They share six mechanical templates but have
  region-specific places, problems, guardian lines and conclusions.
- 36 named survey sites physically marked beside existing wilderness roads.
  Ravenwood's sites are in Fernglass Spring and Thornwatch Outer Ruins. Other
  regions use their first and second outdoor rooms. Approach and use A/E.
- A scrollable regional chronicle reached from the pack-side wilderness controls,
  town services, main journal, or Blackthorn camp/watch-captain conversations.
  Visited regions have selectable entries, readiness, prerequisites, resource
  counts, claim buttons and completed-mission history. The three no-city regions
  remain without settlements.
- Blackthorn's alpha wolf tutorial has a temporary watch squad member and uses
  the existing camp backdrop. The watch's party ward demonstrates team commands.
  This temporary unit does not recruit or replace either Ravenwood guardian.
- Guardian dialogue changes after anchor restoration. Each regional anchor quest
  offers a recorded roads/watch pledge with different consumable/material rewards.
  Pledges are flavor and supplies, not implemented branching political simulation.
- Claims persist, cannot pay twice, and consume delivery materials. Old 0.20
  campaign saves default to empty quest state. Existing victories and recruits
  count toward the new objectives without replaying bosses.
- Repeatable road patrols unlock after the local approach encounter. They provide
  renewable EXP, gold and materials, with essence every third patrol. Each fight
  has its own reward key; retrying the same completed fight never pays twice.
- Make Camp restores HP/MP/status and saves in outdoor rooms and cleared dungeon
  chambers. Uncleared chambers refuse rest. This provides checkpoints during the
  five-room solo opening and in regions without cities.
- Guardian skills ward the party; healer skills restore/cleanse the party; warrior
  skills reduce defense. Ether, antidote and healer-discipline revival are battle
  commands. Invalid commands are rejected, and healing targets living allies.
- Bosses telegraph every third attack. Biome patterns include party attacks,
  poison/rend and life drain. Guard reduces the next hit and blocks poison.
  Commands show relevant availability; floating HP changes make outcomes visible.
- Save slots now include SHA-256 integrity hashes, retain the previous valid slot
  as a backup, validate before loading, and stage replacements. Corrupt primary
  slots can recover their valid backup. Version-1 snapshots remain readable.
  This is not a guarantee against power loss during a multi-file restore.

## Still open

Bespoke guardian/enemy meshes, regional architecture, full combat animation,
longer soundtrack, deeper encounter/quest variety, economy balancing and phone
performance/manual end-to-end testing remain release work. The current six
quest templates are a content foundation, not 108 bespoke quest mechanics.
No new paid/external assets, runtime downloads or cinematics are introduced.
The 3.5 GB finished-game target and 3.0 GB packaged-content guard remain.

Regenerate the original editable quest data using
`python3 tools/campaign/build_quests.py` after `build_campaign.py`.

## Validation

GUT covers all quest references, completion of all 111 missions, prerequisites,
material consumption, repeat-claim rejection, pledge persistence, actual 3D
survey interaction/save, camp safety, boss warning/ward/cleanse/revival and the
fort's temporary squad. Slot tests cover corruption recovery, checksum failures,
legacy migration and preserving current progress after an invalid load.
The scene-flow check also enters the fort battle through the quest button,
claims its reward, surveys both Ravenwood markers, camps in cleared chambers,
and continues through recruitment, travel, shops, forging, saves and the ending.
Automated checks and screenshots do not substitute for a phone playthrough.
