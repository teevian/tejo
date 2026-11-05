#!/usr/bin/env python3
"""Measure alpha/UVs; preserve every generated pixel."""
import ast,json
from pathlib import Path
from collections import deque
from PIL import Image
R=Path(__file__).resolve().parents[1]
tree=ast.parse((R/'tools/measure_village_residents.py').read_text())
f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[f],type_ignores=[]),'bounds','exec'))
def mask(path):
 im=Image.open(path).convert('RGBA');return im,im.getchannel('A').point(lambda x:255 if x>128 else 0)
def pose(a,box):
 x,y,_,_=box;l,t,r,b=person_bounds(a.crop(box));l+=x;r+=x;t+=y;b+=y
 feet=a.crop((l,b-max(7,round((b-t)*.07)),r,b)).getbbox()
 return dict(rect=[l,t,r-l,b-t],foot=[(feet[0]+feet[2])*.5,b-t],height_ratio=1)
m=dict(atlases={},objects=[],animals=[],object_path='res://assets/world/village/living-objects.png',animal_path='res://assets/world/village/living-animals.png')
for n in range(1,7):
 path=R/f'assets/characters/villagers/living-people-{n:02d}.png';im,a=mask(path)
 runs=[];start=None
 for y in range(im.height+1):
  on=y<im.height and a.crop((0,y,im.width,y+1)).getbbox() is not None
  if on and start is None:start=y
  if not on and start is not None:
   if y-start>8:runs.append([start,y])
   start=None
 while len(runs)>4:
  k=min(range(len(runs)-1),key=lambda i:runs[i+1][0]-runs[i][1]);runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
 assert len(runs)==4,(n,runs)
 people=[dict(frames=[pose(a,(round(c*im.width/5),y0,round((c+1)*im.width/5),y1)) for y0,y1 in runs]) for c in range(5)]
 m['atlases'][str(n)]=dict(path='res://'+str(path.relative_to(R)),people=people)
 print(path.name,runs)
for kind,file in [('objects','living-objects.png'),('animals','living-animals.png')]:
 im,a=mask(R/'assets/world/village'/file)
 for i in range(8):m[kind].append(pose(a,(round((i%4)*im.width/4),round((i//4)*im.height/2),round((i%4+1)*im.width/4),round((i//4+1)*im.height/2))))
fallback=R/'assets/characters/villagers/living-prumo.png'
if fallback.exists():
 im,a=mask(fallback)
 m['fallback']=dict(path='res://'+str(fallback.relative_to(R)),frames=[pose(a,(round((i%2)*im.width/2),round((i//2)*im.height/2),round((i%2+1)*im.width/2),round((i//2+1)*im.height/2))) for i in range(4)])
teodoro=R/'assets/characters/villagers/living-teodoro.png'
if teodoro.exists():
 im,a=mask(teodoro)
 frames=[pose(a,(round((i%2)*im.width/2),round((i//2)*im.height/2),round((i%2+1)*im.width/2),round((i//2+1)*im.height/2))) for i in range(4)]
 for f in frames[:2]:f['height_ratio']=.91
 m['teodoro']=dict(path='res://'+str(teodoro.relative_to(R)),frames=frames)
(R/'data/village/living-art.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
