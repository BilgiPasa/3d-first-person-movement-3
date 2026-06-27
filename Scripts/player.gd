class_name Player
extends RigidBody3D

# Note: I changed the default gravity to 30 m/s^2 in Project Settings
# Note2: I have set the layers and the masks in the editor.

# Movement
const AIR_MOVE_MULT: int = 200
const GROUND_MOVE_MULT: float = 750.005
const GROUND_LINEAR_DAMP: float = 12.4
const AIR_LINEAR_DAMP: float = 0.04
const MIN: float = 0.1
var normal_speed: int = Defaults.normal_speed
var run_speed: float = Defaults.normal_speed * 4.0 / 3.0
var move_speed: float
var run_input: bool
var air_damp_active: bool
var on_slope: bool
var trying_to_go_forward_in_air: bool
var trying_to_go_back_in_air: bool
var trying_to_go_right_in_air: bool
var trying_to_go_left_in_air: bool
var move_vector: Vector3
var relative_move_vector: Vector3 # move vector relative to camera
var relative_velocity_in_air: Vector3 # velocity in air relative to camera

# Crouch
var crouch_speed: float = Defaults.normal_speed * 2.0 / 3.0
var crouch_input: bool

# Jump
const CAN_JUMP_TIMER_SECONDS: float = 0.3
const JUMPING_TIMER_SECONDS: float = 0.1
var jump_force: int = Defaults.jump_force
var can_jump: bool = true
var jumping: bool = false
var jump_input: bool

# Coyote Time
const COYOTE_TIME_SECONDS: float = 0.15
var coyote_time_counter: float

# Player States
enum States
{
	IDLE,
	WALKING,
	RUNNING,
	CROUCHING,
	CROUCH_WALKING
}

# Player State Variable
var current_state: States

# Touch Detection
var touching: bool

# Ground Detection
const GROUNDED_AREA_SPHERE_RADIUS: float = 0.3
var grounded: bool

# Bump Detection
const BUMP_AREA_BOX_SIZE: Vector3 = Vector3(0.6, 1.1, 0.1)
var bumping: bool

# Player Rotation
var y_rot_deg: float # This variable is assigned by the player_and_camera script

# Player Sizes
const PLAYER_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.5
const PLAYER_RADIUS: float = 0.5

# @export Variables
@export var player_capsule_mesh: CapsuleMesh
@export var player_capsule_shape: CapsuleShape3D
@export var camera_position: Node3D
@export var slope_ray_cast: RayCast3D
@export var can_jump_timer: Timer
@export var jumping_timer: Timer
@export var grounded_area: Area3D
@export var grounded_area_sphere_shape: SphereShape3D
@export var bump_area: Area3D
@export var bump_area_box_shape: BoxShape3D

func _ready() -> void:
	can_sleep = false
	lock_rotation = true
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	player_capsule_mesh.height = PLAYER_HEIGHT
	player_capsule_mesh.radius = PLAYER_RADIUS
	player_capsule_shape.height = PLAYER_HEIGHT
	player_capsule_shape.radius = PLAYER_RADIUS
	camera_position.position.y = (PLAYER_HEIGHT / 2) - 0.25
	slope_ray_cast.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
	slope_ray_cast.target_position = Vector3(0, GROUNDED_AREA_SPHERE_RADIUS * 2, 0)
	can_jump_timer.wait_time = CAN_JUMP_TIMER_SECONDS
	jumping_timer.wait_time = JUMPING_TIMER_SECONDS
	grounded_area.position.y = -PLAYER_HEIGHT / 2
	grounded_area_sphere_shape.radius = GROUNDED_AREA_SPHERE_RADIUS
	bump_area.position.z = -PLAYER_RADIUS / 2
	bump_area_box_shape.size = BUMP_AREA_BOX_SIZE

# * Get inputs
func _process(_delta: float) -> void:
	run_input = Input.is_action_pressed("run") && Input.is_action_pressed("move_forward")
	crouch_input = Input.is_action_pressed("crouch")
	jump_input = Input.is_action_pressed("jump")

	# Forward is -Z, Backwards is Z, Right is X, Left is -X
	move_vector = Vector3(Input.get_axis("move_left", "move_right"), 0, -Input.get_axis("move_back", "move_forward")).normalized()

