"""Render original Ravenwood field screens and matching runtime metadata."""
import bpy, math, json, random, sys, argparse
from pathlib import Path
from mathutils import Vector
import numpy as np
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--samples',type=int,default=32)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
random.seed(17)
def mat(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough
 noise=m.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=7
 bump=m.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.16;bump.inputs['Distance'].default_value=.08
 m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs['Normal'],bs.inputs['Normal']);return m
wood=mat('Aged chestnut',(.20,.105,.052));dark=mat('Dark timber',(.075,.044,.025));plaster=mat('Warm lime plaster',(.57,.43,.27));roof=mat('Weathered cedar shingles',(.13,.18,.14));stone=mat('Fieldstone',(.26,.28,.23));ground=mat('Packed earth',(.23,.19,.12));green=mat('Forest canopy',(.045,.12,.066));cloth=mat('Ochre canvas',(.48,.27,.075));blue=mat('Indigo canvas',(.09,.17,.23));metal=mat('Iron bands',(.09,.10,.10),.4)
def cube(name,loc,scale,ma,bevel=.05):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(ma)
 if bevel:mod=o.modifiers.new('Soft worn edges','BEVEL');mod.width=bevel;mod.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o
def cyl(name,loc,r,depth,ma,verts=12):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc);o=bpy.context.object;o.name=name;o.data.materials.append(ma);o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return o
def beam(a,b,width=.15,ma=wood):
 o=cube('Timber brace',(Vector(a)+Vector(b))/2,(width,width,(Vector(b)-Vector(a)).length),ma,.025);o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o
def barrel(x,y):
 cyl('Oak barrel',(x,y,.48),.36,.9,wood,16)
 for z in [.12,.7]:cyl('Iron hoop',(x,y,z),.375,.07,metal,16)
 cube('Barrel lid',(x,y,.95),(.54,.57,.04),wood)
def house(x,y,w=3.4,d=3,h=3):
 cube('Fieldstone footing',(x,y,.2),(w+.2,d+.2,.4),stone)
 cube('Plaster walls',(x,y,h/2+.3),(w,d,h),plaster)
 for xx in [x-w/2,x,x+w/2]:cube('Frame upright',(xx,y-d/2-.07,h/2+.3),(.17,.18,h+.15),dark)
 for z in [.5,1.8,h+.3]:cube('Frame crossbeam',(x,y-d/2-.09,z),(w+.2,.2,.16),dark)
 # roof mesh gable with overlapping shingle strips
 for side in [-1,1]:
  for row in range(7):
   t=(row+.5)/7;xx=x+side*t*(w/2+.35);zz=h+1.65-t*1.4
   o=cube('Cedar roof course',(xx,y,zz),((w/2+.35)/7+.06,d+.7,.13),roof,.025);o.rotation_euler[1]=side*math.atan2(1.4,w/2+.35)
 cube('Door recess',(x,y-d/2-.12,1.05),(.9,.12,1.8),dark)
 for xx in [-.29,0,.29]:cube('Door planks',(x+xx,y-d/2-.2,1.05),(.26,.07,1.7),wood,.015)
 for xx in [-1.12,1.12]:
  cube('Window recess',(x+xx,y-d/2-.12,1.9),(.55,.08,.7),dark)
  cube('Window mullion',(x+xx,y-d/2-.2,1.9),(.04,.04,.72),wood)
 beam((x-w/2,y-d/2-.18,.6),(x-.2,y-d/2-.18,1.7),.12,dark)
 barrel(x+w/2+.5,y-d/2)
def tree(x,y,s=1):
 cyl('Pine trunk',(x,y,2*s),.19*s,4*s,wood)
 for z,r in [(2.7,1.5),(3.6,1.2),(4.4,.85)]:
  bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r*s,radius2=.1*s,depth=2.3*s,location=(x,y,z*s));bpy.context.object.data.materials.append(green)
def sign(text,x,y,z=2.4):
 cube('Carved sign',(x,y,z),(2.1,.14,.55),wood)
 bpy.ops.object.text_add(location=(x,y-.09,z));o=bpy.context.object;o.name='Sign '+text;o.rotation_euler=(math.pi/2,0,0);o.data.body=text;o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=.28;o.data.extrude=.003;o.data.materials.append(plaster)
