extends Node2D

@export var chunk_scene: PackedScene
@export var chunk_size := 1024
@export var view_distance := 1
@export var player: Node2D

var loaded_chunks: Dictionary = {}

func _process(_delta):
	_update_chunks()

func _update_chunks():
	if not player:
		return

	var cam_pos = player.global_position
	var cx = int(floor(cam_pos.x / chunk_size))
	var cy = int(floor(cam_pos.y / chunk_size))

	var needed_chunks := {}

	# --- Spawn new chunks ---
	for y in range(cy - view_distance, cy + view_distance + 1):
		for x in range(cx - view_distance, cx + view_distance + 1):
			var key = Vector2i(x, y)
			needed_chunks[key] = true
			if not loaded_chunks.has(key):
				loaded_chunks[key] = _spawn_chunk(key)

	# --- Remove distant chunks ---
	var to_remove := []
	for key in loaded_chunks.keys():
		if not needed_chunks.has(key):
			var chunk = loaded_chunks[key]
			if chunk.has_method("cleanup"):
				chunk.cleanup()
			loaded_chunks[key].queue_free()
			to_remove.append(key)

	for key in to_remove:
		loaded_chunks.erase(key)

func _spawn_chunk(coords: Vector2i) -> Node2D:
	var chunk = chunk_scene.instantiate()
	chunk.position = coords * chunk_size
	chunk.set_offset(coords)
	add_child(chunk)
	return chunk
