"""Original civic decorations and stone fountain; uses the school render rig."""
import importlib.util, sys, json, hashlib, math
from pathlib import Path
import bpy
from mathutils import Vector
argv=sys.argv[sys.argv.index('--')+1:];project=Path(argv[argv.index('--project')+1]).resolve()
spec=importlib.util.spec_from_file_location('school_render',project/'tools/render_school_assets.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
S.OUT=project/'assets/art/town_details';S.OUT.mkdir(parents=True,exist_ok=True)

def mesh(name,vertices,faces,mat):
 data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.materials.append(S.MATS[mat]);obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return obj

def star(cx,y,cz,r):
 points=[(cx,y,cz)]
 for i in range(10):
  a=math.pi/2+i*math.pi/5;rr=r if i%2==0 else r*.42;points.append((cx+math.cos(a)*rr,y,cz+math.sin(a)*rr))
 return mesh('EU star',points,[(0,i+1,(i+1)%10+1) for i in range(10)],'gold')

def flag(europe):
 S.material('fr_blue',(.008,.018,.24),.82);S.material('fr_red',(.62,.012,.028),.82);S.material('flag_white',(.87,.88,.85),.82);S.material('eu_blue',(.006,.025,.24),.82);S.material('gold',(.95,.63,.015),.55)
 cx=.12;cy=.12
 S.box('Stone foot',(cx,cy,.045),(.24,.25,.09),'stone',.025);S.cylinder('Aluminium mast',(cx,cy,.08),(cx,cy,2.50),.018,'chrome',24)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.035,location=(cx,cy,2.51));bpy.context.object.data.materials.append(S.MATS['chrome'])
 w=1.06;h=.66;left=cx+.025;bottom=1.77
 def wave(x,z):return cy-.03+.055*math.sin((x-left)*8+(z-bottom)*2)*(x-left)/w
 verts=[]
 for row in range(13):
  z=bottom+row*h/12
  for col in range(25):
   x=left+col*w/24;verts.append((x,wave(x,z),z-.04*(x-left)/w))
 faces=[]
 for row in range(12):
  for col in range(24):a=row*25+col;faces.append((a,a+1,a+26,a+25))
 o=mesh('Woven cloth flag',verts,faces,'eu_blue' if europe else 'fr_blue')
 if not europe:
  o.data.materials.append(S.MATS['flag_white']);o.data.materials.append(S.MATS['fr_red'])
  for row in range(12):
   for col in range(24):o.data.polygons[row*24+col].material_index=col//8
 for polygon in o.data.polygons:polygon.use_smooth=True
 solid=o.modifiers.new('Cloth thickness','SOLIDIFY');solid.thickness=.002
 if europe:
  for i in range(12):
   a=math.pi/2+i*math.tau/12;x=left+w*.5+math.cos(a)*h*.29;z=bottom+h*.5+math.sin(a)*h*.29;star(x,wave(x,z)-.009,z-.04*(x-left)/w,.031)
 S.pipe([(cx+.035,cy,2.43),(cx+.04,cy,.24)],.004,'paper')

def book_box():
 w=1.0;d=.40/S.SIN
 for x in [.12,.88]:S.box('Display leg',(x,d*.6,.40),(.055,.055,.8),'metal',.008)
 S.box('Bookcase back',(.5,d*.85,1.12),(w,.045,.78),'wood',.012)
 for x in [.025,.975]:S.box('Bookcase side',(x,d*.48,1.10),(.05,d*.8,.82),'wood',.012)
 for z in [.72,1.04,1.46]:S.box('Weatherproof shelf',(.5,d*.46,z),(w,d*.88,.055),'wood',.012)
 roof=S.box('Sloped roof',(.5,d*.5,1.55),(1.12,d+.14,.07),'blue',.012);roof.rotation_euler.x=.12
 for row in range(2):
  for i in range(9):
   x=.12+i*.095;z=.87+row*.34
   S.box('Book spine',(x,d*.24,z),(.067,.20,.25),['blue','red','paper','green','wood'][i%5],.006)
   S.box('Spine label',(x,d*.135,z+.04),(.043,.002,.03),'paper',.001)
 S.text('LIVRES A PARTAGER',(.09,-.01,1.34),.079,'paper')

def media_kiosk():
 w=.76;d=.34/S.SIN
 S.box('Kiosk foot',(w/2,d/2,.035),(w,d,.07),'stone',.025)
 for x in [.12,w-.12]:S.box('Kiosk leg',(x,d*.65,.5),(.055,.055,.95),'metal',.008)
 S.box('Information board',(w/2,d*.6,1.16),(w,.12,1.10),'metal',.035)
 S.box('Poster',(w/2,d*.6-.067,1.16),(w-.08,.009,1.02),'paper',.018)
 S.text('MEDIATHEQUE',(.085,d*.6-.078,1.54),.075,'blue')
 S.cylinder('Film reel',(w*.50,d*.6-.09,1.22),(w*.50,d*.6-.115,1.22),.20,'blue',48)
 for i in range(5):
  a=i*math.tau/5;S.cylinder('Reel cutout',(w*.50+math.cos(a)*.12,d*.6-.118,1.22+math.sin(a)*.12),(w*.50+math.cos(a)*.12,d*.6-.122,1.22+math.sin(a)*.12),.042,'paper',20)
 S.text('LIRE',(.1,d*.6-.078,.93),.08,'blue');S.text('ECOUTER',(.1,d*.6-.078,.80),.08,'blue');S.text('DECOUVRIR',(.1,d*.6-.078,.67),.073,'blue')

