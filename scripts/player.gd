extends Node2D

@export var camera: Camera2D
@export var move_speed := 500.0
@export var zoom_speed := 0.1

@export var initial_zoom := Vector2(4.0, 4.0)
@export var min_zoom := Vector2(2.5, 2.5)
@export var max_zoom := Vector2(5.0, 5.0)


func _ready():
	if camera:
		camera.zoom = initial_zoom

func _process(delta):
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): dir.x += 1

	if dir != Vector2.ZERO:
		position += dir.normalized() * move_speed * delta

func _input(event):
	if event is InputEventKey and event.pressed and camera:
		if event.keycode == KEY_Z:
			_adjust_zoom(1.0 - zoom_speed)
		elif event.keycode == KEY_X:
			_adjust_zoom(1.0 + zoom_speed)

func _adjust_zoom(factor: float):
	camera.zoom *= factor
	camera.zoom.x = clamp(camera.zoom.x, min_zoom.x, max_zoom.x)
	camera.zoom.y = clamp(camera.zoom.y, min_zoom.y, max_zoom.y)
