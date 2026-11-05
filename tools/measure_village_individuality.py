#!/usr/bin/env python3
"""Measure final alpha/feet only. No image pixels are changed."""
import ast,json
from pathlib import Path
from collections import deque
from PIL import Image
R=Path(__file__).resolve().parents[1]
tree=ast.parse((R/'tools/measure_village_residents.py').read_text())
f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[f],type_ignores=[]),'bounds','exec'))
def measure(path,columns,rows):
 im=Image.open(path).convert('RGBA');a=im.getchannel('A').point(lambda v:255 if v>128 else 0)
 people=[]
 for col in range(columns):
  frames=[];x0=round(col*im.width/columns);x1=round((col+1)*im.width/columns)
  runs=[];start=None
  for y in range(im.height+1):
   on=y<im.height and a.crop((x0,y,x1,y+1)).histogram()[255]>3
   if on and start is None:start=y
   if not on and start is not None:
    if y-start>8:runs.append([start,y])
    start=None
  while len(runs)>rows:
   k=min(range(len(runs)-1),key=lambda i:runs[i+1][0]-runs[i][1]);runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
  while len(runs)<rows:
   k=max(range(len(runs)),key=lambda i:runs[i][1]-runs[i][0]);lo,hi=runs[k]
   if hi-lo<im.height/rows*1.3:raise ValueError((path.name,'column',col,'merged row bands',runs))
   cut=min(range(round(lo+(hi-lo)*.35),round(lo+(hi-lo)*.65)),key=lambda y:a.crop((x0,y,x1,y+1)).histogram()[255])
   runs[k:k+1]=[[lo,cut],[cut,hi]]
  for y0,y1 in runs:
   l,t,r,b=person_bounds(a.crop((x0,y0,x1,y1)));l+=x0;r+=x0;t+=y0;b+=y0
   feet=a.crop((l,b-max(7,round((b-t)*.07)),r,b)).getbbox()
   frames.append(dict(path='res://'+str(path.relative_to(R)),rect=[l,t,r-l,b-t],foot=[(feet[0]+feet[2])*.5,b-t],height_ratio=1))
  people.append(frames)
 print(path.name,im.size,'bands',runs)
 return people
m=dict(characters={},meals={},canes={},props=[],bench=[],prumo=[])
walks={q['key']:q for q in json.loads((R/'data/village/individuality-walk-prompts.json').read_text())}
for req in json.loads((R/'data/village/individuality-activity-prompts.json').read_text()):
 path=R/'assets/characters/villagers'/req['file']
 if not path.exists():continue
 columns=measure(path,req['columns'],2)
 walking=measure(R/'assets/characters/villagers'/walks[req['key']]['file'],req['columns'],4)
 for id,frames,steps in zip(req['ids'],columns,walking):
  frames += steps
  if id in ['lurdes','celeste','luz_cinefila','kenji_visitante','noor_visitante','artur_cinema','emma_visitante','camilo_cinema','emi_cinema','luca_visitante','deborah_visitante','yara_cinema']:
   for f in frames[:2]:f['height_ratio']=.82
  if id=='celso':frames[1]['height_ratio']=.8
  if id=='duarte':
   for f in frames:f['height_ratio']=.83
  m['characters'][id]=dict(frames=frames)
for req in json.loads((R/'data/village/individuality-extra-prompts.json').read_text()):
 path=R/('assets/world/village' if req['key']=='terraces' else 'assets/characters/villagers')/req['file']
 if not path.exists():continue
 columns=measure(path,req['columns'],req['rows'])
 if req['key'].startswith('meals'):
  for id,frames in zip(req['ids'],columns):
   for f in frames:f['height_ratio']=.95 if id in ['matilde','tomas'] else .79
   if req['key'].endswith('-lunch'):m['meals'][id]+=frames
   else:m['meals'][id]=frames
 elif req['key'].startswith('canes'):
  for i,id in enumerate(req['ids']):m['canes'][id]=dict(front=columns[i*2],back=columns[i*2+1])
 elif req['key']=='bench':
  m['bench']=[columns[c][r] for r in range(2) for c in range(2)]
  for f in m['bench'][:2]:f['height_ratio']=.91
 elif req['key']=='prumo':m['prumo']=[columns[c][r] for r in range(3) for c in range(2)]
 elif req['key']=='terraces':
  m['props']=[columns[c][r] for r in range(2) for c in range(4)]
  # A perspective bench may have only one leg in the lowest alpha band.
  # Furniture uses its whole footprint centre, not that single leg as a seat origin.
  for p in m['props']:p['foot'][0]=p['rect'][2]*.5
(R/'data/village/individuality-art.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
print('Measured',len(m['characters']),'individuals;',len(m['meals']),'diners;',len(m['canes']),'supported cane gaits')
