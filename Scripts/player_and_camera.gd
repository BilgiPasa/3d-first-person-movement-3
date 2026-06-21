class_name PlayerAndCamera
extends Node3D

@export var player: Player
@export var camera: Camera3D
@export var camera_position: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func get_player_speed() -> float:
	return sqrt(pow(player.linear_velocity.x, 2) + pow(player.linear_velocity.z, 2))
