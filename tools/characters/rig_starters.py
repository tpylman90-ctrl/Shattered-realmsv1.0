"""Fit MPFB's CC0 game-engine skeleton to our original studio mesh study.
No MPFB application code or runtime generator is shipped in the game.
"""
import bpy,sys,os,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(os.environ.get('SR_CHARACTER_OUTPUT',str(ROOT/'.build/characters')));OUT.mkdir(parents=True,exist_ok=True)
MPFB=Path(os.environ.get('SR_MPFB_EXTENSIONS',str(ROOT/'.tools/character-extensions')))
repo=bpy.context.preferences.extensions.repos.get('sr_tools')
if repo is None:bpy.context.preferences.extensions.repos.new(name='Shattered Realms authoring',module='sr_tools',custom_directory=str(MPFB))
import addon_utils
addon_utils.enable('bl_ext.sr_tools.mpfb',default_set=True)
addon_utils.enable('rigify',default_set=True)
from bl_ext.sr_tools.mpfb.services.humanservice import HumanService
from bl_ext.sr_tools.mpfb.services.rigservice import RigService
# Exercise the actual MPFB -> Rigify path before processing our original characters.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
base=HumanService.create_human();meta=HumanService.add_builtin_rig(base,'rigify.human');control=RigService.generate_rigify_rig(meta,meta_rig_action='delete')
rigify_count=len(control.data.bones)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'mpfb-rigify-reference.blend'))
# Save a clean, original MPFB skeleton template before loading the art source.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
base=HumanService.create_human();template=HumanService.add_builtin_rig(base,'game_engine')
bones={b.name:{'head':tuple(b.head_local),'tail':tuple(b.tail_local),'parent':b.parent.name if b.parent else None} for b in template.data.bones}
bpy.ops.wm.open_mainfile(filepath=str(OUT/'neutral-starters-studio.blend'))
roots=[o for o in bpy.data.objects if o.type=='EMPTY' and 'neutral starter' in o.name]
records=[]
for root in roots:
 sex='female' if root.name.startswith('Female') else 'male';W=.9 if sex=='female' else 1
 # Bake the evaluated source (including contours, curves and Boolean seams).
 objects=list(root.children_recursive);bpy.ops.object.select_all(action='DESELECT')
 for ob in objects:ob.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.object.convert(target='MESH');bpy.ops.object.join();ob=bpy.context.object
 world=ob.matrix_world.copy()
 # Remove studio placement and facing, keeping feet at origin and +Y up in glTF.
 local=root.matrix_world.inverted()@world
 for v in ob.data.vertices:v.co=local@v.co
 ob.parent=None;ob.matrix_world.identity();ob.name='Starter_'+sex
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 # Collapse the material palette to vertex colors so each hero is one draw surface.
 colors=ob.data.color_attributes.new(name='HeroColor',type='BYTE_COLOR',domain='CORNER')
 for poly in ob.data.polygons:
  c=ob.data.materials[poly.material_index].diffuse_color
  for li in poly.loop_indices:colors.data[li].color=c
 paint=bpy.data.materials.get('Hero vertex palette')
 if paint is None:
  paint=bpy.data.materials.new('Hero vertex palette');paint.use_nodes=True
  bs=paint.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.72
  vc=paint.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='HeroColor';paint.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
 ob.data.materials.clear();ob.data.materials.append(paint)
 for p in ob.data.polygons:p.material_index=0
 # 28k triangles per full model, including face, hands, hair and clothing.
 ob.data.calc_loop_triangles();before=len(ob.data.loop_triangles)
 dec=ob.modifiers.new('Mobile geometry budget','DECIMATE');dec.ratio=min(1,28000/before);dec.use_collapse_triangulate=True
 bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=dec.name)
 ob.vertex_groups.clear()
 # Instantiate MPFB bone hierarchy and fit it to the existing stylized body.
 arm=bpy.data.armatures.new('MPFB_game_skeleton_'+sex);rig=bpy.data.objects.new('HeroRig_'+sex,arm);bpy.context.collection.objects.link(rig)
 bpy.context.view_layer.objects.active=rig;ob.select_set(False);rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 keep=[n for n in bones if not any(n.startswith(x) for x in ['index_','middle_','pinky_','ring_','thumb_'])]
 fit={'Root':((0,0,0),(0,.08,0)), 'pelvis':((0,0,.84),(0,0,.94)), 'spine_01':((0,0,.94),(0,.005,1.06)), 'spine_02':((0,.005,1.06),(0,.01,1.18)), 'spine_03':((0,.01,1.18),(0,.01,1.34)), 'neck_01':((0,.01,1.34),(0,.01,1.45)), 'head':((0,.01,1.45),(0,.01,1.80))}
 for side,sign in [('l',1),('r',-1)]:
  x=lambda a:sign*a*W
  fit.update({f'clavicle_{side}':((x(.02),.01,1.30),(x(.225),.01,1.29)),f'upperarm_{side}':((x(.225),.01,1.29),(x(.342),-.005,1.045)),f'lowerarm_{side}':((x(.342),-.005,1.045),(x(.386),-.043,.847)),f'hand_{side}':((x(.386),-.043,.847),(x(.390),-.05,.72)),f'thigh_{side}':((x(.105),.008,.80),(x(.105),.008,.46)),f'calf_{side}':((x(.105),.008,.46),(x(.105),.008,.13)),f'foot_{side}':((x(.105),.008,.13),(x(.105),-.12,.06)),f'ball_{side}':((x(.105),-.12,.06),(x(.105),-.19,.06))})
 for n in keep:
  b=arm.edit_bones.new(n);b.head,b.tail=fit[n]
  parent=bones[n]['parent']
  if parent:b.parent=arm.edit_bones[parent]
  b.use_connect=False;b.roll=0
 bpy.ops.object.mode_set(mode='OBJECT')
 # Explicit spatial weights avoid the self-intersections that heat weights can
 # produce on layered clothes. This first rig supports locomotion, not finger posing.
 groups={n:ob.vertex_groups.new(name=n) for n in keep}
 def smooth(a,b,v):
  t=max(0,min(1,(v-a)/(b-a)));return t*t*(3-2*t)
 for v in ob.data.vertices:
  x,y,z=v.co;side='l' if x>=0 else 'r';ax=abs(x);weights={}
  if z>1.44:weights={'head':1}
  elif z>1.34:weights={'neck_01':1-smooth(1.38,1.46,z),'head':smooth(1.38,1.46,z)}
  elif ax>.265*W and z>.60:
   if z<.87:
    t=smooth(.81,.90,z);weights={f'hand_{side}':1-t,f'lowerarm_{side}':t}
   elif z<1.10:
    t=smooth(1.005,1.10,z);weights={f'lowerarm_{side}':1-t,f'upperarm_{side}':t}
   else:
    t=smooth(.23*W,.30*W,ax);weights={f'upperarm_{side}':t,'spine_03':1-t}
  elif z<.88:
   if z<.20:
    t=smooth(.12,.23,z);weights={f'foot_{side}':1-t,f'calf_{side}':t}
   elif z<.53:
    t=smooth(.40,.53,z);weights={f'calf_{side}':1-t,f'thigh_{side}':t}
   else:
    t=smooth(.69,.84,z);weights={f'thigh_{side}':1-t,'pelvis':t}
  elif z<1.04:
   t=smooth(.92,1.04,z);weights={'pelvis':1-t,'spine_01':t}
  elif z<1.19:
   t=smooth(1.06,1.19,z);weights={'spine_01':1-t,'spine_02':t}
  else:
   t=smooth(1.18,1.29,z);weights={'spine_02':1-t,'spine_03':t}
  for n,w in weights.items():
   if w>1e-6:groups[n].add([v.index],w,'REPLACE')
 mod=ob.modifiers.new('Skin to MPFB skeleton','ARMATURE');mod.object=rig;mod.use_deform_preserve_volume=True
 ob.parent=rig
 # Original cyclic locomotion clips, no downloaded animation license dependencies.
 rig.animation_data_create();actions=[];fps=30
 for name,count,angle in [('Idle',60,0),('Walk',30,.32),('Run',20,.55)]:
  action=bpy.data.actions.new(name);rig.animation_data.action=action;actions.append(action)
  for frame in range(1,count+2):
   phase=(frame-1)/count*math.tau
   for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
   rig.pose.bones['spine_03'].rotation_euler.y=.012*math.sin(phase)
   if name=='Idle':rig.pose.bones['spine_02'].rotation_euler.x=.012*math.sin(phase)
   else:
    for side,sgn in [('l',1),('r',-1)]:
     p=phase+(math.pi if sgn<0 else 0)
     rig.pose.bones['thigh_'+side].rotation_euler.x=angle*math.sin(p)
     rig.pose.bones['calf_'+side].rotation_euler.x=-max(0,math.sin(p))*(.46 if name=='Walk' else .9)
     rig.pose.bones['foot_'+side].rotation_euler.x=.08*math.sin(p)
     rig.pose.bones['upperarm_'+side].rotation_euler.x=-angle*.6*math.sin(p)
     rig.pose.bones['lowerarm_'+side].rotation_euler.x=-.12 if name=='Walk' else -.5
    rig.pose.bones['pelvis'].location.z=abs(math.sin(phase))*(.012 if name=='Walk' else .035)
   for pb in rig.pose.bones:
    pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name)
    if pb.name=='pelvis':pb.keyframe_insert('location',frame=frame,group=pb.name)
  track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action);track.mute=True
 rig.animation_data.action=None
 for pb in rig.pose.bones:pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
 bpy.context.scene.render.fps=fps;bpy.context.scene.frame_set(1)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);ob.select_set(True);bpy.context.view_layer.objects.active=rig
 dest=ROOT/'game/assets/characters'/('starter_'+sex+'.glb');dest.parent.mkdir(parents=True,exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',use_selection=True,export_apply=False,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False)
 ob.data.calc_loop_triangles()
 for v in ob.data.vertices:assert abs(sum(g.weight for g in v.groups)-1)<1e-4
 records.append({'id':sex,'triangles':len(ob.data.loop_triangles),'bones':len(arm.bones),'clips':['Idle','Walk','Run'],'source_triangles':before})
 # Keep editable rig per starter, and an animation pose image for visual review.
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('starter_'+sex+'-rigged.blend')))
 rig.animation_data.action=actions[1];bpy.context.scene.frame_set(7)
 # Model is unplaced at origin. Reuse studio camera and aim toward this model only.
 camera=bpy.context.scene.camera;camera.location=(2.8,-6,2.5);camera.rotation_euler=(Vector((0,0,.95))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=2.05
 for other in roots:
  for child in other.children_recursive:child.hide_render=True
 # Only this hero is visible, without the previous actor.
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH' and obj.name.startswith('Starter_'):obj.hide_render=obj!=ob
 ob.hide_render=False
 bpy.context.scene.render.resolution_x=1000;bpy.context.scene.render.resolution_y=1200;bpy.context.scene.render.resolution_percentage=100;bpy.context.scene.cycles.samples=24
 bpy.context.scene.render.filepath=str(OUT/('starter_'+sex+'-walk.png'))
 if '--render' in sys.argv:bpy.ops.render.render(write_still=True)
 rig.animation_data.action=None
 for pb in rig.pose.bones:pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
 bpy.context.scene.frame_set(1)
(OUT/'rig-validation.json').write_text(json.dumps({'mpfb_version':'2.0.18','mpfb_commit':'d0a32e57a7f915cb2f2b95410e2117648c7bbb7e','rigify_generated_bones':rigify_count,'models':records,'notes':['MPFB skeleton fitted to our original meshes; these are not replacement MPFB body meshes.','Original test locomotion clips, no finger or face animation.','Studio noise shaders replaced by exportable vertex colors.']},indent=2))
print('RIGGED_STARTERS_DONE',records)
