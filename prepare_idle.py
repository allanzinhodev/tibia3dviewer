"""Export a stationary Tinkaton with relaxed arms and no hammer."""
import bpy, os, math
from mathutils import Matrix

ROOT = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, 'assets/tinkaton/source/Tera.blend'))
for obj in list(bpy.data.objects):
    if obj.type not in {'ARMATURE', 'MESH'} or '_lod' in obj.name or 'hammer' in obj.name:
        bpy.data.objects.remove(obj, do_unlink=True)
for image in bpy.data.images:
    name = os.path.basename(image.filepath.replace('\\', '/'))
    path = os.path.join(ROOT, 'assets/tinkaton/textures', name)
    if os.path.isfile(path):
        image.filepath = path
        image.reload()
        image.pack()
rig = next(obj for obj in bpy.data.objects if obj.type == 'ARMATURE')
rig.animation_data_clear()
rig.rotation_mode = 'XYZ'
rig.rotation_euler = (math.pi / 2, 0, 0)
rig.scale = (1.85, 1.85, 1.85)
rig.location = (0, 0, 0.20)
for bone in rig.pose.bones:
    bone.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()
for side, angle in [('left', -65), ('right', 65)]:
    bone = rig.pose.bones[side + '_arm_01']
    rest = bone.bone.matrix_local.copy()
    pivot = rest.translation
    bone.matrix = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(angle), 4, 'Z') @ Matrix.Translation(-pivot) @ rest
    bpy.context.view_layer.update()
# Bake this relaxed pose into the mesh: no animation or skeleton can move it.
bpy.ops.object.select_all(action='DESELECT')
for obj in list(bpy.data.objects):
    if obj.type == 'MESH':
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        for modifier in list(obj.modifiers):
            if modifier.type == 'ARMATURE':
                bpy.ops.object.modifier_apply(modifier=modifier.name)
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
        obj.select_set(False)
bpy.data.objects.remove(rig, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, 'assets/tinkaton/source/tinkaton_idle.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, 'assets/tinkaton/tinkaton_idle.glb'), export_format='GLB', export_animations=False)
