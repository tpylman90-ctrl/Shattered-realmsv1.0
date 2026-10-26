"""Deterministic proportion and tailoring pass on the approved CC0 source.

The same smooth deformation is used for meshes and native joint positions.
No reference-image pixels or third-party model geometry are incorporated.
"""
import math
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

REVISION = "0.7.1 female hip and rear tailoring"

def bell(z, center, radius):
    t = min(1.0, abs(z - center) / radius)
    return (1 - t * t) ** 2

def sculpt_point(point, sex):
    x, y, z = point
    if sex == 'female':
        # Match the reference's narrow shoulder / defined waist / rounded hip
        # relationship while retaining an adult, athletic travelling character.
        shoulder = bell(z, 1.365, .16)
        waist = bell(z, 1.045, .16)
        hip = bell(z, .845, .15)
        # Avoid stacking a large waist pinch and hip expansion on the source's
        # existing fitted proportions: that made a padded shelf below the belt.
        x *= 1 - .105 * shoulder - .060 * waist + .012 * hip
        y *= 1 - .040 * waist
        # Softer jaw and smaller chin; keep eyes and skull aligned with hair.
        jaw = bell(z, 1.53, .075)
        x *= 1 - .10 * jaw
        if y < -.08:
            y += .004 * jaw
        # Open the eye/lid region together, rather than enlarging eyeballs
        # independently and exposing gaps in the surrounding face.
        eye = bell(abs(x), .035, .038) * bell(z, 1.617, .034) * bell(y, -.145, .075)
        eye_center = .035 if x >= 0 else -.035
        x += (x - eye_center) * .09 * eye
        z += (z - 1.617) * .15 * eye
        if y < -.14:
            y += .004 * bell(x, 0, .032) * bell(z, 1.578, .035)
        # A gentle chest contour is shared by the covered body and garment.
        if y < -.04 and abs(x) < .17:
            y -= .012 * bell(z, 1.245, .11) * bell(abs(x), .075, .095)
    else:
        x *= 1 + .055 * bell(z, 1.35, .18) - .045 * bell(z, 1.035, .14)
        x *= 1 + .095 * bell(z, 1.53, .075)
        if y < -.06:
            y -= .006 * bell(z, 1.28, .14) + .004 * bell(z, 1.64, .025)
    return Vector((x, y, z))

def tailor_mesh(obj, sex):
    """Refine garment bulk after the shared body / skeleton deformation."""
    tunic = 'viking_tunic' in obj.name
    pants = 'viking_pants' in obj.name
    hair = 'ponytail01' in obj.name or 'short02' in obj.name
    belt = {i for p in obj.data.polygons
            if tunic and sex == 'female' and 'leather' in obj.data.materials[p.material_index].name.lower()
            for i in p.vertices}
    for vertex in obj.data.vertices:
        p = sculpt_point(vertex.co, sex)
        if tunic and vertex.index not in belt:
            if sex == 'female':
                # Remove the padded bell shape at the hem and fit the back.
                hem = bell(p.z, .82, .19)
                p.x *= 1 - .085 * hem
                p.y = -.025 + (p.y + .025) * (1 - .14 * hem)
                # A longer, softly falling hem avoids the compressed band
                # across the seat produced by the previous shortened skirt.
                p.z += .016 * max(0, min(1, (.95 - p.z) / .20))
                # Keep sleeve fabric close to the upper arm rather than bulky.
                sleeve = bell(p.z, 1.25, .18) * max(0, min(1, (abs(p.x) - .17) / .06))
                p.y = -.015 + (p.y + .015) * (1 - .14 * sleeve)
            else:
                hem = bell(p.z, .77, .14)
                p.x *= 1 - .035 * hem
                p.z += .025 * max(0, min(1, (.94 - p.z) / .23))
        if pants and sex == 'female':
            # Taper trouser fabric below the knee, preserving boot contact.
            center = .105 if p.x >= 0 else -.105
            p.x = center + (p.x - center) * (1 - .06 * bell(p.z, .39, .20))
        if hair and sex == 'female':
            # Fuller gathered hair, a little crown volume, no extra draw calls.
            if p.y > .04:
                p.x *= 1.10
                p.y = .04 + (p.y - .04) * 1.06
            p.z += .008 * bell(p.z, 1.73, .06)
        if obj.name.startswith('Natural brow female'):
            p.z += .003 * bell(abs(p.x), .043, .032)
        vertex.co = p

def add_brows(actor, sex):
    if sex != 'male':
        return
    reference = next(o for o in actor.children_recursive
                     if o.name.startswith('Hidden covered-body reference'))
    surface = BVHTree.FromPolygons([v.co for v in reference.data.vertices],
                                  [p.vertices[:] for p in reference.data.polygons])
    material = bpy.data.materials.new('Chestnut male eyebrows')
    material.diffuse_color = (.045, .025, .018, 1)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = material.diffuse_color
    bsdf.inputs['Roughness'].default_value = .82
    for sign in [-1, 1]:
        data = bpy.data.curves.new('Authored eyebrow', 'CURVE')
        data.dimensions = '3D'
        data.bevel_depth = .0026
        data.bevel_resolution = 2
        spline = data.splines.new('BEZIER')
        spline.bezier_points.add(4)
        for point, (x, z, width) in zip(spline.bezier_points,
                [(.018, 1.657, .75), (.030, 1.662, 1), (.044, 1.662, 1),
                 (.057, 1.658, .85), (.070, 1.651, .20)]):
            near, normal, _, _ = surface.find_nearest(Vector((sign*x, -.21, z)))
            point.co = near + normal * .0016
            point.radius = width
            point.handle_left_type = 'AUTO'
            point.handle_right_type = 'AUTO'
        data.materials.append(material)
        obj = bpy.data.objects.new('Natural brow male ' + str(sign), data)
        bpy.context.collection.objects.link(obj)
        obj.parent = actor

