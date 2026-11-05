#!/usr/bin/env python3
"""Measure new native activity poses; never edit final art or existing atlases."""
import ast
import json
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = ast.parse((ROOT / 'tools/measure_village_residents.py').read_text())
function = next(n for n in source.body if isinstance(n, ast.FunctionDef) and n.name == 'person_bounds')
exec(compile(ast.Module(body=[function], type_ignores=[]), 'bounds', 'exec'))
manifest = {'description': 'Authored social poses with measured alpha bounds and fixed scale per identity.', 'characters': {}}
sheets = {
    'social-activities.png': ['farid', 'teresa', 'leonor', 'matilde', 'nuno'],
    'social-service.png': ['ines_escuteira', 'pedro_escuteiro', 'enzo_gelados', 'sofia_policia', 'clara_violinista'],
    'social-friends.png': ['gil', 'tiago', 'alexandre', 'martim', 'afonso'],
    'social-applause.png': ['gil', 'tiago', 'alexandre', 'martim', 'afonso'],
}
for filename, ids in sheets.items():
    path = ROOT / 'assets/characters/villagers' / filename
    if not path.exists(): continue
    im = Image.open(path).convert('RGBA')
    alpha = im.getchannel('A').point(lambda v: 255 if v > 128 else 0)
    runs, start = [], None
    for y in range(im.height + 1):
        on = y < im.height and alpha.crop((0, y, im.width, y + 1)).getbbox() is not None
        if on and start is None: start = y
        if not on and start is not None:
            if y - start > 8: runs.append([start, y])
            start = None
    rows = 2 if filename == 'social-applause.png' else 4
    while len(runs) > rows:
        k = min(range(len(runs) - 1), key=lambda j: runs[j+1][0] - runs[j][1])
        runs[k:k+2] = [[runs[k][0], runs[k+1][1]]]
    assert len(runs) == rows, (filename, runs)
    for col, actor_id in enumerate(ids):
        frames = []
        x0, x1 = round(col * im.width / 5), round((col + 1) * im.width / 5)
        for y0, y1 in runs:
            b = person_bounds(alpha.crop((x0, y0, x1, y1)))
            left, top, right, bottom = x0+b[0], y0+b[1], x0+b[2], y0+b[3]
            feet = alpha.crop((left, bottom-max(8, round((bottom-top)*.08)), right, bottom)).getbbox()
            frames.append({'rect': [left, top, right-left, bottom-top],
                           'foot': [(feet[0]+feet[2])*.5, bottom-top], 'height_ratio': 1})
        # Normalize standing height across independently painted rows. A bow or
        # bent-knee landing is deliberately lower; never stretch individual limbs.
        lowered = {'farid': {2: .91}, 'clara_violinista': {2: .88},
                   'matilde': {1: .94, 2: .82}}
        for row, frame in enumerate(frames): frame['height_ratio'] = lowered.get(actor_id, {}).get(row, 1)
        if actor_id in manifest['characters']:
            for frame in frames: frame['path'] = 'res://assets/characters/villagers/'+filename
            manifest['characters'][actor_id]['frames'].extend(frames)
        else:
            manifest['characters'][actor_id] = {'path': 'res://assets/characters/villagers/'+filename, 'frames': frames}
    print(filename, im.size, 'rows', runs)
(ROOT / 'data/village/social-art.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
