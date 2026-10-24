"""Small reproducible backdrop/camera/GLB fixture, not production scene art."""
import argparse, json, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector
p=argparse.ArgumentParser();p.add_argument('--output',required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_plane_add(size=10);floor=bpy.context.object;floor.name='WalkMesh'
mat=bpy.data.materials.new('Calibration stone');mat.diffuse_color=(0.13,0.19,0.16,1);floor.data.materials.append(mat)
for x in np.linspace(-3,3,5):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(float(x),2,0.5))
    bpy.context.object.name='DepthMarker'
bpy.ops.object.camera_add(location=(9,-13,10));cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=45
scene=bpy.context.scene;scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(0,-2,7));bpy.context.object.data.energy=1500;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=6
scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(out/'backdrop.png')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'calibration.blend'))
bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/'calibration.glb'),export_format='GLB',export_cameras=True,export_lights=True)
(out/'camera.json').write_text(json.dumps({'blender':bpy.app.version_string,'numpy':np.__version__,'resolution':[960,540],'camera_world_matrix':[list(r) for r in cam.matrix_world],'lens_mm':cam.data.lens,'sensor_width_mm':cam.data.sensor_width,'note':'Matrix uses Blender coordinates; GLB export converts camera and geometry together.'},indent=2))
assert (out/'calibration.glb').read_bytes()[:4]==b'glTF'
print('Blender / NumPy / render / GLB calibration passed')
