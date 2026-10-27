# Ravenwood territory board — 0.10.0

World map → Ravenwood Board opens a first playable territory prototype. The
11 × 8 hex board has a single expedition, three movement points per turn,
route previews, touch selection and End Turn. Breadth-first routing excludes
water, mountains and the hostile army tile. Gold outlines mark cells reachable
within the remaining movement budget. There is no movement animation yet.

Blackthorn opens the existing Ravenwood town and hero selection when needed.
Oldwood Timber Camp and North Ridge Mine grant one-time caches of eight wood
and five iron. Briar Crossing and Southwatch are survey locations. Thornwatch
Ruins marks a future dungeon entrance; Red Banner Camp marks an unresolved
hostile position. Tactical battles, dungeon scenes, army composition, enemy
turns, capture, recruitment, production and forge inventory integration are not
implemented. End Turn only restores movement. The local site names and layout
are provisional, not new final story canon.

Position, turn, remaining movement, visited sites and collected caches are saved
in `user://ravenwood_campaign.cfg` after moves, End Turn and town entry. This
file is separate from appearance selection. Resource caches cannot be collected
again after revisiting or reloading. Board resources are a campaign prototype
inventory, not yet the recipe/forge inventory. World Map returns to the atlas;
existing town Menu returns to the main menu. Reopening the board resumes it.

The atlas retains its territory polygons and labels. Code-drawn terrain relief,
cartographic stippling, two illustrative rivers and a compass frame add detail
without new texture assets. Rivers do not define world travel rules.

Checks cover blocked cells, path adjacency, access to every non-hostile site,
movement budgets, End Turn, one-time resources, save/load, touch selection and
town entry visibility. Both map and board are reviewed with actual Godot renders.
