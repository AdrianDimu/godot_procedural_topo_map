extends Node2D

# === Exported Nodes ===
@export var sprite_colors: Sprite2D
@export var sprite_contours: Sprite2D
@export var color_bands_shader: ShaderMaterial
@export var contour_shader: ShaderMaterial

# === Exported Parameters ===
@export var auto_generate := false
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

# === Constants ===
var generator_thread: Thread = null
var is_map_ready: bool = false
var map_gen_start_time := 0
var noise_offset := Vector2i.ZERO

# === Lifecycle ===
func _ready():
	if auto_generate:
		start_map_generation()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		cleanup()

func cleanup():
	if generator_thread:
		# Always wait to finish, even if not alive (Godot needs this for proper GC)
		generator_thread.wait_to_finish()
		generator_thread = null

# === Public ===
func set_offset(offset: Vector2i):
	noise_offset = offset
	start_map_generation()

# === Generation ===
func start_map_generation():
	if generator_thread and generator_thread.is_alive():
		generator_thread.wait_to_finish()

	map_gen_start_time = Time.get_ticks_msec()

	generator_thread = Thread.new()
	generator_thread.start(Callable(self, "_map_thread_job"), Thread.PRIORITY_NORMAL)

func _map_thread_job(_userdata = null):
	var image := _generate_heightmap_image()
	call_deferred("_on_map_ready", image)

func _on_map_ready(image: Image):
	var tex := ImageTexture.create_from_image(image)
	sprite_colors.texture = tex
	sprite_contours.texture = tex
	apply_shader_parameters()
	is_map_ready = true

	var elapsed = Time.get_ticks_msec() - map_gen_start_time
	print("*Map generated in %s ms" % elapsed)

# === Image Generation ===
func _generate_heightmap_image() -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	
	match noise_type:
		"Simplex": noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		"SimplexSmooth": noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		"Cellular": noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		"Perlin": noise.noise_type = FastNoiseLite.TYPE_PERLIN
		"ValueCubic": noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
		"Value": noise.noise_type = FastNoiseLite.TYPE_VALUE

	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RF)
	
	for y in texture_size:
		for x in texture_size:
			var gx = x + noise_offset.x * texture_size
			var gy = y + noise_offset.y * texture_size
			var v := noise.get_noise_2d(gx, gy) * 0.5 + 0.5
			image.set_pixel(x, y, Color(v, 0, 0))

	if blur_radius > 0:
		return blur_image(image, blur_radius)
	else:
		return image

func blur_image(image: Image, radius: int) -> Image:
	var width := image.get_width()
	var height := image.get_height()
	var blurred := Image.create(width, height, false, Image.FORMAT_RF)

	for y in height:
		for x in width:
			var sum := 0.0
			var count := 0
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var nx: int = clamp(x + dx, 0, width - 1)
					var ny: int = clamp(y + dy, 0, height - 1)
					sum += image.get_pixel(nx, ny).r
					count += 1
			var avg := sum / count
			blurred.set_pixel(x, y, Color(avg, 0, 0))

	return blurred

# === Shader ===
func apply_shader_parameters():
	var color_mat := color_bands_shader.duplicate()
	color_mat.set_shader_parameter("bands", bands)
	color_mat.set_shader_parameter("gray_min", gray_min)
	color_mat.set_shader_parameter("gray_max", gray_max)
	sprite_colors.material = color_mat

	var contour_mat := contour_shader.duplicate()
	contour_mat.set_shader_parameter("step", 1.0 / float(bands))
	contour_mat.set_shader_parameter("subdivisions", subdivisions)
	contour_mat.set_shader_parameter("main_thickness", line_thickness)
	contour_mat.set_shader_parameter("minor_thickness", minor_thickness)
	contour_mat.set_shader_parameter("main_color", Color(main_color.r, main_color.g, main_color.b, main_opacity))
	contour_mat.set_shader_parameter("minor_color", Color(minor_color.r, minor_color.g, minor_color.b, minor_opacity))
	sprite_contours.material = contour_mat
