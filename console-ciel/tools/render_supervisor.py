"""Original adult school supervisor, modelled and rendered locally in Blender.
blender -b -t 6 --python tools/render_supervisor.py -- --project . --output /tmp/supervisor
Units are metres. No downloaded mesh, photograph, provider or external dependency.
"""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector

p = argparse.ArgumentParser()
p.add_argument('--project', required=True)
p.add_argument('--output', required=True)
args = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
project, out = Path(args.project).resolve(), Path(args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
materials = {}

def material(name, color, roughness=.6, knit=False):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    n, links = m.node_tree.nodes, m.node_tree.links
    bsdf = n.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    if knit:
        coord = n.new('ShaderNodeTexCoord')
        tex = n.new('ShaderNodeTexNoise')
        tex.inputs['Scale'].default_value = 170
        tex.inputs['Detail'].default_value = 2
        links.new(coord.outputs['Generated'], tex.inputs['Vector'])
        bump = n.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .22
        bump.inputs['Distance'].default_value = .006
        links.new(tex.outputs['Fac'], bump.inputs['Height'])
        links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
        bsdf.inputs['Sheen Weight'].default_value = .22
    materials[name] = m

for values in [
    ('skin', (.70, .43, .29), .6), ('cheek', (.66, .30, .23), .7),
    ('lip', (.38, .105, .09), .65), ('hair', (.42, .235, .063), .42),
    ('hair_light', (.69, .43, .14), .45), ('hair_dark', (.28, .145, .043), .52),
    ('sweater', (.34, .46, .51), .88, True), ('rib', (.26, .36, .41), .88, True),
    ('trousers', (.045, .065, .085), .85, True), ('shoe', (.66, .67, .62), .72),
    ('sole', (.29, .33, .34), .75), ('white', (.84, .84, .77), .5),
    ('eye', (.14, .27, .24), .35), ('pupil', (.012, .016, .018), .35),
    ('badge', (.61, .69, .68), .6), ('metal', (.45, .43, .32), .24)
]: material(*values)

def empty(name, at=(0,0,0), parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    o.location = at
    o.parent = parent
    return o

root = empty('Adult supervisor · 1.60 m')
root.scale = (1.03, 1.03, 1.03)

def ellipsoid(name, at, radii, mat, parent=root):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=(0,0,0))
    o = bpy.context.object
    o.name = name
    o.parent, o.location, o.scale = parent, at, radii
    o.data.materials.append(materials[mat])
    for face in o.data.polygons: face.use_smooth = True
    return o

def tube(name, points, radius, mat, parent=root):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.bevel_depth, data.bevel_resolution = radius, 3
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for q, co in zip(spline.bezier_points, points):
        q.co = co
        q.handle_left_type = q.handle_right_type = 'AUTO'
    o = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    data.materials.append(materials[mat])
    return o

def rings(name, sections, mat, parent=root):
    # Elliptical cross-sections form continuous tailored surfaces, not cubes.
    vertices, faces, count = [], [], 48
    for z, rx, ry, cy in sections:
        for i in range(count):
            angle = math.tau*i/count
            vertices.append((rx*math.cos(angle), cy+ry*math.sin(angle), z))
    for k in range(len(sections)-1):
        for i in range(count):
            a = k*count+i
            faces.append((a,k*count+(i+1)%count,(k+1)*count+(i+1)%count,a+count))
    faces.extend([tuple(reversed(range(count))),tuple((len(sections)-1)*count+i for i in range(count))])
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(materials[mat])
    o = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    for poly in data.polygons: poly.use_smooth = True
    mod = o.modifiers.new('Soft garment surface', 'SUBSURF')
    mod.levels = 2
    return o

# An opaque, oversized jumper with a modest natural bust under loose fabric.
rings('Loose knitted jumper', [(.69,.145,.095,0),(.71,.16,.105,0),(.77,.165,.11,0),
    (.88,.154,.115,-.002),(1.00,.166,.126,-.009),(1.09,.18,.122,-.009),
    (1.16,.178,.103,0),(1.20,.13,.08,0),(1.22,.063,.06,0)], 'sweater')
rings('Wide ribbed hem', [(.69,.145,.093,0),(.71,.152,.102,0),(.75,.154,.103,0)], 'rib')
for i in range(54):
    a=math.tau*i/54
    tube('Hem stitch',[(.150*math.cos(a),.102*math.sin(a),.70),(.154*math.cos(a),.104*math.sin(a),.743)],.0013,'sweater')
ellipsoid('Neck',(0,0,1.245),(.052,.047,.085),'skin')
rings('Soft folded crew neck', [(1.196,.065,.061,0),(1.215,.071,.062,0),(1.238,.061,.053,0)],'rib')
for side in [-1,1]:
    for i in range(3):
        x=side*(.065+i*.025)
        tube('Jumper drape',[(x,-.103,.76),(x+side*.008,-.117,.84),(x+side*.015,-.119,.88)],.0015,'rib')

legs, arms = [], []
for side in [-1,1]:
    leg=empty('Leg joint '+str(side),(side*.077,0,.75),root)
    legs.append(leg)
    rings('Slim trouser leg',[(-.66,.036,.04,0),(-.62,.038,.042,0),(-.39,.046,.047,0),(-.32,.055,.051,0),(-.08,.065,.065,0),(0,.066,.069,0)],'trousers',leg)
    tube('Trouser seam',[(side*.04,.01,-.65),(side*.05,.015,-.37),(side*.062,.025,-.09)],.0018,'rib',leg)
    ellipsoid('Sneaker sole',(0,-.027,-.719),(.047,.099,.023),'sole',leg)
    ellipsoid('Canvas sneaker',(0,-.031,-.692),(.044,.092,.035),'shoe',leg)
    for z in range(3):
        y=-.047+z*.018
        tube('Lace',[(-.024,y,-.659),(.024,y,-.659)],.002,'white',leg)
    arm=empty('Sleeve joint '+str(side),(side*.168,0,1.13),root)
    arm.rotation_euler.y=-side*.10
    arms.append(arm)
    rings('Dropped shoulder sleeve',[(-.39,.042,.045,0),(-.36,.052,.053,0),(-.25,.063,.059,0),(-.10,.069,.064,0),(.02,.065,.064,0),(.06,.035,.04,0)],'sweater',arm)
    rings('Ribbed cuff',[(-.40,.038,.04,0),(-.38,.043,.044,0),(-.35,.046,.047,0)],'rib',arm)
    ellipsoid('Hand',(0,-.004,-.432),(.027,.022,.044),'skin',arm)
    ellipsoid('Thumb',(-side*.024,-.014,-.418),(.011,.014,.026),'skin',arm)

head=empty('Head',(0,0,1.438),root)
# Chin narrows into a jaw, with cheeks kept separate from the eyes and brows.
rings('Face',[(-.122,.016,.025,-.023),(-.112,.043,.045,-.018),(-.084,.066,.060,-.005),
    (-.025,.080,.070,0),(.037,.082,.072,.004),(.086,.067,.061,.009),(.104,.033,.036,.01)],'skin',head)
for side in [-1,1]:
    ellipsoid('Ear',(side*.079,0,-.025),(.012,.014,.025),'skin',head)
    ellipsoid('Eye white',(side*.032,-.066,.002),(.018,.008,.009),'white',head)
    ellipsoid('Iris',(side*.032,-.073,.002),(.006,.0028,.006),'eye',head)
    ellipsoid('Pupil',(side*.032,-.075,.002),(.0028,.001,.0038),'pupil',head)
    ellipsoid('Eye catchlight',(side*.032-.0015,-.076,.004),(.0013,.001,.0014),'white',head)
    tube('Upper eyelid',[(side*.015,-.070,.007),(side*.032,-.075,.012),(side*.049,-.066,.005)],.0016,'hair_dark',head)
    tube('Eyebrow',[(side*.016,-.070,.027),(side*.032,-.073,.031),(side*.053,-.060,.025)],.0030,'hair_dark',head)
    ellipsoid('Cheek',(side*.046,-.059,-.030),(.017,.005,.009),'skin',head)
    ellipsoid('Small earring',(side*.081,-.006,-.045),(.004,.004,.005),'metal',head)
ellipsoid('Nose bridge',(0,-.070,-.013),(.009,.013,.027),'skin',head)
ellipsoid('Nose tip',(0,-.081,-.033),(.013,.014,.009),'skin',head)
tube('Upper lip',[(-.022,-.064,-.063),(-.007,-.071,-.066),(0,-.072,-.064),(.007,-.071,-.066),(.022,-.064,-.063)],.0025,'lip',head)
tube('Soft lower lip',[(-.017,-.066,-.067),(0,-.072,-.071),(.017,-.066,-.067)],.0032,'cheek',head)

# Shoulder-length golden blonde hair. A partial cap leaves the entire face open.
vertices,faces=[],[]
for row in range(17):
    t=row/16
    for col in range(65):
        a=math.tau*col/64
        front=max(0,-math.sin(a))
        limit=2.45-1.32*front**5
        phi=.04+t*limit
        vertices.append((.09*math.sin(phi)*math.cos(a),.011+.083*math.sin(phi)*math.sin(a),.006+.115*math.cos(phi)))
for row in range(16):
    for col in range(64):
        k=row*65+col;faces.append((k,k+1,k+66,k+65))
data=bpy.data.meshes.new('Parted hair cap');data.from_pydata(vertices,[],faces);data.materials.append(materials['hair'])
o=bpy.data.objects.new('Parted hair cap',data);bpy.context.collection.objects.link(o);o.parent=head
for face in data.polygons:face.use_smooth=True
for side in [-1,1]:
    for i in range(13):
        f=i/12
        tube('Blonde shoulder lock',[(side*(.015+f*.040),.015+f*.035,.106-f*.017),
             (side*(.074+f*.012),-.020+f*.052,.041),
             (side*(.085+f*.010),-.007+f*.047,-.058),
             (side*(.105+f*.008),-.012+f*.041,-.148),
             (side*(.099+f*.008),-.006+f*.034,-.190+f*.017)],.008,'hair_light' if i%3==0 else 'hair',head)
    for i in range(5):
        tube('Side swept fringe',[(.012,-.025,.111),(side*(.028+i*.007),-.059,.077),(side*(.071+i*.002),-.052,.028-i*.008)],.006,'hair_light' if i%2==0 else 'hair',head)

# Small work badge, not a uniform jacket.
tube('Badge lanyard',[(-.033,-.06,1.215),(-.014,-.138,1.02),(.046,-.137,1.01),(.033,-.06,1.215)],.003,'rib')
ellipsoid('Staff badge',(.026,-.140,.984),(.029,.006,.035),'badge')
ellipsoid('Badge photo',(.020,-.147,.992),(.009,.001,.011),'white')
for z in [.975,.964]:tube('Badge lettering',[(.012,-.148,z),(.040,-.148,z)],.0015,'rib')

s=bpy.context.scene
s.unit_settings.system='METRIC'
s.render.engine='CYCLES'
s.cycles.device='CPU'
s.cycles.samples=128
s.cycles.use_denoising=False
s.cycles.max_bounces=4
s.render.resolution_x,s.render.resolution_y=256,448
s.render.resolution_percentage=100
s.render.film_transparent=True
s.render.image_settings.file_format='PNG'
s.render.image_settings.color_mode='RGBA'
s.view_settings.view_transform='AgX'
s.view_settings.look='AgX - Medium High Contrast'
s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.73,.79,.88,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
for name,at,power,size in [('Soft window',(-2,-3,4),250,3),('Fill',(2,-1,2),110,2.5),('Hair rim',(0,2,3),220,2)]:
    bpy.ops.object.light_add(type='AREA',location=at)
    o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size
    o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-5,2.03))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,.80))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=1.78;s.camera=camera
