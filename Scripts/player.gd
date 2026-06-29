class_name Player
extends RigidBody3D

# Note: I changed the default gravity to 30 m/s^2 in Project Settings
# Note2: I have set the layers and the masks in the editor.

# Movement
const AIR_MOVE_MULT: int = 100
const GROUND_MOVE_MULT: float = 750.01
const GROUND_LINEAR_DAMP: float = 12.4
const AIR_LINEAR_DAMP: float = 0.001
const MIN: float = 0.1
var normal_speed: int = Defaults.normal_speed
var run_speed: float = Defaults.normal_speed * 4.0 / 3.0
var move_speed: float
var run_input: bool
var trying_to_go_forward: bool
var air_damp_active: bool
var on_slope: bool
var move_vector: Vector3
var move_vector_relative_to_world: Vector3
var lin_vel_in_air_relative_to_cam: Vector3 # linear velocity in air relative to camera

# For optimization in movement
var trying_to_go_forward_in_air: bool
var trying_to_go_back_in_air: bool
var trying_to_go_right_in_air: bool
var trying_to_go_left_in_air: bool

# Crouch
var crouch_speed: float = Defaults.normal_speed * 2.0 / 3.0
var crouching: bool = false
var crouch_input: bool
var dont_uncrouch: bool

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
	IDLE = 0,
	CROUCHING = 1,
	WALKING = 2,
	RUNNING = 3,
	CROUCH_WALKING = 4
}

# Player State Variable
var current_state: States

# Touch Detection
var touching: bool

# Ground Detection
const GROUNDED_AREA_SPHERE_RADIUS: float = 0.3
var grounded: bool

# Bump Detection
const BUMP_AREA_BOX_SIZE: Vector3 = Vector3(0.6, 1.2, 0.1)
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
@export var dont_uncrouch_area: Area3D
@export var dont_uncrouch_area_sp_sh: SphereShape3D # dont uncrouch area sphere shape

func _ready() -> void:
	mass = 75
	can_sleep = false
	lock_rotation = true
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	player_capsule_mesh.height = PLAYER_HEIGHT
	player_capsule_mesh.radius = PLAYER_RADIUS
	player_capsule_shape.height = PLAYER_HEIGHT
	player_capsule_shape.radius = PLAYER_RADIUS
	camera_position.position = Vector3(0, (PLAYER_HEIGHT / 2) - 0.25, 0)
	slope_ray_cast.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
	slope_ray_cast.target_position = Vector3(0, -GROUNDED_AREA_SPHERE_RADIUS * 2, 0)
	can_jump_timer.wait_time = CAN_JUMP_TIMER_SECONDS
	jumping_timer.wait_time = JUMPING_TIMER_SECONDS
	grounded_area.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
	grounded_area_sphere_shape.radius = GROUNDED_AREA_SPHERE_RADIUS
	bump_area.position = Vector3(0, 0, -(PLAYER_RADIUS + BUMP_AREA_BOX_SIZE.z / 2))
	bump_area_box_shape.size = BUMP_AREA_BOX_SIZE
	dont_uncrouch_area.position = Vector3(0, (PLAYER_HEIGHT / 4) - 0.025, 0)
	dont_uncrouch_area_sp_sh.radius = PLAYER_RADIUS

# * Get inputs
func _process(_delta: float) -> void:
	jump_input = Input.is_action_pressed("jump")
	crouch_input = Input.is_action_pressed("crouch")
	run_input = Input.is_action_pressed("run") && Input.is_action_pressed("move_forward")

	# Forward is -Z, Backwards is Z, Right is X, Left is -X
	move_vector = Vector3(Input.get_axis("move_left", "move_right"), 0, -Input.get_axis("move_back", "move_forward")).normalized()
	trying_to_go_forward = move_vector.z < -MIN

# * Handle other things
func _physics_process(delta: float) -> void:
	rotation_degrees.y = y_rot_deg
	touching = get_contact_count() > 0
	grounded = grounded_area.has_overlapping_bodies()
	bumping = bump_area.has_overlapping_bodies()
	coyote_time(delta)
	jump()
	crouch()
	handle_linear_damp()
	movement(delta)
	current_state = player_state_machine(current_state)
	gravity_control()
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

