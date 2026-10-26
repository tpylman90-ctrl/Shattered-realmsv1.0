# World map layout study — 0.9.0

The main menu now opens a simple, selectable world atlas. Colored territory tiles
show clear territory and city/village labels. Positions live in
`game/data/world_map.json` and are provisional; the grid does not establish
adjacency, distances, borders, campaign order or travel routes. The current
layout is a readable naming study, not a finalized geographic map.

Ravenwood can open the existing exploration scene (via hero selection if needed).
Every other tile is explicitly marked as not built yet. No campaign movement,
capture, combat or teleportation to unbuilt settlements is implemented.

Approved naming additions: Silvermere / Silverkeep, Westreach / Westhaven,
Blighted Marsh / Wickermoor, Ashen Wastes / Ashenreach, Deadwind Hollow /
Duskwatch, Dragon's Rest / Cinderport, Hollow Isles / Hollowguard. Eldergrove,
Shadowfen Forest and Cursed Mire have no settlements. Vulgrim is a boss,
not a city. The Devouring Deep is the final boss region. Raven's Hold is
Blackthorn, not a second settlement; it is listed only once under Ravenwood
until geography is decided. Ember Coast remains a coastal geographic label;
seas, passes and offshore landmarks are not promoted to territories here.
