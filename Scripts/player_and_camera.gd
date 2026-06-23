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
var current_fov: int
var camera_zoom_input: bool

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

		# For testing
		#print(camera_holder.rotation_degrees)
		#print(player.rotation_degrees)

func _process(_delta: float) -> void:
	# * Get camera_zoom input
	camera_zoom_input = Input.is_action_pressed("camera_zoom")

	# * Move camera holder to camera position
	camera_holder.position = camera_position.position

	# * Handle camera rotation
	camera_holder.rotation_degrees = Vector3(x_rot_deg, y_rot_deg, 0)
	player.rotation_degrees = Vector3(0, y_rot_deg, 0)

	# * Assign camera FOV
	camera.fov = current_fov

func get_player_speed() -> float:
	return sqrt(pow(player.linear_velocity.x, 2) + pow(player.linear_velocity.z, 2))
