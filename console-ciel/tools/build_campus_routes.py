#!/usr/bin/env python3
"""Three original campus rooms, shared primitives, baked material batches.
blender -b -t 4 --python tools/build_campus_routes.py -- --project .
"""
import json
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import build_campus_3d as base
from build_campus_3d import box, pipe, desk, plant, bench, window, room, clear, save


def rack(x,z):
    box('Rack enclosure',(x,1.05,z),(.85,2.1,.85),'metal',True)
    for y in [.3,.6,.9,1.2,1.5,1.8]:
        box('Switch fascia',(x,y,z+.44),(.73,.20,.055),'black')
        for port in range(10):
            box('RJ45 socket',(x-.30+port*.062,y,z+.475),(.040,.035,.015),'paper')
            box('Link LED',(x-.30+port*.062,y+.046,z+.48),(.013,.01,.012),'leaf')
    for i in range(6):
        dx=-.24+i*.08
        pipe('Patch cable',[(x+dx,1.50,z+.50),(x+dx,1.44,z+.62),(x+dx+.04,1.16,z+.62),(x+dx+.04,1.20,z+.5)],.010,'blue' if i%2 else 'yellow')


def labels(title,subtitle):
    return [{'text':title,'position':[0,2.7,-6.7],'size':.009},
            {'text':subtitle,'position':[0,2.3,-6.69],'size':.0038}]


def door(at,angle=0):return {'position':at,'rotation_y':angle}


clear()
box('Corridor floor',(0,-.12,0),(20,.24,6),'paving',True)
for z in [-3,3]:box('White wall',(0,1.6,z),(20,3.2,.24),'white',True)
box('End wall',(10,1.6,0),(.24,3.2,6),'white',True)
# Recess for the left exit, with a solid backstop and two unobstructed jambs.
for z in [-2.06,2.06]:box('Exit jamb wall',(-10,1.6,z),(.24,3.2,1.88),'white',True)
box('Door lintel',(-10,2.75,0),(.24,.90,2.24),'white',True)
base.collisions.append({'position':[-10.14,1.1,0],'size':[.16,2.2,2.24]})
for z in [-2.84,2.84]:
    box('Oak handrail',(0,.92,z),(19.6,.065,.07),'oak')
    box('Skirting',(0,.08,z),(19.6,.16,.04),'stone')
for x in range(-9,10):box('Floor seam',(x,.006,0),(.012,.006,6),'grout',bevel=0)
for x in [-7,-1,5]:
    box('Ceiling luminaire',(x,3.08,0),(1.6,.055,.35),'paper')
bench(0,2.25);plant(8.8,1.9)
save('corridor',[
    {'text':'ATELIER CIEL','position':[-5,2.6,-2.82],'size':.0047},
    {'text':'01 · RÉSEAUX','position':[0,2.6,-2.82],'size':.0047},
    {'text':'02 · CYBERSÉCURITÉ','position':[5,2.6,-2.82],'size':.0047}],
    {'spawn':[-7.5,.05,.9],'exit':[-8.85,0,0],'to_workshop':[-5,0,-1.55],
     'to_network':[0,0,-1.55],'to_cyber':[5,0,-1.55]})
base.zones['corridor']['doors']=[door([-9.94,0,0],1.57079632679)]+[door([x,0,-2.82]) for x in [-5,0,5]]

clear();room()
desk(-3,-2.0);desk(1,-2.0)
rack(4.8,-5.6);rack(5.85,-5.6)
box('Equipment bench',(-4.9,.81,-5.6),(2.7,.09,.9),'oak',True)
for x in [-6,-3.8]:box('Bench leg',(x,.40,-5.6),(.08,.8,.70),'metal')
box('Router',(-4.9,.94,-5.5),(.55,.17,.30),'white')
for x in [-5.12,-4.68]:box('Wi-Fi antenna',(x,1.16,-5.65),(.025,.40,.025),'black')
box('Diagram board',(0,1.6,-6.80),(3.8,1.3,.08),'paper')
for x in [-1.2,0,1.2]:
    box('Diagram device',(x,1.75,-6.73),(.42,.28,.015),'blue')
pipe('LAN diagram',[(-1.2,1.59,-6.71),(-1.2,1.35,-6.71),(1.2,1.35,-6.71),(1.2,1.59,-6.71)],.018,'metal')
pipe('Gateway diagram',[(0,1.59,-6.71),(0,1.35,-6.71)],.018,'metal')
plant(-5.8,4.9)
save('network',labels('LABORATOIRE RÉSEAU','Relier · adresser · acheminer'),
    {'spawn':[0,.05,4.3],'exit':[0,0,5.5],
     'net_cable':[4.8,0,-4.0],'net_address':[-3,0,-.3],'net_gateway':[1,0,-.3]})
base.zones['network']['doors']=[door([0,0,6.81],3.14159265359)]

clear();room()
desk(-3,-2.0);desk(1,-2.0)
box('Monitoring console',(0,.80,-5.6),(4,.10,.80),'oak',True)
for x in [-1.8,1.8]:box('Console support',(x,.4,-5.6),(.08,.8,.65),'metal')
for x in [-1.25,0,1.25]:
    box('Analysis screen',(x,1.40,-5.75),(1.0,.64,.06),'black')
    box('Screen stand',(x,1.04,-5.75),(.07,.40,.06),'metal')
    box('Dashboard display',(x,1.40,-5.71),(.93,.56,.012),'screen')
    for row in range(6):
        box('Log line',(x-.15,1.60-row*.064,-5.696),(.48-row*.04,.014,.008),'leaf' if row!=3 else 'yellow')
    for bar in range(4):box('Traffic chart',(x+.20+bar*.05,1.28+bar*.025,-5.695),(.029,.07+bar*.05,.008),'blue')
box('Evidence cabinet',(5.8,.70,-4.8),(1.3,1.4,.60),'metal',True)
for y in [.25,.6,.95,1.3]:
    box('Cabinet drawer',(5.8,y,-4.46),(1.18,.28,.045),'white')
    box('Drawer handle',(5.8,y,-4.41),(.18,.025,.03),'metal')
plant(-5.8,4.9)
save('cyber',labels('CYBERSÉCURITÉ','Observer · protéger · réagir'),
    {'spawn':[0,.05,4.3],'exit':[0,0,5.5],
     'cyber_mail':[-3,0,-.3],'cyber_mfa':[1,0,-.3],'cyber_incident':[0,0,-3.8]})
base.zones['cyber']['doors']=[door([0,0,6.81],3.14159265359)]

manifest_path=base.out/'manifest.json'
manifest=json.loads(manifest_path.read_text())
manifest['zones'].update(base.zones)
manifest['route_source']='tools/build_campus_routes.py'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
