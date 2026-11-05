#!/usr/bin/env python3
"""Apply the reviewed walkable courtyards, short stair courts and side-facing buildings.
Run after build_village_layout.py to preserve these authored corrections on a rebuild.
"""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def revise():
 p=ROOT/'data/village/layout.json'; layout=json.loads(p.read_text())
 for route in layout['routes']:
  if route['surface']=='steps': route['surface']='stone'
 p.write_text(json.dumps(layout,ensure_ascii=False,indent=2)+'\n')
 p=ROOT/'data/village/frontages.json'; data=json.loads(p.read_text())
 segments=[(a,b) for r in layout['routes'] if r['surface']!='earth' for a,b in zip(r['points'],r['points'][1:])]
 def closest(point,a,b):
  dx,dy=b[0]-a[0],b[1]-a[1];n=dx*dx+dy*dy
  t=max(0,min(1,((point[0]-a[0])*dx+(point[1]-a[1])*dy)/n)) if n else 0
  return [a[0]+t*dx,a[1]+t*dy]
 count=0
 for i,entry in enumerate(data['buildings']):
  if not entry['id'].startswith('Frontage_'):continue
  at=[entry['at'][0],entry['at'][1]-100]
  near=min(((math.dist(at,closest(at,a,b)),a,b,closest(at,a,b)) for a,b in segments),key=lambda v:v[0])
  distance,a,b,point=near; vertical=abs(b[1]-a[1])>abs(b[0]-a[0])*1.05
  if distance>900 or (not vertical and i%7):continue
  right=point[0]>at[0]
  options={'Padaria':[0],'Loja de louças':[1],'Café':[3],'Loja de lembranças':[6],'Artesanato':[1,5],'Azulejaria':[7],'Habitação':[2,4,7]}
  choices=options.get(entry['label'],[2,4]);kind=choices[i%len(choices)]
  entry['atlas']='side';entry['type']=kind;entry['sprite_mirror']=right!=(kind in [0,2,4,6]);entry['side_facing']='right' if right else 'left'
  count+=1
 data['description']='Fachadas frontais e de lado, com portas orientadas para as ruas próximas. Pátios minerais visíveis são transitáveis, salvo bases sólidas e muros de suporte.'
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('Side-facing buildings:',count)
 from densify_village_blocks import build
 build()
if __name__=='__main__':revise()
