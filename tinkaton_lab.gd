extends "res://camera_lab.gd"

const CHARACTER_LIFT := 1.46
const DEFAULT_TARGET := Vector3(-2.73, 0.5, -1.23)
@export var idle_mode := false
var animation: AnimationPlayer
var clip: StringName
var playhead := 0.0
var playing := true
var speed := 0.6
var timeline: HSlider
var frame_label: Label
var pixel_material: ShaderMaterial
var character: Node3D
var controls_layer: CanvasLayer
var exporting := false


func _ready() -> void:
	super._ready()
	zoom = 10.5
	target = DEFAULT_TARGET
	# Rembrandt-inspired key: 45 degrees to the front/side, 45 above the ground.
	$Sun.position = Vector3(-4, sqrt(32.0), 4)
	$Sun.look_at(Vector3.ZERO, Vector3.UP)
	$Sun.light_energy = 0.9
	$Sun.light_color = Color(1.0, 0.95, 0.9)
	$Sun.shadow_enabled = false
	$WorldEnvironment.environment.ambient_light_color = Color(0.72, 0.8, 1.0)
	$WorldEnvironment.environment.ambient_light_energy = 0.35
	$WorldEnvironment.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	$WorldEnvironment.environment.background_mode = Environment.BG_COLOR
	$WorldEnvironment.environment.background_color = Color("ffff00")
	_update_camera()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_preview.call_deferred()


func _update_camera() -> void:
	if not is_instance_valid(geometry):
		return
	geometry.basis = Basis(Vector3.RIGHT, Vector3(-0.5, 1, -0.5), Vector3.BACK)
	camera.position = target + Vector3(0, 25, 0)
	camera.look_at(target, Vector3.FORWARD)
	camera.size = zoom


func _capture_preview() -> void:
	if idle_mode:
		await _export_still()
		get_tree().quit()
		return
	playing = false
	for sample in [0.0, 0.875, 1.2917]:
		playhead = sample
		_pose()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://references/preview_%02d.png" % roundi(sample * 24))
	await _export_sheet()
	get_tree().quit()


