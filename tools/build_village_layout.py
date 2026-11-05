#!/usr/bin/env python3
"""Author the expanded village. Geometry is saved as data, never randomized at runtime.
Core source coordinates preserve the OSM-derived junctions documented in osm-reference.json.
Residential infill is a playable interpretation of the user-provided photographs, not cadastral data.
"""
import json, math, random
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def point(p):
    return [round(p[0]*3.2+1000), round(p[1]*3-1800)]

def rect(r):
    return point(r[:2])+[round(r[2]*3.2),round(r[3]*3)]

def save(name, data):
    (ROOT/'data/village'/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
CORE = {'world_size': [6400, 5600],
 'adaptation': 'Rede esquemática baseada nos troços OSM indicados; distâncias, curvas menores e larguras '
               'adaptadas à exploração a dois. Ver docs/VILA_DE_SINTRA.md.',
 'routes': [{'id': 'palace_republic',
             'name': 'Praça da República',
             'points': [[2700, 1390], [2600, 1580], [2700, 1956]],
             'width': 230,
             'surface': 'stone',
             'source_way': 30799076},
            {'id': 'padarias',
             'name': 'Rua das Padarias',
             'points': [[2700, 1956], [2790, 2313], [2710, 2623], [2500, 2840]],
             'width': 190,
             'surface': 'stone',
             'source_way': 169733101},
            {'id': 'ferraria',
             'name': 'Rua da Ferraria',
             'points': [[2500, 2840], [2830, 2902], [3100, 3026], [3380, 3290]],
             'width': 180,
             'surface': 'stone',
             'source_way': 50464096},
            {'id': 'costa_castelo',
             'name': 'Rua da Costa do Castelo',
             'points': [[2830, 2902], [2900, 3460], [2780, 3786]],
             'width': 170,
             'surface': 'stone',
             'source_way': 50464097},
            {'id': 'marechal',
             'name': 'Rua Marechal Saldanha',
             'points': [[3380, 3290], [3230, 3460], [2900, 3460]],
             'width': 190,
             'surface': 'stone',
             'source_way': 172389669},
            {'id': 'pipa',
             'name': 'Rua da Fonte da Pipa',
             'points': [[2500, 2840], [2350, 3134], [2310, 3460], [2490, 3878], [2570, 4080]],
             'width': 165,
             'surface': 'stone',
             'source_way': 60099539},
            {'id': 'ferreira',
             'name': 'Largo Ferreira de Castro',
             'points': [[2900, 3460], [2780, 3786], [2700, 4158]],
             'width': 210,
             'surface': 'stone',
             'source_way': 169049311},
            {'id': 'navarro',
             'name': 'Rua Maria Eugénia Reis Ferreira Navarro',
             'points': [[2570, 4080], [2700, 4158]],
             'width': 180,
             'surface': 'stone',
             'source_way': 169735022},
            {'id': 'felix_nunes',
             'name': 'Escadinhas Félix Nunes',
             'points': [[2500, 2840], [2250, 2437], [2090, 1988]],
             'width': 145,
             'surface': 'steps',
             'source_way': 60099542},
            {'id': 'martinho_link',
             'name': 'Adro de São Martinho',
             'points': [[2600, 1580], [2350, 1956], [2090, 1988], [1830, 2282]],
             'width': 180,
             'surface': 'stone',
             'source_way': 50464093},
            {'id': 'biquinha',
             'name': 'Rua da Biquinha',
             'points': [[2090, 1988], [1770, 1693], [1410, 1755], [1170, 2220], [1050, 2499]],
             'width': 180,
             'surface': 'stone',
             'source_way': 142171097},
            {'id': 'gilvicente',
             'name': 'Rua Gil Vicente',
             'points': [[2090, 1988], [1910, 2422], [1480, 2794], [1100, 2840]],
             'width': 190,
             'surface': 'stone',
             'source_way': 96516358},
            {'id': 'briamante',
             'name': 'Escadinhas do Briamante',
             'points': [[1050, 2499], [1100, 2840]],
             'width': 145,
             'surface': 'steps',
             'source_way': 179201294},
            {'id': 'pedroso',
             'name': 'Rua Consiglieri Pedroso',
             'points': [[2090, 1988],
                        [2050, 2700],
                        [1900, 3196],
                        [1540, 3305],
                        [1100, 3398],
                        [870, 3878],
                        [900, 4229]],
             'width': 220,
             'surface': 'stone',
             'source_way': 169148286},
            {'id': 'assembleia',
             'name': 'Escadinhas da Assembleia',
             'points': [[1480, 2794], [1540, 3305]],
             'width': 140,
             'surface': 'steps',
             'source_way': 151662373},
            {'id': 'byron',
             'name': 'Escadinhas Lord Byron',
             'points': [[1100, 2840], [1040, 3196], [870, 3878]],
             'width': 145,
             'surface': 'steps',
             'source_way': 142171095},
            {'id': 'duche',
             'name': 'Volta do Duche',
             'points': [[2600, 1580],
                        [3190, 1941],
                        [3790, 2236],
                        [4540, 2328],
                        [5210, 2189],
                        [5490, 1817],
                        [5480, 1430],
                        [5110, 1190]],
             'width': 250,
             'surface': 'stone',
             'source_way': 23688927},
            {'id': 'monserrate',
             'name': 'Rua Visconde de Monserrate',
             'points': [[3190, 1941],
                        [3210, 2360],
                        [3550, 2592],
                        [3960, 2856],
                        [4490, 3228],
                        [5000, 3538],
                        [5400, 3925]],
             'width': 230,
             'surface': 'stone',
             'source_way': 30798919},
            {'id': 'terreirinho',
             'name': 'Arco do Terreirinho',
             'points': [[2790, 2313], [3010, 2561], [2830, 2902]],
             'width': 140,
             'surface': 'steps',
             'source_way': 51391749},
            {'id': 'audiencia',
             'name': 'Escadinhas da Audiência',
             'points': [[3010, 2561], [3210, 2360]],
             'width': 140,
             'surface': 'steps',
             'source_way': 51391754},
            {'id': 'miradouro',
             'name': 'Miradouro da Ferraria',
             'points': [[3100, 3026], [3300, 2918]],
             'width': 150,
             'surface': 'steps',
             'source_way': 50464094},
            {'id': 'arco_teixeira',
             'name': 'Rua do Arco do Teixeira',
             'points': [[2700, 1956], [2900, 1802], [3190, 1941]],
             'width': 150,
             'surface': 'steps',
             'source_way': 172229296},
            {'id': 'liberdade',
             'name': 'Parque da Liberdade',
             'points': [[5210, 2189], [5510, 2654], [5690, 3150], [5430, 3538], [5000, 3538]],
             'width': 220,
             'surface': 'earth',
             'source_way': 50465653},
            {'id': 'sassetti_entry',
             'name': 'Rua Victor Carlos Sassetti',
             'points': [[2700, 4158], [2390, 4235], [2140, 4323]],
             'width': 210,
             'surface': 'earth',
             'source_way': 169844125},
            {'id': 'sassetti_path',
             'name': 'Caminhos da Vila Sassetti',
             'points': [[2140, 4323],
                        [2200, 4451],
                        [2440, 4528],
                        [2230, 4639],
                        [2370, 4771],
                        [2200, 4898],
                        [2480, 5009],
                        [2590, 5081],
                        [2400, 5180],
                        [2400, 5280]],
             'width': 220,
             'surface': 'earth',
             'source_way': 1186823306},
            {'id': 'sassetti_stairs',
             'name': 'Escadas dos jardins da Vila Sassetti',
             'points': [[2140, 4323], [1880, 4423], [1830, 4517], [2000, 4600], [2230, 4639]],
             'width': 160,
             'surface': 'steps',
             'source_way': 685844669}],
 'plazas': [{'id': 'palace_square', 'name': 'Largo Rainha D. Amélia', 'rect': [2050, 1250, 1300, 320]},
            {'id': 'republic_square', 'name': 'Praça da República', 'rect': [2320, 1584, 520, 280]},
            {'id': 'martinho_terrace', 'name': 'Adro de São Martinho', 'rect': [1530, 2165, 520, 250]},
            {'id': 'ferraria_terrace', 'name': 'Miradouro da Ferraria', 'rect': [3160, 2789, 350, 210]},
            {'id': 'ferreira_square', 'name': 'Largo Ferreira de Castro', 'rect': [2620, 3673, 380, 380]},
            {'id': 'liberdade_garden',
             'name': 'Parque da Liberdade',
             'rect': [5270, 2991, 520, 380],
             'surface': 'earth'},
            {'id': 'sassetti_garden',
             'name': 'Jardins da Vila Sassetti',
             'rect': [2050, 4481, 650, 410],
             'surface': 'earth'}]}

layout = {'world_size':[22400,16000], 'previous_area':6400*5600,
          'adaptation':'Núcleo baseado nas ligações OSM documentadas. Habitação, pátios e ruas de ligação são uma interpretação jogável das 42 fotografias do utilizador, sem pretensão cadastral.',
          'routes':[], 'plazas':[], 'landmarks':[], 'monuments':[], 'urban_zones':[], 'garden_zones':[],
          'street_objects':[], 'observations':[]}
for source in CORE['routes']:
    route = dict(source)
    route['points'] = [point(p) for p in source['points']]
    route['width'] = round(source['width']*(1.65 if source['surface']=='stone' else 1.6))
    if source['id'] in ['duche','pedroso','monserrate']: route['width']=440
    layout['routes'].append(route)
for source in CORE['plazas']:
    plaza = dict(source)
    plaza['rect'] = rect(source['rect'])
    plaza.setdefault('surface','stone')
    layout['plazas'].append(plaza)

# Enlarging the region adds neighbourhoods. Its original squares remain human-scaled.
square_bounds={
 'palace_square':[8646,1950,2500,680],
 'republic_square':[8750,3000,1400,570],
 'martinho_terrace':[6100,4570,1000,620],
 'ferraria_terrace':[11200,6670,850,450],
 'ferreira_square':[9500,9360,900,660]}
for p in layout['plazas']:
    if p['id'] in square_bounds:p['rect']=square_bounds[p['id']]

def route(id, name, points, width=270, surface='stone'):
    layout['routes'].append(dict(id=id,name=name,points=points,width=width,surface=surface,authored_extension=True))

def plaza(id, name, bounds, surface='stone'):
    layout['plazas'].append(dict(id=id,name=name,rect=bounds,surface=surface))

# Connected neighbourhood loops. Short steps and side alleys break up the blocks.
# These are deliberately named as neighbourhoods rather than invented real streets.
extra = [
('poente_01','Casario da Biquinha', [point([1410,1755]),[4700,3650],[3400,3900],[1800,4400],[1150,5600],[1600,6600],point([1100,2840])]),
('poente_02','Casario da Biquinha', [[3400,3900],[3600,5050],[3350,6250],point([1100,2840])]),
('poente_03','Pátios da Vila Velha', [[1800,4400],[2350,5100],[3600,5050],[4700,4850],point([1770,1693])]),
('poente_04','Pátios da Vila Velha', [[1600,6600],[1950,7850],[3100,8150],[4250,7850],point([1480,2794])]),
('poente_05','Travessa das varandas', [[3350,6250],[3100,7150],[3100,8150],[2888,9120]]),
('poente_06','Pátios da Vila Velha', [[1150,5600],[2400,6000],[3350,6250]],220),
('poente_07','Escadinhas dos vasos', [[2350,5100],[2400,6000],[3100,7150]],210,'steps'),
('poente_08','Rua das casas brancas', [[2888,9120],[1600,9300],[1100,10350],[2300,11000],point([900,4229])],330),
('poente_09','Rua das casas brancas', [[1950,7850],[1600,9300],[900,8950],[950,7700],[1600,6600]]),
('poente_10','Largo das hortênsias', [[3100,8150],[4400,9200],[5300,9950],[5600,10900],point([900,4229])]),
('poente_11','Largo das hortênsias', [point([1540,3305]),[6500,9150],[5300,9950],[3900,10100],[2300,11000]]),
('poente_12','Casas da encosta', [[4400,9200],[4250,7850],[5200,7300],point([1480,2794])],230),
('centro_01','Travessa dos artesãos', [point([1830,2282]),[7000,6000],[6700,7150],[6500,8100],point([1900,3196])]),
('centro_02','Travessa dos artesãos', [[7000,6000],[8000,5820],point([2710,2623])],240),
('centro_03','Beco das flores', [point([2350,1956]),[8100,4750],[8000,5820]],215,'steps'),
('centro_04','Casario de São Martinho', [[6700,7150],[7900,7340],point([2310,3460])],230),
('centro_05','Rua das oficinas', [[6500,9150],[7600,9650],point([2490,3878])],260),
('centro_06','Pátio da calçada', [point([1100,3398]),[5200,8350],[6500,8100]],230,'steps'),
('mercado_01','Rua do mercado', [point([2830,2902]),[11100,7220],[11900,7800],[13700,8300],point([4490,3228])],380),
('mercado_02','Rua do mercado', [[11900,7800],[11900,8900],point([2780,3786])],300),
('mercado_03','Travessa das louças', [[11100,7220],[11400,6450],point([3550,2592])],220),
('mercado_04','Beco dos tecidos', [[11900,8900],[13200,9400],[14600,9200],[15000,8450],[13700,8300]],240),
('mercado_05','Pátios de habitação', [[13200,9400],[13300,10500],[12100,10900],point([2700,4158])],260),
('mercado_06','Escadinhas do mercado', [[13700,8300],[13600,7200],point([3960,2856])],220,'steps'),
('norte_01','Casas do Duche', [point([5110,1190]),[16100,1400],[14500,1550],[12900,1600],[12000,2400],point([3790,2236])],330),
('norte_02','Casas do Duche', [[14500,1550],[14550,2800],[15900,3250],point([5490,1817])],300),
('norte_03','Pátios do Duche', [[12900,1600],[13000,3000],[13800,3900],point([4540,2328])],250),
('norte_04','Pátios do Duche', [[12000,2400],[13000,3000],[14550,2800]],230),
('norte_05','Largo das varandas', [point([5110,1190]),[18800,1300],[20400,1700],[21300,2900],[20900,4300],point([5210,2189])],340),
('norte_06','Largo das varandas', [[20400,1700],[20000,3100],[18700,3500],[17900,2500],point([5110,1190])],260),
('norte_07','Rua dos azulejos', [[20000,3100],[20900,4300],[20400,5500],[19000,5900],point([5210,2189])],260),
('norte_08','Rua dos azulejos', [[18700,3500],[19000,4650],[19000,5900]],230),
('norte_09','Escadinhas dos azulejos', [[15900,3250],[16700,3650],[18700,3500]],210,'steps'),
('norte_10','Pátios da fonte', [point([4540,2328]),[16000,5750],[16900,6500],point([5510,2654])],260),
('sul_01','Casario da encosta', [point([5400,3925]),[19700,10800],[21000,11900],[21000,13500],[19800,14500],[18000,14700],[16300,14100],[15100,12900],[13300,12400],[12100,10900]],330),
('sul_02','Casario da encosta', [[19700,10800],[18200,11300],[17000,12000],[16300,13100],[16300,14100]],270),
('sul_03','Pátios das portadas', [[21000,11900],[19500,12400],[18200,12800],[17000,12000],[15100,12900]],260),
('sul_04','Pátios das portadas', [[19800,14500],[19500,13500],[18200,12800],[18200,11300]],240),
('sul_05','Rua dos jardins', [[16300,14100],[14700,14400],[12900,14000],[11300,13200],[10900,11900],point([2700,4158])],280),
('sul_06','Rua dos jardins', [[11300,13200],[13300,12400],[14700,14400]],240),
('sul_07','Escadinhas da encosta', [[13300,10500],[13300,11400],[13300,12400]],210,'steps'),
('sul_08','Travessa das portadas', [[14600,9200],[15700,10200],[17000,12000]],260),
('sul_09','Casario da encosta', [[15700,10200],[18200,11300]],230),
('sul_10','Pátios do jardim', [[10900,11900],[10000,12500],point([2440,4528])],250),
('sul_11','Pátios do jardim', [[11300,13200],[10400,14200],point([2400,5180])],250,'earth'),
]
for e in extra: route(*e)
plaza('market_square','Largo da Feira',[11100,7410,1500,1050])
plaza('western_court','Largo das Hortênsias',[4800,9670,1000,720])
plaza('tile_square','Largo dos Azulejos',[18450,4350,1000,770])
plaza('residential_court','Pátio das Portadas',[17680,12400,1040,760])
plaza('garden_court','Largo dos Jardins',[12500,12100,1030,760])
plaza('byron_court','Recanto Lord Byron',[4300,6480,850,600])

landmarks = [
('palace','Palácio Nacional de Sintra',[2780,1330],470),('republic','Praça da República',[2610,1693],430),
('piriquita','Piriquita · Rua das Padarias',[2790,2127],310),('martinho','Igreja de São Martinho',[1830,2282],350),
('ferraria','Rua da Ferraria',[3000,2980],290),('miradouro','Miradouro da Ferraria',[3350,2918],300),
('valencas','Palácio Valenças',[4000,2840],420),('lawrence','Lawrence’s Hotel',[900,3662],350),
('mourisca','Fonte Mourisca · Volta do Duche',[4600,2328],300),('liberdade','Parque da Liberdade',[5500,3150],650),
('pipa','Fonte da Pipa',[2320,3444],260),('ferreira','Largo Ferreira de Castro',[2780,3832],450),
('sassetti_entry','Entrada da Vila Sassetti',[2500,4218],320),('sassetti','Jardins da Vila Sassetti',[2260,4650],650)]
for id,name,p,radius in landmarks:
    layout['landmarks'].append(dict(id='village_'+id,name=name,position=point(p),radius=radius))
for id,name,p,radius in [('market','Largo da Feira',[11850,8100],600),('western_court','Largo das Hortênsias',[5300,10100],450),('tiles','Largo dos Azulejos',[19000,4900],450),('residential','Pátio das Portadas',[18200,13000],450),('gardens','Largo dos Jardins',[13000,12750],450),('byron','Recanto Lord Byron',[4700,6950],350)]:
    layout['landmarks'].append(dict(id='village_'+id,name=name,position=p,radius=radius))

layout['menu_spawn']=[9775,2250]
layout['forest_access']=point([2400,5180])
layout['earth_test']=point([2390,4750])
layout['stone_test']=point([2700,1956])
layout['districts']=[
 {'name':'Casario da Biquinha','rect':[500,3200,5800,8100]},
 {'name':'Vila Velha · comércio e habitação','rect':[6300,2800,6500,7900]},
 {'name':'Casas do Duche','rect':[12000,900,9850,5900]},
 {'name':'Casario da encosta','rect':[10500,10000,11100,5200]},
 {'name':'Jardins da Vila Sassetti','rect':[6100,10800,4500,4700]},
 {'name':'Parque da Liberdade','rect':[17000,6650,4000,3600]}]
layout['urban_zones']=[
 [700,3400,10800,7700],[7100,1700,4300,2700],[6000,3000,10000,7600],
 [12000,1100,9600,5300],[11500,6000,6000,4900],[10600,10200,10800,4850],
 [16500,9650,4100,1250]]
layout['garden_zones']=[[6550,11000,4050,4300],[17400,6700,3300,3500]]

spec=json.loads((ROOT/'data/village/art-regions.json').read_text())
monuments=[('NationalPalace','Palácio Nacional de Sintra','palace',0,[2780,1245],2500),
('SaoMartinho','Igreja de São Martinho','landmarks',0,[1730,2096],680),
('Valencas','Palácio Valenças','landmarks',1,[3990,2638],940),
('Lawrences','Lawrence’s Hotel','landmarks',2,[590,3600],900),
('Piriquita','Piriquita','landmarks',3,[3035,2142],490),
('Sassetti','Vila Sassetti','landmarks',4,[1915,4661],900),
('MoorishFountain','Fonte Mourisca','landmarks',5,[4600,2127],570)]
occupied=[]
def intersects(a,b,pad=0):
    return a[0]-pad<b[0]+b[2] and a[0]+a[2]+pad>b[0] and a[1]-pad<b[1]+b[3] and a[1]+a[3]+pad>b[1]
for id,label,atlas,cell,p,width in monuments:
    at=point(p)
    if id=='Piriquita':at=[10250,4750]
    source=[20,26,1500,970] if atlas=='palace' else spec[atlas][cell]
    height=width*source[3]/source[2]
    base=[round(at[0]-width*.46),round(at[1]-max(150,height-180)),round(width*.92),round(max(150,height-180))]
    if atlas=='palace':
        factor=width/1440
        bases=[]
        for b in [[2060,960,1440,100],[2060,1060,330,160],[3170,1060,330,160],[2577,1100,52,104],[2830,1100,52,104]]:
            bases.append([round(at[0]+(b[0]-2780)*factor),round(at[1]+(b[1]-1245)*factor),round(b[2]*factor),round(b[3]*factor)])
        gallery=[round(at[0]+(2060-2780)*factor),round(at[1]+(1030-1245)*factor),width,round(230*factor)]
        layout['arcade_floor']=gallery
        layout['arcade_approaches']=[[round(at[0]+(x-2780)*factor),round(at[1]+(1310-1245)*factor)] for x in [2470,2720,3000]]
        layout['arcade_openings']=[[q[0],round(at[1]+(1115-1245)*factor)] for q in layout['arcade_approaches']]
        occupied.append([at[0]-width/2,at[1]-height,width,height])
    else:
        bases=[base]
        occupied.append([at[0]-width/2,at[1]-height,width,height])
        # A real clear public approach joins each landmark to the old core way.
        near=min((p for r in layout['routes'] for p in r['points'] if not (base[0]-40<p[0]<base[0]+base[2]+40 and base[1]-40<p[1]<base[1]+base[3]+40)),key=lambda q: math.dist(q,[at[0],at[1]+130]))
        approach=[near,[at[0],at[1]+130]]
        if id=='Sassetti':
            side=round(at[0]+width*.66)
            approach=[near,[side,near[1]],[side,at[1]+130],[at[0],at[1]+130]]
        route('approach_'+id,label,approach,260)
    layout['monuments'].append(dict(id=id,label=label,atlas=atlas,type=cell,at=at,width=width,bases=bases))
# Explicit setting for the corner cafe from the photographs.
layout['feature_frontages']=[dict(id='LordByronCorner',label='Recanto Lord Byron',atlas='urban',type=3,at=[4380,6340],width=450)]

# Spatially indexed rectangle/route tests for dense continuous building strips.
segments=[]; segments_by_bucket={}
def index_route(r):
    for a,b in zip(r['points'],r['points'][1:]):
        s=(a,b,r['width']/2)
        k=len(segments);segments.append(s)
        bounds=[min(a[0],b[0])-s[2],min(a[1],b[1])-s[2],abs(a[0]-b[0])+s[2]*2,abs(a[1]-b[1])+s[2]*2]
        for x in range(int(bounds[0]//512),int((bounds[0]+bounds[2])//512)+1):
            for y in range(int(bounds[1]//512),int((bounds[1]+bounds[3])//512)+1): segments_by_bucket.setdefault((x,y),set()).add(k)
for r in layout['routes']:index_route(r)

def buckets(bounds):
    return [(x,y) for x in range(int(bounds[0]//512),int((bounds[0]+bounds[2])//512)+1) for y in range(int(bounds[1]//512),int((bounds[1]+bounds[3])//512)+1)]

def seg_distance(p,a,b):
    dx,dy=b[0]-a[0],b[1]-a[1]
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy or 1)))
    return math.hypot(p[0]-a[0]-dx*t,p[1]-a[1]-dy*t)

def line_hits_rect(a,b,r):
    lo,hi=0,1
    for origin,delta,mn,mx in [(a[0],b[0]-a[0],r[0],r[0]+r[2]),(a[1],b[1]-a[1],r[1],r[1]+r[3])]:
        if abs(delta)<1e-9:
            if origin<mn or origin>mx:return False
        else:
            t1,t2=(mn-origin)/delta,(mx-origin)/delta
            lo,hi=max(lo,min(t1,t2)),min(hi,max(t1,t2))
            if lo>hi:return False
    return True

def clear_streets(bounds):
    if any(intersects(bounds,p['rect'],24) for p in layout['plazas']):return False
    if intersects(bounds,layout['arcade_floor'],60):return False
    indices=set()
    for key in buckets(bounds): indices.update(segments_by_bucket.get(key,()))
    for k in indices:
        a,b,r=segments[k]
        if line_hits_rect(a,b,bounds):return False
        x,y,w,h=bounds
        corners=[[x,y],[x+w,y],[x+w,y+h],[x,y+h]]
        separation=min([seg_distance(p,a,b) for p in corners]+[
            math.hypot(max(x-p[0],0,p[0]-x-w),max(y-p[1],0,p[1]-y-h)) for p in [a,b]])
        if separation<r+28:return False
    return True

building_buckets={}
for index,b in enumerate(occupied):
    for key in buckets(b):building_buckets.setdefault(key,[]).append(index)

def add_house(at,width,kind,atlas='urban',label='Habitação',force=False):
    source=spec[atlas][kind]
    height=width*source[3]/source[2]
    depth=min(height-125,225)
    # Ground depth differs from facade height in the game's foot-sorted projection.
    base=[round(at[0]-width*.48),round(at[1]-depth),round(width*.96),round(depth)]
    visual=[at[0]-width/2,at[1]-height,width,height]
    if not force:
        if not clear_streets(base):return False
        if any(intersects(visual,zone,12) for zone in layout['garden_zones']):return False
        near=set()
        for key in buckets(base):near.update(building_buckets.get(key,()))
        if any(intersects(base,occupied[i],8) for i in near):return False
    index=len(occupied);occupied.append(base)
    for key in buckets(base):building_buckets.setdefault(key,[]).append(index)
    houses.append(dict(id='Frontage_%04d'%len(houses),label=label,atlas=atlas,type=kind,at=[round(at[0]),round(at[1])],width=round(width),bases=[base]))
    return True

houses=[]
rng=random.Random(11032026)
for e in layout['feature_frontages']:
    candidates=[e['at']]+[[x,y] for y in range(6000,6500,50) for x in range(4150,5300,50)]
    candidates.sort(key=lambda p:math.dist(p,e['at']))
    for at in candidates:
        if add_house(at,e['width'],e['type'],e['atlas'],e['label']):
            houses[-1]['id']=e['id']
            entrance=[at[0],at[1]+230]
            route('byron_doorstep','Passagem Lord Byron',[[4700,6760],entrance],220)
            index_route(layout['routes'][-1])
            for place in layout['landmarks']:
                if place['id']=='village_byron':place['position']=entrance
            break

# First place shoulder-to-shoulder facades along the public routes.
for r in layout['routes']:
    if r['surface']=='earth':continue
    for a,b in zip(r['points'],r['points'][1:]):
        length=math.dist(a,b)
        ux,uy=(b[0]-a[0])/length,(b[1]-a[1])/length
        for d in range(180,int(length),390):
            for side in [-1,1]:
                kind=rng.randrange(8)
                width=rng.choice([385,410,430,450])
                height=width*spec['urban'][kind][3]/spec['urban'][kind][2]
                depth=min(height-125,225)
                # Support of an axis-aligned lot in the street-normal direction.
                nx,ny=-uy*side,ux*side
                offset=r['width']/2+abs(nx)*width*.5+abs(ny)*depth*.5+45
                center=[a[0]+ux*d+nx*offset,a[1]+uy*d+ny*offset]
                label='Habitação' if kind in [5,6] else ['Padaria','Loja de louças','Café','Loja de lembranças','Artesanato','Habitação','Habitação','Azulejaria'][kind]
                add_house([center[0],center[1]+depth*.5],width,kind,label=label)
# Close the rear lots into blocks instead of leaving woodland between every house.
for zone in layout['urban_zones']:
    x0,y0,w,h=zone
    for row,y in enumerate(range(y0+330,y0+h,260)):
        x=x0+220+(row%2)*26
        while x<x0+w-220:
            kind=rng.randrange(8)
            width=rng.choice([385,410,430,450])
            add_house([x,y],width,kind,label='Habitação')
            x+=width+6
layout['building_count']=len(houses)+len(monuments)

# Furniture is authored in public areas, never scattered through woodland.
def obj(kind,at,width=120,solid=True):
    layout['street_objects'].append(dict(kind=kind,at=at,width=width,solid=solid))
# Palace terrace, main square and market each have their own recognizable centre.
obj(8,[10370,2510],380)
obj(7,[9050,3470],190)
obj(8,point([2320,3444]),220)
for p in [[8250,2680],[8660,2680],[10840,2680],[11250,2680],point([3350,2990]),[19600,5500]]:obj(6,p,400)
for i in range(4):
    obj(i%3,[11290+i*350,7560],270)
    obj((i+1)%3,[11290+i*350,8350],270)
for p in [[8650,3690],[10400,3850],[10630,3850],[4850,6790],[18550,4740],[19150,4740],[17880,12750],[18480,12750],[12650,12400],[13300,12400]]:obj(3,p,250)
for i,r in enumerate(layout['routes']):
    if r['surface']=='earth':continue
    if i%2==0:
        a,b=r['points'][0:2]
        length=math.dist(a,b);nx,ny=-(b[1]-a[1])/length,(b[0]-a[0])/length
        for side in [-1,1]:
            at=[round((a[0]+b[0])/2+nx*side*(r['width']/2-35)),round((a[1]+b[1])/2+ny*side*(r['width']/2-35))]
            obj(4,at,70)
# Shop displays are placed at the edge, leaving the middle of alleys clear.
for p in [[10100,4620],[10040,4900],[9520,5530],[9310,6100],[11100,7000],[13700,7000],[4300,6840],[5240,5050],[19860,4580]]:
    obj(2,p,140);obj(10,[p[0]+100,p[1]+45],100)
layout['benches']=[[8630,2520],[11000,2530],point([3350,2886]),point([2870,3925]),point([5560,2980]),point([2350,4616]),[5290,10220],[19000,5020],[18200,13030],[13000,12750]]
layout['plaques']=[{'text':r['name'],'at':r['points'][0]} for r in layout['routes'][:26:2]]
layout['bunting']=[{'a':[9450,4600],'b':[10050,4620]},{'a':[9360,5650],'b':[9960,5690]},{'a':[11000,7730],'b':[12660,7730]},{'a':[18280,4730],'b':[19550,4770]},{'a':[4520,6350],'b':[5070,6370]}]
notes=[
('palace_arcade','Arcadas do Palácio',layout['menu_spawn'],'As duas chaminés elevam-se sobre os telhados. Sob as arcadas, a sombra guarda a frescura da pedra.'),
('piriquita_facade','Fachada da Piriquita',point([2910,2174]),'Azulejos amarelos, portas brancas e o nome por cima. O cheiro a massa quente parece acompanhar a rua toda.'),
('martinho_view','Adro de São Martinho',point([1730,2344]),'Do adro, a vila aparece entre telhados. A torre da igreja ajuda-nos a encontrar outra vez o caminho.'),
('valencas_loggia','Loggia do Palácio Valenças',point([3990,2840]),'O rosa do palácio e os arcos de pedra clara recortam-se contra o verde do parque.'),
('lawrence_facade','Lawrence’s Hotel',point([900,3662]),'Janelas de cantaria, portadas verdes e um nome antigo. Aqui apetece abrandar o passo e inventar uma história.'),
('mourisca_tiles','Azulejos da Fonte Mourisca',point([4600,2328]),'O arco de ferradura envolve três arcos mais pequenos. A água e o padrão dos azulejos convidam a ficar.'),
('ferraria_view','Miradouro da Ferraria',point([3350,2948]),'Um intervalo entre as casas abre a vista. As escadinhas trouxeram-nos acima da azáfama do largo.'),
('sassetti_tower','Torre da Vila Sassetti',point([2240,4661]),'A torre redonda parece nascer do jardim. Mais acima, as curvas do caminho desaparecem entre os carvalhos.'),
('serra_directions','Indicações da encosta',point([2400,5098]),'Castelo dos Mouros e Pena, pela encosta. Para a nossa mata, seguimos juntos o caminho da serra.'),
('western_directions','Caminho dos Pisões',point([900,4163]),'Para oeste, a estrada continua para a Regaleira, Seteais e Monserrate. Hoje ficamos a descobrir os recantos da vila.'),
('market_ceramics','Bancas de cerâmica',[11800,8020],'Entre a loiça azul e branca, os cestos e os tecidos, cada banca guarda um pequeno mundo de desenhos.'),
('tile_frontages','Casas de azulejos',[19000,4900],'As fachadas mudam de cor a cada esquina. Os ferros das varandas desenham sombras finas na calçada.'),
('residential_patios','Pátios de habitação',[18200,13000],'Portadas abertas, vasos à porta e escadas gastas. Entre as lojas, a vila continua a ser uma casa.'),
('byron_corner','Recanto Lord Byron',next(p['position'] for p in layout['landmarks'] if p['id']=='village_byron'),'A casa cor-de-rosa separa dois caminhos. Podemos escolher a sombra das escadas ou continuar pela rua.')]
for id,label,p,text in notes:
    layout['observations'].append(dict(id=id,kind='observation',label=label,position=p,reach=180,radius=0,text=text))
layout['pickups']=[dict(item=0,at=point([2310,4650])),dict(item=1,at=point([5610,3166]))]
save('layout.json',layout)
save('frontages.json',dict(buildings=houses,seed=11032026,description='Fachadas contíguas e lotes fechados; todas as bases respeitam ruas e largos públicos.'))
print('Area:',22400*16000/(6400*5600),'Buildings:',layout['building_count'],'Routes:',len(layout['routes']),'Plazas:',len(layout['plazas']),'Street objects:',len(layout['street_objects']))
from revise_village_spaces import revise
revise()
