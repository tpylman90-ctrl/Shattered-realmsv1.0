# Character authoring and runtime

The original male/female starter mesh studies are now skinned to the CC0 MPFB game-engine hierarchy, fitted to their stylized proportions. They retain the approved neutral travel outfit. MPFB does not supply their visible body or clothes in this pass. MPFB's Rigify generation is exercised on a separate reference human; the game exports a compact 23-bone skeleton, not the 930-bone control rig.

## Reproduce

Use Blender 4.5.3 LTS. Its Rigify add-on and bundled NumPy are available without paid services.

```sh
python3 tools/characters/bootstrap.py
blender -b --python-exit-code 1 --python tools/characters/model_source.py -- --no-render
blender -b --python-exit-code 1 --python tools/characters/rig_starters.py
python3 tools/characters/validate_exports.py
```

MPFB 2.0.18 is pinned by immutable source revision and archive SHA256, installed into ignored `.tools/character-extensions`. Source, rigged Blender files, a Rigify reference and validation receipts are generated into ignored `.build/characters`. The GitHub Character authoring check workflow rebuilds and uploads these; runtime GLBs are checked into `game/assets/characters`. MPFB application code and a runtime character generator are not packaged into Android. Tooling enables MPFB and Rigify in its Blender process; it does not require the user's computer or credentials.

The MPFB repository explicitly separates GPL application code from CC0 asset data and output. This project uses CC0 skeleton data in original models. See the upstream asset-license copy under `assets/licenses/`, and catalog provenance under `assets/catalog/starter-heroes.json`. Optional community assets are not included.

## Runtime

Choose hero on the main menu; the first Ravenwood entry also opens selection until a choice is saved. The preview supports male/female, drag-to-turn, Idle/Walk/Run and Begin in Ravenwood. `hero_model.gd` reads/writes only the appearance choice, with no class restriction. Each model is one skinned mesh surface using vertex colors, approximately 28,000 triangles and three cyclic prototype clips. Field movement plays Walk, stopping plays Idle. Run is currently a preview clip. Story/campaign save state is not implemented by this appearance preference.

The asset-byte check verifies a single mesh/surface, vertex colors, weights, 23 joints, all three clips and a 30k-triangle ceiling. GUT verifies both models, animated leg tracks, selection switching, saved preference and field integration. Existing town doorway tests still exercise all 22 directions. In-engine captures check both selection models and a field view.

## Remaining

These are first-pass game rigs, not finished hero animation. The test gait needs foot locking and deformation refinement. Fingers and face are not animated. Equipment sockets, class appearances and painted/baked textures are future work. Vertex colors deliberately replace the procedural studio shaders; they export consistently but look different under Godot lighting. Android performance still requires a device test; the triangle ceiling alone is not a performance measurement.
