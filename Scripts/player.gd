class_name Player
extends RigidBody3D

signal set_crosshair_color(crosshair_color: Color)

# Movement
const GROUND_LINEAR_DAMP: int = 750
const AIR_LINEAR_DAMP: int = 5
const GROUND_MOVE_MULT: float = 750.01
const AIR_MOVE_MULT: float = 100.01
const MIN: float = 0.1
const RESET_LOW_LIN_V_TIMER_SECONDS: float = 0.5 # RESET_LOW_LINEAR_VELOCITY_TIMER_SECONDS
var move_speed: float = Globals.normal_speed
var gravity_amount: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var run_speed: float # NOTE: It is assigned at "move_speed_control" function
var run_input: bool
var trying_to_move_forward: bool
var air_damp_active: bool
var on_slope: bool
var move_vector: Vector3
var move_vector_relative_to_world: Vector3
var lin_vel_in_air_relative_to_cam: Vector3 # linear_velocity_in_air_relative_to_camera

# Crouch
var crouch_speed: float # NOTE: It is assigned at "move_speed_control" function
var min_sliding_speed: float # NOTE: It is assigned at "move_speed_control" function
var crouching: bool = false
var crouch_input: bool
var dont_uncrouch: bool

# Jump
const CAN_JUMP_TIMER_SECONDS: float = 0.3
const JUMPING_TIMER_SECONDS: float = 0.1
var can_jump: bool = true
var jumping: bool = false
var jump_input: bool

# Coyote Time
const COYOTE_TIME_SECONDS: float = 0.15
var coyote_time_counter: float

# Player States
enum States{IDLE, CROUCHING, WALKING, RUNNING, CROUCH_WALKING, SLIDING}
var current_state: States = States.IDLE

# Hold and Throw
const CAN_HOLD_TIMER_SECONDS: float = 0.6
const CAN_MUST_REL_OBJ_TIMER_SECONDS: float = 0.5 # CAN_MUST_RELEASE_OBJECT_TIMER_SECONDS
const CR_BLINK_RED_TIMER_SECONDS: float = 0.3 # CROSSHAIR_BLINK_RED_TIMER_SECONDS
var hold_force: int = 50000
var min_hold_distance: int = 3
var max_hold_distance: int = 6
var initial_hold_distance: int = 4
var let_go_holded_obj_distance: int = max_hold_distance * 2
var holded_obj_lin_damp_mode_was: int # holded_object_linear_damp_mode_was
var current_hold_distance: float = initial_hold_distance
var hold_distance_scroll_speed: float = 0.4
var holded_obj_vel_reducer_mult: float = 0.5 # holded_object_velocity_reducer_multiplier
var holded_obj_gravity_scale_was: float
var holded_object_linear_damp_was: float
var can_hold: bool = true
var can_must_release_object: bool = false
var interact_now: bool = false
var throw_now: bool = false
var holded_object: RigidBody3D = null

# Touch Detection
var touching: bool

# Ground Detection
const GROUNDED_AREA_RADIUS: float = 0.3
var grounded: bool

# Bump Detection
var bumping: bool

# Player Rotation Degrees
var y_rot_deg: float # NOTE: It is assigned by camera_holder.gd

# Player Sizes
const PLAYER_HEIGHT: float = 2.5 # NOTE: Don't make it smaller than 0.9
const CROUCH_HEIGHT_DIFFERENCE: float = 0.5 # NOTE: Don't make it bigger than 0.5 because if you do, you might see a visual bug when crouching.
var crouch_height: float = PLAYER_HEIGHT - CROUCH_HEIGHT_DIFFERENCE

# @export Variables
@export var camera_position_marker: Marker3D
@export var slope_ray_cast: RayCast3D
@export var can_jump_timer: Timer
@export var jumping_timer: Timer
@export var can_hold_timer: Timer
@export var can_must_release_object_timer: Timer
@export var crosshair_blink_red_timer: Timer
@export var reset_low_lin_velocity_timer: Timer # reset_low_linear_velocity_timer
@export var camera: Camera3D
@export var holded_object_position_marker: Marker3D
@export var hold_object_ray_cast: RayCast3D
@export var grounded_area: Area3D
@export var grounded_area_coll_shape: CollisionShape3D # INFO: It has a sphere shape
@export var dont_uncrouch_area: Area3D
@export var dont_uncrouch_area_coll_shape: CollisionShape3D # INFO: It has a sphere shape
@export var player_coll_shape: CollisionShape3D # INFO: It has a capsule shape
@export var player_mesh_inst: MeshInstance3D # INFO: It has a capsule mesh
@export var bump_area: Area3D
@export var bump_area_coll_shape: CollisionShape3D # INFO: It has a box shape

