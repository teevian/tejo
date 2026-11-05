#!/usr/bin/env python3
"""Read final generated alpha silhouettes; write native UV/foot metadata, never alter image pixels."""
import json
from collections import deque
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
manifest={'description':'Native final atlas regions. Rows are activity A/B and two right-facing walking poses.','atlases':{}}
def person_bounds(mask):
 """Ignore disconnected slivers of a neighbour crossing the column boundary."""
 w,h=mask.size
 pixels=bytearray(mask.tobytes())
 components=[]
 for origin in range(len(pixels)):
  if not pixels[origin]:continue
  pixels[origin]=0
  queue=deque([origin]);area=0;x0=w;y0=h;x1=y1=0
  while queue:
   p=queue.popleft();y,x=divmod(p,w);area+=1
   x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
   for q in ([p-1] if x else [])+([p+1] if x<w-1 else [])+([p-w] if y else [])+([p+w] if y<h-1 else []):
    if pixels[q]:pixels[q]=0;queue.append(q)
  components.append((area,(x0,y0,x1+1,y1+1)))
 main=max(components)
 a=main[1];kept=[]
 for area,b in components:
  dx=max(a[0]-b[2],b[0]-a[2],0);dy=max(a[1]-b[3],b[1]-a[3],0)
  if area>=3 and (max(dx,dy)<=10 or (area>main[0]*.08 and max(dx,dy)<=28)):kept.append(b)
 return (min(b[0] for b in kept),min(b[1] for b in kept),max(b[2] for b in kept),max(b[3] for b in kept))
for sheet,columns in [(1,5),(2,5),(3,5),(4,5),(5,5),(6,5),(7,3),(8,2)]:
 path=ROOT/'assets/characters/villagers'/('people-%02d.png'%sheet)
 im=Image.open(path).convert('RGBA')
 alpha=im.getchannel('A').point(lambda v:255 if v>128 else 0)
 runs=[];start=None
 for y in range(im.height+1):
  on=y<im.height and alpha.crop((0,y,im.width,y+1)).getbbox() is not None
  if on and start is None:start=y
  if not on and start is not None:
   if y-start>8:runs.append([start,y])
   start=None
 while len(runs)>4:
  k=min(range(len(runs)-1),key=lambda i:runs[i+1][0]-runs[i][1])
  runs[k:k+2]=[[runs[k][0],runs[k+1][1]]]
 assert len(runs)==4,(path.name,runs)
 people=[]
 for col in range(columns):
  frames=[]
  x0,x1=round(col*im.width/columns),round((col+1)*im.width/columns)
  for frame,(y0,y1) in enumerate(runs):
   bounds=person_bounds(alpha.crop((x0,y0,x1,y1)))
   assert bounds and bounds[3]-bounds[1]>45,(sheet,col,frame,bounds)
   left,top,right,bottom=x0+bounds[0],y0+bounds[1],x0+bounds[2],y0+bounds[3]
   feet=alpha.crop((left,bottom-max(8,round((bottom-top)*.08)),right,bottom)).getbbox()
   footx=left+(feet[0]+feet[2])*.5
   ratio=1.0
   if sheet==2 and col in [0,2] and frame<2:ratio=.72 if col==0 else .75
   if sheet==6 and col==0:ratio=.78
   frames.append({'rect':[left,top,right-left,bottom-top],'foot':[round(footx-left,2),bottom-top],'height_ratio':ratio})
  people.append({'frames':frames})
 manifest['atlases'][str(sheet)]={'path':'res://assets/characters/villagers/'+path.name,'image_size':list(im.size),'people':people}
 print(path.name,im.size,'rows',runs)
(ROOT/'data/village/resident-art.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
