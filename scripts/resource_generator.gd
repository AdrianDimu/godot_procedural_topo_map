extends Node2D
class_name ResourceGenerator

const ResourceRule = preload("res://scripts/resource_rule.gd")

@export var height_map_scene: PackedScene
@export var rules: Array[ResourceRule] = []

var texture_size := 512
var noise_seed := 0

var active_sprites: Dictionary = {}
var active_threads: Dictionary = {}

var height_noise: FastNoiseLite
var resource_noise: FastNoiseLite


func _ready():
	if height_map_scene:
		var temp := height_map_scene.instantiate()
		texture_size = temp.texture_size
		noise_seed = temp.noise_seed
		temp.queue_free()

	# Init noise generators once
	height_noise = FastNoiseLite.new()
	height_noise.seed = noise_seed
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = 0.005

	resource_noise = FastNoiseLite.new()
	resource_noise.seed = noise_seed + 12345
	resource_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	resource_noise.frequency = 0.02

func generate_chunk(offset: Vector2i):
	if active_sprites.has(offset) or active_threads.has(offset):
		return  # Already exists or in progress

	var thread := Thread.new()
	active_threads[offset] = thread
	thread.start(Callable(self, "_generate_chunk_threaded").bind(offset), Thread.PRIORITY_NORMAL)

func _generate_chunk_threaded(offset: Vector2i):
	var image = _generate_resource_map(offset)
	call_deferred("_on_chunk_ready", offset, image)

func _on_chunk_ready(offset: Vector2i, image: Image):
	if active_sprites.has(offset):
		return  # Already added in the meantime

	var tex := ImageTexture.create_from_image(image)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = offset * texture_size
	sprite.modulate.a = 0.7
	add_child(sprite)

	active_sprites[offset] = sprite

	# Clean up thread
	if active_threads.has(offset):
		var thread = active_threads[offset]
		if thread.is_alive():
			thread.wait_to_finish()
		thread = null
		active_threads.erase(offset)

func cleanup_chunk(offset: Vector2i):
	if active_sprites.has(offset):
		active_sprites[offset].queue_free()
		active_sprites.erase(offset)

	if active_threads.has(offset):
		var thread = active_threads[offset]
		if thread.is_alive():
			thread.wait_to_finish()
		thread = null
		active_threads.erase(offset)

func _generate_resource_map(offset: Vector2i) -> Image:
	var img := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in texture_size:
		for x in texture_size:
			var gx = x + offset.x * texture_size
			var gy = y + offset.y * texture_size

			var h := height_noise.get_noise_2d(gx, gy) * 0.5 + 0.5
			var r := resource_noise.get_noise_2d(gx, gy) * 0.5 + 0.5

			for rule in rules:
				if h >= rule.min_height and h <= rule.max_height and r >= rule.min_noise and r <= rule.max_noise:
					img.set_pixel(x, y, rule.color)
					break

	return img
