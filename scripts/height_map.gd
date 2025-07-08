extends Node2D

@export var sprite_colors: Sprite2D
@export var resource_sprite: Sprite2D
@export var sprite_contours: Sprite2D
@export var color_bands_shader: ShaderMaterial
@export var contour_shader: ShaderMaterial
@export var thread_pool: Node

@export var draw_chunk_border := false
@export var texture_size = 1024
@export var noise_seed: int = 42
@export_enum("Simplex", "SimplexSmooth", "Cellular", "Perlin", "ValueCubic", "Value") var noise_type: String = "Simplex"
@export_range(0.0001, 0.1, 0.0001) var noise_frequency := 0.001
@export var blur_radius: int = 0
@export var bands: int = 8
@export var subdivisions := 0
@export_range(0.0, 1.0, 0.01) var gray_min := 0.5
@export_range(0.0, 1.0, 0.01) var gray_max := 0.8
@export_range(0.0001, 1.0, 0.0001) var line_thickness := 0.001
@export_range(0.0001, 1.0, 0.0001) var minor_thickness := 0.0005
@export var main_color := Color.BLACK
@export_range(0.0, 1.0, 0.01) var main_opacity := 1.0
@export var minor_color := Color(0, 0, 0)
@export_range(0.0, 1.0, 0.01) var minor_opacity := 0.5

var is_map_ready: bool = false
var noise_offset := Vector2i.ZERO
var job_id: int = 0
var image_queue: Array = []
var map_gen_start_time := 0

func set_offset(offset: Vector2i):
	noise_offset = offset
	start_map_generation()

func _process(_delta):
	if image_queue.size() > 0:
		var item = image_queue.pop_front()
		if item.job_id != job_id:
			return
		var tex := ImageTexture.create_from_image(item.image)
		sprite_colors.texture = tex
		sprite_contours.texture = tex
		apply_shader_parameters()
		is_map_ready = true
		queue_redraw()
		var elapsed = Time.get_ticks_msec() - map_gen_start_time
		print("*Chunk %s generated and uploaded in %s ms" % [noise_offset, elapsed])

func start_map_generation():
	map_gen_start_time = Time.get_ticks_msec()
	job_id += 1
	thread_pool.request_thread(self, "_map_thread_job", job_id)

func _map_thread_job(job_index: int):
	if job_index != job_id:
		return
	var noise_type_enum := FastNoiseLite.TYPE_SIMPLEX
	match noise_type:
		"Simplex": noise_type_enum = FastNoiseLite.TYPE_SIMPLEX
		"SimplexSmooth": noise_type_enum = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		"Cellular": noise_type_enum = FastNoiseLite.TYPE_CELLULAR
		"Perlin": noise_type_enum = FastNoiseLite.TYPE_PERLIN
		"ValueCubic": noise_type_enum = FastNoiseLite.TYPE_VALUE_CUBIC
		"Value": noise_type_enum = FastNoiseLite.TYPE_VALUE

	var params := {
		"seed": noise_seed,
		"frequency": noise_frequency,
		"noise_type": noise_type_enum,
		"offset": noise_offset,
		"texture_size": texture_size,
		"blur_radius": blur_radius,
	}
	var image := _generate_heightmap_image_threaded(params)
	call_deferred("_on_map_ready", image, job_index)

func _on_map_ready(image: Image, job_index: int):
	image_queue.append({ "image": image, "job_id": job_index })

func _generate_heightmap_image_threaded(params: Dictionary) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = params.seed
	noise.frequency = params.frequency
	noise.noise_type = params.noise_type
	var offset = params.offset
	var texture_s = params.texture_size
	var blur_r = params.blur_radius
	var image := Image.create(texture_s, texture_s, false, Image.FORMAT_L8)
	for y in texture_s:
		for x in texture_s:
			var gx = x + offset.x * texture_s
			var gy = y + offset.y * texture_s
			var v := noise.get_noise_2d(gx, gy) * 0.5 + 0.5
			image.set_pixel(x, y, Color(v, 0, 0))
	if blur_r > 0:
		return _blur_image(image, blur_r)
	else:
		return image

func _blur_image(image: Image, radius: int) -> Image:
	var width = image.get_width()
	var height = image.get_height()
	var blurred = Image.create(width, height, false, Image.FORMAT_RF)
	for y in height:
		for x in width:
			var sum = 0.0
			var count = 0
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var nx = clamp(x + dx, 0, width - 1)
					var ny = clamp(y + dy, 0, height - 1)
					sum += image.get_pixel(nx, ny).r
					count += 1
			blurred.set_pixel(x, y, Color(sum / count, 0, 0))
	return blurred

func apply_shader_parameters():
	var color_mat = color_bands_shader.duplicate()
	color_mat.set_shader_parameter("bands", bands)
	color_mat.set_shader_parameter("gray_min", gray_min)
	color_mat.set_shader_parameter("gray_max", gray_max)
	sprite_colors.material = color_mat

	var contour_mat = contour_shader.duplicate()
	contour_mat.set_shader_parameter("step", 1.0 / float(bands))
	contour_mat.set_shader_parameter("subdivisions", subdivisions)
	contour_mat.set_shader_parameter("main_thickness", line_thickness)
	contour_mat.set_shader_parameter("minor_thickness", minor_thickness)
	contour_mat.set_shader_parameter("main_color", Color(main_color.r, main_color.g, main_color.b, main_opacity))
	contour_mat.set_shader_parameter("minor_color", Color(minor_color.r, minor_color.g, minor_color.b, minor_opacity))
	sprite_contours.material = contour_mat

func _draw():
	if draw_chunk_border:
		var rect = Rect2(Vector2.ZERO, Vector2(texture_size, texture_size))
		draw_rect(rect, Color(0, 1, 0, 1), false, 2.0)
