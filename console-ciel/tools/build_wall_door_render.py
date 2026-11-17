#!/usr/bin/env python3
"""Render the existing door along the left wall, in the corridor's orthographic view.
blender -b -t 4 --python tools/build_wall_door_render.py -- --project .
"""
import argparse, sys, math
from pathlib import Path
import bpy
from mathutils import Vector, Matrix
parser=argparse.ArgumentParser();parser.add_argument('--project',required=True)
project=Path(parser.parse_args(sys.argv[sys.argv.index('--')+1:]).project).resolve()
bpy.ops.wm.open_mainfile(filepath=str(project/'art_sources/fire_exit_door.blend'))
# Door width follows the corridor wall, never the horizontal screen axis.
for obj in bpy.context.scene.objects:
    obj.matrix_world=Matrix.Rotation(math.pi/2,4,'Z') @ obj.matrix_world
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.render.film_transparent=True
scene.render.resolution_x=384;scene.render.resolution_y=768;scene.render.resolution_percentage=100
scene.world.color=(.35,.35,.35)
for at,power in [((5,-3,8),650),((3,4,5),350)]:
    bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.size=5
    o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(6,0,15));camera=bpy.context.object
direction=(Vector((0,0,1.12))-camera.location).normalized()
right=direction.cross(Vector((0,-1,0))).normalized();up=right.cross(direction)
camera.rotation_euler=Matrix((right,up,-direction)).transposed().to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=2.30;scene.camera=camera
scene.render.filepath=str(project/'assets/campus3d/fire_exit_door_wall.png')
bpy.ops.render.render(write_still=True)
