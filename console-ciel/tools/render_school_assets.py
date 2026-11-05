"""Original Blender 4.3 models rendered to Godot's existing collision footprints.
Run: blender -b -t 6 --python tools/render_school_assets.py -- --project .
No provider, photograph texture, external model or network dependency.
"""
import bpy, math, json, sys, hashlib, argparse
from pathlib import Path
from mathutils import Vector
parser=argparse.ArgumentParser();parser.add_argument('--project',required=True);parser.add_argument('--only',default='');args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
PROJECT=Path(args.project).resolve();OUT=PROJECT/'assets/art/school_realism';OUT.mkdir(parents=True,exist_ok=True)
SIN=math.sin(math.radians(52));COS=math.cos(math.radians(52));MATS={}
def material(name,color,rough=.5,metal=0,pattern=None):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if pattern:
  coord=n.new('ShaderNodeTexCoord');mapping=n.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(2,65,7) if pattern=='wood' else (34,34,34);l.new(coord.outputs['Generated'],mapping.inputs[0]);noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=1;noise.inputs['Detail'].default_value=2;l.new(mapping.outputs[0],noise.inputs['Vector']);ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.12;ramp.color_ramp.elements[0].color=(*(v*.78 for v in color),1);ramp.color_ramp.elements[1].position=.9;ramp.color_ramp.elements[1].color=(*(min(1,v*1.08) for v in color),1);l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color']);bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.14;bump.inputs['Distance'].default_value=.012 if pattern=='wood' else .006;l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],p.inputs['Normal'])
 MATS[name]=m;return m

def init():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for block in list(bpy.data.materials):bpy.data.materials.remove(block)
 MATS.clear()
 for spec in [('wood',(.55,.39,.22),.42,0,'wood'),('white',(.78,.81,.82),.42,0,None),('plaster',(.83,.835,.82),.82,0,'grain'),('metal',(.29,.34,.38),.3,.78,None),('chrome',(.57,.62,.66),.22,.86,None),('dark',(.035,.045,.052),.38,0,None),('blue',(.105,.22,.31),.48,0,None),('fabric',(.12,.20,.24),.85,0,'grain'),('glass',(.12,.21,.26),.16,.5,None),('screen',(.048,.11,.17),.26,.18,None),('red',(.35,.055,.035),.4,.35,None),('copper',(.48,.23,.10),.27,.72,None),('green',(.055,.16,.10),.4,0,None),('paper',(.86,.87,.83),.65,0,None),('rose',(.51,.34,.32),.8,0,'grain'),('stone',(.69,.67,.6),.8,0,'grain')]:material(*spec)
 s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=256;s.cycles.use_denoising=False;s.cycles.max_bounces=4;s.cycles.diffuse_bounces=2;s.cycles.glossy_bounces=2;s.cycles.adaptive_threshold=.025;s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.image_settings.color_depth='8';s.render.image_settings.compression=100;s.render.film_transparent=True;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX';s.view_settings.look='AgX - Medium High Contrast';s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.78,.85,1,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
 for name,location,power,size,color in [('daylight',(-3,-4,8),1100,5,(1,.92,.82)),('fill',(5,3,7),800,6,(.78,.87,1))]:
  bpy.ops.object.light_add(type='AREA',location=location);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color;o.rotation_euler=(Vector((1,1,.5))-o.location).to_track_quat('-Z','Y').to_euler()