func _export_sheet() -> void:
	if exporting or not animation or clip.is_empty():
		return
	exporting = true
	var was_playing := playing
	var saved_time := playhead
	playing = false
	controls_layer.hide()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://references"))
	var sheet := Image.create_empty(1024, 768, false, Image.FORMAT_RGBA8)
	for index in range(12):
		playhead = animation.get_animation(clip).length * index / 12.0
		_pose()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var screen := get_viewport().get_texture().get_image()
		var side := mini(screen.get_width(), screen.get_height())
		var origin_x := maxi(0, screen.get_width() - side - 40)
		var frame := screen.get_region(Rect2i(origin_x, 0, side, side))
		frame.save_png("res://references/tinkaton_%02d.png" % index)
		frame.resize(256, 256, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(frame, Rect2i(0, 0, 256, 256), Vector2i((index % 4) * 256, (index / 4) * 256))
	sheet.save_png("res://references/tinkaton_martelada_12_poses.png")
	controls_layer.show()
	playhead = saved_time
	playing = was_playing
	_pose()
	exporting = false


func _export_still() -> void:
	if exporting:
		return
	exporting = true
	controls_layer.hide()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://references"))
	get_viewport().get_texture().get_image().save_png("res://references/tinkaton_sem_martelo.png")
	controls_layer.show()
	exporting = false


func _build_world() -> void:
	geometry.get_node("ReferenceCube").hide()
	geometry.get_node("Floor").hide()
	var model_path := "res://assets/tinkaton/tinkaton_idle.glb" if idle_mode else "res://assets/tinkaton/tinkaton.glb"
	character = load(model_path).instantiate()
	# Lowest hammer vertex over the 61 sampled poses was -1.404 units.
	# Lift the whole character to retain > 0.05 units above the ground plane.
	character.position.y = CHARACTER_LIFT
	geometry.add_child(character)
	_apply_toon(character)
	if idle_mode:
		playing = false
		return
	animation = _find_animation(character)
	if animation:
		for name in animation.get_animation_list():
			if "Hammer" in name:
				clip = name
		if clip.is_empty():
			for name in animation.get_animation_list():
				if name != "RESET":
					clip = name
		if not clip.is_empty():
			animation.play(clip)
			animation.pause()
			animation.seek(0, true)


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation(child)
		if found:
			return found
	return null


func _apply_toon(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original = node.get_active_material(surface)
			if original is StandardMaterial3D and original.albedo_texture:
				var material := ShaderMaterial.new()
				material.shader = load("res://toon_reference.gdshader")
				material.set_shader_parameter("albedo_texture", original.albedo_texture)
				material.set_shader_parameter("tint", original.albedo_color)
				if "eye" not in node.name.to_lower():
					var outline := ShaderMaterial.new()
					outline.shader = load("res://anime_outline.gdshader")
					material.next_pass = outline
				node.set_surface_override_material(surface, material)
	for child in node.get_children():
		_apply_toon(child)


func _build_ui() -> void:
	# Pixelate only the world. Both UI panels remain sharp.
	var effect_layer := CanvasLayer.new()
	effect_layer.layer = 1
	add_child(effect_layer)
	var effect := ColorRect.new()
	effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_material = ShaderMaterial.new()
	pixel_material.shader = load("res://pixel_reference.gdshader")
	effect.material = pixel_material
	effect_layer.add_child(effect)
	var layer := CanvasLayer.new()
	layer.layer = 2
	controls_layer = layer
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(310, 0)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)
	var title := Label.new()
	title.text = "TINKATON · SEM MARTELO\nPose parada para desenho" if idle_mode else "TINKATON · MARTELO\nReferência para desenho"
	column.add_child(title)
	var switch_scene := Button.new()
	switch_scene.text = "Ver martelada" if idle_mode else "Ver parado sem martelo"
	switch_scene.pressed.connect(func(): get_tree().change_scene_to_file("res://tinkaton_lab.tscn" if idle_mode else "res://tinkaton_idle.tscn"))
	column.add_child(switch_scene)
	frame_label = Label.new()
	column.add_child(frame_label)
	var pause := Button.new()
	pause.text = "Pausar / continuar [Espaço]"
	pause.pressed.connect(func(): playing = not playing)
	column.add_child(pause)
	timeline = HSlider.new()
	timeline.min_value = 0
	timeline.max_value = 1
	timeline.step = 1.0 / 24.0
	timeline.value_changed.connect(func(v: float): playing = false; playhead = v; _pose())
	column.add_child(timeline)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	for direction in [-1, 1]:
		var button := Button.new()
		button.text = "← Quadro" if direction == -1 else "Quadro →"
		button.pressed.connect(_step.bind(direction))
		buttons.add_child(button)
	_add_slider(column, "Velocidade", 0.1, 1.5, speed, func(v: float): speed = v)
	_add_slider(column, "Tamanho do pixel", 1, 10, 4, func(v: float): pixel_material.set_shader_parameter("pixel_size", v))
	_add_slider(column, "Níveis de cor", 3, 24, 12, func(v: float): pixel_material.set_shader_parameter("color_steps", v))
	var toggle := CheckButton.new()
	toggle.text = "Efeito pixelado"
	toggle.button_pressed = true
	toggle.toggled.connect(func(v: bool): pixel_material.set_shader_parameter("enabled", v))
	column.add_child(toggle)
	var export_button := Button.new()
	export_button.text = "Salvar 12 poses em PNG"
	export_button.pressed.connect(_export_sheet)
	column.add_child(export_button)
	_add_slider(column, "Direção do personagem", -180, 180, 0, func(v: float): character.rotation.y = deg_to_rad(v))
	var help := Label.new()
	help.text = "Espaço: pausar · ← / →: quadro\nRoda: zoom · WASD: mover câmera\nR: restaurar enquadramento\n\nProjeção oblíqua aprovada.\nA martelada repete automaticamente."
	help.add_theme_font_size_override("font_size", 14)
	column.add_child(help)
	if idle_mode:
		# Hide animation-only controls; pixel and direction controls stay available.
		frame_label.hide()
		pause.hide()
		timeline.hide()
		buttons.hide()
		var speed_label := sliders[0].get_index() - 1
		column.get_child(speed_label).hide()
		sliders[0].hide()
		export_button.text = "Salvar pose parada em PNG"
		export_button.pressed.disconnect(_export_sheet)
		export_button.pressed.connect(_export_still)
		help.text = "Roda: zoom · WASD: mover câmera\nR: restaurar enquadramento\n\nPose fixa, sem martelo.\nMesma projeção e iluminação a 45°."


func _pose() -> void:
	if animation and not clip.is_empty():
		var duration := animation.get_animation(clip).length
		playhead = clampf(playhead, 0, duration)
		animation.seek(playhead, true)
		timeline.max_value = duration
		timeline.set_value_no_signal(playhead)
		frame_label.text = "Quadro %02d / %02d · %.2f s" % [roundi(playhead * 24), roundi(duration * 24), playhead]


func _step(direction: int) -> void:
	playing = false
	playhead += direction / 24.0
	_pose()


func _process(delta: float) -> void:
	super._process(delta)
	if playing and animation and not clip.is_empty():
		playhead = fmod(playhead + delta * speed, animation.get_animation(clip).length)
		_pose()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				playing = not playing
			KEY_LEFT:
				_step(-1)
			KEY_RIGHT:
				_step(1)
			KEY_R:
				_oblique_preset()
				zoom = 10.5
				target = DEFAULT_TARGET
				_update_camera()
		return
	super._unhandled_input(event)
