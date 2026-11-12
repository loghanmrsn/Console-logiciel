"""Original modular adult character and unbranded wardrobe, metres, Blender 4.3.
blender -b -t 6 --python tools/build_character_3d.py -- --project .
Creates a real skinned GLB with one fixed rig, idle/walk animations and variants.
"""
import bpy, math, sys, argparse, json, hashlib
from pathlib import Path
from mathutils import Vector
p=argparse.ArgumentParser();p.add_argument('--project',required=True)
args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
project=Path(args.project).resolve();out=project/'assets/character3d';out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mats={};meshes=[]
for name,color,rough in [('skin',(.55,.31,.19),.6),('hair',(.16,.075,.034),.8),('eyes',(.12,.24,.30),.4),('lips',(.40,.16,.14),.62),('top',(.13,.25,.40),.88),('trousers',(.045,.06,.085),.9),('hat',(.25,.40,.52),.9),('socks',(.8,.8,.74),.9),('shoes',(.7,.71,.67),.6),('white',(.64,.65,.61),.5),('pupil',(.009,.012,.016),.45),('seam',(.12,.16,.18),.85),('metal',(.42,.43,.41),.3)]:
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=rough
 if name in ['top','trousers','hat','hair']:n.inputs['Sheen Weight'].default_value=.15
 mats[name]=m

def finish(o,name,mat,bone='spine'):
 o.name=name;o.data.materials.append(mats[mat])
 for face in o.data.polygons:face.use_smooth=True
 meshes.append((o,bone));return o
def ell(name,at,r,mat,bone='spine',segments=16,rings=10):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=at);o=bpy.context.object;o.scale=r;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,mat,bone)
def tube(name,pts,r,mat,bone='spine'):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.resolution_u=4;d.bevel_depth=r;d.bevel_resolution=1;s=d.splines.new('BEZIER');s.bezier_points.add(len(pts)-1)
 for q,co in zip(s.bezier_points,pts):q.co=co;q.handle_left_type=q.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o=bpy.context.object;o.select_set(False);return finish(o,name,mat,bone)
def sections(name,rows,mat,bone='spine',cx=0,cy=0):
 verts=[];faces=[];n=16
 for z,rx,ry in rows:
  for i in range(n):a=i*math.tau/n;verts.append((cx+rx*math.cos(a),cy+ry*math.sin(a),z))
 for k in range(len(rows)-1):
  for i in range(n):a=k*n+i;faces.append((a,k*n+(i+1)%n,(k+1)*n+(i+1)%n,a+n))
 faces.extend([tuple(reversed(range(n))),tuple((len(rows)-1)*n+i for i in range(n))]);d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o)
 result=finish(o,name,mat,bone)
 mod=result.modifiers.new('Soft continuous surface','SUBSURF');mod.levels=1
 bpy.context.view_layer.objects.active=result;result.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);result.select_set(False)
 return result
def box(name,at,size,mat,bone='spine',bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Rounded tailoring','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,name,mat,bone)

# Continuous anatomical surfaces, tapered limbs, separate fingers and sculpted face.
def loft(name,rows,mat,bone='spine',n=24,fold=0):
 verts=[];faces=[]
 for z,x,y,rx,ry in rows:
  for i in range(n):
   a=i*math.tau/n;wrinkle=1+fold*math.cos(a*7+z*42)*math.sin(z*27)
   verts.append((x+rx*math.cos(a)*wrinkle,y+ry*math.sin(a)*wrinkle,z))
 for k in range(len(rows)-1):
  for i in range(n):j=k*n+i;faces.append((j,k*n+(i+1)%n,(k+1)*n+(i+1)%n,j+n))
 faces.extend([tuple(reversed(range(n))),tuple((len(rows)-1)*n+i for i in range(n))])
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);finish(o,name,mat,bone)
 mod=o.modifiers.new('Tailored surface','SUBSURF');mod.levels=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
