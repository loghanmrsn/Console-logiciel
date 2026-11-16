#!/usr/bin/env python3
"""Original double fire door. Blender 4.3, metres, +Z front in Godot.
blender -b -t 4 --python tools/build_fire_door.py -- --project .
Reference: user's white double panic-door photograph; no image pixels/logos used.
Budget: <15k triangles, 8 material families, 640px transparent legacy render.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector


def build():
    mats = {}
    for name, color, rough, metal in [
        ('Painted steel', (.78,.80,.79), .56, .18),
        ('Door frame', (.57,.62,.63), .42, .45),
        ('Brushed hardware', (.35,.40,.42), .28, .8),
        ('Gaskets', (.055,.068,.073), .87, 0),
        ('Exit green', (.015,.24,.17), .62, 0),
        ('Exit white', (.92,.94,.91), .6, 0)]:
        m=bpy.data.materials.new(name);m.use_nodes=True
        n=m.node_tree.nodes.get('Principled BSDF')
        n.inputs['Base Color'].default_value=(*color,1)
        n.inputs['Roughness'].default_value=rough
        n.inputs['Metallic'].default_value=metal
        mats[name]=m
    objects=[]
    def box(name, at, size, mat, bevel=.008):
        bpy.ops.mesh.primitive_cube_add(size=1,location=(at[0],-at[2],at[1]))
        o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1])
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        if bevel:
            b=o.modifiers.new('Rounded manufactured edges','BEVEL');b.width=min(bevel,min(size)*.22);b.segments=3
            bpy.ops.object.modifier_apply(modifier=b.name)
            b=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=b.name)
        o.data.materials.append(mats[mat]);objects.append(o);return o
    for x in [-1.06,1.06]:
        box('Steel jamb',(x,1.14,0),(.10,2.28,.18),'Door frame')
    box('Header',(0,2.24,0),(2.22,.10,.18),'Door frame')
    box('Threshold',(0,.012,.02),(2.12,.024,.23),'Brushed hardware')
    for side in [-1,1]:
        x=side*.515
        box('Perimeter seal',(x,1.105,.018),(1.028,2.19,.07),'Gaskets')
        box('Left leaf' if side<0 else 'Right leaf',(x,1.105,.047),(1.005,2.16,.065),'Painted steel')
        box('Kick plate',(x,.18,.084),(.91,.25,.009),'Door frame')
        for dx in [-.40,.40]:
            box('Panic bar housing',(x+dx,1.03,.12),(.10,.13,.09),'Brushed hardware')
        box('Horizontal panic bar',(x,1.03,.18),(.86,.048,.05),'Brushed hardware',.018)
        box('Latch cover',(side*.065,.96,.108),(.08,.25,.045),'Brushed hardware')
        box('Door closer',(side*.72,2.06,.115),(.27,.065,.085),'Brushed hardware')
        arm=box('Closer arm',(side*.52,2.12,.145),(.34,.018,.024),'Brushed hardware')
        arm.rotation_euler.z=side*.20
        for y in [.25,1.10,1.96]:
            box('Hinge',(side*1.006,y,.09),(.038,.11,.047),'Brushed hardware')
    box('Meeting stile',(.018,1.10,.092),(.038,2.17,.018),'Door frame')
    box('Exit pictogram',(0,1.65,.105),(.22,.22,.014),'Exit green')
    # Simple original exit glyph, geometry rather than a copied safety label.
    for at,size in [((-.054,1.66,.116),(.012,.14,.006)),((-.015,1.725,.116),(.09,.012,.006)),((.024,1.66,.116),(.012,.14,.006)),((-.015,1.595,.116),(.09,.012,.006)),((.045,1.65,.12),(.08,.014,.006))]:
        box('Exit glyph',at,size,'Exit white',0)
    for angle in [-.65,.65]:
        a=box('Exit arrow',(.073,1.65+(0.016 if angle<0 else -.016),.12),(.047,.012,.006),'Exit white',0)
        a.rotation_euler.y=angle
    return objects


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--project',required=True)
    project=Path(parser.parse_args(sys.argv[sys.argv.index('--')+1:]).project).resolve()
    out=project/'assets/campus3d';out.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    objects=build()
    # Batch by material while preserving the editable authored objects in .blend.
    source=project/'art_sources/fire_exit_door.blend';source.parent.mkdir(exist_ok=True)
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    groups={m:[o for o in objects if o.data.materials[0]==m] for m in {o.data.materials[0] for o in objects}}
    for material,group in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in group:o.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join();group[0].name=material.name
    glb=out/'fire_exit_door.glb'
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',export_yup=True,export_animations=False)
    triangles=sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)
    assert triangles<15000
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
    scene.render.resolution_x=640;scene.render.resolution_y=768;scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.world.color=(.30,.30,.30)
    for position,power,size in [((1,-4,6),450,4),((-4,-2,3),180,3)]:
        bpy.ops.object.light_add(type='AREA',location=position);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size
        o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(3.8,-7,4.5));camera=bpy.context.object
    camera.rotation_euler=(Vector((0,0,1.12))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=2.85;scene.camera=camera
    preview=out/'fire_exit_door.png';scene.render.filepath=str(preview);bpy.ops.render.render(write_still=True)
    (out/'fire_exit_door.json').write_text(json.dumps({'source':'tools/build_fire_door.py','blender':bpy.app.version_string,'license':'Original project geometry; user reference only, no copied pixels or branding','units':'metres','dimensions':[2.22,2.29,.26],'triangles':triangles,'sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'preview_sha256':hashlib.sha256(preview.read_bytes()).hexdigest()},indent=2)+'\n')


if __name__=='__main__':main()
