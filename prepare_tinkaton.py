import bpy, os, json, math
from mathutils import Vector, Matrix, Quaternion
ROOT = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'assets/tinkaton/source/Tera.blend'))
for obj in list(bpy.data.objects):
    if obj.type not in {'ARMATURE','MESH'} or '_lod' in obj.name:
        bpy.data.objects.remove(obj, do_unlink=True)
for image in bpy.data.images:
    name = os.path.basename(image.filepath.replace('\\','/'))
    path = os.path.join(ROOT,'assets/tinkaton/textures',name)
    if os.path.exists(path):
        image.filepath = path
        image.reload()
for m in bpy.data.materials:
    if m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                n.inputs['Roughness'].default_value = 0.9
                n.inputs['Metallic'].default_value = 0
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
print('RIG',rig.name,'matrix',rig.matrix_world)
for b in rig.pose.bones:
    if any(s in b.name for s in ['arm_01','arm_02','hand','feeler_01','hammer','spine','waist']):
        print('BONE',b.name,'WORLD',list(rig.matrix_world @ b.head),'POSE',list(b.rotation_quaternion),'PARENT',b.parent.name if b.parent else '')
deps = bpy.context.evaluated_depsgraph_get()
for o in bpy.data.objects:
    if o.type == 'MESH':
        ev = o.evaluated_get(deps)
        points = [ev.matrix_world @ Vector(c) for c in ev.bound_box]
        print('BOUNDS',o.name, [min(p[i] for p in points) for i in range(3)], [max(p[i] for p in points) for i in range(3)])
        if 'hammer' in o.name:
            weights = {}
            for v in o.data.vertices:
                for g in v.groups:
                    name = o.vertex_groups[g.group].name
                    weights[name] = weights.get(name,0) + g.weight
            print('HAMMER WEIGHTS',weights)
# All motion is authored in the source armature coordinates (Y up, +Z front).
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
rig.rotation_mode = 'XYZ'
rig.rotation_euler = (math.pi / 2, 0, 0)
rig.scale = (1.85, 1.85, 1.85)
rig.location = (0, 0, 0.20)
rig.animation_data_clear()
scene = bpy.context.scene
scene.render.fps = 24
scene.frame_start = 1
scene.frame_end = 61
# Frame, hammer angle, body lean, crouch, hair lag.
keys = [(1,-22,0,0,0),(12,-60,-10,-.025,8),(22,-82,-15,-.045,15),
        (27,-65,-8,-.025,10),(32,100,20,-.065,-18),
        (35,97,18,-.06,-10),(40,84,10,-.035,8),
        (49,25,2,-.01,5),(61,-22,0,0,0)]

def values(frame):
    for a,b in zip(keys,keys[1:]):
        if a[0] <= frame <= b[0]:
            t=(frame-a[0])/(b[0]-a[0]); t=t*t*(3-2*t)
            return [a[i]+(b[i]-a[i])*t for i in range(1,5)]
    return list(keys[-1][1:])

def orient(name, head, direction, original_direction):
    q = Vector(original_direction).normalized().rotation_difference(Vector(direction).normalized())
    matrix = (q.to_matrix() @ rest[name].to_3x3()).to_4x4()
    matrix.translation = Vector(head)
    rig.pose.bones[name].matrix = matrix
    bpy.context.view_layer.update()

for frame in range(1,62):
    scene.frame_set(frame)
    angle,lean,crouch,lag = values(frame)
    for b in rig.pose.bones:
        b.matrix_basis = Matrix.Identity(4)
        b.rotation_mode = 'QUATERNION'
    rig.pose.bones['origin'].location = (0,crouch,0)
    spine = rig.pose.bones['spine_01']
    pivot = rest['spine_01'].translation
    spine.matrix = Matrix.Translation(pivot + Vector((0,crouch,0))) @ Matrix.Rotation(math.radians(lean),4,'X') @ Matrix.Translation(-pivot) @ rest['spine_01']
    bpy.context.view_layer.update()
    grip = Vector((0,.42 + crouch,.28))
    rot = Matrix.Rotation(math.radians(angle),4,'X')
    hammer = rig.pose.bones['feeler_01']
    hammer.matrix = Matrix.Translation(grip) @ rot @ Matrix.Translation(-rest['feeler_01'].translation) @ rest['feeler_01']
    bpy.context.view_layer.update()
    for side,sign in [('left',1),('right',-1)]:
        upper=side+'_arm_01'; lower=side+'_arm_02'; hand=side+'_hand'
        shoulder=rig.pose.bones[upper].head.copy()
        # Hands follow the lower portion of the handle throughout the arc.
        wrist=grip + rot.to_3x3() @ Vector((sign*.055,-.035,-.11))
        l1=(rest[lower].translation-rest[upper].translation).length
        l2=(rest[hand].translation-rest[lower].translation).length
        axis=wrist-shoulder
        distance=min(axis.length,l1+l2-.0001)
        axis.normalize()
        wrist=shoulder+axis*distance
        along=(l1*l1-l2*l2+distance*distance)/(2*distance)
        pole=Vector((sign,0,-.15)); pole=(pole-axis*pole.dot(axis)).normalized()
        elbow=shoulder+axis*along+pole*math.sqrt(max(0,l1*l1-along*along))
        orient(upper,shoulder,elbow-shoulder,rest[lower].translation-rest[upper].translation)
        orient(lower,elbow,wrist-elbow,rest[hand].translation-rest[lower].translation)
        orient(hand,wrist,grip-wrist,Vector((sign,0,0)))
        for main,roll in [(lower,side+'_arm_02_roll'),(hand,side+'_hand_roll')]:
            rig.pose.bones[roll].matrix = rig.pose.bones[main].matrix @ rest[main].inverted() @ rest[roll]
            bpy.context.view_layer.update()
    for name in ['left_hair_c_01','right_hair_c_01','root_hair']:
        b=rig.pose.bones[name]
        b.rotation_quaternion = Quaternion((1,0,0),math.radians(lag*.35))
    for b in rig.pose.bones:
        b.keyframe_insert(data_path='location',frame=frame,group=b.name)
        b.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=b.name)
        b.keyframe_insert(data_path='scale',frame=frame,group=b.name)
rig.animation_data.action.name = 'Hammer_Slam'
scene.frame_set(1)
# Keep a directly editable source beside the runtime GLB.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'assets/tinkaton/source/tinkaton_animated.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'assets/tinkaton/tinkaton.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=True)