func crouch() -> void:
	if jumping:
		return

	if crouch_input && !crouching:
		player_capsule_mesh.height = CROUCH_HEIGHT
		player_capsule_shape.height = CROUCH_HEIGHT
		camera_position.position = Vector3(0, (CROUCH_HEIGHT / 2) - 0.25, 0)
		slope_ray_cast.position = Vector3(0, -CROUCH_HEIGHT / 2, 0)
		grounded_area.position = Vector3(0, -CROUCH_HEIGHT / 2, 0)
		bump_area_box_shape.size.y *= CROUCH_HEIGHT / PLAYER_HEIGHT
		crouching = true
	elif crouching:
		dont_uncrouch = dont_uncrouch_area.has_overlapping_bodies()

		if !crouch_input && !dont_uncrouch:
			player_capsule_mesh.height = PLAYER_HEIGHT
			player_capsule_shape.height = PLAYER_HEIGHT
			camera_position.position = Vector3(0, (PLAYER_HEIGHT / 2) - 0.25, 0)
			slope_ray_cast.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
			grounded_area.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
			bump_area_box_shape.size.y *= PLAYER_HEIGHT / CROUCH_HEIGHT
			crouching = false

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
		move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))

		if !on_slope:
			apply_force(move_speed * GROUND_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world)
		else:
			apply_force(move_speed * GROUND_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world.slide(slope_ray_cast.get_collision_normal()))
	else:
		lin_vel_in_air_relative_to_cam = rotate_vector_around_y_axis(linear_velocity, -deg_to_rad(y_rot_deg))
		trying_to_go_forward_in_air = trying_to_go_forward
		trying_to_go_back_in_air = move_vector.z > MIN
		trying_to_go_right_in_air = move_vector.x > MIN
		trying_to_go_left_in_air = move_vector.x < -MIN

		if (trying_to_go_forward_in_air && lin_vel_in_air_relative_to_cam.z < -move_speed) || (trying_to_go_back_in_air && lin_vel_in_air_relative_to_cam.z > move_speed):
			move_vector.z = 0

		if (trying_to_go_right_in_air && lin_vel_in_air_relative_to_cam.x > move_speed) || (trying_to_go_left_in_air && lin_vel_in_air_relative_to_cam.x < -move_speed):
			move_vector.x = 0

		if get_speed() > move_speed:
			if (trying_to_go_forward_in_air && lin_vel_in_air_relative_to_cam.z > -move_speed && lin_vel_in_air_relative_to_cam.z < -move_speed * 0.4 && trying_to_go_right_in_air && lin_vel_in_air_relative_to_cam.x < move_speed && lin_vel_in_air_relative_to_cam.x > move_speed * 0.4) || (trying_to_go_forward_in_air && lin_vel_in_air_relative_to_cam.z > -move_speed && lin_vel_in_air_relative_to_cam.z < -move_speed * 0.4 && trying_to_go_left_in_air && lin_vel_in_air_relative_to_cam.x > -move_speed && lin_vel_in_air_relative_to_cam.x < -move_speed * 0.4) || (trying_to_go_back_in_air && lin_vel_in_air_relative_to_cam.z < move_speed && lin_vel_in_air_relative_to_cam.z > move_speed * 0.4 && trying_to_go_right_in_air && lin_vel_in_air_relative_to_cam.x < move_speed && lin_vel_in_air_relative_to_cam.x > move_speed * 0.4) || (trying_to_go_back_in_air && lin_vel_in_air_relative_to_cam.z < move_speed && lin_vel_in_air_relative_to_cam.z > move_speed * 0.4 && trying_to_go_left_in_air && lin_vel_in_air_relative_to_cam.x > -move_speed && lin_vel_in_air_relative_to_cam.x < -move_speed * 0.4):
				move_vector.z = 0
				move_vector.x = 0
			else:
				if (trying_to_go_forward_in_air && lin_vel_in_air_relative_to_cam.z < -move_speed / 2) || (trying_to_go_back_in_air && lin_vel_in_air_relative_to_cam.z > move_speed / 2):
					move_vector.z = 0
				else:
					if (trying_to_go_forward_in_air || trying_to_go_back_in_air) && !(trying_to_go_forward_in_air && lin_vel_in_air_relative_to_cam.z > MIN) && !(trying_to_go_back_in_air && lin_vel_in_air_relative_to_cam.z < -MIN):
						if lin_vel_in_air_relative_to_cam.x > move_speed:
							move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(move_vector_relative_to_world.z) * rotate_vector_around_y_axis(Vector3.LEFT, deg_to_rad(y_rot_deg)))
						elif lin_vel_in_air_relative_to_cam.x < -move_speed:
							move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(move_vector_relative_to_world.z) * rotate_vector_around_y_axis(Vector3.RIGHT, deg_to_rad(y_rot_deg)))

				if (trying_to_go_right_in_air && lin_vel_in_air_relative_to_cam.x > move_speed / 2) || (trying_to_go_left_in_air && lin_vel_in_air_relative_to_cam.x < -move_speed / 2):
					move_vector.x = 0
				else:
					if (trying_to_go_right_in_air || trying_to_go_left_in_air) && !(trying_to_go_right_in_air && lin_vel_in_air_relative_to_cam.x < -MIN) && !(trying_to_go_left_in_air && lin_vel_in_air_relative_to_cam.x > MIN):
						if lin_vel_in_air_relative_to_cam.z < -move_speed:
							move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(move_vector_relative_to_world.x) * rotate_vector_around_y_axis(Vector3.BACK, deg_to_rad(y_rot_deg)))
						elif lin_vel_in_air_relative_to_cam.z > move_speed:
							move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))
							apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * abs(move_vector_relative_to_world.x) * rotate_vector_around_y_axis(Vector3.FORWARD, deg_to_rad(y_rot_deg)))

		move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))

		if !on_slope:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world)
		else:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world.slide(slope_ray_cast.get_collision_normal()))

