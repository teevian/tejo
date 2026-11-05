#!/usr/bin/env python3
"""Read final PNG alpha into UV and foot metadata; never modify any image pixels."""
import ast,json
from pathlib import Path
from collections import deque
from PIL import Image
R=Path(__file__).resolve().parents[1]
tree=ast.parse((R/'tools/measure_village_residents.py').read_text())
f=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[f],type_ignores=[]),'bounds','exec'))
def measure(path,columns,rows):
 im=Image.open(path).convert('RGBA'); alpha=im.getchannel('A').point(lambda v:255 if v>160 else 0); people=[]
 for col in range(columns):
  x0=round(col*im.width/columns); x1=round((col+1)*im.width/columns)
  runs=[]; start=None
  for y in range(im.height+1):
   on=y<im.height and alpha.crop((x0,y,x1,y+1)).histogram()[255]>5
   if on and start is None:start=y
   if not on and start is not None:
    if y-start>8:runs.append([start,y])
    start=None
  while len(runs)>rows:
   k=min(range(len(runs)-1),key=lambda i:runs[i+1][0]-runs[i][1]); runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
  while len(runs)<rows:
   k=max(range(len(runs)),key=lambda i:runs[i][1]-runs[i][0]);lo,hi=runs[k]
   if hi-lo<im.height/rows*1.22:raise ValueError((path.name,col,runs))
   cut=min(range(round(lo+(hi-lo)*.34),round(lo+(hi-lo)*.68)),key=lambda y:alpha.crop((x0,y,x1,y+1)).histogram()[255])
   runs[k:k+1]=[[lo,cut],[cut,hi]]
  frames=[]
  for y0,y1 in runs:
   l,t,r,b=person_bounds(alpha.crop((x0,y0,x1,y1)));l+=x0;r+=x0;t+=y0;b+=y0
   feet=alpha.crop((l,b-max(7,round((b-t)*.08)),r,b)).getbbox()
   frames.append(dict(path='res://'+str(path.relative_to(R)),rect=[l,t,r-l,b-t],foot=[(feet[0]+feet[2])*.5,b-t],height_ratio=1))
  people.append(frames)
 print(path.name,im.size,'last column bands',runs)
 return people
m=dict(characters={},props=[],pigeon=[])
requests=json.loads((R/'data/village/neighbourhood-image-prompts.json').read_text())
walks=json.loads((R/'data/village/neighbourhood-walk-prompts.json').read_text())
for group in range(1,6):
 a=next(q for q in requests if q['key']==f'activity-{group:02}')
 b=next(q for q in requests if q['key']==f'reaction-{group:02}')
 w=walks[group-1]
 ac=measure(R/'assets/characters/villagers'/a['file'],4,2)
 ex=measure(R/'assets/characters/villagers'/b['file'],4,2)
 wa=measure(R/'assets/characters/villagers'/w['file'],4,4)
 for id,frames,extra,steps in zip(a['ids'],ac,ex,wa):
  poses=frames+extra+steps
  ratios={'rosario_merenda':[.75,1,.73,.78], 'nelson_termos':[.72,.72,.72,.72], 'iris_merenda':[.72,.72,.76,.72], 'leo_merenda':[.78,.72,.76,.74], 'margarida_testes':[.88,.88,1,.74], 'sara_aluna':[1,1,.76,1]}.get(id,[1]*4)
  for f,ratio in zip(poses,ratios):f['height_ratio']=ratio
  m['characters'][id]=dict(frames=poses)
for key in ['objects','pigeon']:
 cols=measure(R/'assets/world/village'/f'neighbours-{key}.png',4,2)
 m['props' if key=='objects' else 'pigeon']=[cols[c][r] for r in range(2) for c in range(4)]
 if key=='objects':
  for p in m['props']:p['foot'][0]=p['rect'][2]*.5
(R/'data/village/neighbourhood-art.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
print('Measured',len(m['characters']),'new identities, 160 native poses, 8 props and 8 courier poses')
