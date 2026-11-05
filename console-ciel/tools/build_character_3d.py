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
for name,color,rough in [('skin',(.55,.31,.19),.6),('hair',(.16,.075,.034),.8),('eyes',(.12,.24,.30),.4),('lips',(.40,.16,.14),.62),('top',(.13,.25,.40),.88),('trousers',(.045,.06,.085),.9),('hat',(.25,.40,.52),.9),('socks',(.8,.8,.74),.9),('shoes',(.7,.71,.67),.6),('white',(.85,.86,.82),.5),('pupil',(.009,.012,.016),.45),('seam',(.12,.16,.18),.85),('metal',(.42,.43,.41),.3)]:
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

# Shared anatomy: never rescaled by outfit choices.
ell('body__neck',(0,0,1.406),(.047,.044,.073),'skin','head')
sections('body__face',[(1.427,.018,.022),(1.44,.044,.040),(1.465,.067,.058),(1.52,.079,.068),(1.58,.081,.070),(1.626,.065,.058),(1.65,.030,.030)],'skin','head',cy=-.005)
for side in [-1,1]:
 ell('body__ear_'+str(side),(side*.080,0,1.52),(.012,.017,.025),'skin','head')
 ell('body__hand_'+str(side),(side*.236,-.014,.833),(.030,.025,.050),'skin','forearm_'+str(side))
 ell('body__thumb_'+str(side),(side*.213,-.028,.843),(.013,.017,.027),'skin','forearm_'+str(side))
 sections('body__arm_'+str(side),[(.86,.027,.026),(.95,.034,.032),(1.08,.040,.037),(1.18,.043,.041),(1.30,.047,.047)],'skin','arm_'+str(side),cx=side*.229)
ell('body__nose_bridge',(0,-.072,1.522),(.010,.016,.029),'skin','head')
ell('body__nose_tip',(0,-.085,1.503),(.014,.014,.009),'skin','head')
for style,height,width in [('almond',.009,.018),('round',.012,.016),('soft',.0075,.019)]:
 for side in [-1,1]:
  x=side*.033
  ell('eyes_'+style+'__white_'+str(side),(x,-.070,1.548),(width,.009,height),'white','head')
  ell('eyes_'+style+'__iris_'+str(side),(x,-.078,1.548),(.006,.0028,height*.78),'eyes','head')
  ell('eyes_'+style+'__pupil_'+str(side),(x,-.0805,1.548),(.0028,.0015,height*.62),'pupil','head')
  ell('eyes_'+style+'__spark_'+str(side),(x-.002,-.0815,1.551),(.0015,.001,.0016),'white','head',12,8)
  tube('eyes_'+style+'__lid_'+str(side),[(x-width,-.068,1.55),(x,-.077,1.548+height),(x+width,-.068,1.55)],.0015,'hair','head')
for side in [-1,1]:tube('body__brow_'+str(side),[(side*.017,-.068,1.575),(side*.033,-.071,1.580),(side*.053,-.058,1.574)],.003,'hair','head')
for style,lift in [('neutral',0),('soft',.004),('wide',.010)]:
 tube('smile_'+style+'__upper',[(-.024,-.061,1.474+lift),(-.008,-.072,1.473),(0,-.073,1.476),(.008,-.072,1.473),(.024,-.061,1.474+lift)],.003,'lips','head')
 tube('smile_'+style+'__lower',[(-.023,-.061,1.473+lift),(0,-.074,1.468),(.023,-.061,1.473+lift)],.0035,'lips','head')

for style,amp,hem in [('tee',1,.925),('sweater',1.10,.90),('hoodie',1.14,.89),('cardigan',1.08,.91)]:
 name='top_'+style+'__'
 sections(name+'torso',[(hem,.153*amp,.101*amp),(hem+.035,.160*amp,.108*amp),(1.08,.161*amp,.106*amp),(1.23,.182*amp,.120*amp),(1.31,.184*amp,.106*amp),(1.36,.135,.075),(1.38,.059,.053)],'top')
 sections(name+'collar',[(1.364,.062,.056),(1.385,.060,.054)],'top')
 for side in [-1,1]:
  bone='arm_'+str(side)
  if style=='tee':
   sections(name+'sleeve_'+str(side),[(1.145,.052,.054),(1.20,.059,.062),(1.29,.065,.067),(1.325,.038,.040)],'top',bone,cx=side*.208)
  else:
   sections(name+'sleeve_'+str(side),[(.865,.042,.044),(.90,.052*amp,.052*amp),(1.05,.056*amp,.057*amp),(1.15,.061*amp,.061*amp),(1.29,.064*amp,.068*amp),(1.325,.038,.040)],'top',bone,cx=side*.222)
   sections(name+'cuff_'+str(side),[(.861,.044,.046),(.889,.046,.049)],'top','forearm_'+str(side),cx=side*.232)
 if style!='tee':
  for i in range(32):
   a=math.tau*i/32;tube(name+'hem_rib_'+str(i),[(.159*amp*math.cos(a),.108*amp*math.sin(a),hem+.005),(.159*amp*math.cos(a),.108*amp*math.sin(a),hem+.026)],.0013,'top')
 if style=='hoodie':
  ell(name+'hood',(0,.063,1.349),(.102,.074,.101),'top')
  for side in [-1,1]:tube(name+'drawstring_'+str(side),[(side*.047,-.092,1.33),(side*.038,-.128,1.18)],.003,'white')
  tube(name+'pocket',[(-.101,-.117,1.015),(-.065,-.132,1.08),(.065,-.132,1.08),(.101,-.117,1.015)],.002,'top')
 if style=='cardigan':
  tube(name+'zip',[(0,-.111,.94),(0,-.122,1.20),(0,-.061,1.37)],.0025,'metal')
  ell(name+'zip_pull',(0,-.126,1.18),(.005,.003,.012),'metal')

