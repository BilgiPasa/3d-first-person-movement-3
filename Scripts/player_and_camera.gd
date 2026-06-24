class_name PlayerAndCamera
extends Node3D

# Camera Rotation
var mouse_sensitivity: int = 100
var x_rot_deg: float = 0
var y_rot_deg: float = 0

# Camera Rotation Multipliers
const NORMAL_CAM_ROT_MULT: int = 1
const ZOOMED_CAM_ROT_MULT: float = 0.5
var current_cam_rot_mult: float

# Camera Zoom
var normal_fov: int = 90
var sprint_fov: int
var zoom_fov: int
var zoom_sprint_fov: int
var current_fov: int
var zoom_input: bool

# @export Variables
@export var player: Player
@export var camera: Camera3D
@export var camera_holder: Node3D
@export var camera_position: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	current_cam_rot_mult = NORMAL_CAM_ROT_MULT
	current_fov = normal_fov

# * Get camera rotation input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		y_rot_deg -= event.relative.x * mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg -= event.relative.y * mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg = clamp(x_rot_deg, -90, 90)

func _process(_delta: float) -> void:
	camera_position_and_rotation()
	fov_change()

func camera_position_and_rotation() -> void:
	camera_holder.position = camera_position.position # Move camera holder to camera position
	camera_holder.rotation_degrees = Vector3(x_rot_deg, y_rot_deg, 0) # Rotate camera holder
	player.rotation_degrees = Vector3(0, y_rot_deg, 0) # Rotate player

func fov_change() -> void:
	zoom_input = Input.is_action_pressed("camera_zoom") # Get camera_zoom input

	if !zoom_input:
		current_cam_rot_mult = NORMAL_CAM_ROT_MULT
		# TODO: Add more code
	else:
		current_cam_rot_mult = ZOOMED_CAM_ROT_MULT
		# TODO: Add more code

	camera.fov = current_fov # Assign camera FOV

func get_player_speed() -> float:
	return sqrt(pow(player.linear_velocity.x, 2) + pow(player.linear_velocity.z, 2))
