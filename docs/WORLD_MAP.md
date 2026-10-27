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

## Continental layout — 0.9.1

The tile grid is replaced by a single connected continent with an irregular
coastline, shallow-water outline, shared region borders and simple biome symbols.
All 19 regions remain selectable by their actual clipped polygon, including
on touchscreens. Settlement markers and a selected-region detail strip retain
the approved names and Ravenwood entry. Label positions and region polygons
are data, so the provisional geography can be rearranged without replacing art.
This is still a layout study, not the final illustrated world or campaign board.
No routes or travel rules are inferred from neighboring regions.

## Atlas polish and territory entry — 0.10.0

The accepted continent layout is unchanged. Terrain relief, rivers, stippling
and a compass frame provide the next visual pass. Ravenwood now opens the
territory board, where Blackthorn opens town exploration. See
`docs/RAVENWOOD_BOARD.md` for implemented campaign mechanics and remaining work.

## Connected rooms — 0.11.0

Explore Ravenwood now opens Oldwood Road rather than the retired hex-board
prototype. The atlas remains the overview; lightweight city exploration is
preserved. See `docs/WOODLAND.md` for the connected 3D wilderness implementation.
