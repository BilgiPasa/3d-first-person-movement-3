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

# Camera FOV
var normal_fov: float = 90
var sprint_fov: float
var zoom_fov: float
var zoom_sprint_fov: float

# Camera Zoom
var zooming_speed: float = 12
var zoom_input: bool

# @export Variables
@export var player: Player
@export var camera: Camera3D
@export var camera_holder: Node3D
@export var camera_position: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	current_cam_rot_mult = NORMAL_CAM_ROT_MULT
	camera.fov = normal_fov

# * Get camera rotation input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		y_rot_deg -= event.relative.x * mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg -= event.relative.y * mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg = clamp(x_rot_deg, -90, 90)

func _process(delta: float) -> void:
	camera_position_and_rotation()
	fov_change(delta)

func camera_position_and_rotation() -> void:
	camera_holder.position = camera_position.position # Move camera holder to camera position
	camera_holder.rotation_degrees = Vector3(x_rot_deg, y_rot_deg, 0) # Rotate camera holder
	player.rotation_degrees = Vector3(0, y_rot_deg, 0) # Rotate player

func fov_change(proccess_delta: float) -> void:
	zoom_input = Input.is_action_pressed("camera_zoom") # Get camera_zoom input

	if !zoom_input:
		current_cam_rot_mult = NORMAL_CAM_ROT_MULT

		if !(Globals.dynamic_fov && player.current_state == player.States.RUNNING):
			if camera.fov > normal_fov - 0.01 && camera.fov < normal_fov + 0.01:
				camera.fov = normal_fov
			else:
				camera.fov = lerpf(camera.fov, normal_fov, zooming_speed * proccess_delta)
		else:
			sprint_fov = normal_fov + 10

			if camera.fov > sprint_fov - 0.01:
				camera.fov = sprint_fov
			else:
				camera.fov = lerpf(camera.fov, sprint_fov, zooming_speed * proccess_delta)
	else:
		current_cam_rot_mult = ZOOMED_CAM_ROT_MULT

		if !(Globals.dynamic_fov && player.current_state == player.States.RUNNING):
			zoom_fov = normal_fov / 5

			if camera.fov < zoom_fov + 0.01:
				camera.fov = zoom_fov
			else:
				camera.fov = lerpf(camera.fov, zoom_fov, zooming_speed * proccess_delta)
		else:
			zoom_sprint_fov = (normal_fov + 10) / 5

			if camera.fov > zoom_sprint_fov - 0.01 && camera.fov < zoom_sprint_fov + 0.01:
				camera.fov = zoom_sprint_fov
			else:
				camera.fov = lerpf(camera.fov, zoom_sprint_fov, zooming_speed * proccess_delta)

func get_player_speed() -> float:
	return player.get_speed()
