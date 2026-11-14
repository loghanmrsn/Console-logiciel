"""Original compact human/rabbit, reusing the project's wardrobe and animation rig.

blender -b -t 4 --python tools/build_compact_characters.py -- --project .
The adult source is read only. Each output has its own authored bind pose;
runtime bone scaling is never used. Geometry is in metres, feet at ground level.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
project = Path(args.project).resolve()
source = project / 'art_sources/character_modular.blend'
out = project / 'assets/character3d/compact'
out.mkdir(parents=True, exist_ok=True)
records = []


def height(z):
    if z <= .77:
        return z * (.30 / .77)
    if z <= 1.43:
        return .30 + (z - .77) * (.35 / .66)
    return .65 + (z - 1.43) * (1.85)


def reshape(v):
    x, y, z = v
    # Smooth neck-to-head transition; a broad head and short, sturdy limbs.
    t = max(0, min(1, (z - 1.38) / .10))
    t = t * t * (3 - 2 * t)
    width = .90 + 1.80 * t
    return Vector((x * width, y * width, height(z)))


for style in ['classic', 'human', 'rabbit']:
    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
    mats = {m.name: m for m in bpy.data.materials}
    extra = []
    detail_offset = 0

    def finish(o, name, material, bone):
        o.name = name
        o.data.materials.append(mats[material])
        for p in o.data.polygons:
            p.use_smooth = True
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        if bone == 'head' and detail_offset:
            for vertex in o.data.vertices:
                vertex.co.z += detail_offset
        o.select_set(False)
        group = o.vertex_groups.new(name=bone)
        group.add(list(range(len(o.data.vertices))), 1, 'REPLACE')
        o.parent = rig
        mod = o.modifiers.new('Shared rig', 'ARMATURE')
        mod.object = rig
        extra.append(o)
        return o

    def ell(name, at, size, material, bone='head', rotation=0):
        bpy.ops.object.select_all(action='DESELECT')
        bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=at)
        o = bpy.context.object
        o.scale = size
        o.rotation_euler.y = rotation
        return finish(o, name, material, bone)

    def tube(name, points, radius, material, bone='head'):
        d = bpy.data.curves.new(name, 'CURVE')
        d.dimensions = '3D'
        d.resolution_u = 2
        d.bevel_depth = radius
        d.bevel_resolution = 1
        spline = d.splines.new('BEZIER')
        spline.bezier_points.add(len(points) - 1)
        for q, co in zip(spline.bezier_points, points):
            q.co = co
            q.handle_left_type = q.handle_right_type = 'AUTO'
        o = bpy.data.objects.new(name, d)
        bpy.context.collection.objects.link(o)
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target='MESH')
        return finish(bpy.context.object, name, material, bone)

    def box(name, at, size, material, bone='spine'):
        bpy.ops.object.select_all(action='DESELECT')
        bpy.ops.mesh.primitive_cube_add(size=1, location=at)
        o = bpy.context.object
        o.dimensions = size
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bevel = o.modifiers.new('Soft corners', 'BEVEL')
        bevel.width = min(size) * .22
        bevel.segments = 3
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        return finish(o, name, material, bone)

    # Accessories are authored once at the adult scale, then fitted with the rig.
    for material, color in [('accessory', (.66, .08, .08)), ('fur', (.85, .83, .75)), ('tail_fur', (.85, .83, .75)), ('inner_ear', (.72, .39, .40))]:
        m = bpy.data.materials.new(material)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = (*color, 1)
        bsdf.inputs['Roughness'].default_value = .85
        mats[material] = m
    # A scarf, a pocketed rucksack and round glasses are separate equippable items.
    tube('accessory_scarf__collar', [(math.cos(i*math.tau/24)*.064, math.sin(i*math.tau/24)*.061, 1.39) for i in range(25)], .022, 'accessory', 'spine')
    ribbon_points = [(0, .08, 1.39), (-.10, .10, 1.31), (-.22, .08, 1.20), (-.32, .06, 1.18)]
    ribbon_vertices = [(x, y+dy, z+dz) for x,y,z in ribbon_points for dy,dz in [(-.009,-.035),(.009,-.035),(.009,.035),(-.009,.035)]]
    ribbon_faces = [(i*4+j,i*4+(j+1)%4,(i+1)*4+(j+1)%4,(i+1)*4+j) for i in range(3) for j in range(4)]
    ribbon_faces += [(3,2,1,0),(12,13,14,15)]
    ribbon_mesh=bpy.data.meshes.new('Scarf ribbon');ribbon_mesh.from_pydata(ribbon_vertices,[],ribbon_faces)
    ribbon=bpy.data.objects.new('accessory_scarf__tail',ribbon_mesh);bpy.context.collection.objects.link(ribbon)
    finish(ribbon,'accessory_scarf__tail','accessory','spine')
    box('accessory_backpack__bag', (0, .154, 1.11), (.25, .12, .30), 'accessory')
    box('accessory_backpack__pocket', (0, .218, 1.06), (.18, .028, .12), 'accessory')
    for side in [-1, 1]:
        tube('accessory_backpack__strap', [(side*.11, .12, 1.29), (side*.12, -.065, 1.31), (side*.12, -.125, 1.12), (side*.11, .12, .99)], .012, 'accessory', 'spine')
        tube('accessory_glasses__rim', [(side*.034 + math.cos(i*math.tau/24)*.026, -.077, 1.548 + math.sin(i*math.tau/24)*.022) for i in range(25)], .0025, 'accessory')
        tube('accessory_glasses__temple', [(side*.061, -.077, 1.55), (side*.083, .025, 1.55)], .002, 'accessory')
    tube('accessory_glasses__bridge', [(-.009, -.077, 1.55), (0, -.08, 1.556), (.009, -.077, 1.55)], .002, 'accessory')

    if style != 'classic':
        # Replace the adult face entirely instead of enlarging its fine details.
        for o in list(bpy.context.scene.objects):
            if o.type != 'MESH':
                continue
            if o.name.startswith(('eyes_', 'smile_')):
                bpy.data.objects.remove(o, do_unlink=True)
                continue
            if o.name == 'body':
                bm = bmesh.new()
                bm.from_mesh(o.data)
                cut=[]
                for vertex in bm.verts:
                    x,y,z=o.matrix_world @ vertex.co
                    if z>1.43 or (style=='rabbit' and abs(x)>.185 and .72<z<.855):cut.append(vertex)
                bmesh.ops.delete(bm, geom=cut, context='VERTS')
                bm.to_mesh(o.data)
                bm.free()
            matrix = o.matrix_world.copy()
            points = [reshape(matrix @ v.co) for v in o.data.vertices]
            o.matrix_world = Matrix.Identity(4)
            for vertex, point in zip(o.data.vertices, points):
                vertex.co = point
        bpy.ops.object.select_all(action='DESELECT')
        rig.select_set(True)
        bpy.context.view_layer.objects.active = rig
        bpy.ops.object.mode_set(mode='EDIT')
        for bone in rig.data.edit_bones:
            bone.head = reshape(bone.head)
            bone.tail = reshape(bone.tail)
        bpy.ops.object.mode_set(mode='OBJECT')
        detail_offset = -.29
        skin = 'fur' if style == 'rabbit' else 'skin'
        ell('body__round_head', (0, -.005, 1.165), (.211, .183, .223), skin)
        if style == 'rabbit':
            for o in bpy.context.scene.objects:
                if o.type == 'MESH' and o.name == 'body':
                    for slot in o.material_slots:
                        if slot.material and slot.material.name == 'skin':
                            slot.material = mats['fur']
            for side in [-1, 1]:
                ell('body__ear', (side*.126, .01, 1.475), (.057, .046, .22), 'fur', rotation=side*.12)
                ell('body__ear_inset', (side*.127, -.033, 1.49), (.032, .010, .15), 'inner_ear', rotation=side*.12)
                ell('body__muzzle', (side*.04, -.175, 1.075), (.065, .035, .047), 'fur')
            ell('body__nose', (0, -.21, 1.105), (.021, .014, .015), 'lips')
            ell('body__tail', (0, .14, .36), (.065, .065, .065), 'tail_fur', 'hips')
            for side in [-1,1]:
                ell('body__paw', reshape((side*.235,-.006,.80)), (.028,.026,.040), 'fur', 'forearm_'+str(side))
            # Soft paws for the free footwear, with the other purchased shoes retained.
            for o in list(bpy.context.scene.objects):
                if o.type=='MESH' and o.name=='shoes_canvas':bpy.data.objects.remove(o,do_unlink=True)
            for side in [-1,1]:
                ell('shoes_canvas__paw', (side*.071,-.035,.030), (.048,.075,.030), 'shoes', 'foot_'+str(side))
        else:
            for side in [-1, 1]:
                ell('body__ear', (side*.211, .0, 1.16), (.029, .025, .047), 'skin')
                tube('body__eyebrow', [(side*.045, -.172, 1.26), (side*.09, -.168, 1.274), (side*.132, -.141, 1.26)], .008, 'hair')
            ell('body__nose', (0, -.185, 1.125), (.029, .025, .027), 'skin')
        for eye_style, width, tall in [('almond', .031, .040), ('round', .035, .044), ('soft', .033, .031)]:
            for side in [-1, 1]:
                x = side * .083
                ell('eyes_'+eye_style+'__outline', (x, -.177, 1.185), (width+.005, .012, tall+.005), 'pupil')
                ell('eyes_'+eye_style+'__iris', (x, -.188, 1.185), (width*.79, .007, tall*.85), 'eyes')
                ell('eyes_'+eye_style+'__pupil', (x, -.194, 1.187), (width*.48, .004, tall*.67), 'pupil')
                ell('eyes_'+eye_style+'__shine', (x-.009, -.199, 1.204), (.008, .003, .009), 'white')
        for smile, lift in [('soft', .008), ('wide', .020), ('neutral', 0)]:
            tube('smile_'+smile+'__mouth', [(-.035, -.176, 1.055+lift), (0, -.19, 1.050), (.035, -.176, 1.055+lift)], .0045, 'lips')
        # Glasses sit in front of the new large eyes, with no opaque lens.
        for o in list(bpy.context.scene.objects):
            if o.type == 'MESH' and o.name.startswith('accessory_glasses'):
                bpy.data.objects.remove(o, do_unlink=True)
        for side in [-1, 1]:
            tube('accessory_glasses__rim', [(side*.083+math.cos(i*math.tau/32)*.057, -.213, 1.185+math.sin(i*math.tau/32)*.058) for i in range(33)], .006, 'accessory')
            tube('accessory_glasses__temple', [(side*.14, -.213, 1.20), (side*.215, .015, 1.20)], .005, 'accessory')
        tube('accessory_glasses__bridge', [(-.027, -.213, 1.195), (0, -.22, 1.205), (.027, -.213, 1.195)], .005, 'accessory')

    groups = {}
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            groups.setdefault(o.name.split('__')[0], []).append(o)
    for name, objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        bpy.context.object.name = name
    bpy.context.scene.frame_set(1)
    target = out / (style + '.glb')
    bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', export_animations=True, export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True, export_apply=False)
    triangles = sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in bpy.context.scene.objects if o.type == 'MESH')
    records.append({'id': style, 'file': target.name, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'all_variant_triangles': triangles, 'meshes': len(groups), 'bones': len(rig.data.bones), 'animations': ['walk', 'idle']})

manifest = {'version': 1, 'license': 'CC0-1.0 original project geometry', 'engine': 'Godot 4.6.3 Compatibility', 'blender': bpy.app.version_string, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'reference': 'Two user-provided screenshots: compact human and white rabbit. Original 3D interpretation; no reference pixels or third-party meshes copied.', 'prompt': 'Compact friendly 3D characters: large rounded head, short sturdy body, expressive dark eyes, brown swept hair or white rabbit ears. Warm matte materials, original unbranded modular clothes. Scarf, backpack and round glasses. Feet at origin, natural upright walk, one fixed gameplay capsule.', 'negative_prompt': 'logos, copied textures, realistic adult facial microdetail, elongated limbs, ragdoll lean, variable collider scale', 'models': records}
(out/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('COMPACT_CHARACTERS_COMPLETE', json.dumps(records), flush=True)
