# Equipment foundation — 0.13.0

The equipment catalog contains 190 territory weapon base designs (19 territories
× sword, greatsword, axe, bow, crossbow, cannon, scythe, staff, spear, twin daggers),
plus ten starter weapons, eight stat-only gear items and seven consumable/material
items. Regional curves, width, guard/ornament motifs and material palettes are
original base proposals. They are programmatic multipart 3D meshes, not 190 final
artist-polished sculpts or finished upgrade trees. They are reproducible without
external providers, paid assets or Blender at runtime.

Only weapons receive 3D equipment models. Armor, offhand gear, accessories,
consumables and materials use original SVG inventory images. Travel outfits stay
unchanged. The equipped weapon is mounted for travel on the hero's native spine
bone; residents and appearance-selection previews do not inherit it. Combat
wielding, weapon-specific attacks and battle animations remain future work.

Pack / Smithy is available from the main menu, towns and woodland UI. Inventory
shows owned items, item quantities, stat totals and equipment slots. Weapon
Designs previews all regions and ten families with a draggable 3D view. Ravenwood
recipes can consume exact iron/wood/leather requirements and grant a base weapon.
Other territory designs are explicitly previews and cannot be forged yet. The
full Entropic Forge timing minigame and infusion are not implemented here.

The initial practice pack includes one weapon from each family so their designs
and travel mounts can be reviewed, basic clothing/buckler/charm, three potions,
two ethers, two antidotes and a small smithing supply. This is provisional starter
balance. Four one-time supply caches can be collected near the middle of Oldwood
Road, Timber Camp, Mine and Ancient Grove. Claims, quantities, equipped slots and
HP/MP/poison state persist in `user://equipment.cfg`. Existing exploration and
appearance saves are independent. Inventory return resumes the same town screen
or saved wilderness position. Cache rewards cannot repeat after reload.

Potions/ethers/antidotes have implemented state effects and avoid consuming items
when unneeded. Battles do not yet damage the hero, so the normal exploration
session starts at full HP/MP. The UI's attack/defense/magic totals are equipment
state ready for combat integration, not evidence of an implemented battle system.
Gear upgrades and item prices are catalog data; shops, drops, progression gates,
ability learning, combat, quests and the wider campaign remain future work.

`tools/equipment/build_catalog.py` reproduces the catalog and original vector
inventory art. `weapon_model.gd` is the reusable 3D source. Characters retain their
approved GLB hashes. Content tests instantiate every regional model, validate
crafting consumption/gates, equipment/stat persistence, cache uniqueness and
consumable effects. Actual Godot renders review the inventory and weapon studio.
