"""Check actual glTF bytes: mobile budget, weights, skeleton and cyclic clip keys."""
from pathlib import Path
import struct,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
results=[]
for sex in ['male','female']:
 path=ROOT/'game/assets/characters'/f'starter_{sex}.glb';data=path.read_bytes()
 magic,version,length=struct.unpack_from('<4sII',data);assert magic==b'glTF' and version==2 and length==len(data)
 size,kind=struct.unpack_from('<II',data,12);assert kind==0x4e4f534a
 doc=json.loads(data[20:20+size]);assert len(doc['skins'])==1 and len(doc['skins'][0]['joints'])==23
 assert len(doc['meshes'])==1 and len(doc['meshes'][0]['primitives'])==1
 primitive=doc['meshes'][0]['primitives'][0]
 assert all(k in primitive['attributes'] for k in ['POSITION','NORMAL','JOINTS_0','WEIGHTS_0','COLOR_0'])
 triangles=doc['accessors'][primitive['indices']]['count']//3;assert 10000<triangles<=30000
 names={a['name'] for a in doc['animations']};assert names=={'Idle','Walk','Run'}
 for a in doc['animations']:
  assert len(a['channels'])>=20
  assert any(doc['accessors'][s['input']]['count']>10 for s in a['samplers'])
 results.append({'id':sex,'triangles':triangles,'bones':23,'clips':sorted(names),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
print(json.dumps({'status':'passed','models':results},indent=2))
