extends Node3D

const RESOLUTION := 256
var viewport: SubViewport
var projection: Node3D
var character: Node3D
var camera: Camera3D

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(RESOLUTION, RESOLUTION)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	projection = Node3D.new()
	# Same oblique projection as the existing Tibia reference scene.
	projection.basis = Basis(Vector3.RIGHT, Vector3(-0.5, 1, -0.5), Vector3.BACK)
	viewport.add_child(projection)
	character = load("res://assets/mewtwo/source/Mew-two.fbx").instantiate()
	projection.add_child(character)
	_apply_material(character)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.01
	camera.far = 1000
	viewport.add_child(camera)
	_capture.call_deferred()

func _apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		if "outline" in node.name.to_lower():
			node.hide()
			return
		print("MESH ", node.name, " bounds ", node.get_aabb(), " transform ", node.global_transform)
		var material := ShaderMaterial.new()
		material.shader = load("res://mewtwo_toon.gdshader")
		material.set_shader_parameter("albedo_texture", load("res://assets/mewtwo/textures/M2_High_BaseColor.png"))
		node.material_override = material
	for child in node.get_children():
		_apply_material(child)

func _points(node: Node, points: Array[Vector3]) -> void:
	if node is MeshInstance3D and node.visible:
		var bounds: AABB = node.get_aabb()
		for corner in range(8):
			points.append(node.global_transform * bounds.get_endpoint(corner))
	for child in node.get_children():
		_points(child, points)

func _frame() -> void:
	var points: Array[Vector3] = []
	_points(character, points)
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center := bounds.get_center()
	camera.position = center + Vector3(0, 200, 0)
	camera.look_at(center, Vector3.FORWARD)
	camera.size = maxf(bounds.size.x, bounds.size.z) * 1.16
	print("FRAME ", bounds, " camera size ", camera.size)

func _outline(source: Image) -> Image:
	source.convert(Image.FORMAT_RGBA8)
	var result := source.duplicate() as Image
	for y in range(RESOLUTION):
		for x in range(RESOLUTION):
			if source.get_pixel(x, y).a > 0.5:
				var color := source.get_pixel(x, y)
				color.a = 1.0
				result.set_pixel(x, y, color)
				continue
			result.set_pixel(x, y, Color.TRANSPARENT)
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = Vector2i(x, y) + offset
				if Rect2i(0, 0, RESOLUTION, RESOLUTION).has_point(neighbor) and source.get_pixelv(neighbor).a > 0.5:
					result.set_pixel(x, y, Color.BLACK)
					break
	return result

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://references/mewtwo"))
	var sheet := Image.create_empty(RESOLUTION * 4, RESOLUTION * 2, false, Image.FORMAT_RGBA8)
	for index in range(8):
		character.rotation_degrees.y = index * 45.0
		_frame()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var sprite := _outline(viewport.get_texture().get_image())
		var name := "res://references/mewtwo/mewtwo_%d" % (index * 45)
		sprite.save_png(name + "_%d.png" % RESOLUTION)
		sheet.blit_rect(sprite, Rect2i(0, 0, RESOLUTION, RESOLUTION), Vector2i((index % 4) * RESOLUTION, (index / 4) * RESOLUTION))
		sprite.resize(768, 768, Image.INTERPOLATE_NEAREST)
		sprite.save_png(name + "_768.png")
	sheet.save_png("res://references/mewtwo/mewtwo_8_direcoes.png")
	print("MEWTWO_RENDER_COMPLETE")
	get_tree().quit()
