import bpy, math, random, json, os, sys
from mathutils import Vector
from pathlib import Path
random.seed(17)
OUT=Path(os.environ.get('SR_CHARACTER_OUTPUT',str(Path(__file__).resolve().parents[2]/'.build/characters')))
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
# Native mesh study: all forms, including facial features and clothing, are geometry.
def mat(name,color,rough=.6,metal=0,noise=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if noise:
  tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=noise;tex.inputs['Detail'].default_value=2
  bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.13;bump.inputs['Distance'].default_value=.004
  m.node_tree.links.new(tex.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs['Normal'],p.inputs['Normal'])
 return m
skin=mat('Warm skin',(.58,.31,.19),.52);skin.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.065
skin2=mat('Warm skin female',(.66,.39,.26),.52);skin2.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.06
linen=mat('Undyed linen',(.56,.49,.37),.88,noise=350)
vest=mat('Weathered brown vest',(.15,.085,.045),.8,noise=90)
vestedge=mat('Vest edging',(.26,.15,.075),.75)
pants=mat('Slate woven trousers',(.16,.17,.17),.88,noise=280)
leather=mat('Brown boot leather',(.20,.09,.035),.54,noise=75)
leatheredge=mat('Leather edges',(.30,.15,.055),.65)
sole=mat('Boot soles',(.055,.035,.022),.86)
thread=mat('Stitch thread',(.43,.29,.13),.83)
metal=mat('Aged brass buckle',(.38,.26,.12),.32,.75)
hair=mat('Chestnut hair',(.105,.038,.016),.5,noise=50)
hairlit=mat('Hair warm ridges',(.16,.065,.024),.55)
white=mat('Eye whites',(.83,.80,.70),.3)
iris=mat('Hazel irises',(.18,.085,.026),.3)
pupil=mat('Pupils',(.006,.004,.003),.2)
mouth=mat('Lip shadow',(.23,.07,.045),.65)
lip=mat('Lips',(.45,.19,.13),.6)
shine=mat('Eye catchlight',(.95,.97,1),.1)
current=[]
def register(o,name,m):
 o.name=name
 if m:o.data.materials.append(m)
 current.append(o)
 return o
def mesh(name,vs,fs,m,sub=0):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);register(o,name,m)
 for p in me.polygons:p.use_smooth=True
 if sub:
  mod=o.modifiers.new('Soft contour','SUBSURF');mod.levels=sub;mod.render_levels=sub
 return o
def uv(name,p,s,m,seg=32,rings=20):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=p);o=bpy.context.object;o.scale=s;register(o,name,m)
 for f in o.data.polygons:f.use_smooth=True
 return o
def cube(name,p,s,m,bevel=.02):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);register(o,name,m)
 if bevel:
  mod=o.modifiers.new('Rounded edges','BEVEL');mod.width=bevel;mod.segments=3
  mod=o.modifiers.new('Weighted shading','WEIGHTED_NORMAL')
 return o
def curve(name,pts,r,m):
 cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=12;cu.bevel_depth=r;cu.bevel_resolution=3
 sp=cu.splines.new('BEZIER');sp.bezier_points.add(len(pts)-1)
 for p,co in zip(sp.bezier_points,pts):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);register(ob,name,m);return ob
def loft(name,rings,m,n=40,sub=1):
 # rings: z,cx,cy,rx,ry. ellipse angle 0 = character's front.
 vs=[]
 for z,cx,cy,rx,ry in rings:
  for j in range(n):
   a=j/n*math.tau;vs.append((cx+rx*math.sin(a),cy-ry*math.cos(a),z))
 fs=[]
 for i in range(len(rings)-1):
  for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 fs.extend([tuple(reversed(range(n))),tuple((len(rings)-1)*n+j for j in range(n))]);return mesh(name,vs,fs,m,sub)
def tube(name,points,radii,m,n=12):
 vs=[]
 for i,p in enumerate(points):
  p=Vector(p);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
  if d.length<.00001:d=Vector((0,0,1))
  d.normalize();ref=Vector((0,1,0));u=d.cross(ref).normalized();v=d.cross(u).normalized()
  for j in range(n):
   a=j*math.tau/n;vs.append(p+(u*math.cos(a)+v*math.sin(a))*radii[i])
 fs=[]
 for i in range(len(points)-1):
  for j in range(n):fs.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 fs+=[tuple(reversed(range(n))),tuple((len(points)-1)*n+j for j in range(n))];return mesh(name,vs,fs,m,1)