trunk=[(.77,0,.004,.105,.077),(.83,0,.009,.151,.094),(.91,0,.008,.153,.096),(.99,0,0,.126,.077),(1.07,0,0,.113,.071),(1.14,0,0,.131,.086),(1.23,0,-.005,.155,.105),(1.29,0,0,.163,.088),(1.325,0,0,.170,.070),(1.35,0,0,.132,.058),(1.375,0,0,.055,.045),(1.405,0,0,.042,.039),(1.448,0,.003,.043,.039)]
loft('body__torso',trunk,'skin','anatomy')
for side in [-1,1]:
 armrows=[(.855,side*.235,-.004,.023,.023),(.91,side*.234,-.002,.025,.027),(.985,side*.232,0,.032,.032),(1.055,side*.229,0,.031,.030),(1.09,side*.225,0,.029,.029),(1.16,side*.217,0,.037,.037),(1.25,side*.201,0,.045,.043),(1.30,side*.180,0,.045,.044),(1.322,side*.167,0,.030,.034)]
 loft('body__arm_'+str(side),armrows,'skin','anatomy')
 loft('body__palm_'+str(side),[(.785,side*.235,-.006,.024,.014),(.812,side*.235,-.006,.027,.018),(.85,side*.235,-.005,.021,.020),(.866,side*.235,-.004,.021,.020)],'skin','anatomy',16)
 for finger in range(4):
  x=side*(.215+finger*.013);length=[.048,.058,.054,.041][finger]
  loft('body__finger_'+str(side)+'_'+str(finger),[(.79-length,x,-.014,.003,.004),(.794-length,x,-.015,.0055,.006),(.78,x,-.013,.006,.007),(.802,x,-.009,.007,.009)],'skin','anatomy',10)
 tube('body__thumb_'+str(side),[(side*.215,-.009,.835),(side*.200,-.019,.811),(side*.197,-.023,.790)],.009,'skin','anatomy')
 loft('body__leg_'+str(side),[(.085,side*.079,0,.028,.036),(.16,side*.079,0,.030,.033),(.28,side*.080,.012,.047,.051),(.36,side*.079,.006,.045,.049),(.445,side*.079,-.007,.038,.039),(.50,side*.080,-.002,.047,.052),(.65,side*.082,0,.068,.071),(.78,side*.082,0,.078,.080),(.86,side*.078,0,.077,.081)],'skin','anatomy')
 ell('body__ear_'+str(side),(side*.077,.004,1.535),(.011,.016,.024),'skin','head',20,12)
 # Subtle collarbones, not detached shoulder spheres.
# Facial surface: cheekbones, jaw, brow ridge, bridge, nose wings and chin.
face=loft('body__face',[(1.43,0,-.009,.018,.024),(1.443,0,-.011,.035,.036),(1.463,0,-.005,.050,.045),(1.49,0,0,.062,.054),(1.53,0,.001,.075,.062),(1.563,0,.003,.077,.064),(1.606,0,.005,.075,.066),(1.645,0,.006,.056,.052),(1.665,0,.006,.018,.020)],'skin','head',40)
def bump(x,z,cx,cz,sx,sz,amount):return amount*math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
for v in face.data.vertices:
 x,y,z=v.co
 if y<0:
  front=max(0,min(1,-y/.035));d=0
  for side in [-1,1]:
   d+=bump(x,z,side*.042,1.527,.025,.025,.006)
   d+=bump(x,z,side*.032,1.568,.023,.010,.006)
   d-=bump(x,z,side*.032,1.549,.019,.011,.004)
  d+=bump(x,z,0,1.529,.009,.033,.015)+bump(x,z,0,1.506,.013,.011,.022)
  d+=bump(x,z,0,1.480,.025,.012,.008)+bump(x,z,0,1.449,.025,.014,.006)
  v.co.y-=d*front