# * Handle other things
func _physics_process(delta: float) -> void:
	rotation_degrees.y = y_rot_deg
	touching = get_contact_count() > 0
	grounded = grounded_area.has_overlapping_bodies()
	bumping = bump_area.has_overlapping_bodies()
	coyote_time(delta)
	jump()
	handle_linear_damp()
	movement(delta)
	current_state = player_state_machine(current_state)
	move_speed_control()

func coyote_time(physics_process_delta: float) -> void:
	if grounded:
		coyote_time_counter = COYOTE_TIME_SECONDS
	elif coyote_time_counter <= 0:
		coyote_time_counter = 0
	else:
		coyote_time_counter -= physics_process_delta

func jump() -> void:
	if jump_input && can_jump && !jumping && ((touching && grounded) || (!grounded && coyote_time_counter > 0)):
		can_jump = false
		jumping = true
		linear_velocity.y = jump_force
		can_jump_timer.start()
		jumping_timer.start()

func _on_can_jump_timer_timeout() -> void:
	# Reset can_jump and reset the timer
	can_jump = true
	can_jump_timer.stop()
	can_jump_timer.wait_time = CAN_JUMP_TIMER_SECONDS

func _on_jumping_timer_timeout() -> void:
	# Reset jumping and reset the timer
	jumping = false
	jumping_timer.stop()
	jumping_timer.wait_time = JUMPING_TIMER_SECONDS

func handle_linear_damp() -> void:
	if grounded && !jumping:
		linear_damp = GROUND_LINEAR_DAMP
		air_damp_active = false
	else:
		linear_damp = AIR_LINEAR_DAMP
		air_damp_active = true

func movement(physics_process_delta: float) -> void:
	on_slope = slope_ray_cast.is_colliding() && slope_ray_cast.get_collision_normal() != Vector3.UP

	if !air_damp_active:
		relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))

		if !on_slope:
			apply_force(move_speed * GROUND_MOVE_MULT * physics_process_delta * mass * relative_move_vector)
		else:
			apply_force(move_speed * GROUND_MOVE_MULT * physics_process_delta * mass * relative_move_vector.project(slope_ray_cast.get_collision_normal()))
	else:
		relative_velocity_in_air = rotate_vector_around_y_axis(linear_velocity, -deg_to_rad(y_rot_deg))
		trying_to_go_forward_in_air = move_vector.z < -MIN
		trying_to_go_back_in_air = move_vector.z > MIN
		trying_to_go_right_in_air = move_vector.x > MIN
		trying_to_go_left_in_air = move_vector.x < -MIN

		if (trying_to_go_forward_in_air && relative_velocity_in_air.z < -move_speed) || (trying_to_go_back_in_air && relative_velocity_in_air.z > move_speed):
			move_vector.z = 0

		if (trying_to_go_right_in_air && relative_velocity_in_air.x > move_speed) || (trying_to_go_left_in_air && relative_velocity_in_air.x < -move_speed):
			move_vector.x = 0

		if relative_velocity_in_air.length() > move_speed:
			if (trying_to_go_forward_in_air && relative_velocity_in_air.z > -move_speed && relative_velocity_in_air.z < -move_speed * 0.4 && trying_to_go_right_in_air && relative_velocity_in_air.x < move_speed && relative_velocity_in_air.x > move_speed * 0.4) || (trying_to_go_forward_in_air && relative_velocity_in_air.z > -move_speed && relative_velocity_in_air.z < -move_speed * 0.4 && trying_to_go_left_in_air && relative_velocity_in_air.x > -move_speed && relative_velocity_in_air.x < -move_speed * 0.4) || (trying_to_go_back_in_air && relative_velocity_in_air.z < move_speed && relative_velocity_in_air.z > move_speed * 0.4 && trying_to_go_right_in_air && relative_velocity_in_air.x < move_speed && relative_velocity_in_air.x > move_speed * 0.4) || (trying_to_go_back_in_air && relative_velocity_in_air.z < move_speed && relative_velocity_in_air.z > move_speed * 0.4 && trying_to_go_left_in_air && relative_velocity_in_air.x > -move_speed && relative_velocity_in_air.x < -move_speed * 0.4):
				move_vector.z = 0
				move_vector.x = 0
			else:
				if (trying_to_go_forward_in_air && relative_velocity_in_air.z < -move_speed / 2) || (trying_to_go_back_in_air && relative_velocity_in_air.z > move_speed / 2):
					move_vector.z = 0
				else:
					if (trying_to_go_forward_in_air || trying_to_go_back_in_air) && !(trying_to_go_forward_in_air && relative_velocity_in_air.z > MIN) && !(trying_to_go_back_in_air && relative_velocity_in_air.z < -MIN):
						if relative_velocity_in_air.x > move_speed:
							relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(relative_move_vector.z) * rotate_vector_around_y_axis(Vector3.LEFT, deg_to_rad(y_rot_deg)))
						elif relative_velocity_in_air.x < -move_speed:
							relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(relative_move_vector.z) * rotate_vector_around_y_axis(Vector3.RIGHT, deg_to_rad(y_rot_deg)))

				if (trying_to_go_right_in_air && relative_velocity_in_air.x > move_speed / 2) || (trying_to_go_left_in_air && relative_velocity_in_air.x < -move_speed / 2):
					move_vector.x = 0
				else:
					if (trying_to_go_right_in_air || trying_to_go_left_in_air) && !(trying_to_go_right_in_air && relative_velocity_in_air.x < -MIN) && !(trying_to_go_left_in_air && relative_velocity_in_air.x > MIN):
						if relative_velocity_in_air.z < -move_speed:
							relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(relative_move_vector.x) * rotate_vector_around_y_axis(Vector3.BACK, deg_to_rad(y_rot_deg)))
						elif relative_velocity_in_air.z > move_speed:
							relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(relative_move_vector.x) * rotate_vector_around_y_axis(Vector3.FORWARD, deg_to_rad(y_rot_deg)))

		relative_move_vector = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))

		if !on_slope:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * relative_move_vector)
		else:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * relative_move_vector.project(slope_ray_cast.get_collision_normal()))

