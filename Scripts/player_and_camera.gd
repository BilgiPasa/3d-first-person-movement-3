class_name PlayerAndCamera
extends Node3D

@export var player: Player
@export var camera: Camera3D
@export var camera_position: Node3D
var mouse_sensitivity: int
var x_rotation: int
var y_rotation: int
var camera_zoom_input: bool

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	camera_zoom_input = Input.is_action_pressed("camera_zoom")

func get_player_speed() -> float:
	return sqrt(pow(player.linear_velocity.x, 2) + pow(player.linear_velocity.z, 2))