for side in [-1,1]:
 ell('body__nostril_'+str(side),(side*.009,-.077,1.501),(.003,.0015,.0015),'lips','head',12,8)
 tube('body__brow_'+str(side),[(side*.016,-.061,1.572),(side*.036,-.060,1.578),(side*.057,-.044,1.569)],.0024,'hair','head')
for style,height,width in [('almond',.006,.015),('round',.008,.014),('soft',.0055,.016)]:
 for side in [-1,1]:
  x=side*.031
  ell('eyes_'+style+'__white_'+str(side),(x,-.061,1.548),(width,.004,height),'white','head')
  ell('eyes_'+style+'__iris_'+str(side),(x,-.067,1.548),(.006,.0028,height*.78),'eyes','head')
  ell('eyes_'+style+'__pupil_'+str(side),(x,-.069,1.548),(.0028,.0015,height*.62),'pupil','head')
  ell('eyes_'+style+'__spark_'+str(side),(x-.002,-.070,1.551),(.0015,.001,.0016),'white','head',12,8)
  tube('eyes_'+style+'__lid_'+str(side),[(x-width,-.056,1.55),(x,-.065,1.548+height),(x+width,-.056,1.55)],.0015,'hair','head')
for style,lift in [('neutral',0),('soft',.004),('wide',.010)]:
 tube('smile_'+style+'__upper',[(-.024,-.061,1.474+lift),(-.008,-.072,1.473),(0,-.073,1.476),(.008,-.072,1.473),(.024,-.061,1.474+lift)],.003,'lips','head')
 tube('smile_'+style+'__lower',[(-.023,-.061,1.473+lift),(0,-.074,1.468),(.023,-.061,1.473+lift)],.0035,'lips','head')

# Tailoring: shaped torso, sloping shoulders, tapered sleeves and cloth folds.
for side in [-1,1]:
 ell('body__nose_wing_'+str(side),(side*.009,-.075,1.505),(.006,.007,.005),'skin','head',16,10)
 tube('body__lower_lid_'+str(side),[(side*.017,-.059,1.546),(side*.031,-.065,1.542),(side*.046,-.054,1.546)],.0014,'skin','head')
ell('body__nose_tip',(0,-.080,1.509),(.008,.009,.007),'skin','head',20,12)
for style,amp,hem in [('tee',1.05,.94),('sweater',1.13,.92),('hoodie',1.17,.91),('cardigan',1.10,.93)]:
 name='top_'+style+'__'
 rows=[(hem,0,0,.148*amp,.100*amp),(hem+.018,0,0,.151*amp,.102*amp),(1.02,0,0,.132*amp,.086*amp),(1.12,0,0,.139*amp,.095*amp),(1.23,0,-.003,.165*amp,.114*amp),(1.30,0,0,.177*amp,.098*amp),(1.335,0,0,.160*amp,.073*amp),(1.368,0,0,.060,.049),(1.380,0,0,.048,.045)]
 loft(name+'torso',rows,'top','anatomy',32,.008)
 for side in [-1,1]:
  rows=[(.859,side*.235,-.004,.029,.030),(.885,side*.235,-.004,.033,.034),(.98,side*.234,0,.043*amp,.043*amp),(1.085,side*.228,0,.042*amp,.043*amp),(1.17,side*.218,0,.047*amp,.048*amp),(1.27,side*.196,0,.055*amp,.054*amp),(1.32,side*.178,0,.048,.043)]
  if style=='tee':rows=[(1.17,side*.218,0,.051,.052),(1.18,side*.217,0,.052,.053)]+rows[-2:]
  loft(name+'sleeve_'+str(side),rows,'top','anatomy',24,.025 if style!='tee' else .008)
  tube(name+'shoulder_seam_'+str(side),[(side*.060,-.04,1.373),(side*.130,-.05,1.35),(side*.185,-.020,1.313)],.0014,'top','anatomy')
 loft(name+'collar',[(1.367,0,0,.053,.050),(1.381,0,0,.050,.046)],'top')
 if style=='hoodie':
  loft(name+'hood',[(1.30,0,.06,.080,.046),(1.36,0,.073,.105,.057),(1.415,0,.055,.084,.050),(1.425,0,.043,.056,.039)],'top')
  for side in [-1,1]:tube(name+'drawstring_'+str(side),[(side*.044,-.087,1.34),(side*.040,-.13,1.20)],.002,'white')
  tube(name+'pocket',[(-.09,-.102,.98),(-.06,-.113,1.055),(.06,-.113,1.055),(.09,-.102,.98)],.002,'top')
 if style=='cardigan':tube(name+'zip',[(0,-.106,.94),(0,-.12,1.23),(0,-.05,1.375)],.002,'metal')
