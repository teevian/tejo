#!/usr/bin/env python3
"""Attach rear houses inside existing blocks without changing the public street graph."""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def overlap(a, b):
    return max(0, min(a[0]+a[2], b[0]+b[2])-max(a[0], b[0])) * max(0, min(a[1]+a[3], b[1]+b[3])-max(a[1], b[1]))

def grow(r, amount):
    return [r[0]-amount, r[1]-amount, r[2]+2*amount, r[3]+2*amount]

def contains(r, p):
    return r[0] <= p[0] <= r[0]+r[2] and r[1] <= p[1] <= r[1]+r[3]

def distance(p, a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]
    t = max(0, min(1, ((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy or 1)))
    return math.dist(p, [a[0]+t*dx, a[1]+t*dy])

def line_hits(a, b, r):
    lo, hi = 0, 1
    for origin, delta, low, high in [(a[0], b[0]-a[0], r[0], r[0]+r[2]), (a[1], b[1]-a[1], r[1], r[1]+r[3])]:
        if abs(delta) < 1e-9:
            if not low <= origin <= high: return False
        else:
            t1, t2 = (low-origin)/delta, (high-origin)/delta
            lo, hi = max(lo, min(t1, t2)), min(hi, max(t1, t2))
            if lo > hi: return False
    return True

def segment_clear(r, a, b, radius):
    if line_hits(a, b, r): return False
    x, y, w, h = r
    gap = min([distance(p, a, b) for p in [[x,y], [x+w,y], [x+w,y+h], [x,y+h]]] +
              [math.hypot(max(x-p[0], 0, p[0]-x-w), max(y-p[1], 0, p[1]-y-h)) for p in [a,b]])
    return gap >= radius

def build():
    layout_path = ROOT/'data/village/layout.json'
    layout = json.loads(layout_path.read_text())
    houses = json.loads((ROOT/'data/village/frontages.json').read_text())['buildings']
    existing = layout['monuments'] + houses
    segments = [(a,b,r['width']/2) for r in layout['routes'] for a,b in zip(r['points'], r['points'][1:])]
    protected = [grow(p['rect'], 85) for p in layout['plazas']] + [grow(layout['arcade_floor'], 140)]
    for spec in json.loads((ROOT/'data/village/terraces.json').read_text())['terraces']:
        x,y,w,h = spec['platform']
        protected.append(grow([x,y,w,h+spec['run']+spec['landing']], 100))
    residents = json.loads((ROOT/'data/village/residents.json').read_text())['residents']
    def door(b):
        x,y = b['at']
        if 'side_facing' in b:
            return [x+(1 if b['side_facing']=='right' else -1)*(b['width']/2+32),y-70]
        return [x,y+35]
    # Keep every public entrance and all possible nearby routine residences.
    # The unused rear lots can be attached, as in a closed historic town block.
    homes = [b for b in houses if b['label']=='Habitação']
    routine_houses = set()
    for resident in residents:
        anchor = [resident['home'][0]+220,resident['home'][1]]
        routine_houses.update(b['id'] for b in sorted(homes,key=lambda b:math.dist(door(b),anchor))[:6])
    for b in existing:
        x,y = door(b)
        public = min(distance([x,y],a,c)-radius for a,c,radius in segments)<150
        if b['label']=='Habitação' and b['id'] not in routine_houses and not public: continue
        protected.append([x-105,y-100,210,200])
    for p in layout['observations']:
        x,y = p['position']; protected.append([x-150,y-150,300,300])
    for p in json.loads((ROOT/'data/village/daily-routines.json').read_text())['places'].values():
        x,y = p['at']; protected.append([x-210,y-210,420,420])
    for p in residents:
        x,y = p['home']; protected.append([x-190,y-190,380,380])
    bases = [r for b in existing for r in b['bases']]
    added = []
    anchors = []
    for ordinal, house in enumerate(houses):
        if house['label'] != 'Habitação': continue
        x,y = house['at']
        if min(distance([x,y-110], a,b)-radius for a,b,radius in segments) < 220: continue
        if any(math.dist([x,y], anchor)<720 for anchor in anchors): continue
        cluster = []
        for wing, (dx,dy,scale) in enumerate([(-82,-148,.92), (144,-205,.82), (-90,-300,1.02), (110,-330,.90), (-240,-128,.8), (280,-160,.88), (0,-410,1), (-280,-350,.94)]):
            if len(cluster)>=3: break
            width = round(house['width']*scale)
            at = [round(x+dx),round(y+dy)]
            base = [round(at[0]-width*.48),at[1]-225,round(width*.96),225]
            corners = [[base[0],base[1]], [base[0]+base[2],base[1]+base[3]]]
            if not all(any(contains(zone, p) for zone in layout['urban_zones']) for p in corners): continue
            if any(overlap(base,grow(zone,140)) for zone in layout['garden_zones']): continue
            if any(overlap(base,r) for r in protected): continue
            if any(not segment_clear(base,a,b,radius+64) for a,b,radius in segments): continue
            if sum(overlap(base,r) for r in bases) < base[2]*base[3]*.30: continue
            if any(overlap(base,b['bases'][0])>base[2]*base[3]*.7 for b in added): continue
            # Attached bases close tiny inaccessible slots, not public alleys.
            entry = dict(id='BlockInfill_%03d'%len(added),label='Casario interior',atlas='urban',
                         type=[5,6,7,2][(ordinal+wing)%4],at=at,width=width,bases=[base],
                         block_infill=True,cluster=house['id'])
            if house.get('side_facing'):
                entry.update(atlas='side',type=[2,4,7][(ordinal+wing)%3],side_facing=house['side_facing'])
                entry['sprite_mirror'] = (entry['side_facing']=='right') != (entry['type'] in [0,2,4,6])
            added.append(entry); cluster.append(entry['id'])
        if cluster: anchors.append([x,y])
        if len(anchors)>=64: break
    result = dict(description='Casas adossadas nos interiores dos quarteirões. Bases sobrepostas fecham os lotes; ruas, largos, entradas públicas e das rotinas, e patamares ficam livres.',
                  buildings=added,clusters=len(anchors),street_clearance=64,public_and_routine_doors_preserved=True)
    (ROOT/'data/village/block-infill.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    layout['building_count'] = len(existing)+len(added)
    layout_path.write_text(json.dumps(layout,ensure_ascii=False,indent=2)+'\n')
    print('Attached rear houses:',len(added),'in',len(anchors),'blocks; total',layout['building_count'])

if __name__=='__main__': build()
