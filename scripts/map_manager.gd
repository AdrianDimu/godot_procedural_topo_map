extends Node2D

@export var chunk_scene: PackedScene
@export var view_distance := 2                   # How many chunks in each direction are visible
@export var buffer_distance := 1                 # Extra ring of chunks to preload
@export var cleanup_distance := 10               # Distance threshold beyond which chunks are despawned
@export var player: Node2D                       # Reference to player node (or camera)

var chunk_size := 0                              # Size of each chunk in pixels
var loaded_chunks: Dictionary = {}               # Currently active chunks
var generation_queue: Array[Vector2i] = []       # Chunks waiting to be generated

func _ready():
	# Determine chunk size from a temporary instance
	if chunk_scene:
		var temp_chunk = chunk_scene.instantiate()
		chunk_size = temp_chunk.texture_size
		temp_chunk.queue_free()

func _process(_delta):
	# Main tick
	_queue_chunks_near_player()
	_spawn_queued_chunks()

# === Queue new chunks to generate in a spiral pattern around the player ===
func _queue_chunks_near_player():
	if not player:
		return

	var cam_pos = player.global_position
	var center_chunk = Vector2i(floor(cam_pos.x / chunk_size), floor(cam_pos.y / chunk_size))
	var max_radius = view_distance + 1 + buffer_distance

	# --- Despawn chunks far beyond cleanup_distance ---
	var to_remove := []
	for key in loaded_chunks.keys():
		if key.distance_to(center_chunk) > cleanup_distance:
			var chunk = loaded_chunks[key]
			if chunk.has_method("cleanup"):
				chunk.cleanup()
			chunk.queue_free()
			to_remove.append(key)
	for key in to_remove:
		loaded_chunks.erase(key)

	# --- Spiral chunk generation queue (priority: close chunks first) ---
	var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var pos = Vector2i.ZERO
	var dir_index = 0
	var step_length = 1
	var steps_taken = 0
	var segment_passes = 0

	for i in range((2 * max_radius + 1) ** 2):
		var chunk_coords = center_chunk + pos
		if not loaded_chunks.has(chunk_coords) and not generation_queue.has(chunk_coords):
			generation_queue.append(chunk_coords)

		pos += directions[dir_index]
		steps_taken += 1

		if steps_taken == step_length:
			steps_taken = 0
			dir_index = (dir_index + 1) % 4
			segment_passes += 1
			if segment_passes % 2 == 0:
				step_length += 1

# === Spawn 1 chunk per frame from the queue ===
func _spawn_queued_chunks():
	if generation_queue.size() == 0:
		return

	var coords = generation_queue.pop_front()
	if not loaded_chunks.has(coords):
		var chunk = chunk_scene.instantiate()
		chunk.position = coords * chunk_size
		chunk.set_offset(coords)
		add_child(chunk)
		loaded_chunks[coords] = chunk