def stall(x,y,ma):
 for xx in [-1.2,1.2]:
  for yy in [-.65,.65]:cube('Stall posts',(x+xx,y+yy,1.2),(.1,.1,2.4),wood)
 aw=cube('Canvas awning',(x,y,2.4),(2.8,1.8,.12),ma);aw.rotation_euler[0]=.12
 cube('Market counter',(x,y-.2,.8),(2.5,1,.15),wood)
 for xx in np.linspace(-.9,.9,4):
  cube('Produce crate',(x+float(xx),y-.2,1),(.42,.6,.3),wood)
  for j in range(3):
   bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.11,location=(x+float(xx),y-.4+j*.2,1.2));bpy.context.object.data.materials.append(cloth)
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for field in ['gate','market','camp']:
 reset();cube('Ground',(0,1,-.2),(100,100,.35),ground)
 # Subtle stone paving borders leave central traversal clear.
 for x in np.linspace(-7,7,22):
  for y in [-3.8,3.8]:cube('Road edge stone',(float(x),y,.015),(.48,.32,.08),stone,.08)
 for j in range(420):
  x=random.uniform(-10,10);y=random.uniform(-5,7)
  if random.random() < .65 and abs(y) > 2:continue
  cube('Worn cobblestone',(x,y,-.005),(random.uniform(.15,.38),random.uniform(.13,.3),.055),stone,.015)
 cube('Forest floor',(0,17,-.04),(100,20,.08),green,0)
 for y in [11,15,19]:
  for x in range(-21,23,3):tree(x+random.uniform(-.5,.5),y,random.uniform(1,1.8))
 if field=='gate':
  for side in [-1,1]:
   for x in np.linspace(3.4,10,18):
    xx=float(x)*side;cyl('Palisade',(xx,6,1.9),.2,3.8,wood)
   house(side*5,4.8,3.2,3,3.4)
  for xx in [-2.5,2.5]:cube('Gate pier',(xx,6,2.4),(.5,.6,4.8),dark)
  cube('Gate crossbeam',(0,6,4.5),(5.6,.7,.6),wood);sign('RAVENWOOD',0,5.6,4.55)
  sign('MARKET',-5.2,1.8);sign('CAMP',5.2,1.8)
  barrel(-5.7,2.8);barrel(5.7,2.8)
 elif field=='market':
  house(-4.7,5,3.8,3,3.5);sign('THE GREEN HART',-4.7,3.35,2.8)
  house(4.7,5,3.8,3,3);sign('IRON & EMBER',4.7,3.35,2.7)
  stall(-4,1.1,cloth);stall(3.7,1.1,blue)
  for x in [-1.1,0,1.1]:barrel(x,4.5)
  sign('GATE →',5.5,-.5,2.8)
 else:
  for x in [-4.5,4.5]:
   for y in [3,6]:
    # Triangular canvas tents
    verts=[(x-1.3,y-1,0),(x+1.3,y-1,0),(x,y-1,2.1),(x-1.3,y+1,0),(x+1.3,y+1,0),(x,y+1,2.1)]
    mesh=bpy.data.meshes.new('Tent');mesh.from_pydata(verts,[],[(0,2,5,3),(2,1,4,5),(3,5,4)]);o=bpy.data.objects.new('Army canvas tent',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(cloth)
    beam((x,y-1.3,0),(x,y-1.3,2.3),.1)
  for x in [2.4,3,3.6]:beam((x,1,0),(x,1,2),.08,metal)
  beam((2.2,1,1.4),(3.8,1,1.4),.12)
  for x in [-1,0,1]:cube('Supply chest',(x,5,.35),(.8,.65,.7),wood)
  sign('← GATE',-5.5,-.5,2.8);sign('MUSTER YARD',0,6,2.5)
 # Foreground objects rendered as a separate transparent overlay.
 before=set(bpy.data.objects)
 barrel(-7,-4.6);barrel(-6.3,-4.9);tree(7.6,-3.9,.9)
 foreground=set(bpy.data.objects)-before
 bpy.ops.object.camera_add(location=(0,-18,15));cam=bpy.context.object;cam.rotation_euler=(Vector((0,2,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=34;cam.data.sensor_width=36
 scene=bpy.context.scene;scene.camera=cam
 bpy.ops.object.light_add(type='AREA',location=(-5,-3,12));bpy.context.object.data.energy=2300;bpy.context.object.data.size=9
 scene.world.color=(.26,.3,.36);scene.render.engine='CYCLES';scene.cycles.samples=a.samples;scene.cycles.use_denoising=True
 scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
 scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
 for o in foreground:o.hide_render=True
 scene.render.film_transparent=False;scene.render.filepath=str(out/(field+'.png'));bpy.ops.render.render(write_still=True)
 for o in list(bpy.data.objects):
  if o.type=='MESH' or o.type=='FONT':o.hide_render=o not in foreground
 scene.render.film_transparent=True;scene.render.filepath=str(out/(field+'_foreground.png'));bpy.ops.render.render(write_still=True)
 fovy=math.degrees(2*math.atan(36/(2*34*(1280/720))))
 (out/(field+'.json')).write_text(json.dumps({'camera_position':[0,15,18],'camera_target':[0,1,-2],'fov':fovy,'bounds':[-9.5,9.5,0,3.2],'walkmesh':[[-9.5,0,0],[9.5,0,0],[9.5,0,3.2],[-9.5,0,3.2]],'triangles':[0,2,1,0,3,2]},indent=2))
 print('FIELD_COMPLETE',field)
