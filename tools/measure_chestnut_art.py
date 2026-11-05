#!/usr/bin/env python3
"""Measure alpha regions and anchors only, preserving the generated PNGs unchanged."""
import ast, json
from pathlib import Path
from collections import deque
from PIL import Image

R = Path(__file__).resolve().parents[1]
for file, name in [('measure_village_residents.py', 'person_bounds'), ('measure_village_neighbours.py', 'measure')]:
    tree = ast.parse((R / 'tools' / file).read_text())
    fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == name)
    exec(compile(ast.Module(body=[fn], type_ignores=[]), name, 'exec'))
stall = [col[0] for col in measure(R / 'assets/world/village/chestnut-stall-final.png', 3, 1)]
height = max(pose['rect'][3] for pose in stall[:2])
for pose in stall:
    pose['foot'][0] = pose['rect'][2] * .5
    pose['height_ratio'] = pose['rect'][3] / height
food = [col[0] for col in measure(R / 'assets/items/chestnut-portions.png', 2, 1)]
(R / 'data/village/chestnut-art.json').write_text(json.dumps({'stall': stall, 'food': food}, ensure_ascii=False, indent=2) + '\n')
