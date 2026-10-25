"""Inspect actual portable meshes, native skins, packed textures and looping clips."""
from pathlib import Path
import struct,json,hashlib,math
ROOT=Path(__file__).resolve().parents[2];results=[]
for sex in ['male','female']:
 path=ROOT/'game/assets/characters'/f'starter_{sex}.glb';data=path.read_bytes()
 magic,version,length=struct.unpack_from('<4sII',data);assert magic==b'glTF' and version==2 and length==len(data)
 size,kind=struct.unpack_from('<II',data,12);assert kind==0x4e4f534a;doc=json.loads(data[20:20+size]);binary=data[28+size:]
 def read(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];formats={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'};n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];fmt='<'+formats[a['componentType']]*n
  step=v.get('byteStride',struct.calcsize(fmt));start=v.get('byteOffset',0)+a.get('byteOffset',0)
  return [struct.unpack_from(fmt,binary,start+i*step) for i in range(a['count'])]
 assert len(doc['skins'])==1;skin=doc['skins'][0];assert len(skin['joints'])==53
 bone_names={doc['nodes'][n]['name'] for n in skin['joints']}
 assert {'pelvis','head','thigh_l','calf_r','hand_l'}<=bone_names
 triangles=0;primitives=0
 for mesh in doc['meshes']:
  for p in mesh['primitives']:
   primitives+=1;attrs=p['attributes'];assert {'POSITION','NORMAL','JOINTS_0','WEIGHTS_0'}<=set(attrs)
   triangles+=doc['accessors'][p['indices']]['count']//3
   for weights,joints in zip(read(attrs['WEIGHTS_0']),read(attrs['JOINTS_0'])):
    assert abs(sum(weights)-1)<1e-4 and all(w>=0 and math.isfinite(w) for w in weights)
    assert all(0<=j<53 for j in joints)
 assert 20000<=triangles<=60000 and primitives<=12
 assert all('bufferView' in im for im in doc['images']) and len(doc['images'])==2
 assert {a['name'] for a in doc['animations']}=={'Idle','Walk','Run'}
 for anim in doc['animations']:
  assert len(anim['channels'])>=20
  assert any(doc['accessors'][s['input']]['count']>10 for s in anim['samplers'])
  assert max(read(s['input'])[-1][0] for s in anim['samplers'])>.5
  for channel in anim['channels']:
   sampler=anim['samplers'][channel['sampler']];keys=read(sampler['input']);values=read(sampler['output'])
   assert len(keys)>=1 and all(math.isfinite(v) for row in values for v in row)
   # Cycles must close without a reset snap (quaternion signs are equivalent).
   first,last=values[0],values[-1]
   error=max(abs(a-b) for a,b in zip(first,last))
   if channel['target']['path']=='rotation':error=min(error,max(abs(a+b) for a,b in zip(first,last)))
   assert error<.0001,(sex,anim['name'],'cycle seam',error)
 results.append({'id':sex,'triangles':triangles,'bones':53,'surfaces':primitives,'clips':['Idle','Walk','Run'],'embedded_images':len(doc['images']),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
print(json.dumps({'status':'passed','models':results},indent=2))