s.render.fps=10;s.frame_start=1;s.frame_end=9
for frame in range(9):
    phase=math.tau*(frame-1)/8
    root.rotation_euler.z=-.10 if frame==0 else math.radians(72)
    root.location.z=0 if frame==0 else .012*abs(math.sin(phase))
    root.keyframe_insert('rotation_euler',frame=frame+1)
    root.keyframe_insert('location',frame=frame+1)
    for i,(leg,arm) in enumerate(zip(legs,arms)):
        step=0 if frame==0 else math.sin(phase+i*math.pi)
        leg.rotation_euler.x=.28*step
        arm.rotation_euler.x=-.20*step
        leg.keyframe_insert('rotation_euler',frame=frame+1)
        arm.keyframe_insert('rotation_euler',frame=frame+1)
s.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'surveillante.blend'),compress=True)
atlas=np.zeros((448,256*9,4),dtype=np.float32)
for frame in range(9):
    s.frame_set(frame+1)
    s.render.filepath=str(out/f'frame_{frame:02}.png')
    bpy.ops.render.render(write_still=True)
    im=bpy.data.images.load(s.render.filepath,check_existing=False)
    pixels=np.empty(448*256*4,dtype=np.float32);im.pixels.foreach_get(pixels)
    atlas[:,frame*256:(frame+1)*256,:]=pixels.reshape(448,256,4)
    bpy.data.images.remove(im)
    print('SUPERVISOR_FRAME',frame,flush=True)
