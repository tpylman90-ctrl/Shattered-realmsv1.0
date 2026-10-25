# Toolchain

- Godot 4.5.2 stable, Compatibility renderer; version-matched export templates.
- Blender 4.5.3 LTS in an isolated CI download. NumPy is checked inside Blender, not merely system Python.
- Dialogue Manager v3.10.0 and GUT v9.5.0 pinned to exact upstream commits in tools/dependencies.json.
- Python for automation; NumPy for geometry/calculation within Blender.
- FFmpeg for user-provided cutscenes. `python3 tools/convert_cutscene.py input.mp4 output.ogv` converts to a maximum 1280px width; inspect audio, image quality and file size before admitting assets.
- Material Maker 1.4 authoring source is available via manual workflow. Its GUI is not a headless texture generation service. Blender procedural materials and baking remain available in CI.
- Quaternius free CC0 animation subset: curated catalog link only, no paid packs or automatic harvesting. Select/download specific free clips, retain their license, then retarget and inspect on our actual character rig.

## Local

Run bootstrap, open game/project.godot, allow initial import, then run:

```sh
godot --headless --path game --editor --import
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
blender --background --python tools/blender_calibration.py -- --output .build/calibration
```

## Android

CI uses Java 17 and Android SDK platform 35/build-tools 35.0.0. Debug keystore is generated for test builds only; a clean runner may produce a different key, requiring uninstall before reinstall. For stable release updates, configure a persistent release signing key through repository secrets in a future release workflow. Never commit keys/passwords. Debug builds do not require user-provided secrets.

The tools are installed on GitHub runners during jobs, not on the phone. Artifacts expire after seven days to moderate storage; source scripts stay in Git.


## Approved gate art and signing

Gate art is a checked-in WebP copy of the user-approved generated illustration, preserving its dimensions. The market and camp now use matching original illustrations too. All three are checked in and packaged directly. Blender no longer regenerates field artwork during APK builds; the optional calibration/asset scripts remain available.

The project uses a fixed 1280×720 reference viewport with aspect-preserving letterboxing so traced screen-space paths, occlusion silhouettes and camera projection share the same coordinate system on phones and desktops. This fixes camera composition across aspect ratios; the source backdrop remains 1672×941.

Main/manual builds use ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD and ANDROID_KEY_ALIAS when all four repository secrets are present. Separate store/key passwords are supported through apksigner. A partially configured set fails explicitly. Without secrets, test-only debug signing remains available. PR builds never receive signing secrets. The persistent key is decoded only on the runner and deleted after signing; it is never included in artifacts.

Switching from the previous temporary debug certificate to persistent signing requires uninstalling the old test APK once. Future APKs signed with the same key can update that installation. These remain debuggable development APKs, not store release builds.

## Signing setup diagnostics

The workflow reports availability of each exact repository Actions secret before downloading build dependencies. No secret values are logged. If all four are unavailable, this is a configuration/access issue, not a Base64 decoding failure. Add repository secrets under Settings → Secrets and variables → Actions in this exact repository; environment secrets require a matching job environment and are not selected by this workflow.

ANDROID_KEYSTORE_BASE64 accepts line breaks, whitespace and missing trailing padding from clipboard transfer. Do not paste the secret heading, code fences, passwords or the complete credentials document into that value. Keep the same original signing key, alias and passwords; changing the key prevents in-place updates of applications signed with the previous key.


The canonical repository secret names match the user's existing setup:

| Repository secret | Meaning |
|---|---|
| ANDROID_KEYSTORE_BASE64 | Base64 contents of the original keystore |
| ANDROID_KEYSTORE_PASSWORD | Keystore password |
| ANDROID_KEY_ALIAS | Key alias (`shatteredrealms`) |
| ANDROID_KEY_PASSWORD | Private key password |

The workflow also accepts the earlier KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEYSTORE_USER and KEY_PASSWORD names as fallbacks. Values are mapped into the canonical environment variable names before validation and signing. The original key is reused.