for style,width in [('regular',1),('baggy',1.42),('balloon',1.6)]:
 name='trousers_'+style+'__'
 sections(name+'waist',[(.79,.147,.092),(.90,.151,.103),(.95,.149,.101)],'trousers','hips')
 for side in [-1,1]:
  if style=='balloon':upper=[(.44,.090,.085),(.57,.107,.095),(.75,.105,.095),(.84,.080,.084)]
  else:upper=[(.44,.054*width,.055*width),(.61,.065*width,.063*width),(.83,.077*width,.079*width)]
  lower=[(.115,.046,.048),(.18,.059,.061),(.34,.096,.084),(.45,.09,.085)] if style=='balloon' else [(.115,.041*width,.045*width),(.28,.046*width,.047*width),(.46,.054*width,.055*width)]
  sections(name+'leg_'+str(side),lower[:-1]+upper,'trousers','thigh_'+str(side),cx=side*.079)
  tube(name+'seam_'+str(side),[(side*(.079+.04*width),0,.15),(side*(.079+.048*width),0,.31),(side*(.079+.053*width),0,.43)],.0012,'trousers','shin_'+str(side))

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
for o,b in meshes:
 group=o.vertex_groups.new(name=b)
 if b.startswith('thigh_') or b.startswith('arm_'):
  other=o.vertex_groups.new(name=b.replace('thigh_','shin_') if b.startswith('thigh_') else b.replace('arm_','forearm_'))
  pivot=.45 if b.startswith('thigh_') else 1.085
  span=.085 if b.startswith('thigh_') else .065
  for v in o.data.vertices:
   z=(o.matrix_world@v.co).z;weight=max(0,min(1,(z-pivot+span)/(span*2)));group.add([v.index],weight,'REPLACE');other.add([v.index],1-weight,'REPLACE')
 else:group.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Shared character skeleton','ARMATURE');mod.object=rig;o.parent=rig
# Batch every garment/hair variant into one skinned mesh, preserving bone groups.
# Only the chosen variants are visible at runtime: no hundreds of draw objects.
triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o,b in meshes)
groups={}
for o,b in meshes:groups.setdefault(o.name.split('__')[0],[]).append(o)
for name,objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();joined=bpy.context.object;joined.name=name
 if name.startswith('top_'):
  # Fuse sleeves and shoulders into a single soft garment, then restore the
  # same rig weights. This avoids separate ball-like shoulder pieces.
  for m in list(joined.modifiers):joined.modifiers.remove(m)
  remesh=joined.modifiers.new('Continuous cloth','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.009;remesh.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=remesh.name)
  smooth=joined.modifiers.new('Soft cloth folds','SMOOTH');smooth.factor=.8;smooth.iterations=3;bpy.ops.object.modifier_apply(modifier=smooth.name)
  decimate=joined.modifiers.new('Bounded garment detail','DECIMATE');decimate.ratio=.12;bpy.ops.object.modifier_apply(modifier=decimate.name)
  joined.vertex_groups.clear()
  bones={name_:joined.vertex_groups.new(name=name_) for name_ in ['spine','arm_-1','arm_1','forearm_-1','forearm_1']}
  for v in joined.data.vertices:
   co=joined.matrix_world@v.co
   if abs(co.x)<.16:bones['spine'].add([v.index],1,'REPLACE')
   else:
    side=1 if co.x>0 else -1;blend=max(0,min(1,(co.z-1.02)/.13));bones['arm_'+str(side)].add([v.index],blend,'REPLACE');bones['forearm_'+str(side)].add([v.index],1-blend,'REPLACE')
  mod=joined.modifiers.new('Shared character skeleton','ARMATURE');mod.object=rig
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
record={'version':1,'license':'CC0-1.0 original artwork','blender_version':bpy.app.version_string,'height_reference_metres':1.70,'rig':'standard_170','body_editable':False,'mesh_objects':len(groups),'all_variant_triangles':triangles,'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'glb_sha256':hashlib.sha256((out/'character.glb').read_bytes()).hexdigest(),'source_blend_sha256':hashlib.sha256((sources/'character_modular.blend').read_bytes()).hexdigest(),'animations':['idle','walk'],'prompt':'Original adult character with a fixed regular 1.70 m build, naturally proportioned face, customizable skin, hair, eyes, lips and smile. Modular casual wardrobe: plain shirts, loose knitwear, regular, baggy and balloon trousers, denim and structured flat-brim caps, straw and felt hats, generic unbranded shoes. One shared skeleton and no garment colliders.','negative_prompt':'logos, brand names, sports team emblems, copied textures, variable body scaling, oversized cartoon head, downloaded models','external_models_or_images':False}
(out/'manifest.json').write_text(json.dumps(record,indent=2)+'\n');print('CHARACTER_3D_COMPLETE',json.dumps(record),flush=True)