for style,width in [('regular',1.0),('baggy',1.25),('balloon',1.40)]:
 name='trousers_'+style+'__'
 loft(name+'pelvis',[(.76,0,.003,.136,.088),(.80,0,.006,.157,.104),(.90,0,.005,.159,.106),(.96,0,0,.144,.096)],'trousers','anatomy',32)
 for side in [-1,1]:
  rows=[(.112,side*.079,0,.038*width,.042*width),(.14,side*.079,0,.041*width,.045*width),(.28,side*.079,.008,.055*width,.058*width),(.44,side*.079,-.002,.048*width,.050*width),(.53,side*.081,0,.058*width,.062*width),(.69,side*.082,0,.078*width,.080*width),(.82,side*.081,0,.082*width,.085*width)]
  loft(name+'leg_'+str(side),rows,'trousers','anatomy',24,.018)
  tube(name+'pocket_'+str(side),[(side*.075,-.087,.945),(side*.11,-.092,.90),(side*.143,-.065,.875)],.0017,'trousers','anatomy')
 loft(name+'waistband',[(.938,0,0,.148,.099),(.960,0,0,.144,.096)],'trousers','hips')
 # Stitched fly and button, on a continuous pelvis rather than a separate sphere.
 tube(name+'fly',[(0,-.101,.95),(0,-.105,.84)],.0012,'trousers','hips')
 ell(name+'button',(0,-.103,.948),(.004,.002,.004),'metal','hips',12,8)
# Reference outfit: grey folded bandeau dress, detached sleeves, sheer-look tights.
loft('top_madison__dress',[(.705,0,0,.180,.116),(.717,0,0,.181,.117),(.80,0,.007,.182,.123),(.89,0,.006,.176,.119),(.98,0,0,.139,.093),(1.065,0,0,.121,.082),(1.14,0,-.003,.141,.101),(1.22,0,-.004,.170,.121),(1.275,0,0,.167,.108),(1.284,0,0,.166,.107)],'top','anatomy',40,.005)
loft('top_madison__folded_band',[(1.213,0,-.004,.174,.125),(1.225,0,-.004,.176,.126),(1.279,0,0,.174,.115),(1.291,0,0,.171,.112)],'top','anatomy',40)
for side in [-1,1]:
 loft('top_madison__sleeve_'+str(side),[(.833,side*.235,-.005,.029,.028),(.87,side*.235,-.005,.030,.029),(.97,side*.233,0,.037,.036),(1.075,side*.228,0,.034,.034),(1.16,side*.217,0,.042,.041),(1.236,side*.204,0,.048,.047)],'top','anatomy',24,.009)
 tube('top_madison__bow_'+str(side),[(side*.252,-.006,1.225),(side*.279,-.014,1.249),(side*.274,-.01,1.212),(side*.252,-.006,1.225),(side*.276,-.012,1.193)],.003,'seam','anatomy')
 tube('top_madison__ribbon_'+str(side),[(side*.254,0,1.224),(side*.270,.003,1.13),(side*.264,0,1.075)],.0025,'seam','anatomy')