func _ready() -> void:
	# Initialize the process_mode
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Initialize RigidBody3D variables
	mass = 75
	can_sleep = false
	lock_rotation = true
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE

	# Initialize @export variables
	camera_position_marker.position = Vector3(0, (PLAYER_HEIGHT / 2) - 0.25, 0)
	slope_ray_cast.position = Vector3(0, (-PLAYER_HEIGHT / 2) + 0.05, 0)
	slope_ray_cast.target_position = Vector3(0, (-GROUNDED_AREA_RADIUS * 2) - 0.05, 0)
	can_jump_timer.wait_time = CAN_JUMP_TIMER_SECONDS
	jumping_timer.wait_time = JUMPING_TIMER_SECONDS
	can_hold_timer.wait_time = CAN_HOLD_TIMER_SECONDS
	can_must_release_object_timer.wait_time = CAN_MUST_REL_OBJ_TIMER_SECONDS
	crosshair_blink_red_timer.wait_time = CR_BLINK_RED_TIMER_SECONDS
	reset_low_lin_velocity_timer.wait_time = RESET_LOW_LIN_V_TIMER_SECONDS
	reset_low_lin_velocity_timer.start()
	holded_object_position_marker.position = Vector3(0, 0, -current_hold_distance)
	hold_object_ray_cast.target_position = Vector3(0, 0, -max_hold_distance)
	grounded_area.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
	grounded_area_coll_shape.shape.radius = GROUNDED_AREA_RADIUS
	dont_uncrouch_area.position = Vector3(0, (PLAYER_HEIGHT / 2) - player_coll_shape.shape.radius, 0)
	dont_uncrouch_area_coll_shape.shape.radius = player_coll_shape.shape.radius
	player_coll_shape.shape.height = PLAYER_HEIGHT
	player_mesh_inst.mesh.height = PLAYER_HEIGHT
	bump_area_coll_shape.shape.size.y = (PLAYER_HEIGHT / 2) + 0.1

# * Get inputs
func _process(_delta: float) -> void:
	jump_input = Input.is_action_pressed("jump")
	crouch_input = Input.is_action_pressed("crouch")
	run_input = Input.is_action_pressed("run") && Input.is_action_pressed("move_forward")

	# Forward is -Z, Back is Z, Right is X, Left is -X
	move_vector = Vector3(Input.get_axis("move_left", "move_right"), 0, Input.get_axis("move_forward", "move_back")).normalized()
	trying_to_move_forward = move_vector.z <= -MIN

	if Input.is_action_just_pressed("interact"):
		interact_now = true

	if holded_object:
		if Input.is_action_just_pressed("throw"):
			throw_now = true

		if Input.is_action_just_pressed("scroll_up"):
			current_hold_distance += hold_distance_scroll_speed

		if Input.is_action_just_pressed("scroll_down"):
			current_hold_distance -= hold_distance_scroll_speed

# * Handle other things
func _physics_process(delta: float) -> void:
	player_coll_shape.rotation_degrees.y = y_rot_deg
	touching = get_contact_count() > 0
	grounded = grounded_area.has_overlapping_bodies()
	bumping = bump_area.has_overlapping_bodies()
	coyote_time(delta)
	jump()
	crouch()
	handle_linear_damp(delta)
	movement(delta)
	current_state = state_machine(current_state)
	gravity_control(delta)
	move_speed_control()
	handle_hold_and_throw(delta)

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
		linear_velocity.y = Globals.jump_speed
		can_jump_timer.start()
		jumping_timer.start()

func _on_can_jump_timer_timeout() -> void:
	can_jump_timer.stop()
	can_jump = true # Reset can_jump

func _on_jumping_timer_timeout() -> void:
	jumping_timer.stop()
	jumping = false # Reset jumping