def sleeve_surface(reference, sex):
    return BVHTree.FromPolygons(
        [sculpt_point(v.co, sex) for v in reference.data.vertices],
        [p.vertices[:] for p in reference.data.polygons])

def fit_sleeves(obj, surface):
    if 'viking_tunic' not in obj.name:
        return
    groups = {g.index for g in obj.vertex_groups
              if g.name.startswith(('upperarm_', 'lowerarm_'))}
    for vertex in obj.data.vertices:
        weight = sum(g.weight for g in vertex.groups if g.group in groups)
        blend = max(0., min(1., (weight - .25) / .5))
        if not blend:
            continue
        near, normal, _, distance = surface.find_nearest(vertex.co)
        if .009 < distance < .12:
            delta = near + normal * .009 - vertex.co
            if delta.length > .025:
                delta *= .025 / delta.length
            vertex.co += delta * blend * .85

def fit_female_hem(objects):
    """Follow the trouser seat instead of retaining the source skirt bustle."""
    trousers = next(o for o in objects if 'viking_pants' in o.name)
    tunic = next(o for o in objects if 'viking_tunic' in o.name)
    belt = {i for p in tunic.data.polygons
            if 'leather' in tunic.data.materials[p.material_index].name.lower()
            for i in p.vertices}
    surface = BVHTree.FromPolygons([v.co for v in trousers.data.vertices],
                                  [p.vertices[:] for p in trousers.data.polygons])
    for vertex in tunic.data.vertices:
        if vertex.index in belt:
            continue
        p = vertex.co
        # Retain the belt, torso, and front bridge over the separated legs.
        lower = max(0., min(1., (.975 - p.z) / .10))
        back = max(0., min(1., (p.y - .005) / .06))
        side = max(0., min(1., (abs(p.x) - .16) / .055))
        strength = lower * max(back, side)
        if strength <= 0:
            continue
        near, normal, _, distance = surface.find_nearest(p)
        if distance > .012 and distance < .16:
            delta = near + normal * .018 - p
            # Fit horizontal ease only. Pulling the hem upward toward the
            # trouser crotch creates a cupped/scalloped rear instead of fabric.
            delta.z = 0
            if delta.length > .06:
                delta *= .06 / delta.length
            vertex.co += delta * strength
    # Keep the separate leather band outside the newly fitted fabric. Its
    # old seat contour otherwise intersects the cloth and flickers at the rear.
    cloth_faces = [p.vertices[:] for p in tunic.data.polygons
                   if 'leather' not in tunic.data.materials[p.material_index].name.lower()]
    cloth = BVHTree.FromPolygons([v.co for v in tunic.data.vertices], cloth_faces)
    for index in belt:
        vertex = tunic.data.vertices[index]
        if vertex.co.y < -.025:
            continue  # Preserve the front buckle and hanging belt tip.
        near, normal, _, _ = cloth.find_nearest(vertex.co)
        outward = Vector((near.x, near.y + .025, 0)).normalized()
        delta = near + outward * .012 - vertex.co
        delta.z = 0
        if delta.length > .06:
            delta *= .06 / delta.length
        vertex.co += delta

def stabilize_female_rear(obj):
    """Keep the back of the tunic on the pelvis instead of pinching into legs."""
    if 'viking_tunic' not in obj.name:
        return
    pelvis = obj.vertex_groups.get('pelvis')
    if pelvis is None:
        return
    for vertex in obj.data.vertices:
        x, y, z = vertex.co
        rear = max(0., min(1., y / .07))
        lower = max(0., min(1., (.965 - z) / .065))
        amount = rear * lower if abs(x) < .27 else 0
        if amount <= 0:
            continue
        weights = [(g.group, g.weight) for g in vertex.groups]
        for index, weight in weights:
            obj.vertex_groups[index].add([vertex.index], weight * (1 - amount), 'REPLACE')
        previous = sum(weight for index, weight in weights if index == pelvis.index)
        pelvis.add([vertex.index], previous * (1 - amount) + amount, 'REPLACE')

def skin_palette(obj, sex):
    """Use native anatomical masks for subtle lip / ear / nail coloration.

    Vertex colors survive GLB export without another texture or draw surface.
    """
    if obj.name != 'MPFB_' + sex + '_actual_body':
        return
    masks = {name: obj.vertex_groups.get(name) for name in ['lips', 'ears', 'fingernails']}
    material = obj.data.materials[0]
    bsdf = material.node_tree.nodes.get('Principled BSDF')
    base = tuple(bsdf.inputs['Base Color'].default_value)
    # Preserve the approved complexion, adding warmth and readable lips.
    colors = obj.data.color_attributes.new(name='SkinTone', type='BYTE_COLOR', domain='CORNER')
    values = {}
    def weight(vertex, group):
        return sum(g.weight for g in vertex.groups if group and g.group == group.index)
    for vertex in obj.data.vertices:
        color = list(base)
        for group, target, strength in [
            ('lips', (.36, .12, .105, 1), .48 if sex == 'female' else .28),
            ('ears', (.52, .27, .20, 1), .15),
            ('fingernails', (.68, .48, .36, 1), .14)]:
            amount = weight(vertex, masks[group]) * strength
            color = [a * (1 - amount) + b * amount for a, b in zip(color, target)]
        values[vertex.index] = color
    for loop in obj.data.loops:
        colors.data[loop.index].color = values[loop.vertex_index]
    node = material.node_tree.nodes.new('ShaderNodeVertexColor')
    node.layer_name = 'SkinTone'
    material.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
    bsdf.inputs['Roughness'].default_value = .56