for side in [-1,1]:
 loft('trousers_tights__leg_'+str(side),[(.08,side*.079,0,.029,.037),(.16,side*.079,0,.032,.035),(.28,side*.080,.012,.049,.053),(.36,side*.079,.006,.047,.051),(.445,side*.079,-.007,.040,.041),(.50,side*.080,-.002,.049,.054),(.65,side*.082,0,.070,.073),(.78,side*.082,0,.080,.082),(.86,side*.078,0,.080,.084)],'trousers','anatomy',24)
loft('trousers_tights__waist',[(.76,0,0,.145,.095),(.86,0,0,.158,.103),(.95,0,0,.142,.092)],'trousers','anatomy')
for side in [-1,1]:
 sections('socks_socks__'+str(side),[(.07,.039,.042),(.19,.039,.042)],'socks','shin_'+str(side),cx=side*.079)
 for style in ['canvas','court','boots','loafers','runner','high']:
  name='shoes_'+style+'__'+str(side)
  y=-.035;z=.058;rx=.047;ry=.101
  if style=='boots':z=.08;rx=.053
  if style=='runner':ry=.110
  ell(name+'sole',(side*.079,y,.027),(rx+.004,ry,.025),'seam','foot_'+str(side))
  ell(name+'upper',(side*.079,y,z),(rx,ry-.004,.044 if style!='loafers' else .032),'shoes','foot_'+str(side))
  if style in ['boots','high']:
   sections(name+'ankle',[(.055,.043,.052),(.16 if style=='boots' else .13,.043,.047)],'shoes','foot_'+str(side),cx=side*.079)
  if style=='loafers':tube(name+'strap',[(side*.079-.040,-.045,.079),(side*.079,-.052,.090),(side*.079+.040,-.045,.079)],.007,'shoes','foot_'+str(side))
  else:
   for i in range(4):tube(name+'lace_'+str(i),[(side*.079-.025,-.062+i*.019,.096),(side*.079+.025,-.062+i*.019,.096)],.0019,'white','foot_'+str(side))
  if style=='runner':
   for i in range(5):tube(name+'sole_groove_'+str(i),[(side*.079-.05,-.095+i*.035,.026),(side*.079+.05,-.095+i*.035,.026)],.002,'white','foot_'+str(side))

def cap(name,z,rx=.09,ry=.08,front_limit=1.2):
 verts=[];faces=[];n=32;rows=10
 for row in range(rows+1):
  for col in range(n+1):
   a=math.tau*col/n;front=max(0,-math.sin(a));phi=.02+row/rows*(2.1-front_limit*front**5);verts.append((rx*math.sin(phi)*math.cos(a),.009+ry*math.sin(phi)*math.sin(a),z+.108*math.cos(phi)))
 for row in range(rows):
  for col in range(n):i=row*(n+1)+col;faces.append((i,i+1,i+n+2,i+n+1))
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);return finish(o,name,'hair','head')
styles=['short','sidepart','middlepart','long','ponytails_mid','ponytails_long','mullet','fringe_straight','fringe_curly','bun_low','bun_high','buzz']
for style in styles:
 name='hair_'+style+'__';cap(name+'cap',1.566,.083 if style=='buzz' else .092,.075 if style=='buzz' else .083,1.30 if style=='buzz' else 1.0)
 if style=='buzz':continue
 if style in ['short','sidepart','middlepart','fringe_straight','mullet']:
  for i in range(3):
   x=-.045+i*.040;part=abs(x)*.5 if style=='middlepart' else x*.25
   o=ell(name+'swept_lock_'+str(i),(x-.005,-.028,1.648+part*.25),(.042,.057,.022),'hair','head');o.rotation_euler.y=-.25 if style!='middlepart' else (-.30 if x<0 else .30)
 if style=='fringe_curly':
  for i in range(6):
   for j in range(3):
    x=-.065+i*.025;y=-.075+j*.031;ell(name+'curl_'+str(i)+'_'+str(j),(x,y,1.636+j*.01),(.022,.021,.022),'hair','head',12,8)
 if style in ['long','mullet']:
  for i in range(12):
   a=math.pi*i/11;x=.082*math.cos(a);y=.015+.07*math.sin(a)
   tube(name+'back_lock_'+str(i),[(x,y,1.61),(x*1.15,y,1.46),(x*1.35,y-.01,1.29 if style=='long' else 1.38)],.016,'hair','head')
 if style.startswith('ponytails'):
  for side in [-1,1]:
   length=.32 if style.endswith('long') else .21
   for i in range(6):tube(name+'tail_'+str(side)+'_'+str(i),[(side*.078,.035,1.57),(side*(.12+i*.004),.045,1.50),(side*(.12+i*.004),.065,1.57-length)],.014,'hair','head')
   ell(name+'tie_'+str(side),(side*.096,.036,1.55),(.020,.027,.024),'seam','head')
 if style.startswith('bun'):
  z=1.68 if style=='bun_high' else 1.475;y=.015 if style=='bun_high' else .078
  ell(name+'bun',(0,y,z),(.050,.047,.045),'hair','head')
  for i in range(8):
   a=i*math.tau/8;tube(name+'coil_'+str(i),[(.037*math.cos(a),y+.035*math.sin(a),z-.020),(.049*math.cos(a+.3),y+.044*math.sin(a+.3),z),(.030*math.cos(a+.6),y+.03*math.sin(a+.6),z+.035)],.003,'hair','head')

