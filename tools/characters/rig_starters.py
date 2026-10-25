"""Rig the approved MPFB meshes with their original native weights.
Reconstruct the exact posed MPFB skeleton, then bake foot-target locomotion.
The packed Blender scene is the approved art source; no source mesh is regenerated.
"""
import bpy, math, json, os, addon_utils
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(os.environ.get('SR_CHARACTER_OUTPUT',str(ROOT/'.build/characters')));OUT.mkdir(parents=True,exist_ok=True)
MPFB=Path(os.environ.get('SR_MPFB_EXTENSIONS',str(ROOT/'.tools/character-extensions')))
bpy.context.preferences.extensions.repos.new(name='SR native rig',module='sr_native',custom_directory=str(MPFB))
addon_utils.enable('bl_ext.sr_native.mpfb',default_set=True)
from bl_ext.sr_native.mpfb.services.humanservice import HumanService
from bl_ext.sr_native.mpfb.services.targetservice import TargetService
spec=json.loads((ROOT/'art/characters/provenance.json').read_text())
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def stylize(v,neck):
 t=smooth(neck,neck+.08,v.z);s=1+.17*t
 return Vector((v.x*s,v.y*s,neck+(v.z-neck)*s))
# Recover the precise rest coordinates corresponding to the baked approval pose.
rest={}
for record in spec['characters']:
 sex=record['sex'];bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 body=HumanService.create_human(macro_detail_dict=record['macro'])
 targets=[('eyes/'+side+'-eye-height2-incr',.35) for side in ['l','r']]
 if sex=='female':
  targets += [('chin/chin-width-decr',.25),('chin/chin-bones-decr',.20),('nose/nose-scale-horiz-decr',.12),('cheek/l-cheek-volume-incr',.12),('cheek/r-cheek-volume-incr',.12)]
  targets += [('eyes/'+side+'-eye-scale-incr',.20) for side in ['l','r']]
 targets += record['anatomical_targets']
 for name,value in targets:TargetService.load_target(body,str(MPFB/'mpfb/data/targets'/(name+'.target.gz')),weight=value)
 rig=HumanService.add_builtin_rig(body,'game_engine')
 for side,sign in [('l',1),('r',-1)]:
  pb=rig.pose.bones['upperarm_'+side];basis=pb.bone.matrix_local.to_3x3();pb.rotation_mode='QUATERNION';pb.rotation_quaternion=(basis.inverted()@Matrix.Rotation(.30*sign,3,'Y')@basis).to_quaternion()
 bpy.context.view_layer.update()
 for m in body.modifiers:
  if m.type=='MASK':m.show_viewport=False
 dg=bpy.context.evaluated_depsgraph_get();ev=body.evaluated_get(dg);em=ev.to_mesh()
 g=body.vertex_groups['joint-neck'];ids=[v.index for v in body.data.vertices if any(w.group==g.index for w in v.groups)]
 neck=sum(em.vertices[i].co.z for i in ids)/len(ids)
 # MPFB helpers can extend above the scalp; use the same visible mask as authoring.
 ev.to_mesh_clear()
 for m in body.modifiers:
  if m.type=='MASK':m.show_viewport=True
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=body.evaluated_get(dg);em=ev.to_mesh()
 factor=1.75/max(stylize(v.co,neck).z for v in em.vertices);ev.to_mesh_clear()
 rest[sex]={pb.name:{'head':list(stylize(rig.matrix_world@pb.head,neck)*factor),'tail':list(stylize(rig.matrix_world@pb.tail,neck)*factor),'z':list(pb.matrix.to_3x3().col[2]),'parent':pb.parent.name if pb.parent else None} for pb in rig.pose.bones}
