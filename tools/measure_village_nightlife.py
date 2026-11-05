#!/usr/bin/env python3
"""Measure native PNG regions and foot anchors only; preserve every generated pixel."""
import ast, json
from collections import deque

from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
tree = ast.parse((ROOT/'tools/measure_village_residents.py').read_text())
fn = next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[fn],type_ignores=[]),'bounds','exec'))
# Row bands follow the actual painted silhouettes, not an assumed equal-cell grid.
source=ast.parse((ROOT/'tools/measure_village_neighbours.py').read_text())
f=next(n for n in source.body if isinstance(n,ast.FunctionDef) and n.name=='measure')
R=ROOT
exec(compile(ast.Module(body=[f],type_ignores=[]),'measure','exec'))
def rows(path,cols,count):
 columns=measure(path,cols,count)
 return [[columns[c][r] for c in range(cols)] for r in range(count)]
manifest=dict(characters={},props=[])
for name,ids in [('friends',['gil','tiago','alexandre','martim','afonso']),('guests',['yuki','camila','beatriz','samira'])]:
 poses=rows(ROOT/f'assets/characters/villagers/nightlife-{name}.png',len(ids),4)
 for col,id in enumerate(ids):
  for row in range(4):poses[row][col]['height_ratio']=poses[row][col]['rect'][3]/poses[0][col]['rect'][3]
  manifest['characters'][id]=[poses[row][col] for row in range(4)]
props=rows(ROOT/'assets/world/village/nightlife-bar.png',3,2)
manifest['props']=props[0]+[props[1][0]]
for pose in manifest['props']:pose['foot'][0]=pose['rect'][2]*.5
manifest['characters']['nuno']=[props[1][1],props[1][2]]
(ROOT/'data/village/nightlife-art.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