cap('hair_updo__scalp',1.566,.087,.080,1.2)
ell('hair_updo__bun',(0,.025,1.681),(.048,.046,.055),'hair','head',24,16)
for i in range(14):
 a=i*math.tau/14
 tube('hair_updo__coils_'+str(i),[(.041*math.cos(a),.025+.039*math.sin(a),1.65),(.046*math.cos(a+.4),.025+.044*math.sin(a+.4),1.69),(.027*math.cos(a+.9),.025+.025*math.sin(a+.9),1.724)],.0035,'hair','head')
for side in [-1,1]:
 for i in range(5):
  tube('hair_updo__sweep_'+str(side)+'_'+str(i),[(side*.009,-.062+i*.002,1.641),(side*.055,-.069+i*.003,1.61),(side*.076,-.035,1.56),(side*.056,-.052,1.485-i*.004)],.005-i*.00045,'hair','head')
for side in [-1,1]:
 ell('shoes_heels__toe_'+str(side),(side*.079,-.056,.045),(.042,.088,.032),'shoes','foot_'+str(side))
 box('shoes_heels__heel_'+str(side),(side*.079,.029,.036),(.025,.026,.066),'shoes','foot_'+str(side),.004)
 tube('shoes_heels__strap_'+str(side),[(side*.079-.033,0,.09),(side*.079,-.035,.105),(side*.079+.033,0,.09)],.005,'shoes','foot_'+str(side))

for style in ['cap_denim','cap_flat','straw','fedora']:
 name='headwear_'+style+'__'
 if style.startswith('cap'):
  # Structured high crown, flat visor, six panels. Never a logo or trademark.
  sections(name+'crown',[(1.590,.096,.087),(1.62,.096,.086),(1.69,.078,.069),(1.72,.034,.033),(1.724,.005,.005)],'hat','head')
  ell(name+'visor',(0,-.110,1.595),(.106,.083,.006),'hat','head')
  ell(name+'button',(0,0,1.728),(.009,.009,.006),'hat','head')
  for i in range(6):
   a=math.tau*i/6;tube(name+'panel_seam_'+str(i),[(.096*math.cos(a),.087*math.sin(a),1.595),(.080*math.cos(a),.072*math.sin(a),1.68),(.025*math.cos(a),.023*math.sin(a),1.718)],.0012,'hat','head')
  for i in range(3):tube(name+'visor_stitch_'+str(i),[(-.080,-.125-i*.01,1.601),(0,-.17-i*.006,1.602),(.080,-.125-i*.01,1.601)],.0009,'hat','head')
 else:
  ell(name+'brim',(0,0,1.594),(.163,.143,.009),'hat','head')
  sections(name+'crown',[(1.596,.095,.087),(1.67,.086,.074),(1.70,.074,.060),(1.704,.01,.01)],'hat','head')
  sections(name+'band',[(1.607,.097,.089),(1.627,.095,.086)],'seam','head')
  if style=='straw':
   for i in range(4):
    z=1.63+i*.016;r=.093-i*.004;tube(name+'weave_'+str(i),[(r*math.cos(a*math.tau/16),r*.9*math.sin(a*math.tau/16),z) for a in range(17)],.0012,'hat','head')
  else:
   tube(name+'crease',[(-.055,0,1.70),(0,0,1.677),(.055,0,1.70)],.009,'hat','head')