def stitches(name,points,m=thread,step=.023,r=.0013):
 for k in range(len(points)-1):
  a,b=Vector(points[k]),Vector(points[k+1]);length=(b-a).length;n=max(1,int(length/step))
  for i in range(n):
   p=a.lerp(b,(i+.15)/n);q=a.lerp(b,(i+.65)/n);curve(name,[p,q],r,m)
def character(female=False,xpos=0):
 global current;current=[]
 sk=skin2 if female else skin
 W=.9 if female else 1
 # Anatomy: 4.9-head hero proportions with intentionally expressive face and hands.
 # Single branched quad surface: two legs share a crotch seam and flow into
 # one waist. No separate pelvic ellipsoid or intersections at the thighs.
 N=40;vs=[];fs=[];top_indices={}
 for side in [-1,1]:
  rings=[(.22,.105*W,.066,.064),(.28,.105*W,.075,.073),(.33,.106*W,.077,.074),(.39,.106*W,.080,.080),(.445,.106*W,.082,.084),(.50,.105*W,.088,.087),(.565,.104*W,.094,.096),(.625,.102*W,.100,.104)]
  base=len(vs)
  for z,cx,rx,ry in rings:
   for j in range(N):
    a=j*math.tau/N;vs.append((side*(cx+rx*math.sin(a)),.009-ry*math.cos(a),z))
  for j in range(N):
   a=j*math.tau/N;outer=math.sin(a)>=-1e-8
   x=side*.201*W*max(0,math.sin(a));y=.009-.119*math.cos(a)
   z=.785 if outer else .785-.108*abs(math.sin(a))
   vs.append((x,y,z))
  for r in range(len(rings)):
   for j in range(N):
    f=(base+r*N+j,base+r*N+(j+1)%N,base+(r+1)*N+(j+1)%N,base+(r+1)*N+j)
    fs.append(f if side==1 else tuple(reversed(f)))
  f=tuple(base+j for j in reversed(range(N)));fs.append(f if side==1 else tuple(reversed(f)))
  top_indices[side]=[base+len(rings)*N+j for j in range(N//2+1)]
 # Outer leg semicircles combine into the complete hip ring, clockwise from front.
 previous=top_indices[1]+list(reversed(top_indices[-1]))[1:-1]
 for z,rx,ry,cy in [(.815,.206*W,.125,.009),(.855,.204*W,.129,.004),(.89,.196*W,.125,0),(.93,.184*W,.115,0)]:
  new=[]
  for j in range(N):
   a=j*math.tau/N;new.append(len(vs));vs.append((rx*math.sin(a),cy-ry*math.cos(a),z))
  for j in range(N):fs.append((previous[j],previous[(j+1)%N],new[(j+1)%N],new[j]))
  previous=new
 fs.append(tuple(previous))
 trousers=mesh('Tailored continuous trousers',vs,fs,pants,1)
 import bmesh
 bm=bmesh.new();bm.from_mesh(trousers.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(trousers.data);bm.free()
 for side in [-1,1]:
  x=side*.105*W
  # Subtle fly stitching provides a readable front instead of an anatomical crease.
 curve('Trouser fly seam',[(.012,-.131,.882),(.012,-.130,.835),(.007,-.118,.79)],.0015,pants)
 for s in [-1,1]:
  x=s*.105*W
  # Boots: broad toe box, instep, shaft and overlapping cuffs.
  uv('Boot foot',(x,-.055,.092),(.088,.155,.077),leather)
  cube('Layered outsole',(x,-.053,.038),(.18,.30,.047),sole,.027)
  cube('Stacked heel',(x,.035,.021),(.15,.105,.04),sole,.012)
  loft('Boot shaft',[(.09,x,.015,.072,.08),(.14,x,.01,.075,.083),(.18,x,.008,.07,.075),(.22,x,.006,.071,.073),(.26,x,.008,.082,.082),(.30,x,.012,.084,.085),(.33,x,.012,.086,.085)],leather)
  loft('Boot cuff',[(.295,x,.012,.087,.09),(.30,x,.012,.094,.095),(.335,x,.012,.094,.095),(.343,x,.012,.087,.09)],leatheredge)
  for z in [.15,.21]:curve('Ankle leather crease',[(x-.055,-.045,z),(x,-.070,z-.012),(x+.055,-.045,z+.003)],.0035,leatheredge)
  curve('Toe cap seam',[(x-.075,-.11,.125),(x-.045,-.143,.145),(x,-.15,.151),(x+.045,-.143,.145),(x+.075,-.11,.125)],.002,leatheredge)
  stitches('Boot stitching',[(x-.07,-.14,.115),(x-.04,-.17,.12),(x,-.18,.123),(x+.04,-.17,.12),(x+.07,-.14,.115)],r=.001)
  # Cuff back seam and side piping.
  curve('Boot side seam',[(x+s*.077,.01,.13),(x+s*.078,.01,.24),(x+s*.086,.01,.31)],.002,leatheredge)
 # Shirt torso with natural waist taper and slight folds.
 loft('Linen shirt',[(.87,0,0,.182*W,.115),(.91,0,0,.188*W,.12),(.96,0,0,.18*W,.115),(1.02,0,.002,.177*W,.115),(1.10,0,.005,.20*W,.128),(1.18,0,.008,.226*W,.13),(1.27,0,.014,.24*W,.123),(1.32,0,.018,.20*W,.108),(1.35,0,.014,.115,.08),(1.36,0,.012,.083,.065)],linen)
 # One continuous vest surface, with open armholes and connected shoulders.
 vs=[];fs=[]
 zs=[.93,.96,1.04,1.13,1.20,1.27,1.32,1.35,1.373]
 rx=[.194*W,.193*W,.188*W,.214*W,.237*W,.235*W,.205*W,.151*W,.086]
 ry=[.128,.128,.127,.139,.143,.139,.123,.099,.073]
 ns=64
 for i,z in enumerate(zs):
  for j in range(ns+1):
   a=.36+(math.tau-.72)*j/ns
   vs.append((rx[i]*math.sin(a),.012-ry[i]*math.cos(a),z))
 for i in range(len(zs)-1):
  for j in range(ns):
   a=.36+(math.tau-.72)*(j+.5)/ns
   # The armholes widen below the shoulder; their top ends below the yoke.
   cut=(i==3 and abs(math.sin(a))>.94) or (i in [4,5] and abs(math.sin(a))>.79) or (i==6 and abs(math.sin(a))>.97)
   fs.append((i*(ns+1)+j,i*(ns+1)+j+1,(i+1)*(ns+1)+j+1,(i+1)*(ns+1)+j))
 ob=mesh('Connected shoulder vest',vs,fs,vest,1)
 mod=ob.modifiers.new('Vest leather thickness','SOLIDIFY');mod.thickness=.009
 # Cut smooth oval armholes through the thickened cloth, avoiding stepped
 # polygon omissions and the pointed flaps they produce at the shoulders.
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 for modifier in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=modifier.name)
 for side in [-1,1]:
  cutter=uv('Temporary armhole cutter',(side*.235*W,.012,1.245),(.071*W,.24,.096),None,48,32)
  bpy.context.view_layer.objects.active=ob
  mod=ob.modifiers.new('Tailored oval armhole','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
  bpy.ops.object.modifier_apply(modifier=mod.name)
  current.remove(cutter);bpy.data.objects.remove(cutter,do_unlink=True)
 bevel=ob.modifiers.new('Soft leather cut edges','BEVEL');bevel.width=.002;bevel.segments=2

 for side in [-1,1]:
  front=[(side*rx[i]*math.sin(.36),.006-ry[i]*math.cos(.36),zs[i]) for i in range(len(zs))]
  curve('Vest front binding',front,.0035,vestedge)
  stitches('Vest front stitching',[(x+side*.009,y-.003,z) for x,y,z in front])
 # bottom stitched hem follows wrap
 hem=[]
 for j in range(49):
  a=.36+(math.tau-.72)*j/48;hem.append((.196*W*math.sin(a),.007-.133*math.cos(a),.945))
 curve('Vest hem binding',hem,.0035,vestedge);stitches('Hem stitch',[(x,y,z+.012) for x,y,z in hem],step=.025)
 # Neck and shirt stand collar, open at front.
 uv('Neck',(0,.012,1.395),(.07,.065,.104),sk)
 for s in [-1,1]:
  collar=mesh('Open linen collar',[(s*.013,-.071,1.345),(s*.085,-.085,1.30),(s*.108,-.03,1.355),(s*.065,-.018,1.408),(s*.014,-.047,1.39)],[(0,1,2,3,4)],linen,1)
  sol=collar.modifiers.new('Collar thickness','SOLIDIFY');sol.thickness=.006
 # rolled sleeves and arms angled naturally away from body, hands separate and fingers modeled.
 for s in [-1,1]:
  tube('Linen upper sleeve',[(s*.195*W,.015,1.285),(s*.25*W,.017,1.275),(s*.285*W,.012,1.205),(s*.315*W,0,1.115),(s*.344*W,-.005,1.025)],[.09,.087,.078,.070,.066],linen,20)
  tube('Rolled sleeve cuff',[(s*.335*W,-.003,1.065),(s*.343*W,-.005,1.04),(s*.349*W,-.008,1.02)],[.079,.081,.075],linen,24)
  tube('Forearm',[(s*.342*W,-.005,1.065),(s*.351*W,-.013,1.015),(s*.365*W,-.026,.965),(s*.377*W,-.038,.90),(s*.386*W,-.043,.847),(s*.390*W,-.043,.815)],[.048,.055,.054,.043,.033,.034],sk,20)
  # sleeve wrinkles
  for off in [0,.035]:curve('Sleeve fold',[(s*.30*W,-.07,1.12+off),(s*.32*W,-.072,1.10+off),(s*.35*W,-.056,1.115+off)],.003,linen)
  palm=uv('Hand palm',(s*.39*W,-.04,.805),(.041,.032,.068),sk)
  for finger in range(4):
   xx=s*(.365*W+finger*.017);zz=.752+(abs(finger-1.3)*.006);length=[.061,.073,.068,.050][finger]
   tube('Finger',[(xx,-.045,zz),(xx+s*.004,-.05,zz-length*.48),(xx+s*.002,-.062,zz-length)],[.0105,.010,.008],sk,10)
   uv('Fingernail',(xx+s*.002,-.070,zz-length+.01),(.006,.0015,.009),skin2,16,10)
  tube('Thumb',[(s*.36*W,-.063,.805),(s*.34*W,-.075,.782),(s*.337*W,-.085,.756)],[.018,.015,.011],sk,12)
 # Leather belt and handmade buckle.
 loft('Waist belt',[(.889,0,0,.198*W,.13),(.894,0,0,.203*W,.135),(.932,0,0,.203*W,.135),(.936,0,0,.196*W,.129)],leather)
 for z in [.897,.929]:
  pts=[(.204*W*math.sin(j*math.tau/64),-.136*math.cos(j*math.tau/64),z) for j in range(65)];curve('Belt seam',pts,.0014,leatheredge)
 # rectangular buckle frame with open center, genuine geometry
 curve('Buckle frame',[(-.026,-.145,.892),(.027,-.145,.892),(.027,-.145,.938),(-.026,-.145,.938),(-.026,-.145,.892)],.005,metal)
 curve('Buckle pin',[(-.026,-.15,.915),(.018,-.15,.915)],.0028,metal)
 for i in range(4):uv('Belt punched hole',(.055+i*.018,-.133,.914),(.002,.0015,.002),sole,12,8)
 # pouch offset on right hip
 px=-.16*W
 cube('Belt pouch',(px,-.115,.85),(.095,.053,.12),leather,.016)
 cube('Pouch flap',(px,-.15,.883),(.098,.014,.055),leatheredge,.012)
 curve('Pouch stitching',[(px-.039,-.155,.865),(px-.039,-.155,.807),(px+.039,-.155,.807),(px+.039,-.155,.865)],.0017,thread)
 uv('Pouch clasp',(px,-.162,.872),(.007,.003,.008),metal,16,10)
 # Sculpted head shell. Extra forward cheek volume and a tapered jaw/chin.
 hz=1.62;headrings=[(-.198,.028,.041,.001),(-.18,.065,.061,-.005),(-.14,.105,.084,-.003),(-.09,.133,.104,0),(-.035,.15,.117,.002),(.025,.153,.121,.005),(.085,.15,.117,.011),(.14,.135,.105,.02),(.18,.10,.078,.024),(.205,.035,.034,.024)]
 if female:headrings=[(z,rx*.95,ry*.97,cy) for z,rx,ry,cy in headrings]
 loft('Sculpted head',[(hz+z,0,cy,rx,ry) for z,rx,ry,cy in headrings],sk,n=64,sub=2)
 # cheek pads blend into skull; eyes sit on face rather than sockets painted onto sphere.
 for s in [-1,1]:
  uv('Ear',(s*.145*W,.008,hz-.025),(.025,.035,.052),sk)
  uv('Ear inner',(s*.160*W,-.010,hz-.024),(.009,.019,.031),lip)
  # Cheek volume belongs to the continuous head, not separate pads.
  ex=s*.054;ez=hz+.014
  # custom almond-shaped eyeball and colored lens, framed by eyelid geometry
  ev=[(ex,-.124,ez)];n=32
  for j in range(n):
   a=j*math.tau/n;ev.append((ex+.034*math.cos(a),-.113,ez+.017*math.sin(a)*(.8+.2*abs(math.sin(a)))))
  mesh('Almond eye',ev,[(0,j+1,(j+1)%n+1) for j in range(n)],white,1)
  uv('Iris',(ex,-.125,ez),(.013,.004,.016),iris,32,20)
  uv('Pupil',(ex,-.131,ez+.001),(.006,.002,.010),pupil,24,16)
  uv('Eye glint',(ex-.006,-.133,ez+.008),(.004,.001,.004),shine,16,10)
  upper=[(ex-.033,-.115,ez),(ex-.018,-.124,ez+.015),(ex,-.127,ez+.018),(ex+.018,-.123,ez+.015),(ex+.033,-.114,ez+.001)]
  lower=[(ex-.033,-.114,ez),(ex-.018,-.122,ez-.011),(ex,-.126,ez-.014),(ex+.018,-.122,ez-.011),(ex+.033,-.114,ez+.001)]
  curve('Upper eyelid',upper,.003,sk);curve('Upper lash',[(x,y-.002,z+.001) for x,y,z in upper],.0018,hair)
  curve('Lower eyelid',lower,.0025,sk)
  curve('Eyebrow',[(ex-.038,-.112,ez+.05),(ex-.012,-.121,ez+.060),(ex+.014,-.118,ez+.059),(ex+.036,-.106,ez+.05)],.0055,hair)
 # Nose bridge, nostrils, lips modeled as small continuous shapes.
 uv('Nose bridge',(0,-.113,hz-.012),(.015,.020,.044),sk)
 uv('Nose tip',(0,-.14,hz-.048),(.020,.022,.017),sk)
 for s in [-1,1]:
  uv('Nose wing',(s*.018,-.128,hz-.055),(.010,.014,.009),sk,24,16)
  uv('Nostril',(s*.014,-.142,hz-.063),(.0055,.003,.003),mouth,16,10)
 curve('Upper lip',[(-.032,-.094,hz-.102),(-.014,-.109,hz-.10),(0,-.112,hz-.104),(.014,-.109,hz-.10),(.032,-.094,hz-.102)],.0035,lip)
 curve('Mouth line',[(-.032,-.097,hz-.104),(0,-.113,hz-.109),(.032,-.097,hz-.104)],.0018,mouth)
 curve('Lower lip',[(-.024,-.099,hz-.11),(0,-.112,hz-.116),(.024,-.099,hz-.11)],.004,lip)
 # Hair cap deliberately avoids forehead and sideburn silhouette is individual locks.
 vs=[];fs=[];na=64;nv=12
 for i in range(nv):
  t=(i+.01)/(nv-1)
  for j in range(na):
   a=j*math.tau/na;bottom=1.18+.72*(1-math.cos(a))/2
   theta=t*bottom
   vs.append((.16*math.sin(theta)*math.sin(a),.025-.135*math.sin(theta)*math.cos(a),hz+.025+.208*math.cos(theta)))
 for i in range(nv-1):
  for j in range(na):fs.append((i*na+j,i*na+(j+1)%na,(i+1)*na+(j+1)%na,(i+1)*na+j))
 cap=mesh('Hair cap',vs,fs,hair,1)
 mod=cap.modifiers.new('Closed scalp shell','SOLIDIFY');mod.thickness=.018
 def lock(name,points,width,thick=.45):
  # tapered ribbon-like clump, solid 3D swept cross-section
  vs=[];ns=10
  rr=[.3,.95,1,.7,.025]
  for i,p in enumerate(points):
   p=Vector(p);d=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)]);d.normalize();u=d.cross(Vector((0,1,0))).normalized();v=d.cross(u).normalized()
   for j in range(ns):
    a=j*math.tau/ns;vs.append(p+u*width*rr[i]*math.cos(a)+v*width*thick*rr[i]*math.sin(a))
  fs=[]
  for i in range(len(points)-1):
   for j in range(ns):fs.append((i*ns+j,i*ns+(j+1)%ns,(i+1)*ns+(j+1)%ns,(i+1)*ns+j))
  fs.extend([tuple(reversed(range(ns))),tuple((len(points)-1)*ns+j for j in range(ns))]);mesh(name,vs,fs,hair if random.random()<.72 else hairlit,1)
 # Asymmetric swept clumps, flowing across the scalp rather than parallel spikes.
 if female:
  for side in [-1,1]:
   for k in range(5):
    w=.026+k*.001
    points=[(side*.012,.005,hz+.222),(side*(.035+k*.008),-.075,hz+.20),(side*(.075+k*.012),-.117,hz+.15),(side*(.11+k*.012),-.115,hz+.075),(side*(.135+k*.009),-.085,hz-.015-k*.018)]
    lock('Parted fringe',points,w)
 else:
  for k in range(7):
   xx=-.11+k*.036
   points=[(xx*.45+.07,.035,hz+.216),(xx*.65+.045,-.035,hz+.23),(xx-.005,-.093,hz+.195),(xx-.044,-.125,hz+.13),(xx-.06,-.112,hz+.075+abs(xx)*.2)]
   lock('Swept fringe',points,.036)
 for k in range(17):
  a=.8+k*(math.tau-1.6)/16
  p=[]
  for ang,r,z in [(a-.20,.075,.19),(a-.15,.125,.15),(a-.08,.16,.09),(a,.168,.012),(a+.05,.16,-.07-random.random()*.03)]:p.append((r*math.sin(ang),.026-r*.85*math.cos(ang),hz+z))
  lock('Layered hair',p,.028 if female else .031)
 if female:
  uv('Ponytail tie',(0,.158,hz+.035),(.042,.027,.037),leather)
  for k in range(6):
   a=k*math.tau/6;xx=.035*math.cos(a)
   lock('Low ponytail',[(xx*.5,.14,hz+.06),(xx,.22,hz+.02),(xx*1.25,.26,hz-.05),(xx,.25,hz-.14),(xx*.5,.20,hz-.22)],.030)
 # All components grouped to a reusable transform. No rigging claimed yet.
 root=bpy.data.objects.new('Female neutral starter' if female else 'Male neutral starter',None);bpy.context.collection.objects.link(root)
 for o in current:o.parent=root
 # Weld intersecting anatomical volumes for a continuous surface.
 def weld(prefixes,name,voxel,smooth):
  objects=[o for o in root.children if any(o.name.startswith(p) for p in prefixes) and not o.name.startswith('Fingernail')]
  if not objects:return
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0]
  bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object;o.name=name
  bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  print('Refining',name,flush=True)
  rem=o.modifiers.new('Continuous surface','REMESH');rem.mode='VOXEL';rem.voxel_size=voxel;rem.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=rem.name)
  sm=o.modifiers.new('Surface relaxation','SMOOTH');sm.factor=.65;sm.iterations=smooth;bpy.ops.object.modifier_apply(modifier=sm.name)
  return o
 weld(['Sculpted head','Ear','Nose bridge','Nose tip','Nose wing'],'Continuous sculpted head',.006,5)
 weld(['Linen shirt','Linen upper sleeve'],'Continuous shirt and shoulders',.004,3)
 weld(['Forearm','Hand palm','Finger','Thumb'],'Continuous arms and hands',.003,3)
 weld(['Hair cap','Swept fringe','Parted fringe','Layered hair','Low ponytail'],'Sculpted hair',.006,3)
 # Slightly smaller head and face proportion, preserving neck contact.
 for o in list(root.children):
  if any(o.name.startswith(p) for p in ['Continuous sculpted head','Sculpted hair','Almond eye','Iris','Pupil','Eye glint','Upper eyelid','Upper lash','Lower eyelid','Eyebrow','Nostril','Upper lip','Mouth line','Lower lip','Ponytail tie']):
   if o.type=='MESH':
    for v in o.data.vertices:
     co=o.matrix_local@v.co;co.x*=.88;co.z=1.42+(co.z-1.42)*.90;v.co=o.matrix_local.inverted()@co
   elif o.type=='CURVE':
    for sp in o.data.splines:
     for p in sp.bezier_points:
      for attr in ['co','handle_left','handle_right']:
       co=getattr(p,attr).copy();co.x*=.88;co.z=1.42+(co.z-1.42)*.90;setattr(p,attr,co)
 root.location.x=xpos
 root.rotation_euler.z=math.radians(-6 if female else 5)
 root['stage']='Native Blender mesh study, unrigged. Not final concept fidelity.'
 root['visible_equipment']='Weapons and shields only. Armor will change statistics, not model appearance.'
 return root
