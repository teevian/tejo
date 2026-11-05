#!/usr/bin/env python3
"""UV/foot metadata only; no modifications to generated PNG pixels."""
import ast,json
from pathlib import Path
from collections import deque
from PIL import Image
R=Path(__file__).resolve().parents[1]
t=ast.parse((R/'tools/measure_village_residents.py').read_text());f=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='person_bounds')
exec(compile(ast.Module(body=[f],type_ignores=[]),'bounds','exec'))
t=ast.parse((R/'tools/measure_village_neighbours.py').read_text());f=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name=='measure')
exec(compile(ast.Module(body=[f],type_ignores=[]),'measure','exec'))
cols=measure(R/'assets/items/bakery-food.png',4,2)
m={'food':[cols[c][r] for r in range(2) for c in range(4)],'counter':measure(R/'assets/world/village/bakery-counter.png',1,1)[0][0]}
m['counter']['foot'][0]=m['counter']['rect'][2]*.5
(R/'data/village/bakery-art.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
