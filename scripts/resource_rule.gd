extends Resource
class_name ResourceRule

@export var name: String = "Iron"
@export var color: Color = Color(1, 0, 0, 1)
@export_range(0.0, 1.0) var min_height: float = 0.8
@export_range(0.0, 1.0) var max_height: float = 0.9
@export_range(0.0, 1.0) var min_noise: float = 0.2
@export_range(0.0, 1.0) var max_noise: float = 0.8