def lathe(name,profile,cx,cy,mat):
 verts=[];count=96
 for r,z in profile:
  for i in range(count):a=i*math.tau/count;verts.append((cx+r*math.cos(a),cy+r*math.sin(a)/S.SIN,z))
 faces=[]
 for row in range(len(profile)):
  for i in range(count):faces.append((row*count+i,row*count+(i+1)%count,((row+1)%len(profile))*count+(i+1)%count,((row+1)%len(profile))*count+i))
 o=mesh(name,verts,faces,mat)
 for poly in o.data.polygons:poly.use_smooth=True
 return o

def water_disk(name,cx,cy,r,z):
 bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=r,depth=.012,location=(cx,cy,z-.006));o=bpy.context.object;o.name=name;o.scale.y=1/S.SIN;o.data.materials.append(S.MATS['water'])

def fountain():
 cx=.95;cy=.95/S.SIN
 S.material('granite',(.38,.40,.38),.60,0,'grain');water=S.material('water',(.025,.18,.23),.16,.08)
 p=water.node_tree.nodes.get('Principled BSDF');p.inputs['Transmission Weight'].default_value=0;p.inputs['IOR'].default_value=1.333
 lathe('Carved stone basin',[(.70,.12),(.76,.30),(.79,.44),(.82,.49),(.91,.49),(.95,.44),(.95,.15),(.91,.08),(.78,.08)],cx,cy,'granite')
 water_disk('Inner water',cx,cy,.79,.32)
 S.cylinder('Central pedestal',(cx,cy,.13),(cx,cy,.91),.10,'stone',32)
 lathe('Upper stone cup',[(.08,.80),(.30,.91),(.38,1.00),(.38,1.05),(.33,1.06),(.29,.98),(.08,.90)],cx,cy,'granite')
 water_disk('Upper water',cx,cy,.32,1.01)
 S.cylinder('Water nozzle',(cx,cy,1.00),(cx,cy,1.36),.025,'chrome',24)
 # Segment joints and water-darkened edge in the carved limestone.
 S.material('wet_stone',(.24,.28,.27),.27,.10,'grain')
 lathe('Wet inner rim',[(.785,.40),(.795,.445),(.81,.454),(.806,.43)],cx,cy,'wet_stone')
 for i in range(16):
  a=i*math.tau/16
  S.pipe([(cx+.826*math.cos(a),cy+.826*math.sin(a)/S.SIN,.496),(cx+.91*math.cos(a),cy+.91*math.sin(a)/S.SIN,.496)],.003,'metal')
 # Concentric shallow grooves give the stone rim a carved edge.
 lathe('Polished rim',[(.84,.492),(.86,.498),(.89,.498),(.91,.492)],cx,cy,'stone')


def main():
 catalog_path=project/'data/town_forecourts.json';catalog=json.loads(catalog_path.read_text())
 model_spec=importlib.util.spec_from_file_location('town_prop_models',project/'tools/town_prop_models.py');models=importlib.util.module_from_spec(model_spec);model_spec.loader.exec_module(models)
 definitions={(x['kind'],*x['size']) for x in catalog['decorations']};definitions.add(('fountain',190,190))
 records={}
 for name,width,height in sorted(definitions):
  S.init()
  if name=='flag_fr':flag(False)
  elif name=='flag_eu':flag(True)
  elif name=='book_box':book_box()
  elif name=='media_kiosk':media_kiosk()
  elif name=='fountain':fountain()
  else:models.build(S,name,width,height)
  bpy.context.scene.render.resolution_percentage=200
  bpy.context.scene.cycles.samples=256
  bpy.context.view_layer.update();key=f'{name}_{width}x{height}';record=S.render(key,width,height);record['scale']=2.0;records[key]=record;print('TOWN_RENDERED',key,flush=True)
 result={'version':1,'sprites':records,'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'models_sha256':hashlib.sha256((project/'tools/town_prop_models.py').read_bytes()).hexdigest(),'catalog_sha256':hashlib.sha256(catalog_path.read_bytes()).hexdigest(),'rig_sha256':hashlib.sha256((project/'tools/render_school_assets.py').read_bytes()).hexdigest(),'blender_version':bpy.app.version_string,'license':'CC0-1.0 original artwork','eu_star_count':12,'fr_stripe_order':['blue','white','red'],'intent':'Domain-specific physical forecourt decorations for every city building, rendered at 2x resolution. Stone fountain with animated flowing water in Godot.'}
 (S.OUT/'manifest.json').write_text(json.dumps(result,indent=2)+'\n')
if __name__=='__main__':main()
