#!/usr/bin/env python3
"""Original metre-scale campus, Blender 4.x -> GLB + simple collision proxies.
blender -b -t 4 --python tools/build_campus_3d.py -- --project .
Coordinates in this script follow Godot (+Y up, front towards +Z).
"""
import argparse, hashlib, json, math, random, sys
from pathlib import Path
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True)
project = Path(parser.parse_args(sys.argv[sys.argv.index('--') + 1:]).project).resolve()
out = project / 'assets/campus3d'
out.mkdir(parents=True, exist_ok=True)
random.seed(36)
mats = {}
zones = {}
collisions = []

def xyz(p): return (p[0], -p[2], p[1])

def material(name, color, rough=.7, metal=0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    n = m.node_tree.nodes.get('Principled BSDF')
    n.inputs['Base Color'].default_value = (*color, 1)
    n.inputs['Roughness'].default_value = rough
    n.inputs['Metallic'].default_value = metal
    m.diffuse_color = (*color, 1); mats[name] = m

for spec in [('stone', (.68,.65,.58)), ('white', (.84,.84,.80)), ('brick', (.43,.24,.19)),
             ('paving', (.43,.47,.46)), ('grout', (.29,.32,.32)), ('wood', (.43,.26,.12)),
             ('oak', (.64,.48,.30)), ('metal', (.12,.17,.18), .35,.55),
             ('glass', (.095,.22,.29), .18,.35), ('water', (.11,.43,.48), .12,.25),
             ('green', (.16,.28,.14)), ('leaf', (.26,.39,.18)), ('pink', (.62,.24,.30)),
             ('paper', (.88,.86,.78)), ('yellow', (.84,.63,.14)), ('blue', (.15,.29,.43)),
             ('screen', (.055,.12,.16), .3), ('black', (.025,.035,.038)), ('red', (.65,.16,.13))]:
    material(*spec)
material('stream', (.16,.51,.56), .13,.18)

def finish(o, name, mat):
    o.name = name; o.data.materials.append(mats[mat])
    return o

def box(name, at, size, mat='white', solid=False, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(at)); o=bpy.context.object
    o.dimensions = (size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        m=o.modifiers.new('Soft manufactured edges','BEVEL');m.width=min(bevel,min(size)*.2);m.segments=2
        bpy.ops.object.modifier_apply(modifier=m.name)
        m=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=m.name)
    if solid: collisions.append({'position':list(at),'size':list(size)})
    return finish(o,name,mat)

def cylinder(name, at, radius, depth, mat, radius_top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=radius, radius2=radius if radius_top is None else radius_top, depth=depth, location=xyz(at))
    o=bpy.context.object
    for p in o.data.polygons: p.use_smooth=len(p.vertices)==4
    return finish(o,name,mat)

def ell(name,at,scale,mat):
    tiny = name in ['Petal', 'Flower heart']
    bpy.ops.mesh.primitive_uv_sphere_add(segments=6 if tiny else 12, ring_count=4 if tiny else 8, location=xyz(at));o=bpy.context.object
    o.scale=(scale[0],scale[2],scale[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for p in o.data.polygons:p.use_smooth=True
    return finish(o,name,mat)

def pipe(name,points,radius,mat):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=radius;c.bevel_resolution=2
    s=c.splines.new('POLY');s.points.add(len(points)-1)
    for p,co in zip(s.points,points):p.co=(*xyz(co),1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
    return finish(o,name,mat)

def plant(x,z,flowers=False):
    cylinder('Terracotta planter',(x,.23,z),.28,.46,'stone',.36)
    cylinder('Soil',(x,.47,z),.32,.03,'wood')
    for i in range(14):
        a=i*2.4;r=.1+(i%3)*.08;h=.7+(i%4)*.13
        pipe('Stem',[(x,.45,z),(x+r*math.cos(a),h,z+r*math.sin(a))],.008,'green')
        leaf((x+r*math.cos(a),h-.08,z+r*math.sin(a)), .24, a, 'leaf')
        if flowers:
            for j in range(5):
                b=j*math.tau/5
                ell('Petal',(x+r*math.cos(a)+.045*math.cos(b),h,z+r*math.sin(a)+.045*math.sin(b)),(.035,.013,.025),'pink' if i%2 else 'paper')
            ell('Flower heart',(x+r*math.cos(a),h+.015,z+r*math.sin(a)),(.018,.014,.018),'yellow')

def leaf(at, length, angle, mat):
    # Pointed curved blade, shared material, no rounded placeholder canopy.
    vs=[(0,0,0),(-.28*length,.025*length,.40*length),(0,.10*length,.45*length),(.28*length,.025*length,.40*length),(0,0,length)]
    verts=[]
    for x,y,z in vs:
        verts.append(xyz((at[0]+x*math.cos(angle)-z*math.sin(angle),at[1]+y+z*.3,at[2]+x*math.sin(angle)+z*math.cos(angle))))
    d=bpy.data.meshes.new('Leaf blade');d.from_pydata(verts,[],[(0,1,2),(0,2,3),(1,4,2),(2,4,3)])
    o=bpy.data.objects.new('Leaf blade',d);bpy.context.collection.objects.link(o);finish(o,'Leaf blade',mat)

def bench(x,z):
    for i in range(5):box('Bench oak slat',(x,.48,z-.22+i*.11),(1.8,.065,.09),'oak')
    for i in range(3):box('Backrest',(x,.76+i*.13,z-.30),(1.8,.10,.055),'wood')
    for dx in [-.67,.67]:box('Bench support',(x+dx,.24,z),(.07,.48,.54),'metal')
    collisions.append({'position':[x,.5,z],'size':[1.85,1,.65]})

def window(x,y,z,w=1.65,h=2):
    box('Recessed blue glazing',(x,y,z),(w,.01+h,.12),'glass')
    for dx in [-w/2,0,w/2]:box('Aluminium mullion',(x+dx,y,z+.08),(.055,h+.12,.10),'metal')
    for dy in [-h/2,h/2]:box('Limestone frame',(x,y+dy,z+.10),(w+.18,.09,.20),'stone')
    box('Window transom',(x,y+.28,z+.08),(w,.04,.08),'metal')

def building(x,z,width=8,height=4,mat='white'):
    box('Masonry',(x,height/2,z-2),(width,height,4),mat,True)
    box('Roof coping',(x,height,z-2),(width+.3,.18,4.3),'stone')
    box('Foundation',(x,.15,z+.04),(width,.3,.24),'stone')
    for dx in [-width*.32,width*.32]:window(x+dx,1.7,z+.08,1.75,2.35)
    window(x,1.25,z+.13,1.5,2.5)
    box('Door handle',(x+.5,1.1,z+.28),(.035,.45,.05),'paper')
    box('Sign backing',(x,3.22,z+.15),(width*.80,.6,.12),'stone')

def desk(x,z):
    box('Desk oak top',(x,.76,z),(2.4,.065,.85),'oak',True)
    for dx in [-1.08,1.08]:
        for dz in [-.33,.33]:box('Desk steel leg',(x+dx,.37,z+dz),(.05,.74,.05),'metal')
    for dx in [-.60,.60]:
        box('Monitor foot',(x+dx,.81,z-.18),(.28,.025,.18),'metal')
        box('Monitor stand',(x+dx,.96,z-.22),(.045,.3,.04),'metal')
        box('Monitor bezel',(x+dx,1.19,z-.23),(.53,.33,.045),'black')
        box('Monitor display',(x+dx,1.19,z-.202),(.49,.285,.008),'screen')
        for j in range(4):box('Code on screen',(x+dx-.08,1.27-j*.035,z-.195),(.20-j*.02,.008,.003),'leaf',bevel=0)
        box('Keyboard',(x+dx,.81,z+.12),(.38,.025,.14),'metal')
        for row in range(3):
            for col in range(10):box('Keycap',(x+dx-.16+col*.035,.827,z+.075+row*.035),(.025,.006,.024),'paper',bevel=0)
        ell('Mouse',(x+dx+.27,.825,z+.14),(.04,.025,.07),'black')
        box('Chair seat',(x+dx,.46,z+.85),(.44,.08,.44),'blue')
        box('Chair back',(x+dx,.76,z+1.04),(.44,.5,.06),'blue')
        for leg in [-.17,.17]:box('Chair leg',(x+dx+leg,.22,z+.85),(.025,.44,.37),'metal')
    collisions.append({'position':[x,.5,z+.85],'size':[2.1,1,.45]})

def room():
    box('Floor',(0,-.12,0),(14,.24,14),'paving',True)
    for x in [-7,7]:box('White wall',(x,1.7,0),(.25,3.4,14),'white',True)
    for z in [-7,7]:box('White wall',(0,1.7,z),(14,3.4,.25),'white',True)
    for x in [-6.82,6.82]:box('Skirting',(x,.09,0),(.04,.18,14),'stone')
    for z in range(-6,7):box('Floor joint',(0,.005,z),(14,.005,.013),'grout',bevel=0)
    for x in range(-6,7):box('Floor joint',(x,.006,0),(.013,.005,14),'grout',bevel=0)
    for x in [-4,0,4]:window(x,2.1,-6.85,2.7,1.7)

def save(zone, labels, anchors):
    # Batch static geometry by material: one draw surface per family.
    bpy.ops.object.select_all(action='DESELECT')
    for name in mats:
        objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==mats[name]]
        if not objs:continue
        for o in objs:o.select_set(True)
        bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.select_set(False)
    triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
    f=out/(zone+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(f),export_format='GLB',export_yup=True,export_animations=False)
    zones[zone]={'file':f.name,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'triangles':triangles,'collisions':list(collisions),'labels':labels,'anchors':anchors}
    print(zone,triangles,'triangles',len(collisions),'collision boxes',flush=True)

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);collisions.clear()

clear()
box('Square',(0,-.15,5),(38,.3,38),'paving',True)
for x in range(-18,19,2):box('Paving joint',(x,.005,5),(.018,.008,38),'grout',bevel=0)
for z in range(-14,25,2):box('Paving joint',(0,.006,z),(38,.008,.018),'grout',bevel=0)
building(0,-5,18,5,'brick')
for x in [-7,-3.5,3.5,7]:window(x,3.9,-4.91,2.4,1.35)
box('Canopy',(0,2.85,-4.0),(4.5,.15,2.5),'metal')
for x in [-2.12,2.12]:box('Canopy post',(x,1.4,-2.85),(.07,2.8,.07),'metal')
building(-13,4,7,4,'stone');building(13,4,7,4,'white')
building(-13,16,7,4,'brick')
for x,z in [(-3,-2),(3,-2),(-10,5),(10,5),(-10,16)]:plant(x,z,x==10)
for i in range(5):plant(10+i*.55,5.7,True)
bench(-5,5);bench(5,5);bench(3,17)
box('Post envelope sign',(-13,1.5,4.65),(1.35,1.05,.12),'yellow')
box('Envelope',(-13,1.5,4.73),(.95,.58,.025),'paper')
pipe('Envelope fold',[(-13.46,1.77,4.75),(-13,1.43,4.75),(-12.54,1.77,4.75)],.015,'metal')
box('Book exchange',(-11,1,16.6),(1.0,1.3,.50),'wood',True)
for i in range(8):box('Books',(-11.40+i*.10,1.15,16.9),(.075,.55,.23),['red','blue','paper'][i%3])
for z in [0,10,21]:
    for x in [-8.5,8.5]:
        cylinder('Lamp post',(x,1.65,z),.045,3.3,'metal')
        box('Lamp head',(x,3.3,z),(.45,.08,.25),'metal')
        box('Lamp diffuser',(x,3.255,z),(.37,.015,.19),'paper')
for x,z in [(-7,11),(7,11),(-7,20),(7,20)]:
    cylinder('Tree trunk',(x,1.2,z),.12,2.4,'wood')
    for i in range(8):
        a=i*2.4;end=(x+.85*math.cos(a),2.6+(i%3)*.3,z+.85*math.sin(a))
        pipe('Branch',[(x,1.7,z),end],.025,'wood')
        for j in range(50):
            dx=random.uniform(-.58,.58);dy=random.uniform(-.45,.45);dz=random.uniform(-.58,.58)
            if dx*dx+dz*dz+dy*dy>.55:continue
            leaf((end[0]+dx,end[1]+dy,end[2]+dz),random.uniform(.18,.35),random.uniform(0,math.tau),'leaf' if j%3 else 'green')
    collisions.append({'position':[x,1,z],'size':[.35,2,.35]})
for r,y in [(1.8,.25),(1.65,.52)]:
    bpy.ops.mesh.primitive_torus_add(major_segments=64,minor_segments=10,location=xyz((0,y,10)),major_radius=r,minor_radius=.12)
    finish(bpy.context.object,'Carved basin rim','stone')
cylinder('Basin base',(0,.17,10),1.8,.22,'stone')
cylinder('Water surface',(0,.40,10),1.6,.025,'water')
cylinder('Fountain stem',(0,.83,10),.22,1.2,'stone',.13)
cylinder('Upper bowl',(0,1.45,10),.65,.16,'stone',.78)
for i in range(12):
    a=i*math.tau/12
    pts=[((.70+t*.35)*math.cos(a),1.50-t*t*1.04,10+(.70+t*.35)*math.sin(a)) for t in [j/12 for j in range(13)]]
    pipe('Water stream',pts,.016,'stream')
collisions.append({'position':[0,.4,10],'size':[3.7,.8,3.7]})
for x in [-19,19]:collisions.append({'position':[x,2,5],'size':[.3,4,38]})
for z in [-14,24]:collisions.append({'position':[0,2,z],'size':[38,4,.3]})
save('square',[
 {'text':'LYCÉE LOUISE MICHEL','position':[0,3.25,-4.74],'size':.009},
 {'text':'LA POSTE','position':[-13,3.25,4.26],'size':.009},
 {'text':'FLEURISTE','position':[13,3.25,4.26],'size':.009},
 {'text':'BIBLIOTHÈQUE','position':[-13,3.25,16.26],'size':.008}],
 {'spawn':[0,.05,2],'school':[0,0,-3.8],'post':[-13,0,5.8],'flowers':[13,0,5.6],'books':[-11,0,18],'fountain':[0,0,12.7]})

clear();room()
box('Reception desk',(-3.5,.53,-2.7),(3.4,1.06,.85),'wood',True)
box('Reception counter',(-3.5,1.08,-2.7),(3.55,.08,1),'stone')
for x in [-4.9,-4.7,-4.5,-4.3,-4.1,-3.9,-3.7,-3.5,-3.3,-3.1,-2.9,-2.7,-2.5,-2.3,-2.1]:box('Oak rib',(x,.56,-2.23),(.055,.92,.05),'oak')
box('Reception screen',(-3.9,1.36,-2.8),(.5,.35,.05),'black');box('Screen stand',(-3.9,1.19,-2.8),(.06,.2,.07),'metal')
bench(-4,3);plant(-5.9,-5.8);plant(5.8,4.5)
box('Notice board',(-6.81,1.6,0),(.10,1.25,2.1),'oak')
for z in [-.6,0,.6]:box('Notice',(-6.74,1.65,z),(.01,.65,.38),'paper')
for i in range(10):
    box('Straight stair',(3,.09+i*.18,-1.0-i*.30),(2.2,.18,.31),'stone')
    for x in [1.8,4.2]:box('Stair baluster',(x,.5+i*.18,-1-i*.3),(.035,.85,.035),'metal')
for x in [1.8,4.2]:pipe('Straight handrail',[(x,.95,-.9),(x,2.57,-3.7)],.035,'wood')
box('Upper landing',(3,1.77,-4.5),(2.3,.18,1.3),'stone')
collisions.append({'position':[3,1,-2.5],'size':[2.6,2,3.6]})
window(0,1.2,6.84,1.8,2.4)
save('reception',[{'text':'ACCUEIL','position':[-3.5,2.4,-6.7],'size':.013},{'text':'ATELIERS  →','position':[3,2.9,-6.7],'size':.01}],
 {'spawn':[0,.05,3.7],'exit':[0,0,5.2],'supervisor':[-2,0,-.6],'stairs':[3,0,.4]})

clear();room()
for x in [-3,1]:
    for z in [-3.5,.0]:desk(x,z)
box('Network rack',(5.8,1.05,-4.9),(.8,2.1,.8),'metal',True)
for y in [.35,.65,.95,1.25,1.55,1.85]:
    box('Rack server',(5.8,y,-4.46),(.69,.22,.06),'black')
    for x in [5.54,5.62,5.70]:box('Status LED',(x,y,-4.42),(.025,.025,.012),'leaf')
box('Whiteboard',(0,1.9,-6.80),(3.5,1.2,.08),'paper')
box('Board tray',(0,1.26,-6.66),(3.5,.04,.18),'metal')
plant(5.5,4.8)
save('workshop',[{'text':'ATELIER CIEL','position':[0,2.1,-6.70],'size':.010},{'text':'RÉSEAUX · INFORMATIQUE · ÉLECTRONIQUE','position':[0,1.7,-6.69],'size':.0038}],
 {'spawn':[0,.05,4.6],'exit':[0,0,5.7],'computer':[-3,0,1.65],'rack':[5.8,0,-3.1]})

(out/'manifest.json').write_text(json.dumps({'version':1,'source':'tools/build_campus_3d.py','tool':bpy.app.version_string,'license':'Original project geometry; no third-party models or logos','units':'metres','renderer':'Godot 4.6.3 Compatibility','zones':zones},ensure_ascii=False,indent=2)+'\n')