func crouch() -> void:
	if jumping:
		return

	if crouch_input && !crouching:
		camera_position_marker.position = Vector3(0, (crouch_height / 2) - 0.25, 0)
		slope_ray_cast.position = Vector3(0, (-crouch_height / 2) + 0.05, 0)
		grounded_area.position = Vector3(0, -crouch_height / 2, 0)
		player_coll_shape.shape.height = crouch_height
		player_mesh_inst.mesh.height = crouch_height
		bump_area_coll_shape.shape.size.y = (crouch_height / 2) + 0.1

		if grounded:
			position.y -= CROUCH_HEIGHT_DIFFERENCE / 2

		crouching = true
	elif crouching:
		dont_uncrouch = dont_uncrouch_area.has_overlapping_bodies()

		if !crouch_input && !dont_uncrouch:
			if grounded:
				position.y += CROUCH_HEIGHT_DIFFERENCE / 2

			slope_ray_cast.position = Vector3(0, (-PLAYER_HEIGHT / 2) + 0.05, 0)
			grounded_area.position = Vector3(0, -PLAYER_HEIGHT / 2, 0)
			player_coll_shape.shape.height = PLAYER_HEIGHT
			player_mesh_inst.mesh.height = PLAYER_HEIGHT
			bump_area_coll_shape.shape.size.y = (PLAYER_HEIGHT / 2) + 0.1
			camera_position_marker.position = Vector3(0, (PLAYER_HEIGHT / 2) - 0.25, 0)
			crouching = false

func handle_linear_damp(physics_process_delta: float) -> void:
	if grounded && !jumping && current_state != States.SLIDING:
		linear_damp = GROUND_LINEAR_DAMP * physics_process_delta
		air_damp_active = false
	else:
		linear_damp = AIR_LINEAR_DAMP * physics_process_delta
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

		# If (player is moving forward and player is faster than its movement speed in -Z) or (player is moving back and player is faster than its movement speed in Z)
		if (move_vector.z <= -MIN && lin_vel_in_air_relative_to_cam.z < -move_speed) || (move_vector.z >= MIN && lin_vel_in_air_relative_to_cam.z > move_speed):
			move_vector.z = 0 # Stop Z axis acceleration

		# If (player is moving right and player is faster than its movement speed in X) or (player is moving left and player is faster than its movement speed in -X)
		if (move_vector.x >= MIN && lin_vel_in_air_relative_to_cam.x > move_speed) || (move_vector.x <= -MIN && lin_vel_in_air_relative_to_cam.x < -move_speed):
			move_vector.x = 0 # Stop X axis acceleration

		# If player is faster than its movement speed
		if get_flat_speed() > move_speed:
			# If (player is moving forward and player is faster than half of its movement speed in -Z) or (player is moving back and player is faster than half of its movement speed in Z)
			if (move_vector.z <= -MIN && lin_vel_in_air_relative_to_cam.z < -move_speed / 2) || (move_vector.z >= MIN && lin_vel_in_air_relative_to_cam.z > move_speed / 2):
				move_vector.z = 0 # Stop Z axis acceleration

				# If (player is moving right and player is faster than half of its movement speed in X) or (player is moving left and player is faster than half of its movement speed in -X)
				if (move_vector.x >= MIN && lin_vel_in_air_relative_to_cam.x > move_speed / 2) || (move_vector.x <= -MIN && lin_vel_in_air_relative_to_cam.x < -move_speed / 2):
					move_vector.x = 0 # Stop X axis acceleration
			# Else if (player is moving right and player is faster than half of its movement speed in X) or (player is moving left and player is faster than half of its movement speed in -X)
			elif (move_vector.x >= MIN && lin_vel_in_air_relative_to_cam.x > move_speed / 2) || (move_vector.x <= -MIN && lin_vel_in_air_relative_to_cam.x < -move_speed / 2):
				move_vector.x = 0 # Stop X axis acceleration

				# If (player is moving forward and player is faster than half of its movement speed in -Z) or (player is moving back and player is faster than half of its movement speed in Z)
				if (move_vector.z <= -MIN && lin_vel_in_air_relative_to_cam.z < -move_speed / 2) || (move_vector.z >= MIN && lin_vel_in_air_relative_to_cam.z > move_speed / 2):
					move_vector.z = 0 # Stop Z axis acceleration
			# Else if (player is moving forward and not (player has Z velocity)) or (player is moving back and not (player has -Z velocity))
			elif (move_vector.z <= -MIN && !(lin_vel_in_air_relative_to_cam.z >= MIN)) || (move_vector.z >= MIN && !(lin_vel_in_air_relative_to_cam.z <= -MIN)):
				# If player is faster than its movement speed in X
				if lin_vel_in_air_relative_to_cam.x > move_speed:
					apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * rotate_vector_around_y_axis(Vector3.LEFT, deg_to_rad(y_rot_deg)))
				# If player is faster than its movement speed in -X
				elif lin_vel_in_air_relative_to_cam.x < -move_speed:
					apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * rotate_vector_around_y_axis(Vector3.RIGHT, deg_to_rad(y_rot_deg)))
			# Else if (player is moving right and not (player has -X velocity)) || (player is moving left and not (player has X velocity))
			elif (move_vector.x >= MIN && !(lin_vel_in_air_relative_to_cam.x <= -MIN)) || (move_vector.x <= -MIN && !(lin_vel_in_air_relative_to_cam.x >= MIN)):
				# If player is faster than its movement speed in -Z
				if lin_vel_in_air_relative_to_cam.z < -move_speed:
					apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * rotate_vector_around_y_axis(Vector3.BACK, deg_to_rad(y_rot_deg)))
				# If player is faster than its movement speed in Z
				elif lin_vel_in_air_relative_to_cam.z > move_speed:
					apply_force((move_speed / 2) * AIR_MOVE_MULT * physics_process_delta * mass * rotate_vector_around_y_axis(Vector3.FORWARD, deg_to_rad(y_rot_deg)))

		move_vector_relative_to_world = rotate_vector_around_y_axis(move_vector, deg_to_rad(y_rot_deg))

		if !on_slope:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world)
		else:
			apply_force(move_speed * AIR_MOVE_MULT * physics_process_delta * mass * move_vector_relative_to_world.slide(slope_ray_cast.get_collision_normal()))

