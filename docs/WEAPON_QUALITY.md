# Weapon quality pass — 0.22.0

The existing 190 regional bases and ten starters now use refined original
procedural geometry. Item IDs, recipes, combat stats, quality outcomes and saves
are unchanged. This is a visual pass on the existing catalog, not a new crafting
system or a claim of 200 individually sculpted assets.

- Sword, greatsword and dagger blades have raised central ridges, tapered edges,
  shaped guards and fitted pommels. Regional motifs change blade width profiles;
  regional curves, widths and palettes remain data-driven.
- Axes/scythes have shaped cutting surfaces, eye sockets, collars, fasteners and
  a scythe brace. Generic floating crest ornaments are removed.
- Bows and crossbows use tapered solid limbs; bows have a straight taut
  string. Crossbows add guide rails, a bolt and trigger fittings.
- Staves have shaped prongs surrounding a faceted focus. Spears have shaped
  heads. Shafts use dark wrapped grips with metal end collars.
- Cannons have an open outer barrel, inward-facing bore, muzzle ring, sights,
  rails and trigger fittings. The native uncapped CylinderMesh avoids the
  missing-shell issue found during the first attempted pass.
- Material groups are merged into 4–7 mesh surfaces per model. Tests enforce
  fewer than 16,000 triangles per assembled weapon. This is a geometry budget,
  not a measured Android frame-rate result.
- Equipment previews frame the actual model bounds, use a slightly elevated view
  and include a 32-pixel sky-reflection source for metal readability. Battle
  weapons attach to the native animated right wrist on both starter rigs.
  Battle motion remains the existing simple attack tween, not full authored
  two-handed/ranged combat animation. Twin daggers remain one paired display
  assembly; independent dual-hand animation is future work.

Narrow ranged limbs use overlapping native solid segments to avoid disappearing
polygon faces at oblique viewing angles.

Source: game/scripts/weapon_model.gd. Original code-authored art; no paid assets,
provider generation, texture downloads or modified character GLBs. Native Godot
4.5.2 captures are in docs/previews/weapon-quality-0.22.0-*.jpg.

Validation covers the complete territory/family matrix, surface and triangle
budgets, both native wrist mounts, inventory/recipe/save regressions and the
existing scene-flow smoke test. Phone visual review remains separate.