# Open canonical art with packed eye/hair textures, fabric materials and fitted clothes.
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/characters/neutral-starters.blend'))
actors=[o for o in bpy.data.objects if o.type=='EMPTY' and o.name.startswith('MPFB ')]
source_hidden={o.name:o.hide_render for o in bpy.data.objects}
records=[]
for actor in actors:
 sex='female' if 'female' in actor.name else 'male';objects=[o for o in actor.children_recursive if o.type in ['MESH','CURVE'] and not source_hidden.get(o.name,o.hide_render)]
 # Retain UVs, alpha hair, native skin groups and individual materials.
 for ob in objects:
  bpy.ops.object.select_all(action='DESELECT');ob.hide_render=False;ob.hide_set(False);ob.select_set(True);bpy.context.view_layer.objects.active=ob
  for m in list(ob.modifiers):
   if m.type=='SUBSURF':ob.modifiers.remove(m)
  if ob.type=='CURVE':bpy.ops.object.convert(target='MESH')
  ob.parent=None;ob.matrix_world.identity()
  ob.data.calc_loop_triangles()
  if len(ob.data.loop_triangles)>16000:
   dec=ob.modifiers.new('Bounded mobile simplification','DECIMATE');dec.ratio=16000/len(ob.data.loop_triangles);dec.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=dec.name)
 # Texture resolution is bounded for Android; preserve the original alpha channels.
 for im in bpy.data.images:
  if im.type=='IMAGE' and max(im.size)>1024:
   w,h=im.size;scale=1024/max(w,h);im.scale(max(1,round(w*scale)),max(1,round(h*scale)))
 arm=bpy.data.armatures.new('MPFB_native_'+sex);rig=bpy.data.objects.new('HeroRig_'+sex,arm);bpy.context.collection.objects.link(rig)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
 for name,source in rest[sex].items():
  b=arm.edit_bones.new(name);b.head=source['head'];b.tail=source['tail'];b.align_roll(Vector(source['z']))
  if source['parent']:b.parent=arm.edit_bones[source['parent']]
 bpy.ops.object.mode_set(mode='OBJECT')
 names=set(rest[sex]);fallback=0;triangles=0
 for ob in objects:
  # Brow curves have no native groups; attach them rigidly to the head.
  existing={g.index:g.name for g in ob.vertex_groups}
  for g in list(ob.vertex_groups):
   if g.name not in names:ob.vertex_groups.remove(g)
  if not ob.vertex_groups:
   g=ob.vertex_groups.new(name='head');g.add(list(range(len(ob.data.vertices))),1,'REPLACE')
  # Normalize and limit explicitly, rather than relying on exporter truncation.
  bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
  bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False)
  for v in ob.data.vertices:
   if not v.groups or sum(w.weight for w in v.groups)<.999:
    g=ob.vertex_groups.get('head') or ob.vertex_groups.new(name='head');g.add([v.index],1,'REPLACE');fallback+=1
  mod=ob.modifiers.new('Native MPFB skin','ARMATURE');mod.object=rig;mod.use_deform_preserve_volume=True;ob.parent=rig
  ob.data.calc_loop_triangles();triangles+=len(ob.data.loop_triangles)
 assert fallback==0, ('Unexpected missing native weights',sex,fallback)
 assert triangles<=60000,(sex,triangles)
 # Native geometry faces -Y in Blender; glTF faces +Z in Godot.
 R={b.name:b.matrix_local.copy() for b in arm.bones}
 def pose_segment(name,head,tail):
  b=rig.pose.bones[name];restdir=arm.bones[name].tail_local-arm.bones[name].head_local
  delta=restdir.rotation_difference(tail-head)
  b.matrix=Matrix.Translation(head)@delta.to_matrix().to_4x4()@R[name].to_quaternion().to_matrix().to_4x4()
  bpy.context.view_layer.update()
 def foot_pose(side,phase,clip,bob):
  thigh='thigh_'+side;calf='calf_'+side;foot='foot_'+side
  hip=rig.pose.bones[thigh].head.copy();base=arm.bones[foot].head_local.copy()
  duty=.62 if clip=='Walk' else .50;stride=.50 if clip=='Walk' else .80;lift=.075 if clip=='Walk' else .16
  u=phase%1
  if u<duty:y=-stride*.5+stride*u/duty;z=0
  else:
   v=(u-duty)/(1-duty);y=stride*.5-stride*smooth(0,1,v);z=lift*math.sin(math.pi*v)
  target=base+Vector((0,y,z));axis=target-hip
  reach=arm.bones[thigh].length+arm.bones[calf].length
  assert axis.length<=reach+.001,(sex,clip,'unreachable foot target',axis.length,reach)
  dist=min(axis.length,reach-.0001);axis.normalize()
  a=arm.bones[thigh].length;b=arm.bones[calf].length;x=(a*a-b*b+dist*dist)/(2*dist);height=math.sqrt(max(0,a*a-x*x))
  hint=Vector((0,-1,0));bend=(hint-axis*hint.dot(axis)).normalized();knee=hip+axis*x+bend*height
  pose_segment(thigh,hip,knee);pose_segment(calf,knee,target)
  rig.pose.bones[foot].matrix=Matrix.Translation(target)@R[foot].to_quaternion().to_matrix().to_4x4()
 actions=[];rig.animation_data_create();fps=30
 for clip,frames in [('Idle',60),('Walk',30),('Run',22)]:
  action=bpy.data.actions.new(clip);actions.append(action);rig.animation_data.action=action
  for frame in range(1,frames+2):
   u=(frame-1)/frames;t=math.tau*u
   for pb in rig.pose.bones:pb.rotation_mode='QUATERNION';pb.matrix_basis=Matrix.Identity(4)
   bob=.003*math.sin(t) if clip=='Idle' else (-.055 if clip=='Walk' else -.12)+(.012 if clip=='Walk' else .025)*(.5-.5*math.cos(2*t))
   rig.pose.bones['pelvis'].matrix=Matrix.Translation((0,0,bob))@R['pelvis']
   bpy.context.view_layer.update()
   spine=rig.pose.bones['spine_03'];axis=R['spine_03'].to_3x3();delta=Matrix.Rotation((.009*math.sin(t) if clip=='Idle' else .025*math.sin(t)),3,'Z');spine.rotation_quaternion=(axis.inverted()@delta@axis).to_quaternion()
   bpy.context.view_layer.update()
   for side,offset,sign in [('l',0,1),('r',.5,-1)]:
    phase=u+offset
    if clip!='Idle':foot_pose(side,phase,clip,bob)
    shoulder=rig.pose.bones['upperarm_'+side].head.copy();swing=(.015 if clip=='Idle' else .24 if clip=='Walk' else .42)*math.sin(math.tau*phase)
    upper=Vector((sign*.17,-swing,-1)).normalized()*arm.bones['upperarm_'+side].length;elbow=shoulder+upper
    lower=Vector((sign*.055,-.17-swing*.4,-1 if clip!='Run' else -.36)).normalized()*arm.bones['lowerarm_'+side].length;wrist=elbow+lower
    pose_segment('upperarm_'+side,shoulder,elbow);pose_segment('lowerarm_'+side,elbow,wrist)
    restdir=arm.bones['lowerarm_'+side].tail_local-arm.bones['lowerarm_'+side].head_local;delta=restdir.rotation_difference(lower)
    rig.pose.bones['hand_'+side].matrix=Matrix.Translation(wrist)@delta.to_matrix().to_4x4()@R['hand_'+side].to_quaternion().to_matrix().to_4x4()
   bpy.context.view_layer.update()
   for pb in rig.pose.bones:
    pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
    # Absolute IK targets generate local translations at the joints as well.
    pb.keyframe_insert('location',frame=frame,group=pb.name)
  track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);track.mute=True
 rig.animation_data.action=None
 for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 bpy.context.scene.render.fps=fps;bpy.context.scene.frame_set(1)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
 for ob in objects:ob.select_set(True)
 bpy.context.view_layer.objects.active=rig
 dest=ROOT/'game/assets/characters'/('starter_'+sex+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',use_selection=True,export_apply=False,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_materials='EXPORT')
 # Save rig with the studio scene for review, hiding the other static actor.
 for a in actors:
  for o in a.children_recursive:o.hide_render=True
 for o in objects:o.hide_render=False
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('starter_'+sex+'-rigged.blend')))
 if '--render' in __import__('sys').argv:
  rig.animation_data.action=actions[1];bpy.context.scene.frame_set(8)
  camera=bpy.context.scene.camera;camera.location=(2.8,-6,2.5);camera.rotation_euler=(Vector((0,0,.95))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=2.1
  for o in bpy.context.scene.objects:
   if o.type=='ARMATURE' and o!=rig:
    for child in o.children_recursive:child.hide_render=True
  bpy.context.scene.render.resolution_x=800;bpy.context.scene.render.resolution_y=1000;bpy.context.scene.cycles.samples=16
  bpy.context.scene.render.filepath=str(OUT/('starter_'+sex+'-walk.png'));bpy.ops.render.render(write_still=True)
 rig.animation_data.action=None
 for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 records.append({'id':sex,'triangles':triangles,'bones':len(arm.bones),'meshes':len(objects),'clips':['Idle','Walk','Run'],'native_weights':True,'fallback_weights':fallback,'texture_limit':1024})
(OUT/'rig-validation.json').write_text(json.dumps({'models':records,'source':'art/characters/neutral-starters.blend','walk_stride':.50,'walk_duration':1.,'walk_stance':.62,'run_stride':.80,'run_duration':22/30,'run_stance':.5,'limitations':['No facial animation','Foot contact on the fitted floor; stairs use whole-character floor placement']},indent=2))
print('NATIVE_RIGS_COMPLETE',records)