func rotate_vector_around_y_axis(vector: Vector3, radians: float) -> Vector3:
	return Vector3(vector.x * cos(radians) + vector.z * sin(radians), vector.y, -vector.x * sin(radians) + vector.z * cos(radians))

func state_machine(state: States) -> States:
	if state == States.IDLE:
		if get_flat_speed() >= MIN:
			return States.WALKING
		elif crouching:
			return States.CROUCHING
		else:
			return States.IDLE
	elif state == States.CROUCHING:
		if crouching:
			if on_slope:
				return States.SLIDING
			elif get_flat_speed() >= MIN:
				return States.CROUCH_WALKING
			else:
				return States.CROUCHING
		else:
			return States.IDLE
	elif state == States.WALKING:
		if get_flat_speed() >= MIN:
			if crouching:
				return States.CROUCH_WALKING
			elif run_input:
				return States.RUNNING
			else:
				return States.WALKING
		else:
			return States.IDLE
	elif state == States.RUNNING:
		if get_flat_speed() >= MIN:
			if crouching:
				return States.CROUCH_WALKING
			elif run_input:
				return States.RUNNING
			elif bumping || !trying_to_move_forward:
				return States.WALKING
			else:
				return States.RUNNING
		else:
			return States.IDLE
	elif state == States.CROUCH_WALKING:
		if crouching:
			if on_slope:
				return States.SLIDING
			elif get_flat_speed() >= min_sliding_speed:
				return States.SLIDING
			elif get_flat_speed() >= MIN:
				return States.CROUCH_WALKING
			else:
				return States.CROUCHING
		else:
			return States.WALKING
	elif state == States.SLIDING:
		if crouching:
			if on_slope:
				return States.SLIDING
			elif get_flat_speed() >= min_sliding_speed:
				return States.SLIDING
			else:
				return States.CROUCH_WALKING
		else:
			return States.WALKING
	else:
		return States.IDLE

# Return the player speed at XZ plane
func get_flat_speed() -> float:
	return sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z, 2))

func gravity_control(physics_process_delta: float) -> void:
	if touching && grounded:
		if current_state == States.SLIDING:
			gravity_scale = 1
		elif on_slope && linear_velocity.y >= MIN:
			gravity_scale = 1
			apply_force((gravity_amount - 10) * physics_process_delta * mass * Vector3.UP)
		else:
			gravity_scale = 0
	else:
		gravity_scale = 1