# A single Skeleton shared by every modular mesh; rigid segment weights keep
# clothing aligned while walking, without any change to gameplay collision.
bpy.ops.object.select_all(action='DESELECT');bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object;rig.name='CharacterRig';arm=rig.data;arm.name='Fixed170Skeleton';arm.edit_bones.remove(arm.edit_bones[0])
def bone(name,a,b,parent=None):
 o=arm.edit_bones.new(name);o.head=a;o.tail=b
 if parent:o.parent=arm.edit_bones[parent]
 return o
bone('hips',(0,0,.79),(0,0,1.01));bone('spine',(0,0,1.01),(0,0,1.36),'hips');bone('head',(0,0,1.36),(0,0,1.65),'spine')
for side in [-1,1]:
 bone('arm_'+str(side),(side*.17,0,1.30),(side*.23,0,1.08),'spine');bone('forearm_'+str(side),(side*.23,0,1.08),(side*.236,0,.84),'arm_'+str(side))
 bone('thigh_'+str(side),(side*.079,0,.82),(side*.079,0,.45),'hips');bone('shin_'+str(side),(side*.079,0,.45),(side*.079,0,.10),'thigh_'+str(side));bone('foot_'+str(side),(side*.079,0,.10),(side*.079,-.10,.045),'shin_'+str(side))
bpy.ops.object.mode_set(mode='OBJECT')
def weights(o):
 o.vertex_groups.clear();groups={n:o.vertex_groups.new(name=n) for n in arm.bones.keys()}
 def blend(v,a,b,w):
  w=max(0,min(1,w));groups[a].add([v.index],w,'REPLACE');groups[b].add([v.index],1-w,'REPLACE')
 for v in o.data.vertices:
  x,y,z=o.matrix_world@v.co;side='1' if x>0 else '-1'
  if not o.name.startswith('trousers_') and ((abs(x)>.18 and z>1.03) or (abs(x)>.19 and .72<z<=1.03)):
   if z>1.245:blend(v,'arm_'+side,'spine',(abs(x)-.145)/.065)
   else:blend(v,'arm_'+side,'forearm_'+side,(z-1.035)/.09)
  elif z<.87:
   if z>.74:blend(v,'hips','thigh_'+side,(z-.74)/.13)
   elif z<.15:blend(v,'shin_'+side,'foot_'+side,(z-.08)/.07)
   else:blend(v,'thigh_'+side,'shin_'+side,(z-.40)/.10)
  elif z>1.38:blend(v,'head','spine',(z-1.38)/.06)
  else:blend(v,'spine','hips',(z-.96)/.18)
for o,b in meshes:
 if b=='anatomy':weights(o)
 else:
  group=o.vertex_groups.new(name=b);group.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Shared character skeleton','ARMATURE');mod.object=rig;o.parent=rig