male=character(False,-.52);female=character(True,.52)
for ob in list(bpy.data.objects):
 if ob.name.startswith(('Knee fold','Calf fold','Sleeve fold')):bpy.data.objects.remove(ob,do_unlink=True)
# Render scene uses a neutral cyclorama, studio lighting and soft shadows.
floor=mat('Studio background',(.24,.26,.25),.93)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006));ground=bpy.context.object;ground.name='Studio floor';ground.data.materials.append(floor)
world=bpy.data.worlds.new('Soft studio');bpy.context.scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.48,.52,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5
def area(name,pos,power,size,color):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=color;o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area('Large softbox',(-3,-4,5),450,4,(1,.86,.73));area('Cool fill',(3,-2,3),280,3,(.75,.85,1));area('Rim',(1,2.5,4),500,3,(1,.90,.77))
bpy.ops.object.camera_add(location=(2.6,-7,2.7));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.99))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.62;bpy.context.scene.camera=cam
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.render.resolution_x=1800;sc.render.resolution_y=1400;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX'
# Export genuine meshes, keeping studio scene out of game GLB.
bpy.ops.object.select_all(action='DESELECT')
for root in [male,female]:
 root.select_set(True)
 for ob in root.children_recursive:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'neutral-starters-mesh-study.glb'),export_format='GLB',use_selection=True,export_apply=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'neutral-starters-studio.blend'))
sc.render.filepath=str(OUT/'neutral-starters-front.png')
if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)
cam.location=(2.7,7,2.8);cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.resolution_x=1400;sc.render.resolution_y=1100
sc.render.filepath=str(OUT/'neutral-starters-back.png')
if '--no-render' not in sys.argv:bpy.ops.render.render(write_still=True)
# Check evaluated geometry counts, independently of export's success message.
dg=bpy.context.evaluated_depsgraph_get();counts={}
for root in [male,female]:
 triangles=0
 for ob in root.children_recursive:
  if ob.type in ['MESH','CURVE']:
   ev=ob.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();triangles+=len(me.loop_triangles);ev.to_mesh_clear()
 counts[root.name]=triangles
(OUT/'validation.json').write_text(json.dumps({'stage':'unrigged native Blender mesh study','triangles':counts,'renderer':'Blender 4.5.3 Cycles CPU','samples':32,'pass':'Shoulder, arm and pelvis continuity revision','not_yet_done':['UV paint matching approved concept','deformation topology and skinning','animations','Godot import and phone review']},indent=2))
print('STARTER_STUDY_DONE',counts)
