"""Deterministic original woodland texture sources; Pillow + NumPy, no downloads."""
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFilter
out=Path(__file__).resolve().parents[2]/'game/assets/woodland';out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(714)
def noise(size=512):
 a=np.zeros((size,size),float)
 for n,weight in [(4,.32),(16,.24),(64,.24),(256,.2)]:
  b=Image.fromarray(rng.integers(0,256,(n,n),dtype=np.uint8)).resize((size,size),Image.Resampling.BICUBIC)
  a+=np.asarray(b)*weight
 return (a-128)/128
for name,color in [('ground',(74,83,44)),('road',(128,111,77)),('stone',(103,113,96)),('bark',(91,72,49))]:
 n=noise();a=np.zeros((512,512,3));
 if name=='bark':
  x=np.arange(512)[None,:];y=np.arange(512)[:,None];n+=.27*np.sin(x*.32+np.sin(y*.02)*2)+.15*np.sin(x*.91+y*.003)
 for c in range(3):a[:,:,c]=color[c]*(1+n*.45)
 img=Image.fromarray(np.uint8(np.clip(a,0,255)))
 draw=ImageDraw.Draw(img,'RGBA')
 if name in ['ground','road']:
  for i in range(3200):
   x,y=rng.integers(0,512,2);r=int(rng.integers(1,4));draw.ellipse((x,y,x+r,y+r*.6),fill=(170,158,104,70) if i%2 else (29,39,18,65))
 img.save(out/(name+'.webp'),quality=90)
# Transparent branch clusters with distinct leaf silhouettes, used on double-sided cards.
img=Image.new('RGBA',(256,256));draw=ImageDraw.Draw(img)
for j in range(11):
 angle=j*2.399;end=np.array([128+np.cos(angle)*rng.uniform(50,110),128+np.sin(angle)*rng.uniform(50,110)])
 draw.line([128,128,*end],fill=(86,84,37,255),width=3)
 for t in np.linspace(.25,1,8):
  center=np.array([128,128])*(1-t)+end*t
  for side in [-1,1]:
   direction=angle+side*.8;length=rng.uniform(13,25);width=length*.45
   tip=center+np.array([np.cos(direction),np.sin(direction)])*length
   middle=(center+tip)/2;perp=np.array([-np.sin(direction),np.cos(direction)])*width/2
   green=int(rng.integers(75,145));draw.polygon([tuple(center),tuple(middle+perp),tuple(tip),tuple(middle-perp)],fill=(int(green*.55),green,int(green*.32),255))
img.save(out/'leaves.png')
print('Wrote five original woodland textures')
