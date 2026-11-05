#!/usr/bin/env python3
"""Measure alpha bounds of the final street-life assets without altering their pixels."""
import ast,json
from pathlib import Path
from PIL import Image
from collections import deque
ROOT=Path(__file__).resolve().parents[1]
# Reuse the silhouette measurement, without rerunning or changing existing atlases.
source=ast.parse((ROOT/'tools/measure_village_residents.py').read_text())
function=next(n for n in source.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[function],type_ignores=[]),'bounds','exec'))
manifest={'atlases':{},'props':{}}
for i in [1,2]:
 p=ROOT/f'assets/characters/villagers/street-people-{i:02d}.png';im=Image.open(p).convert('RGBA')
 a=im.getchannel('A').point(lambda v:255 if v>128 else 0)
 runs=[];start=None
 for y in range(im.height+1):
  on=y<im.height and a.crop((0,y,im.width,y+1)).getbbox() is not None
  if on and start is None:start=y
  if not on and start is not None:
   if y-start>8:runs.append([start,y])
   start=None
 while len(runs)>4:
  k=min(range(len(runs)-1),key=lambda j:runs[j+1][0]-runs[j][1])
  runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
 assert len(runs)==4,(p,runs)
 people=[]
 for col in range(5):
  frames=[]
  x0,x1=round(col*im.width/5),round((col+1)*im.width/5)
  for row in range(4):
   y0,y1=runs[row]
   b=person_bounds(a.crop((x0,y0,x1,y1)))
   l,t,r,bottom=x0+b[0],y0+b[1],x0+b[2],y0+b[3]
   foot=a.crop((l,bottom-max(8,round((bottom-t)*.08)),r,bottom)).getbbox()
   frames.append({'rect':[l,t,r-l,bottom-t],'foot':[(foot[0]+foot[2])/2,bottom-t],'height_ratio':1})
  people.append({'frames':frames})
 manifest['atlases'][str(i)]={'path':'res://assets/characters/villagers/'+p.name,'people':people}
 print(p.name,im.size,runs)
p=ROOT/'assets/world/village/street-life.png';im=Image.open(p).convert('RGBA');a=im.getchannel('A').point(lambda v:255 if v>128 else 0)
for i,name in enumerate(['icecream','lamp','raffles','concert']):
 x0,x1=round((i%2)*im.width/2),round((i%2+1)*im.width/2)
 y0,y1=round((i//2)*im.height/2),round((i//2+1)*im.height/2)
 b=a.crop((x0,y0,x1,y1)).getbbox()
 manifest['props'][name]=[x0+b[0],y0+b[1],b[2]-b[0],b[3]-b[1]]
 print(name,manifest['props'][name])
(ROOT/'data/village/street-life-art.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
