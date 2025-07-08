extends Node2D

@export var move_speed := 300.0
@export var zoom_speed := 0.1
@export var camera: Camera2D

func _process(delta):
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): dir.x += 1

	if dir != Vector2.ZERO:
		position += dir.normalized() * move_speed * delta

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z:
			camera.zoom *= 1.0 - zoom_speed
		elif event.keycode == KEY_X:
			camera.zoom *= 1.0 + zoom_speed