im=bpy.data.images.new('Supervisor sprites',width=256*9,height=448,alpha=True)
im.pixels.foreach_set(atlas.ravel())
im.filepath_raw=str(out/'supervisor.png');im.file_format='PNG';im.save()
manifest={'version':1,'blender_version':bpy.app.version_string,'license':'CC0-1.0 original artwork',
    'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'sprite_sha256':hashlib.sha256((out/'supervisor.png').read_bytes()).hexdigest(),
    'blend_sha256':hashlib.sha256((out/'surveillante.blend').read_bytes()).hexdigest(),
    'frame_size':[256,448],'frame_count':9,'idle_frame':0,'walk_frames':list(range(1,9)),
    'height_reference_metres':1.60,'build_reference':'slim adult woman; approximate 55 kg visual reference, not a physical mass simulation',
    'prompt':'Adult school supervisor, slender build, about 1.60 m, golden blonde shoulder-length hair, naturally proportioned face, modest natural bust under a completely opaque oversized blue-grey knitted sweater, slim dark trousers, pale sneakers, small work badge. Friendly and professional. Front idle and right walking cycle.',
    'negative_prompt':'child, giant chibi head, uniform jacket, revealing or tight clothing, exaggerated anatomy, external copyrighted models',
    'runtime':'Orthographic RGBA sprite atlas; no runtime Blender or 3D dependency.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('SUPERVISOR_COMPLETE',flush=True)