# I assigned the crouch_speed and the run_speed here because I can change the normal_speed in PlayerTweaksMenu
func move_speed_control() -> void:
	match current_state:
		States.CROUCHING, States.CROUCH_WALKING:
			crouch_speed = Globals.normal_speed * 2.0 / 3.0
			move_speed = crouch_speed
		States.RUNNING:
			run_speed = Globals.normal_speed * 4.0 / 3.0
			move_speed = run_speed
		States.SLIDING:
			run_speed = Globals.normal_speed * 4.0 / 3.0
			min_sliding_speed = run_speed
			crouch_speed = Globals.normal_speed * 2.0 / 3.0
			move_speed = crouch_speed
		_:
			move_speed = Globals.normal_speed

func handle_hold_and_throw(physics_process_delta: float) -> void:
	if holded_object:
		holded_object.apply_force(hold_force * physics_process_delta * holded_object.mass * (holded_object_position_marker.global_position - holded_object.global_position))
		holded_object.linear_velocity *= holded_obj_vel_reducer_mult
		holded_object.angular_velocity *= holded_obj_vel_reducer_mult

		if throw_now:
			throw_now = false
			holded_object.apply_impulse(Globals.throw_force * -camera.global_basis.z);
			release_holded_object(false)
			return

		# If the holded object is too far from the holded_object_position_marker, release the object and reset its linear and angular velocities.
		if (holded_object_position_marker.global_position - holded_object.global_position).length() > let_go_holded_obj_distance:
			release_holded_object(true)
			return

		if current_hold_distance > max_hold_distance:
			current_hold_distance = max_hold_distance
		elif current_hold_distance < min_hold_distance:
			current_hold_distance = min_hold_distance

		holded_object_position_marker.position.z = -current_hold_distance

		if can_must_release_object:
			# Release holded object if Player is touching to it
			for i in get_colliding_bodies():
				if i == holded_object:
					release_holded_object(true)
					return

			# Release holded object if Player is standing on it
			for i in grounded_area.get_overlapping_bodies():
				if i == holded_object:
					release_holded_object(true)
					return

	if interact_now:
		interact_now = false

		if holded_object:
			release_holded_object(false)
			return

		if hold_object_ray_cast.is_colliding() && can_hold && hold_object_ray_cast.get_collider() is RigidBody3D && !hold_object_ray_cast.get_collider().freeze:
			can_hold = false
			can_must_release_object = false
			holded_object = hold_object_ray_cast.get_collider()
			holded_obj_gravity_scale_was = holded_object.gravity_scale
			holded_object.gravity_scale = 0
			holded_object_linear_damp_was = holded_object.linear_damp
			holded_object.linear_damp = 0
			holded_obj_lin_damp_mode_was = int(holded_object.linear_damp_mode)
			holded_object.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			set_crosshair_color.emit(Color.CYAN)
			can_hold_timer.start()
			can_must_release_object_timer.start()
		elif can_hold:
			can_hold = false
			crosshair_blink_red()
			can_hold_timer.start()

func release_holded_object(reset_velocities: bool) -> void:
	holded_object.gravity_scale = holded_obj_gravity_scale_was
	holded_object.linear_damp = holded_object_linear_damp_was
	holded_object.linear_damp_mode = holded_obj_lin_damp_mode_was as RigidBody3D.DampMode

	if reset_velocities:
		holded_object.linear_velocity = Vector3.ZERO
		holded_object.angular_velocity = Vector3.ZERO

	holded_object = null
	current_hold_distance = initial_hold_distance
	set_crosshair_color.emit(Color.BLACK)

func crosshair_blink_red() -> void:
	set_crosshair_color.emit(Color.RED)
	crosshair_blink_red_timer.start()

func _on_can_hold_timer_timeout() -> void:
	can_hold_timer.stop()
	can_hold = true # Reset can_hold

func _on_can_must_r_o_timer_timeout() -> void: # _on_can_must_release_object_timer_timeout
	can_must_release_object_timer.stop()
	can_must_release_object = true # Enable mandatorily releasing object

func _on_cr_blink_red_timer_timeout() -> void: # _on_crosshair_blink_red_timer_timeout
	crosshair_blink_red_timer.stop()
	set_crosshair_color.emit(Color.BLACK)

func _on_reset_l_l_v_timer_timeout() -> void: # _on_reset_low_linear_velocity_timer_timeout
	if linear_velocity.length() <= MIN:
		linear_velocity = Vector3.ZERO