def box(name,loc,size,mat='white',bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(MATS[mat])
 if bevel:
  mod=o.modifiers.new('Machined rounded edges','BEVEL');mod.width=min(bevel,min(size)*.3);mod.segments=3;mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return o

def cylinder(name,a,b,r,mat='metal',vertices=20):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(MATS[mat]);be=o.modifiers.new('Rounded rim','BEVEL');be.width=min(.008,r*.15);be.segments=2
 for poly in o.data.polygons:poly.use_smooth=True
 return o

def pipe(points,r=.018,mat='copper'):
 data=bpy.data.curves.new('Pipe or cable','CURVE');data.dimensions='3D';data.bevel_depth=r;data.bevel_resolution=2;path=data.splines.new('POLY');path.points.add(len(points)-1)
 for q,co in zip(path.points,points):q.co=(*co,1)
 o=bpy.data.objects.new('Routed cable',data);bpy.context.collection.objects.link(o);o.data.materials.append(MATS[mat]);return o

def text(body,at,size=.14,mat='dark'):
 bpy.ops.object.text_add(location=at,rotation=(math.pi/2,0,0));o=bpy.context.object;o.data.body=body;o.data.size=size;o.data.extrude=.0005;o.data.materials.append(MATS[mat]);return o

def bench(w,d):
 for x in [.1,w-.1]:
  for y in [.10,d-.10]:box('Steel leg',(x,y,.36),(.055,.055,.72),'metal',.008)
  box('Lower side brace',(x,d/2,.17),(.04,d-.2,.04),'metal',.005)
 box('Rear beam',(w/2,d-.12,.55),(w-.15,.045,.09),'metal',.005)
 box('Solid beech worktop',(w/2,d/2,.78),(w,d,.09),'wood',.025)
 return .825

def monitor(x,y,z,width=.95):
 box('Monitor foot',(x,y-.07,z+.015),(.31,.23,.03),'metal',.015);box('Monitor stand',(x,y+.015,z+.25),(.07,.07,.44),'metal',.01)
 box('Monitor shell',(x,y,z+.69),(width,.065,width*.57),'dark',.018)
 box('Matte display',(x,y-.038,z+.70),(width-.045,.007,width*.57-.05),'screen',.006)
 for i in range(4):box('Interface line',(x-width*.22+i*.012,y-.044,z+.80-i*.038),(width*.33-i*.032,.002,.009),'white',0)
 box('Window sidebar',(x-width*.39,y-.045,z+.70),(width*.11,.002,width*.4),'blue',0)

def keyboard(x,y,z,w=.65):
 box('Keyboard',(x,y,z+.025),(w,.24,.045),'dark',.018)
 for row in range(4):
  for col in range(13):box('Keycap',(x-w*.45+col*w*.072,y-.08+row*.052,z+.053),(w*.059,.042,.018),'white',.004)
 box('Spacebar',(x,y-.115,z+.055),(w*.4,.025,.015),'white',.004)

def computer(w,d):
 z=bench(w,d)
 for x in [w*.27,w*.73] if w>2.6 else [w*.45]:
  monitor(x,d*.67,z,.95);keyboard(x,d*.28,z)
  o=box('Mouse',(x+.46,d*.28,z+.035),(.11,.17,.07),'dark',.04)
  pipe([(x,d*.48,z+.03),(x,d*.5,z+.04),(x+.35,d*.5,z+.04),(x+.46,d*.37,z+.04)],.007,'dark')
 box('Computer tower',(w-.18,d*.7,z+.33),(.27,.46,.66),'dark',.02)
 for i in range(8):box('Tower grille',(w-.18,d*.467,z+.1+i*.035),(.17,.004,.008),'metal',.001)
 cylinder('Power light',(w-.18,d*.461,z+.48),(w-.18,d*.455,z+.48),.014,'blue')

def gauge(x,y,z,r=.11):
 cylinder('Gauge rim',(x,y,z),(x,y-.045,z),r,'chrome',32);cylinder('Gauge dial',(x,y-.046,z),(x,y-.051,z),r*.83,'paper',32)
 pipe([(x,y-.055,z),(x+r*.42,y-.055,z+r*.38)],.006,'dark')
 for i in range(9):
  a=math.pi*(.2+i*.2);pipe([(x+math.cos(a)*r*.67,y-.055,z+math.sin(a)*r*.67),(x+math.cos(a)*r*.77,y-.055,z+math.sin(a)*r*.77)],.003,'dark')

def trainer(w,d,regulation=False):
 for x in [.10,w-.10]:
  box('Frame upright',(x,d*.7,1.05),(.055,.055,2.1),'metal',.005);box('Stable foot',(x,d*.45,.035),(.22,d,.07),'metal',.012)
 box('Teaching backboard',(w/2,d*.72,1.15),(w-.22,.06,1.77),'white',.012)
 for z in [.63,1.18,1.76]:box('DIN rail',(w/2,d*.67,z),(w-.4,.035,.035),'chrome',.002)
 for row,z in enumerate([.65,1.2,1.77]):
  for i in range(6):
   x=.38+i*(w-.7)/6
   box('Electrical module',(x,d*.61,z),(.22,.17,.25),'paper',.012);box('Breaker switch',(x,d*.51,z+.025),(.07,.035,.09),'dark',.005)
   for dz in [-.09,.09]:cylinder('Terminal screw',(x,d*.516,z+dz),(x,d*.507,z+dz),.014,'chrome',12)
   if row<2:pipe([(x,d*.50,z+.13),(x,d*.47,z+.25),(x+.10,d*.47,z+.25),(x+.10,d*.49,z+.42)],.012,'blue' if i%2 else 'red')
 if regulation:
  for i in range(3):gauge(w*.25*(i+1),d*.45,.40,.105)
 else:
  for i in range(4):cylinder('Push button',(w*(i+1)/5,d*.63,.35),(w*(i+1)/5,d*.46,.35),.06,'blue' if i<3 else 'red')
 text('REGULATION' if regulation else 'PLATINE PEDAGOGIQUE',(.27,d*.675,2.02),.095)

def chair(w,d,stool=False):
 cx,cy=w/2,d/2
 if stool:
  cylinder('Seat',(cx,cy,.5),(cx,cy,.55),w*.48,'wood',40)
  for dx,dy in [(-1,-1),(-1,1),(1,-1),(1,1)]:cylinder('Tubular leg',(cx+dx*w*.25,cy+dy*d*.25,.49),(cx+dx*w*.42,cy+dy*d*.42,.03),.024)
 else:
  box('Upholstered seat',(cx,cy,.45),(w*.94,d*.8,.13),'fabric',.07)
  back=box('Upholstered curved back',(cx,d*.88,.79),(w*.94,.12,.5),'fabric',.07);back.rotation_euler.x=-.11
  for x in [.08,w-.08]:
   cylinder('Chair leg',(x,d*.8,.83),(x,d*.92,.025),.025);cylinder('Front leg',(x,d*.12,.43),(x,d*.02,.025),.025)
   pipe([(x,d*.9,.52),(x,d*.87,.70),(x,d*.17,.70),(x,d*.13,.52)],.025,'metal')

def cabinet(w,d,books=False):
 height=1.5
 box('Cabinet body',(w/2,d/2,height/2),(w,d,height),'metal',.025)
 for row in range(4):
  for col in range(4):
   x=(col+.5)*w/4;z=.15+row*.34
   box('Drawer front',(x,-.018,z+.1),(w/4-.035,.055,.29),'white',.008)
   if books:
    box('Shelf recess',(x,-.05,z+.12),(w/4-.08,.035,.23),'dark',.002)
    for j in range(4):box('Binder',(x-w/10+j*w/17,-.08,z+.12),(w/20,.09,.21),['blue','paper','red','wood'][j],.003)
   else:
    box('Drawer label',(x,-.052,z+.18),(w/7,.003,.045),'paper',.002);box('Drawer handle',(x,-.076,z+.08),(w/9,.045,.025),'chrome',.006)
 for x in [.12,w-.12]:box('Cabinet foot',(x,d/2,.025),(.08,d*.8,.05),'dark',.006)

def tabletop(kind,w,d):
 z=bench(w,d)
 if kind=='laptop_bench':
  for x in [w*.24,w*.73]:
   box('Laptop base',(x,d*.45,z+.018),(.88,.56,.035),'metal',.015);keyboard(x,d*.36,z+.03,.7)
   box('Laptop open screen',(x,d*.74,z+.30),(.88,.035,.56),'dark',.018);box('Laptop glass',(x,d*.718,z+.30),(.82,.005,.49),'screen',.005)
 elif kind=='meeting_table':
  for x,y in [(w*.25,d*.35),(w*.72,d*.65)]:
   box('Notebook',(x,y,z+.015),(.34,.45,.025),'blue',.006);box('Paper',(x+.06,y-.03,z+.032),(.27,.36,.008),'paper',.003);cylinder('Pen',(x+.24,y-.15,z+.02),(x+.24,y+.15,z+.02),.008,'blue',12)
 elif kind=='printer3d':
  x=w*.35;y=d*.55
  box('Printer base',(x,y,z+.06),(1.15,.95,.12),'dark',.02)
  for dx in [-.50,.50]:
   for dy in [-.40,.40]:box('Extrusion frame',(x+dx,y+dy,z+.67),(.045,.045,1.28),'metal',.004)
  box('Top crossbar',(x,y,z+1.30),(1.1,.90,.06),'dark',.012)
  box('Heated bed',(x,y,z+.32),(.92,.75,.04),'metal',.004);box('Printed prototype',(x,y,z+.43),(.25,.27,.19),'blue',.015)
  cylinder('X rail',(x-.52,y-.1,z+.95),(x+.52,y-.1,z+.95),.025,'chrome');box('Extruder',(x+.10,y-.1,z+.87),(.15,.17,.18),'dark',.01)
  cylinder('Filament spool',(x+.85,y,z+.64),(x+.85,y+.18,z+.64),.30,'dark',40);cylinder('Filament',(x+.85,y-.006,z+.64),(x+.85,y-.02,z+.64),.23,'wood',40);pipe([(x+.85,y,z+.9),(x+.65,y,z+1.42),(x+.10,y-.1,z+1.18)],.012,'paper')
  box('Printer control',(x+.38,y-.48,z+.09),(.28,.04,.10),'screen',.008)
 else:
  # Oscilloscope with a graticule, controls and routed test leads.
  x=w*.68;y=d*.65
  box('Oscilloscope casing',(x,y,z+.23),(.8,.4,.46),'white',.04);box('Display',(x-.10,y-.21,z+.26),(.43,.008,.29),'screen',.005)
  for i in range(6):box('Screen graticule',(x-.29+i*.075,y-.217,z+.26),(.002,.001,.25),'blue',0)
  wave=[(x-.30+i*.01,y-.22,z+.26+math.sin(i*.4)*.075) for i in range(40)];pipe(wave,.005,'green')
  for row in range(3):
   for col in range(2):cylinder('Instrument knob',(x+.18+col*.10,y-.21,z+.12+row*.11),(x+.18+col*.10,y-.25,z+.12+row*.11),.03,'dark',16)
  box('Circuit board',(w*.25,d*.4,z+.016),(.65,.45,.025),'green',.008)
  for i in range(3):
   box('Integrated circuit',(w*.12+i*.17,d*.4,z+.047),(.10,.20,.045),'dark',.003)
   for j in range(6):box('IC pin',(w*.12+i*.17-.06,d*.32+j*.03,z+.032),(.025,.012,.012),'chrome',.001)
  pipe([(w*.35,d*.33,z+.04),(w*.45,d*.20,z+.03),(w*.55,d*.23,z+.03),(x+.18,y-.25,z+.03)],.012,'red')
  if kind=='tools_bench':
   for i in range(3):
    x=.2+i*.25;cylinder('Screwdriver shank',(x,.2,z+.025),(x,.5,z+.025),.012,'chrome',12);cylinder('Screwdriver grip',(x,.5,z+.03),(x,.7,z+.03),.035,'red',16)

def rack(w,d):
 box('19 inch enclosure',(w/2,d/2,1.02),(w,d,2.04),'dark',.025)
 for x in [.07,w-.07]:box('Frame rail',(x,-.02,1.02),(.035,.045,1.94),'chrome',.003)
 for row in range(9):
  z=.17+row*.20;box('Rack unit',(w/2,-.025,z),(w-.17,.06,.16),'metal',.006)
  for col in range(8):
   x=.17+col*(w-.34)/8;box('RJ45 port',(x,-.062,z+.018),(.065,.008,.045),'dark',.002)
   cylinder('Status LED',(x,-.068,z-.042),(x,-.075,z-.042),.007,'green',8)
  if row%2==0:pipe([(.25,-.08,z),(.25,-.13,z-.10),(w-.23,-.13,z-.10),(w-.23,-.08,z)],.012,'blue')

def hydraulic(w,d):
 box('Steel platform',(w/2,d/2,.045),(w,d,.09),'metal',.018)
 for x in [.1,w-.1]:box('Platform foot',(x,d/2,.02),(.16,d*.9,.04),'dark',.006)
 x=w*.23;y=d*.65
 cylinder('Insulated cylinder',(x,y,.1),(x,y,1.95),.44,'white',48)
 for z in [.19,1.84]:cylinder('Cylinder collar',(x,y,z),(x,y,z+.025),.45,'chrome',48)
 pipe([(x+.44,y,1.65),(w*.58,y,1.65),(w*.58,y,.48),(w*.85,y,.48),(w*.85,y,1.9)],.035,'copper')
 for xx in [w*.58,w*.85]:
  gauge(xx,y-.15,1.65,.13);box('Valve lever',(xx,y-.02,1.03),(.26,.055,.035),'red',.012)
 box('Circulator motor',(w*.58,y,.65),(.27,.30,.30),'red',.04)
 cylinder('Circulator cover',(w*.58,y-.15,.65),(w*.58,y-.2,.65),.12,'dark',32)
 box('Control box',(w*.86,d*.2,.9),(.5,.25,.70),'white',.02)
 for i in range(3):cylinder('Control',(w*.77+i*.09,d*.06,1),(w*.77+i*.09,d*.035,1),.025,'blue',16)

def board(w,d):
 box('Whiteboard frame',(w/2,d/2,1.15),(w,.07,.90),'metal',.012);box('Whiteboard surface',(w/2,d/2-.04,1.15),(w-.07,.01,.83),'paper',.008)
 for i in range(3):
  x=.25+i*w*.31
  for dx,dz in [(0,0),(.75,0)]:pipe([(x+dx,d/2-.05,.95),(x+dx,d/2-.05,1.32)],.006,'blue')
  for z in [.95,1.32]:pipe([(x,d/2-.05,z),(x+.75,d/2-.05,z)],.006,'blue')
 box('Pen tray',(w/2,d/2-.10,.67),(w-.1,.16,.035),'chrome',.008)

def mezzanine(w,d):
 box('Deck',(w/2,d/2,1.5),(w,d,.13),'metal',.01)
 for x in [.12,w-.12]:box('Red steel upright',(x,d*.65,.72),(.12,.12,1.45),'rose',.008)
 for i in range(int(w/.35)+1):
  x=.08+i*(w-.16)/int(w/.35);cylinder('Guardrail baluster',(x,.06,1.52),(x,.06,2.25),.016,'blue',12)
 for z in [1.58,1.93,2.25]:cylinder('Handrail',(.04,.06,z),(w-.04,.06,z),.025,'blue')
 # Stair flight at the right end gives the mezzanine a plausible access.
 for i in range(6):box('Stair tread',(w-.55,d*.8-i*.10,.15+i*.20),(.85,.14,.045),'metal',.005)

def model(kind,w,d):
 if kind=='cyber_desk':computer(w,d)
 elif kind in ['laptop_bench','electronics','printer3d','meeting_table','tools_bench','measurement_bench','network_console']:tabletop(kind,w,d)
 elif kind in ['training_panel','regulation_panel']:trainer(w,d,kind=='regulation_panel')
 elif kind in ['chair','stool']:chair(w,d,kind=='stool')
 elif kind in ['parts_cabinet','bookcase']:cabinet(w,d,kind=='bookcase')
 elif kind=='rack':rack(w,d)
 elif kind=='hydraulic_bench':hydraulic(w,d)
 elif kind in ['meeting_board','whiteboard']:board(w,d)
 elif kind=='mezzanine':mezzanine(w,d)
 elif kind=='steel_column':
  box('Anchored base',(w/2,d/2,.03),(w,d,.06),'metal',.006)
  box('I beam web',(w/2,d/2,1.2),(.04,d*.5,2.4),'rose',.003)
  for y in [d*.25,d*.75]:box('I beam flange',(w/2,y,1.2),(w*.55,.04,2.4),'rose',.003)
 else:raise ValueError(kind)

def render(name,width,height,elevation=52,facade=False):
 global SIN,COS
 sin,cos=math.sin(math.radians(elevation)),math.cos(math.radians(elevation))
 bpy.context.view_layer.update()
 points=[]
 for o in bpy.context.scene.objects:
  if o.type not in ['MESH','FONT','CURVE']:continue
  for v in o.bound_box:
   v=o.matrix_world@Vector(v);points.append((v.x*100,height-100*(v.y*sin+v.z*cos)))
 lowx=math.floor(min(x for x,y in points)-18);highx=math.ceil(max(x for x,y in points)+22);lowy=math.floor(min(y for x,y in points)-12);highy=math.ceil(max(y for x,y in points)+32)
 # Floor contact shadows are drawn separately in Godot, so no cropped catcher.
 for light_name,delta in [('daylight',(-3,-4,8)),('fill',(5,3,7))]:
  o=bpy.data.objects[light_name];target_light=Vector((width/200,1,.5));o.location=target_light+Vector(delta);o.rotation_euler=(target_light-o.location).to_track_quat('-Z','Y').to_euler()
 if facade:
  sun=bpy.data.objects['daylight'];sun.data.type='SUN';sun.data.energy=2.0;sun.data.angle=.12
  bpy.data.objects['fill'].data.size=20
 cx=(lowx+highx)/200;up=(height-(lowy+highy)/2)/100
 target=Vector((cx,up*sin,up*cos));normal=Vector((0,-cos,sin))
 bpy.ops.object.camera_add(location=target+normal*40);camera=bpy.context.object;camera.rotation_euler=(-normal).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.sensor_fit='HORIZONTAL';camera.data.ortho_scale=(highx-lowx)/100
 s=bpy.context.scene;s.camera=camera;s.render.resolution_x=highx-lowx;s.render.resolution_y=highy-lowy;s.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
 return {'file':name+'.png','rect':[lowx,lowy,highx-lowx,highy-lowy],'scale':1.0,'alpha':'straight','footprint':[width,height],'sha256':hashlib.sha256((OUT/(name+'.png')).read_bytes()).hexdigest()}

def facade():
 w=18;d=2.4
 box('Rose entrance block',(2.8,d/2,1.58),(5.6,d,3.16),'rose',.025)
 box('White workshop wing',(11.8,d/2+.2,1.35),(12.4,d,2.70),'plaster',.018)
 for x,cw,z in [(2.8,5.7,3.20),(11.8,12.5,2.76)]:
  box('Concrete roof coping',(x,d/2,z),(cw,d+.13,.11),'stone',.016);box('Flat roof gravel',(x,d/2,z+.07),(cw-.18,d-.1,.025),'metal',.004)
 def window(x,z,ww,hh,door=False,shutter=False):
  box('Deep window reveal',(x,-.04,z),(ww+.16,.16,hh+.16),'stone',.008)
  box('Aluminium window frame',(x,-.14,z),(ww,.08,hh),'metal',.008)
  box('Glazing',(x,-.186,z),(ww-.08,.012,hh-.08),'glass',.004)
  for dx in [-ww/2+.02,0,ww/2-.02]:box('Glazing mullion',(x+dx,-.204,z),(.035,.04,hh),'white',.003)
  box('Horizontal glazing bar',(x,-.204,z+hh*.22),(ww,.04,.035),'white',.003)
  # Soft reflected sky bands in the double glazing.
  for i in range(3):box('Glass reflection',(x-ww*.2+i*.15,-.198,z+hh*.12),(.045,.001,hh*.75),'blue',0)
  if shutter:
   for row in range(12):box('Roller shutter slat',(x,-.23,z+hh*.42-row*.043),(ww-.05,.05,.039),'white',.005)
  if door:
   for xx in [x-.11,x+.11]:cylinder('Door pull',(xx,-.28,.9),(xx,-.28,1.15),.012,'chrome',16)
   box('Entrance threshold',(x,-.25,.025),(ww+.3,.5,.05),'stone',.008)
  else:box('Concrete window sill',(x,-.20,z-hh/2-.04),(ww+.2,.22,.065),'stone',.006)
 for x in [.95,4.75]:window(x,1.15,1.55,1.95)
 window(3.0,1.10,1.5,2.18,True)
 for x in [6.7,8.75,12.9,14.95,17]:window(x,1.34,1.35,1.53,False,True)
 window(10.97,1.04,1.50,2.05,True)
 for x in [5.75,7.65,9.7,12,14,16.1,17.9]:box('Facade pier',(x,-.06,1.35),(.10,.13,2.7),'plaster',.004)
 cylinder('Rainwater pipe',(5.65,-.18,.08),(5.65,-.18,2.78),.027,'metal')
 box('School name panel',(2.80,-.15,2.80),(4.8,.08,.36),'plaster',.01)
 text('LYCEE LOUISE MICHEL',(.63,-.198,2.72),.235,'dark')
 text('ATELIERS',(10.48,-.22,2.37),.12,'dark')
 # Clock and wall lights are physical details of the original frontage.
 gauge(5.12,-.22,2.70,.13)
 for x in [2.12,3.86]:box('Entrance wall luminaire',(x,-.2,2.43),(.15,.12,.08),'dark',.015)
 box('Forecourt step',(9,-.28,.0),(18,.55,.045),'stone',.009)
 return render('lycee_facade',1800,330,18,True)

def main():
 source=PROJECT/'assets/art/baked/manifest.json';old=json.loads(source.read_text());specs={}
 # Explicit stable footprint list mirrors the existing shared geometry.
 dims={'cyber_desk':[(320,110)],'laptop_bench':[(480,150)],'electronics':[(420,150)],'printer3d':[(420,150)],'chair':[(70,40)],'rack':[(120,80)],'training_panel':[(420,90)],'regulation_panel':[(420,110)],'tools_bench':[(440,150)],'parts_cabinet':[(360,100),(250,80)],'meeting_table':[(300,140),(420,160)],'bookcase':[(280,90)],'hydraulic_bench':[(420,180)],'mezzanine':[(1220,80)],'steel_column':[(48,48)],'stool':[(48,42)],'measurement_bench':[(210,110)],'meeting_board':[(650,30)],'whiteboard':[(520,30),(600,30)],'network_console':[(420,160)]}
 manifest_path=OUT/'manifest.json';result=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'version':1,'sprites':{}}
 for kind,sizes in dims.items():
  if args.only and kind not in args.only.split(','):continue
  for width,height in sizes:
   init();bpy.context.view_layer.update();model(kind,width/100,height/100/SIN);bpy.context.view_layer.update();name=kind+'_'+str(width)+'x'+str(height);result['sprites'][name]=render(name,width,height);manifest_path.write_text(json.dumps(result,indent=2)+'\n');print('RENDERED',name,flush=True)
 if not args.only or 'facade' in args.only.split(','):
  init();facade_result=facade();result['sprites']['lycee_facade']=facade_result
 result['generator_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest();result['blender_version']=bpy.app.version_string;result['license']='CC0-1.0 for original rendered artwork. No third-party model or photograph texture. The school logo is drawn separately by Godot and retains its own rights.';manifest_path.write_text(json.dumps(result,indent=2)+'\n')
if __name__ == "__main__": main()
