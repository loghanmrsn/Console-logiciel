"""Original domain-specific street furniture. Blender meshes, no external assets.
One metre equals 100 world pixels. The caller supplies the shared Cycles rig.
"""
import math, random
import bpy

def build(S, kind, width, height):
 w=width/100;d=height/100/S.SIN;cx=w/2;cy=d/2
 B=S.box;C=S.cylinder;P=S.pipe;T=S.text
 for args in [('postal',(.78,.47,.015),.36,.25,None),('terracotta',(.41,.16,.075),.78,0,'grain'),('leaf',(.07,.19,.035),.78,0,'grain'),('petal',(.72,.06,.15),.56,0,None),('cream',(.85,.72,.47),.65,0,None),('rubber',(.018,.024,.028),.93,0,'grain'),('brass',(.55,.33,.085),.24,.8,None)]:S.material(*args)
 rng=random.Random(kind)
 def sphere(name,at,size,mat):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=1,location=at);o=bpy.context.object;o.name=name;o.scale=size;o.data.materials.append(S.MATS[mat])
  for f in o.data.polygons:f.use_smooth=True
  return o
 def torus(name,at,r,tube,mat,rotation=(0,0,0)):
  bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,location=at,major_radius=r,minor_radius=tube,rotation=rotation);o=bpy.context.object;o.name=name;o.data.materials.append(S.MATS[mat]);return o
 def pot(x,y,z,r=.14):
  bpy.ops.mesh.primitive_cone_add(vertices=40,radius1=r*.7,radius2=r,depth=r*1.8,location=(x,y,z+r*.9));o=bpy.context.object;o.name='Fired clay pot';o.data.materials.append(S.MATS['terracotta']);be=o.modifiers.new('Rounded ceramic lip','BEVEL');be.width=.009;be.segments=3
  torus('Rolled pot rim',(x,y,z+r*1.7),r*.96,.012,'terracotta');C('Soil',(x,y,z+r*1.68),(x,y,z+r*1.73),r*.86,'dark',40)
  return z+r*1.7
 def plant(x,y,z,flowers=False,scale=1):
  base=pot(x,y,z,.14*scale)
  for j in range(5):
   a=j*math.tau/5;tip=(x+math.cos(a)*.12*scale,y+math.sin(a)*.10*scale,base+(.23+j%2*.12)*scale)
   P([(x,y,base),tip],.009*scale,'leaf')
   leaf=sphere('Curved leaf',(tip[0],tip[1],tip[2]-.08*scale),(.085*scale,.025*scale,.035*scale),'leaf');leaf.rotation_euler.z=a
   if flowers:
    sphere('Flower centre',tip,(.028*scale,)*3,'cream')
    for k in range(7):
     b=k*math.tau/7;o=sphere('Petal',(tip[0]+math.cos(b)*.036*scale,tip[1]+math.sin(b)*.036*scale,tip[2]),(.04*scale,.023*scale,.015*scale),'petal' if j%2 else 'paper');o.rotation_euler.z=b
 def sign(title,mat='blue',z=1.0):
  B('Weighted plinth',(cx,cy,.035),(w,d,.07),'stone',.025)
  for x in [w*.15,w*.85]:B('Metal post',(x,cy,.66),(.045,.045,1.3),'metal',.006)
  B('Enamel panel',(cx,cy,z),(w-.04,.08,.65),mat,.035)
  for x in [w*.08,w*.92]:
   for zz in [z-.26,z+.26]:C('Fixing screw',(x,cy-.047,zz),(x,cy-.052,zz),.009,'chrome',12)
  if title:T(title,(.09,cy-.048,z+.18),min(.085,w*.085),'paper')
 def crate(x,y,z,ww=.42,dd=.30):
  B('Crate base',(x,y,z+.015),(ww,dd,.03),'wood',.006)
  for side in [-1,1]:
   for zz in [.06,.15]:B('Crate slat',(x,y+side*dd/2,z+zz),(ww,.023,.065),'wood',.005)
   B('Crate end',(x+side*ww/2,y,z+.10),(.025,dd,.2),'wood',.006)
 def cart():
  for x in [.08,w-.08]:
   for y in [.07,d-.07]:C('Leg',(x,y,.10),(x,y,.8),.022,'metal');torus('Castor',(x,y,.08),.043,.016,'rubber',(math.pi/2,0,0))
  B('Lower shelf',(cx,cy,.20),(w,d,.045),'wood',.008);B('Worktop',(cx,cy,.82),(w,d,.065),'wood',.014)
 def bottle(x,y,z,mat='green'):
  C('Bottle',(x,y,z+.015),(x,y,z+.21),.04,mat,24);C('Bottle neck',(x,y,z+.20),(x,y,z+.30),.018,mat,20);B('Paper label',(x,y-.039,z+.12),(.055,.004,.08),'paper',.002)
 def wheel(x,y,z,r=.25):
  torus('Tyre',(x,y,z),r,.027,'rubber',(math.pi/2,0,0));torus('Wheel rim',(x,y,z),r-.026,.010,'chrome',(math.pi/2,0,0))
  for j in range(24):
   a=j*math.tau/24;P([(x,y,z),(x+(r-.03)*math.cos(a),y,z+(r-.03)*math.sin(a))],.0028,'chrome')
  C('Axle',(x,y-.05,z),(x,y+.05,z),.025,'metal')
 if kind=='post_envelope':
  sign('COURRIER','postal',1.42)
  # A physical embossed envelope, raised flap and seam, readable from afar.
  B('Envelope plaque',(cx,cy-.056,1.32),(w*.70,.027,.36),'paper',.012)
  for a,b in [((-.35,.18),(0,-.015)),((0,-.015),(.35,.18)),((-.35,-.18),(-.09,-.02)),((.35,-.18),(.09,-.02))]:P([(cx+a[0]*w,cy-.075,1.32+a[1]),(cx+b[0]*w,cy-.075,1.32+b[1])],.008,'brass')
  B('Letter box',(cx,cy,.48),(.44,.30,.57),'postal',.045);B('Mail slot',(cx,cy-.157,.66),(.28,.012,.035),'dark',.004);T('LETTRES',(cx-.15,cy-.166,.51),.055,'dark');C('Lock',(cx+.12,cy-.17,.35),(cx+.12,cy-.18,.35),.018,'chrome')
 elif kind in ['flower_display','garden_planter','residence_planter']:
  if kind=='flower_display':
   for z,y in [(.13,d*.2),(.46,d*.66)]:
    B('Display shelf',(cx,y,z),(w,.25,.04),'wood',.01)
    for x in [.18,cx,w-.18]:plant(x,y,z+.02,True,.8)
   for x in [.07,w-.07]:P([(x,d*.12,.02),(x,d*.72,.5)],.022,'metal')
   # Watering can: spout, handle and body.
   C('Watering can',(w-.13,d*.82,.04),(w-.13,d*.82,.22),.085,'green');P([(w-.19,d*.82,.08),(w-.34,d*.80,.24)],.022,'green')
  else:
   B('Stone planter',(cx,cy,.20),(w,d,.40),'stone',.045);B('Dark soil',(cx,cy,.405),(w-.08,d-.08,.025),'dark',.005)
   for x in [.23,w-.23]:plant(x,cy,.40,kind=='garden_planter',.85)
   if kind=='residence_planter':
    B('Letterboxes',(cx,cy+.03,.95),(.30,.12,.42),'blue',.015)
    for i in range(3):B('Postal slot',(cx,cy-.035,.82+i*.13),(.23,.009,.018),'dark',.002)
 elif kind in ['produce_stall','organic_stall','bread_stall','butcher_stall','coffee_cart','restaurant_service','bar_barrel']:
  cart()
  if kind in ['produce_stall','organic_stall']:
   for side in [-1,1]:
    x=cx+side*w*.23;crate(x,cy,.86,w*.43,d*.8)
    for j in range(12):
     at=(x+(j%4-1.5)*.08,cy+(j//4-1)*.07,1.02)
     sphere('Fresh produce',at,(.041,.039,.041),'red' if side<0 else 'green')
   T('BIO' if kind=='organic_stall' else 'MARCHE',(.06,-.016,.65),.09,'blue')
  elif kind=='bread_stall':
   for i in range(5):
    x=.13+i*(w-.26)/4;o=sphere('Crusty baguette',(x,cy,1.00),(.055,d*.42,.075),'cream');o.rotation_euler.z=.10
    for j in range(4):P([(x-.03,cy-d*.25+j*d*.15,1.065),(x+.025,cy-d*.20+j*d*.15,1.065)],.006,'wood')
   T('PAIN ARTISAN',(.06,-.018,.65),.075,'blue')
  elif kind=='coffee_cart':
   B('Espresso machine',(cx,cy,.99),(w*.65,d*.8,.30),'chrome',.04);B('Machine front',(cx,-.01,1.00),(w*.58,.035,.15),'dark',.012)
   for x in [cx-.15,cx+.15]:
    P([(x,-.035,1.04),(x,-.12,1.04)],.025,'chrome');C('Porcelain cup',(x,d*.16,.86),(x,d*.16,.94),.047,'paper',24)
   T('CAFE',(.07,-.02,.64),.12,'blue')
  elif kind=='restaurant_service':
   C('Serving tray',(cx,cy,.86),(cx,cy,.885),w*.36,'chrome',48)
   sphere('Polished cloche',(cx,cy,.885),(w*.32,d*.40,.22),'chrome');sphere('Cloche handle',(cx,cy,1.12),(.035,.025,.035),'brass')
   B('Menu holder',(.14,cy+.1,1.02),(.20,.06,.32),'blue',.01);T('MENU',(.06,cy+.065,1.08),.055,'paper')
  elif kind=='bar_barrel':
   C('Oak barrel',(cx,cy,.87),(cx,cy,1.3),.19,'wood',48)
   for z in [.92,1.22]:torus('Barrel hoop',(cx,cy,z),.192,.018,'metal')
   for x in [.1,w-.1]:bottle(x,cy,.86)
  else:
   B('Butcher scale',(cx,cy,1.0),(.40,.28,.26),'chrome',.025);C('Scale tray',(cx,cy,1.13),(cx,cy,1.15),.25,'chrome',48)
   B('Dial',(cx,-.02,1.01),(.29,.015,.12),'paper',.006);T('0.000',(cx-.12,-.032,1.0),.07,'dark')
   B('Wrapped parcel',(.13,cy,.90),(.22,.24,.10),'paper',.02);P([(.13,cy-.13,.96),(.13,cy+.13,.96)],.004,'red')
 elif kind in ['pharmacy_sign','health_sign']:
  sign('PHARMACIE' if kind=='pharmacy_sign' else 'SANTE','paper',1.1)
  for size in [(.18,.025,.48),(.48,.025,.18)]:B('Medical cross',(cx,cy-.065,1.06),size,'green',.014)
  B('First aid case',(cx,cy,.32),(.45,.23,.33),'paper',.025);P([(cx-.08,cy,.50),(cx-.08,cy,.56),(cx+.08,cy,.56),(cx+.08,cy,.50)],.016,'metal')
 elif kind=='optician_sign':
  sign('OPTIQUE','blue',1.0)
  for x in [cx-.23,cx+.23]:torus('Eyeglass frame',(x,cy-.064,.99),.17,.017,'brass',(math.pi/2,0,0));sphere('Lens',(x,cy-.058,.99),(.152,.008,.152),'glass')
  P([(cx-.06,cy-.07,1.04),(cx,cy-.07,1.07),(cx+.06,cy-.07,1.04)],.012,'brass')
 elif kind=='bicycle':
  y=cy;x1=.24;x2=w-.24;wheel(x1,y,.27,.24);wheel(x2,y,.27,.24)
  a=(x1,y,.27);b=(cx-.10,y,.25);c=(cx-.20,y,.68);e=(x2-.10,y,.68);f=(x2,y,.27)
  for start,end in [(a,b),(a,c),(b,c),(b,e),(c,e),(e,f)]:P([start,end],.018,'blue')
  P([c,(c[0]-.015,y,.78)],.015,'chrome');B('Saddle',(c[0]-.03,y,.79),(.19,.11,.05),'rubber',.02)
  P([e,(e[0],y,.87),(e[0]+.07,y-.10,.88),(e[0]+.13,y-.10,.83)],.017,'chrome')
  C('Pedal axle',(b[0],y-.11,b[2]),(b[0],y+.11,b[2]),.025,'chrome');P([(b[0],y-.11,b[2]),(b[0]+.10,y-.11,b[2]-.06)],.014,'metal')
  B('Pedal',(b[0]+.10,y-.11,b[2]-.06),(.11,.07,.025),'rubber',.006);P([a,(x1+.07,y+.10,.02)],.012,'metal')
 elif kind=='garage_tools':
  for z in [.09,.24,.39]:
   torus('Stacked tyre',(w*.28,cy,z),.20,.075,'rubber')
   for j in range(32):
    a=j*math.tau/32;B('Tyre tread',(w*.28+.263*math.cos(a),cy+.263*math.sin(a),z),(.023,.025,.07),'rubber',.004)
  B('Hydraulic jack',(w*.75,cy,.08),(.25,d*.75,.11),'red',.015);P([(w*.75,cy,.1),(w*.75,cy+.15,.75)],.018,'metal')
  C('Lifting ram',(w*.75,cy,.12),(w*.75,cy,.34),.05,'chrome')
 elif kind in ['cyber_terminal','school_display','bank_terminal']:
  B('Kiosk pedestal',(cx,cy,.44),(w*.72,d,.88),'metal',.045);B('Control unit',(cx,cy,.98),(w*.88,d, .46),'blue',.035)
  B('Display',(cx,cy-d*.51,1.02),(w*.66,.025,.25),'screen',.012)
  T('CIEL' if kind=='school_display' else ('>_ CYBER' if kind=='cyber_terminal' else 'BANQUE'),(.13,cy-d*.55,1.06),.082,'paper')
  for i in range(4):B('Screen status',(cx,cy-d*.55,.93+i*.025),(w*.45-i*.07,.003,.008),'green' if i%2 else 'paper',.001)
  B('Keyboard',(cx,-.03,.84),(w*.60,.12,.04),'dark',.006)
  for i in range(12):B('Key',(cx-w*.26+i*w*.047,-.035,.865),(.025,.06,.012),'paper',.002)
  if kind=='bank_terminal':B('Card slot',(cx,cy-d*.51,.63),(.23,.015,.025),'dark',.003)
 elif kind in ['cinema_display','community_board','association_board','music_display','stationery_display','art_display','canal_display','hotel_luggage','laundry_display','tool_cart']:
  if kind=='hotel_luggage':
   B('Trolley platform',(cx,cy,.10),(w,d,.12),'wood',.018)
   for x in [.07,w-.07]:
    for y in [.07,d-.07]:torus('Trolley wheel',(x,y,.06),.045,.016,'rubber',(math.pi/2,0,0))
   P([(.08,d*.72,.12),(.08,d*.72,1.35),(cx,d*.72,1.50),(w-.08,d*.72,1.35),(w-.08,d*.72,.12)],.023,'brass')
   for x,z,ww,hh in [(.28,.40,.40,.50),(.72,.50,.34,.70)]:
    B('Travel suitcase',(x,cy,z),(ww,d*.75,hh),'wood' if x<.5 else 'blue',.04)
    for dx in [-ww*.25,ww*.25]:B('Leather strap',(x+dx,cy-d*.39,z),(.035,.012,hh),'dark',.004)
    P([(x-.06,cy,z+hh/2),(x-.06,cy,z+hh/2+.07),(x+.06,cy,z+hh/2+.07),(x+.06,cy,z+hh/2)],.012,'dark')
  elif kind=='laundry_display':
   B('Washer housing',(cx,cy,.45),(w*.75,d,.90),'paper',.04);torus('Chrome drum rim',(cx,-.012,.44),.25,.035,'chrome',(math.pi/2,0,0));sphere('Drum glass',(cx,-.025,.44),(.22,.03,.22),'glass')
   for x in [cx-.20,cx+.18]:C('Control knob',(x,-.01,.81),(x,-.04,.81),.033,'metal')
   for i in range(3):B('Folded towel',(cx,cy,.94+i*.035),(.50,d*.7,.035),'fabric' if i%2 else 'paper',.014)
  elif kind=='tool_cart':
   cart();B('Tool chest',(cx,cy,1.0),(w*.86,d,.30),'red',.015)
   for z in [.91,1.02,1.12]:B('Drawer pull',(cx,-.012,z),(w*.64,.04,.017),'chrome',.004)
   P([(.13,cy,1.20),(.60,cy,1.20)],.025,'wood');B('Hammer head',(.63,cy,1.20),(.16,.10,.085),'metal',.012)
  elif kind=='music_display':
   B('Guitar stand',(cx,cy,.025),(.60,d,.05),'metal',.012)
   sphere('Guitar lower bout',(cx,cy,.45),(.24,.10,.27),'wood');sphere('Guitar upper bout',(cx,cy,.66),(.17,.09,.18),'wood')
   C('Sound hole',(cx,cy-.101,.59),(cx,cy-.108,.59),.070,'dark',40);B('Guitar neck',(cx,cy,.98),(.075,.06,.57),'wood',.008);B('Fingerboard',(cx,cy-.035,.98),(.07,.02,.56),'dark',.003);B('Headstock',(cx,cy,1.31),(.10,.06,.16),'wood',.008)
   for i in range(14):B('Fret',(cx,cy-.048,.72+i*.038),(.075,.006,.005),'chrome',.001)
   for i in range(6):P([(cx-.022+i*.009,cy-.12,.36),(cx-.022+i*.009,cy-.05,1.35)],.0013,'chrome')
  elif kind=='stationery_display':
   cart()
   for j in range(4):B('Notebook',(cx-.20+j*.035,cy,.88+j*.04),(.47,d*.7,.035),['blue','red','paper','green'][j],.006)
   C('Pencil cup',(w-.18,cy,.86),(w-.18,cy,1.08),.08,'chrome')
   for j in range(7):
    x=w-.18+.045*math.cos(j);y=cy+.045*math.sin(j);C('Pencil',(x,y,.94),(x,y,1.30+(j%3)*.02),.009,'postal',8)
  elif kind=='art_display':
   for x in [.1,w-.1]:P([(x,cy,.02),(cx,cy,1.3)],.023,'wood')
   B('Canvas',(cx,cy-.04,.98),(w*.78,.06,.55),'paper',.012)
   for i in range(4):sphere('Paint relief',(cx-.25+i*.15,cy-.077,1.02+math.sin(i)*.10),(.12,.008,.09),['blue','red','cream','green'][i])
  elif kind=='canal_display':
   sign('RESIDENCE DU CANAL','blue',1.05);torus('Lifebuoy',(cx,cy-.08,.98),.22,.055,'cream',(math.pi/2,0,0))
   for z in [.77,1.20]:B('Rescue ring band',(cx,cy-.14,z),(.11,.02,.07),'red',.01)
  else:
   sign('CINEMA' if kind=='cinema_display' else ('ASSOCIATIONS' if kind=='association_board' else 'QUARTIER'),'blue',1.05)
   if kind=='cinema_display':
    C('Film reel',(cx,cy-.05,1.02),(cx,cy-.09,1.02),.23,'chrome',48)
    for j in range(5):a=j*math.tau/5;C('Reel aperture',(cx+.14*math.cos(a),cy-.094,1.02+.14*math.sin(a)),(cx+.14*math.cos(a),cy-.10,1.02+.14*math.sin(a)),.05,'dark',24)
    B('Clapper board',(cx,cy,.35),(.55,.09,.24),'dark',.008)
    for j in range(6):B('Clapper stripe',(cx-.22+j*.09,cy-.052,.47),(.05,.012,.035),'paper',.002)
   else:
    for i in range(4):
     x=.18+i*.21;B('Community flyer',(x,cy-.054,.99),(.17,.008,.25),'paper' if i%2 else 'cream',.003)
     for j in range(4):B('Printed flyer line',(x,cy-.060,1.06-j*.045),(.11,.003,.006),'blue',.001)
 else:raise ValueError('Unknown model '+kind)
