extends Node3D

# Camera Rotation Degrees
var x_rot_deg: float = 0
var y_rot_deg: float = 0

# Camera Rotation Multipliers
const NORMAL_CAM_ROT_MULT: int = 1
const ZOOMED_CAM_ROT_MULT: float = 0.5
var current_cam_rot_mult: float

# Camera FOV
var sprint_fov: int
var zoom_fov: float
var zoom_sprint_fov: float

# Camera Zoom
const ZOOMING_SPEED: int = 12
var zoom_input: bool

# @export Variables
@export var player: Player
@export var camera_position_marker: Marker3D
@export var camera: Camera3D

func _ready() -> void:
	top_level = true # This setting allows the CameraHolder node to move independently from its parent node, the Player node.
	current_cam_rot_mult = NORMAL_CAM_ROT_MULT
	camera.fov = Globals.normal_fov

# * Get camera rotation input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		y_rot_deg -= event.relative.x * Globals.mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg -= event.relative.y * Globals.mouse_sensitivity * current_cam_rot_mult * 0.001
		x_rot_deg = clamp(x_rot_deg, -90, 90)

func _process(delta: float) -> void:
	camera_position_and_rotation()
	fov_change(delta)

func camera_position_and_rotation() -> void:
	global_position = camera_position_marker.global_position # Move camera holder to camera position
	rotation_degrees = Vector3(x_rot_deg, y_rot_deg, 0) # Rotate camera holder
	player.y_rot_deg = y_rot_deg # Assign rotation degrees for player

func fov_change(process_delta: float) -> void:
	zoom_input = Input.is_action_pressed("camera_zoom") # Get camera_zoom input

	if !zoom_input:
		current_cam_rot_mult = NORMAL_CAM_ROT_MULT

		if !(Globals.sprint_fov_change > 0 && (player.current_state == player.States.RUNNING || (player.current_state == player.States.SLIDING && player.get_flat_speed() > player.run_speed))):
			if camera.fov > Globals.normal_fov - 0.01 && camera.fov < Globals.normal_fov + 0.01:
				camera.fov = Globals.normal_fov
			else:
				camera.fov = lerpf(camera.fov, Globals.normal_fov, ZOOMING_SPEED * process_delta)
		else:
			sprint_fov = Globals.normal_fov + Globals.sprint_fov_change

			if camera.fov > sprint_fov - 0.01:
				camera.fov = sprint_fov
			else:
				camera.fov = lerpf(camera.fov, sprint_fov, ZOOMING_SPEED * process_delta)
	else:
		current_cam_rot_mult = ZOOMED_CAM_ROT_MULT

		if !(Globals.sprint_fov_change > 0 && (player.current_state == player.States.RUNNING || (player.current_state == player.States.SLIDING && player.get_flat_speed() > player.run_speed))):
			zoom_fov = Globals.normal_fov / 5.0 # To make floating point division, 5.0 is written here instead of 5

			if camera.fov < zoom_fov + 0.01:
				camera.fov = zoom_fov
			else:
				camera.fov = lerpf(camera.fov, zoom_fov, ZOOMING_SPEED * process_delta)
		else:
			zoom_sprint_fov = (Globals.normal_fov + Globals.sprint_fov_change) / 5.0 # To make floating point division, 5.0 is written here instead of 5

			if camera.fov > zoom_sprint_fov - 0.01 && camera.fov < zoom_sprint_fov + 0.01:
				camera.fov = zoom_sprint_fov
			else:
				camera.fov = lerpf(camera.fov, zoom_sprint_fov, ZOOMING_SPEED * process_delta)
