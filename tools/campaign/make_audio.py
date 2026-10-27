from pathlib import Path
import math,wave,struct,random
root=Path(__file__).resolve().parents[2]/'game/assets/audio';root.mkdir(parents=True,exist_ok=True)
rate=12000;seconds=16
for name,notes in [('explore',[146.83,174.61,220,261.63]),('town',[130.81,164.81,196,261.63]),('battle',[110,130.81,164.81,220]),('ending',[130.81,164.81,196,293.66])]:
 samples=[]
 for i in range(rate*seconds):
  t=i/rate;value=0
  for j,hz in enumerate(notes):
   trem=.65+.35*math.sin(2*math.pi*t/seconds*(j+1))
   value+=math.sin(2*math.pi*hz*t)*.065*trem+math.sin(2*math.pi*hz*2*t)*.012
  beat=(int(t*2)%8);pulse=math.exp(-((t*2)%1)*14)*(.06 if name=='battle' else .015)
  value+=math.sin(2*math.pi*55*t)*pulse
  envelope=min(1,t*2,(seconds-t)*2)
  samples.append(int(max(-.9,min(.9,value*envelope))*32767))
 with wave.open(str(root/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Original four-track adaptive underscore generated')
