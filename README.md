# Shattered Realms

A fresh Android-first Godot RPG: turn-based army campaigns, ATB dungeon battles, and recipe-driven Entropic Forge crafting.

## Get started

Requires Python 3.11+, Git and Godot 4.5.2. Blender 4.5 LTS is used by the optional asset/calibration tooling.

```sh
python3 tools/bootstrap.py
# Open game/project.godot in Godot 4.5.2
```

Bootstrap installs pinned Dialogue Manager and GUT add-ons into ignored `game/addons`, preserving their licenses. Run it before opening the editor. GitHub Actions does this automatically.

## Workflows

- **Build and validate**: installs dependencies, imports Godot, runs GUT, exports a debug APK on every main push and PR. Download `shattered-realms-debug` from the successful run's artifacts. Manual dispatch also supported.
- **Blender asset check**: installs Blender 4.5.3 LTS, verifies NumPy, creates a small camera/walkmesh calibration scene, renders it and exports GLB plus camera metadata. This is a pipeline fixture, not finished Ravenwood art.
- **Character authoring check**: pinned MPFB 2.0.18 and bundled Rigify in Blender 4.5.3; rebuilds original starter meshes, fits game rigs and validates portable exports. Runs when character tools change or by manual dispatch.
- **Material Maker source**: manually fetches the pinned authoring source, with its license, as an artifact. It is a desktop authoring tool, not part of the Android runtime.

See [toolchain](docs/TOOLCHAIN.md), [design](docs/DESIGN.md), [field scenes](docs/FIELD_SCENES.md), and [asset catalog](assets/catalog/README.md).

## Current state

Ravenwood now has 12 connected illustrated locations: gate, market, army camp, upper town, lookout and forest approach, plus the inn, forge, provisioner, great hall, command tent and barracks interiors. Each uses a traced 3D floor, foreground occlusion and routed tap movement. The town map highlights the current location; nearby objects offer short inspections. Every door has a return route. Male/female starter selection is saved locally; both original models now use a fitted MPFB skeleton with prototype idle/walk/run clips. Touch joystick and fixed cameras support location review. NPCs, lodging/trading, recruitment, character texture/animation polish, ATB, armies and forge gameplay remain planned. No Square Enix game assets are included.

Original project code and art remain all rights reserved pending an explicit project license choice. Third-party tools retain their own licenses.