func rotate_vector_around_y_axis(vector: Vector3, radians: float) -> Vector3:
	return Vector3(vector.x * cos(radians) + vector.z * sin(radians), vector.y, -vector.x * sin(radians) + vector.z * cos(radians))

func player_state_machine(state: States) -> States:
	if state == States.IDLE:
		if get_speed() > MIN:
			return States.WALKING
		else:
			if crouch_input:
				return States.CROUCHING
			else:
				return States.IDLE
	elif state == States.CROUCHING:
		if get_speed() > MIN:
			return States.CROUCH_WALKING
		else:
			if crouch_input:
				return States.CROUCHING
			else:
				return States.IDLE
	elif state == States.WALKING:
		if get_speed() > MIN:
			if crouch_input:
				return States.CROUCH_WALKING
			elif run_input:
				return States.RUNNING
			else:
				return States.WALKING
		else:
			return States.IDLE
	elif state == States.RUNNING:
		if get_speed() > MIN:
			if crouching:
				return States.CROUCH_WALKING
			elif run_input:
				return States.RUNNING
			else:
				if bumping || !trying_to_go_forward:
					return States.WALKING
				else:
					return States.RUNNING
		else:
			return States.IDLE
	elif state == States.CROUCH_WALKING:
		if get_speed() > MIN:
			if crouch_input:
				return States.CROUCH_WALKING
			else:
				return States.WALKING
		else:
			return States.CROUCHING
	else:
		return state

func get_speed() -> float:
	return sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z, 2))

func gravity_control() -> void:
	if touching && grounded:
		if on_slope && linear_velocity.y > MIN:
			gravity_scale = 1
			apply_force(20 * mass * Vector3.UP) # Change this line if you change gravity. (30 - 20 = 10)
		else:
			gravity_scale = 0
	else:
		gravity_scale = 1

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
