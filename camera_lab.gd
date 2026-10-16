extends Node3D

@onready var camera: Camera3D = $Camera3D
# Blender camera Euler (60, 0, 45), converted from Z-up to Godot Y-up.
# 60 degrees from vertical means 30 degrees above the ground.
var azimuth := 45.0
var elevation := 30.0
var zoom := 12.0
var target := Vector3(0, 0.5, 0)
var readout: Label
var sliders: Array[HSlider] = []
var oblique := true
var geometry: Node3D


func _ready() -> void:
	geometry = Node3D.new()
	geometry.name = "ProjectionGeometry"
	add_child(geometry)
	$Floor.reparent(geometry)
	$ReferenceCube.reparent(geometry)
	_build_world()
	_build_ui()
	_update_camera()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _box(at: Vector3, dimensions: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = at
	geometry.add_child(instance)


func _build_world() -> void:
	for x in range(-6, 6):
		for z in range(-6, 6):
			var color := Color("46564d") if (x + z) % 2 == 0 else Color("526456")
			_box(Vector3(x + 0.5, 0, z + 0.5), Vector3(0.98, 0.02, 0.98), color)
	_box(Vector3(-3, 0.5, 0), Vector3.ONE, Color("6bace0"))
	_box(Vector3(3, 1.5, -2), Vector3(1, 3, 1), Color("c6a8df"))
	_box(Vector3(-2, 0.5, -3), Vector3(3, 1, 1), Color("d4c390"))
	_box(Vector3(2, 0.25, 2), Vector3(1, 0.5, 1), Color("82b9ad"))
	_box(Vector3(3, 0.5, 2), Vector3.ONE, Color("82b9ad"))
	_box(Vector3(4, 0.75, 2), Vector3(1, 1.5, 1), Color("82b9ad"))
	_add_label("CUBO 1 × 1 × 1", Vector3(0, 1.35, 0))
	_add_label("+X", Vector3(5.5, 0.15, 0))
	_add_label("+Z", Vector3(0, 0.15, 5.5))


func _add_label(value: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = 32
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size.x = 310
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.text = "LABORATÓRIO DE CÂMERA"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	readout = Label.new()
	column.add_child(readout)
	var tibia_button := Button.new()
	tibia_button.text = "Tibia / oblíqua 45°"
	tibia_button.pressed.connect(_oblique_preset)
	column.add_child(tibia_button)
	_add_slider(column, "Rotação ao redor de Y", -180, 180, azimuth, func(v: float): azimuth = v; _update_camera())
	_add_slider(column, "Elevação sobre o chão", 5, 89, elevation, func(v: float): elevation = v; _update_camera())
	_add_slider(column, "Zoom / tamanho ortográfico", 4, 24, zoom, func(v: float): zoom = v; _update_camera())
	var presets := HBoxContainer.new()
	column.add_child(presets)
	for preset in [["Blender 60/0/45", 45.0, 30.0], ["Isométrica", 45.0, 35.264], ["45° / 45°", 45.0, 45.0]]:
		var button := Button.new()
		button.text = preset[0]
		button.pressed.connect(_preset.bind(float(preset[1]), float(preset[2])))
		presets.add_child(button)
	var help := Label.new()
	help.text = "Arraste com botão direito: girar\nRoda do mouse: zoom\nWASD / setas: mover o foco\nR: restaurar câmera\n\nProjeção ortográfica, sem ponto de fuga.\nO cubo laranja é a referência central."
	help.add_theme_font_size_override("font_size", 14)
	column.add_child(help)


func _add_slider(parent: Control, title: String, minimum: float, maximum: float, value: float, changed: Callable) -> void:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.1
	slider.value = value
	slider.value_changed.connect(changed)
	parent.add_child(slider)
	sliders.append(slider)


func _preset(rotation_y: float, angle: float) -> void:
	oblique = false
	azimuth = rotation_y
	elevation = angle
	zoom = 12.0
	target = Vector3(0, 0.5, 0)
	_update_camera()


func _oblique_preset() -> void:
	oblique = true
	zoom = 12.0
	target = Vector3(0, 0.5, 0)
	_update_camera()


func _update_camera() -> void:
	var yaw := deg_to_rad(azimuth)
	var pitch := deg_to_rad(elevation)
	camera.position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 25.0
	camera.look_at(target)
	# A top-down orthographic view plus a height shear gives an oblique
	# projection: screen_x = x - 0.5*y, screen_y = z - 0.5*y.
	# Ground tiles stay square; height recedes diagonally up and left.
	geometry.basis = Basis.IDENTITY
	if oblique:
		geometry.basis = Basis(Vector3.RIGHT, Vector3(-0.5, 1, -0.5), Vector3.BACK)
		camera.position = target + Vector3(0, 25, 0)
		camera.look_at(target, Vector3.FORWARD)
	camera.size = zoom
	if is_instance_valid(readout):
		readout.text = "Rotação: %.1f°  |  Elevação: %.1f°\nTamanho: %.1f" % [azimuth, elevation, zoom]
		for index in range(sliders.size()):
			sliders[index].set_value_no_signal([azimuth, elevation, zoom][index])
		if oblique:
			readout.text = "Oblíqua 45° | chão quadrado\nAltura: diagonal para cima/esquerda"
		for index in range(2):
			sliders[index].editable = not oblique


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if oblique:
			return
		azimuth = wrapf(azimuth - event.relative.x * 0.3, -180, 180)
		elevation = clampf(elevation + event.relative.y * 0.3, 5, 89)
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(4, zoom - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(24, zoom + 0.5)
		_update_camera()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_oblique_preset()


func _process(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		movement.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		movement.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		movement.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		movement.x += 1
	if movement != Vector2.ZERO:
		var right := camera.global_basis.x
		var forward := Vector3(right.z, 0, -right.x)
		target += (right * movement.x + forward * movement.y).normalized() * delta * 4
		_update_camera()
