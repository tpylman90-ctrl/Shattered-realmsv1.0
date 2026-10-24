# Shattered Realms

A fresh Android-first Godot RPG: turn-based army campaigns, ATB dungeon battles, and recipe-driven Entropic Forge crafting.

## Get started

Requires Python 3.11+, Git, Godot 4.5.2 and Blender 4.5 LTS.

```sh
python3 tools/bootstrap.py
blender --background --python tools/build_ravenwood.py -- --output game/assets/generated/ravenwood
# Open game/project.godot in Godot 4.5.2
```

Bootstrap installs pinned Dialogue Manager and GUT add-ons into ignored `game/addons`, preserving their licenses. Run it before opening the editor. GitHub Actions does this automatically.

## Workflows

- **Build and validate**: installs dependencies, imports Godot, runs GUT, exports a debug APK on every main push and PR. Download `shattered-realms-debug` from the successful run's artifacts. Manual dispatch also supported.
- **Blender asset check**: installs Blender 4.5.3 LTS, verifies NumPy, creates a small camera/walkmesh calibration scene, renders it and exports GLB plus camera metadata. This is a pipeline fixture, not finished Ravenwood art.
- **Material Maker source**: manually fetches the pinned authoring source, with its license, as an artifact. It is a desktop authoring tool, not part of the Android runtime.

See [toolchain](docs/TOOLCHAIN.md), [design](docs/DESIGN.md), [field scenes](docs/FIELD_SCENES.md), and [asset catalog](assets/catalog/README.md).

## Current state

Ravenwood has three connected field screens with a geometric movement placeholder, touch joystick, tap-to-walk, fixed-camera backdrops and foreground layers. Final character art, interiors, ATB, armies and forge gameplay remain planned. No Square Enix game assets are included.

Original project code and art remain all rights reserved pending an explicit project license choice. Third-party tools retain their own licenses.