# Weld only the underlying anatomy and ordinary sewn garments, preserving facial
# details, fingers and detached sleeves. Never convert clothing to rigid segments.
groups={}
for o,b in meshes:groups.setdefault(o.name.split('__')[0],[]).append(o)
for name,objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();joined=bpy.context.object;joined.name=name
 if name=='body':
  decimate=joined.modifiers.new('Anatomy runtime budget','DECIMATE');decimate.ratio=.80;bpy.ops.object.modifier_apply(modifier=decimate.name)
 if name in ['top_tee','top_sweater','top_hoodie','top_cardigan','trousers_regular','trousers_baggy','trousers_balloon']:
  for m in list(joined.modifiers):joined.modifiers.remove(m)
  remesh=joined.modifiers.new('Continuous sewn fabric','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.005;remesh.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=remesh.name)
  smooth=joined.modifiers.new('Cloth finish','SMOOTH');smooth.factor=.5;smooth.iterations=2;bpy.ops.object.modifier_apply(modifier=smooth.name)
  decimate=joined.modifiers.new('Runtime garment budget','DECIMATE');decimate.ratio=.065;bpy.ops.object.modifier_apply(modifier=decimate.name)
  weights(joined);mod=joined.modifiers.new('Shared character skeleton','ARMATURE');mod.object=rig
rig.animation_data_create()
for name,count in [('walk',25),('idle',61)]:
 action=bpy.data.actions.new(name);rig.animation_data.action=action
 for f in range(1,count+1):
  phase=(f-1)/(count-1)*math.tau
  for b in rig.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
  if name=='walk':
   for side in [-1,1]:
    step=math.sin(phase)*side;rig.pose.bones['thigh_'+str(side)].rotation_euler.x=step*.34;rig.pose.bones['shin_'+str(side)].rotation_euler.x=-max(0,-step)*.42;rig.pose.bones['arm_'+str(side)].rotation_euler.x=-step*.25;rig.pose.bones['forearm_'+str(side)].rotation_euler.x=-.07
   rig.pose.bones['hips'].location.y=abs(math.sin(phase))*.012
  else:rig.pose.bones['spine'].rotation_euler.x=math.sin(phase)*.006
  for b in rig.pose.bones:b.keyframe_insert('rotation_euler',frame=f);b.keyframe_insert('location',frame=f)
 track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action)
rig.animation_data.action=None
bpy.context.scene.frame_set(1);bpy.context.scene.render.fps=24
triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
sources=project/'art_sources';sources.mkdir(exist_ok=True);(sources/'.gdignore').touch()
bpy.ops.wm.save_as_mainfile(filepath=str(sources/'character_modular.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(out/'character.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_yup=True,export_apply=False)
record={'version':1,'license':'CC0-1.0 original artwork','blender_version':bpy.app.version_string,'height_reference_metres':1.70,'rig':'standard_170','body_editable':False,'mesh_objects':len(groups),'all_variant_triangles':triangles,'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'glb_sha256':hashlib.sha256((out/'character.glb').read_bytes()).hexdigest(),'source_blend_sha256':hashlib.sha256((sources/'character_modular.blend').read_bytes()).hexdigest(),'animations':['idle','walk'],'reference':'User-supplied Madison Beer outfit image; original mesh interpretation, not an official game asset. No image texture copied.', 'prompt':'Anatomical adult female character, sculpted jaw and cheeks, tapered limbs, defined hands with separate fingers; folded grey bandeau mini dress, detached sleeves with ribbons, dark tights, heels and brunette updo. Original adult character with a fixed regular 1.70 m build, naturally proportioned face, customizable skin, hair, eyes, lips and smile. Modular casual wardrobe: plain shirts, loose knitwear, regular, baggy and balloon trousers, denim and structured flat-brim caps, straw and felt hats, generic unbranded shoes. One shared skeleton and no garment colliders.','negative_prompt':'logos, brand names, sports team emblems, copied textures, variable body scaling, oversized cartoon head, downloaded models','external_models_or_images':False}
(out/'manifest.json').write_text(json.dumps(record,indent=2)+'\n');print('CHARACTER_3D_COMPLETE',json.dumps(record),flush=True)