func rotate_vector_around_y_axis(vector: Vector3, radians: float) -> Vector3:
	return Vector3(vector.x * cos(radians) + vector.z * sin(radians), vector.y, -vector.x * sin(radians) + vector.z * cos(radians))

func player_state_machine(state: States) -> States:
	if state == States.IDLE:
		if is_moving_with_WASD():
			return States.WALKING
		else:
			if crouch_input:
				return States.CROUCHING
			else:
				return States.IDLE
	elif state == States.CROUCHING:
		if is_moving_with_WASD():
			return States.CROUCH_WALKING
		else:
			if crouch_input:
				return States.CROUCHING
			else:
				return States.IDLE
	elif state == States.WALKING:
		if is_moving_with_WASD():
			if crouch_input:
				return States.CROUCH_WALKING
			elif run_input:
				return States.RUNNING
			else:
				return States.WALKING
		else:
			return States.IDLE
	elif state == States.RUNNING:
		if is_moving_with_WASD():
			if run_input:
				return States.RUNNING
			else:
				if bumping:
					return States.WALKING
				else:
					return States.RUNNING
		else:
			return States.IDLE
	elif state == States.CROUCH_WALKING:
		if is_moving_with_WASD():
			if crouch_input:
				return States.CROUCH_WALKING
			else:
				return States.WALKING
		else:
			return States.CROUCHING
	else:
		return States.IDLE

func is_moving_with_WASD() -> bool:
	return move_vector.length() > MIN && get_speed() > MIN

func get_speed() -> float:
	return sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z, 2))

func move_speed_control() -> void:
	match current_state:
		States.CROUCHING, States.CROUCH_WALKING:
			move_speed = crouch_speed
		States.RUNNING:
			move_speed = run_speed
		_:
			move_speed = normal_speed

	if abs(linear_velocity.z) <= MIN:
		linear_velocity.z = 0

	if abs(linear_velocity.x) <= MIN:
		linear_velocity.x = 0

	if abs(linear_velocity.y) <= MIN:
		linear_velocity.y = 0
