class_name Player
extends RigidBody3D

# Note: I changed the default gravity to 30 m/s^2 in Project Settings
# Note2: I have set the layers and the masks in the editor.

# Movement
const NORMAL_SPEED: int = 9
const RUN_SPEED: int = 12
const MIN: float = 0.1
var move_speed: int
var run_input: bool
var move_vector: Vector2 # X is X, Y is -Z.

# Crouch
const CROUCH_SPEED: int = 6
var crouch_input: bool

# Jump
const CAN_JUMP_TIMER_SECONDS: float = 0.3
const JUMPING_TIMER_SECONDS: float = 0.1
var normal_jump_force: int = 10
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
const GROUNDED_AREAS_SPHERE_RADIUS: float = 0.3
var normal_grounded: bool

# Bump Detection
const BUMP_AREA_BOX_SIZE: Vector3 = Vector3(0.6, 1.1, 0.1)
var bumping: bool

# Player Rotation
var degrees_to_rotate: float # This variable is assigned by the player_and_camera script

# Player Sizes
const PLAYER_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.5
const PLAYER_RADIUS: float = 0.5

# @export Variables
@export var player_capsule_mesh: CapsuleMesh
@export var player_capsule_shape: CapsuleShape3D
@export var camera_position: Node3D
@export var normal_grounded_area: Area3D
@export var norm_gded_area_sphere_shape: SphereShape3D # Normal Grounded Area Sphere Shape
@export var bump_area: Area3D
@export var bump_area_box_shape: BoxShape3D
@export var can_jump_timer: Timer
@export var jumping_timer: Timer

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
	normal_grounded_area.position.y = -(PLAYER_HEIGHT / 2)
	norm_gded_area_sphere_shape.radius = GROUNDED_AREAS_SPHERE_RADIUS
	bump_area.position.z = -(PLAYER_RADIUS / 2)
	bump_area_box_shape.size = BUMP_AREA_BOX_SIZE
	can_jump_timer.wait_time = CAN_JUMP_TIMER_SECONDS
	jumping_timer.wait_time = JUMPING_TIMER_SECONDS

# * Get inputs
func _process(_delta: float) -> void:
	# move_vector's X is X in 3D, Y is -Z in 3D. Also, it is normalized.
	move_vector = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward")).normalized()

	# Other inputs
	run_input = Input.is_action_pressed("run") && Input.is_action_pressed("move_forward")
	crouch_input = Input.is_action_pressed("crouch")
	jump_input = Input.is_action_pressed("jump")

# * Handle physics
func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	rotation_degrees.y = degrees_to_rotate
	jump()
	move_speed_control()

func jump() -> void:
	if jump_input && can_jump && !jumping && ((touching && normal_grounded) || (!normal_grounded && coyote_time_counter > 0)):
		execute_jump(normal_jump_force)

func execute_jump(jump_force: int) -> void:
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

func move_speed_control() -> void:
	match current_state:
		States.CROUCHING, States.CROUCH_WALKING:
			move_speed = CROUCH_SPEED
		States.RUNNING:
			move_speed = RUN_SPEED
		_:
			move_speed = NORMAL_SPEED

	if abs(linear_velocity.z) <= MIN:
		linear_velocity.z = 0

	if abs(linear_velocity.x) <= MIN:
		linear_velocity.x = 0

	if abs(linear_velocity.y) <= MIN:
		linear_velocity.y = 0

# * Handle other things
func _physics_process(delta: float) -> void:
	touching = get_contact_count() > 0
	normal_grounded = normal_grounded_area.has_overlapping_bodies()
	bumping = bump_area.has_overlapping_bodies()
	coyote_time(delta)
	current_state = player_state_machine(current_state)

func coyote_time(physics_process_delta: float) -> void:
	if normal_grounded:
		coyote_time_counter = COYOTE_TIME_SECONDS
	elif coyote_time_counter <= 0:
		coyote_time_counter = 0
	else:
		coyote_time_counter -= physics_process_delta

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
				return States.WALKING
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
