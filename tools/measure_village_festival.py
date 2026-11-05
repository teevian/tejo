#!/usr/bin/env python3
"""Measure final generated native pixels without changing existing or new art."""
import ast,json
from collections import deque
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
source=ast.parse((ROOT/'tools/measure_village_residents.py').read_text())
function=next(n for n in source.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[function],type_ignores=[]),'bounds','exec'))
manifest={'atlases':{},'props':{},'vehicles':{},'dog':{}}
def alpha(im):return im.getchannel('A').point(lambda v:255 if v>128 else 0)
def pose(mask,box):
 x0,y0,x1,y1=box
 b=person_bounds(mask.crop(box))
 l,t,r,bottom=x0+b[0],y0+b[1],x0+b[2],y0+b[3]
 feet=mask.crop((l,bottom-max(8,round((bottom-t)*.08)),r,bottom)).getbbox()
 return dict(rect=[l,t,r-l,bottom-t],foot=[(feet[0]+feet[2])*.5,bottom-t],height_ratio=1)
def quadrants(path):
 im=Image.open(path).convert('RGBA');a=alpha(im);frames=[]
 for i in range(4):
  box=(round(i%2*im.width/2),round(i//2*im.height/2),round((i%2+1)*im.width/2),round((i//2+1)*im.height/2))
  b=a.crop(box).getbbox();assert b,(path,i)
  frames.append(pose(a,box))
 return frames
for sheet in range(1,11):
 path=ROOT/f'assets/characters/villagers/festival-people-{sheet:02d}.png'
 if not path.exists():continue
 im=Image.open(path).convert('RGBA');a=alpha(im);runs=[];start=None
 for y in range(im.height+1):
  on=y<im.height and a.crop((0,y,im.width,y+1)).getbbox() is not None
  if on and start is None:start=y
  if not on and start is not None:
   if y-start>8:runs.append([start,y])
   start=None
 while len(runs)>4:
  k=min(range(len(runs)-1),key=lambda j:runs[j+1][0]-runs[j][1]);runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
 assert len(runs)==4,(path,runs)
 people=[]
 for col in range(5):
  frames=[pose(a,(round(col*im.width/5),y0,round((col+1)*im.width/5),y1)) for y0,y1 in runs]
  if sheet in [3,4]:
   for f in frames[:2]:f['height_ratio']=.73
  people.append(dict(frames=frames))
 manifest['atlases'][str(sheet)]=dict(path='res://assets/characters/villagers/'+path.name,people=people)
 print(path.name,im.size,'rows',runs)
for name,ids in [('festival-props.png',['cinema','fruit','sweets','chess']),('festival-details.png',['flowers','score','poetry','bicycle'])]:
 path=ROOT/'assets/world/village'/name
 if not path.exists():continue
 # Include complete freestanding supports and nearby equipment in each quadrant.
 im=Image.open(path).convert('RGBA');a=alpha(im)
 for i,id in enumerate(ids):
  x0,y0=round(i%2*im.width/2),round(i//2*im.height/2)
  x1,y1=round((i%2+1)*im.width/2),round((i//2+1)*im.height/2)
  b=a.crop((x0,y0,x1,y1)).getbbox()
  manifest['props'][id]=dict(path='res://assets/world/village/'+name,rect=[x0+b[0],y0+b[1],b[2]-b[0],b[3]-b[1]])
for kind,name in [('tuk_green','festival-tuk-green.png'),('tuk_yellow','festival-tuk-yellow.png'),('carriage','festival-carriage.png')]:
 path=ROOT/'assets/world/village'/name
 if path.exists():manifest['vehicles'][kind]=dict(path='res://assets/world/village/'+name,frames=quadrants(path))
path=ROOT/'assets/characters/villagers/festival-dog.png'
if path.exists():manifest['dog']=dict(path='res://assets/characters/villagers/'+path.name,frames=quadrants(path))
(ROOT/'data/village/festival-art.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Measured',len(manifest['atlases'])*5,'people,',len(manifest['props']),'props,',len(manifest['vehicles']),'vehicles and',bool(manifest['dog']),'dog.')
