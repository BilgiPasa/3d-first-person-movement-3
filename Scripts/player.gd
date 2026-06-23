class_name Player
extends RigidBody3D

# Note: I changed the default gravity to 30 m/s^2 in Project Settings
# Note2: I have set the layers and the masks in the editor.

# Movement
const NORMAL_SPEED: int = 9
const RUN_SPEED: int = 12
const CROUCH_SPEED: int = 6
var current_speed: int
var run_input: bool
var move_vector: Vector2 # X is X, Y is -Z.

# Crouch
var crouch_input: bool

# Jump
var jump_input: bool

# Touch Detection
var touching: bool = false
var touched_body: Node3D = null

# Ground Detection
const GROUNDED_AREA_SPHERE_RADIUS: float = 0.3
var grounded: bool = false
var grounded_body: Node3D = null

# Bump Detection
const BUMP_AREA_BOX_SIZE: Vector3 = Vector3(0.6, 1.1, 0.1)
var bumping: bool = false
var bumped_body: Node3D = null

# Player Sizes
const PLAYER_HEIGHT: float = 2.0
const CROUCH_HEIGHT: float = 1.5
const PLAYER_RADIUS: float = 0.5

# @export Variables
@export var player_capsule_mesh: CapsuleMesh
@export var player_capsule_shape: CapsuleShape3D
@export var camera_position: Node3D
@export var grounded_area: Area3D
@export var grounded_area_sphere_shape: SphereShape3D
@export var bump_area: Area3D
@export var bump_area_box_shape: BoxShape3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	can_sleep = false
	lock_rotation = true
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 10
	player_capsule_mesh.height = PLAYER_HEIGHT
	player_capsule_mesh.radius = PLAYER_RADIUS
	player_capsule_shape.height = PLAYER_HEIGHT
	player_capsule_shape.radius = PLAYER_RADIUS
	camera_position.position.y = (PLAYER_HEIGHT / 2) - 0.25
	grounded_area.position.y = -(PLAYER_HEIGHT / 2)
	grounded_area_sphere_shape.radius = GROUNDED_AREA_SPHERE_RADIUS
	bump_area.position.z = -(PLAYER_RADIUS / 2)
	bump_area_box_shape.size = BUMP_AREA_BOX_SIZE

func _process(_delta: float) -> void:
	# move_vector's X is X in 3D, Y is -Z in 3D. Also, it is normalized.
	move_vector = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward")).normalized()

	# Other inputs
	run_input = Input.is_action_pressed("run")
	crouch_input = Input.is_action_pressed("crouch")
	jump_input = Input.is_action_pressed("jump")

func _physics_process(delta: float) -> void:
	if crouch_input:
		current_speed = CROUCH_SPEED
	elif run_input:
		current_speed = RUN_SPEED
	else:
		current_speed = NORMAL_SPEED

func _on_body_entered(body: Node) -> void:
	if body == null:
		touched_body = body
		touching = true

func _on_body_exited(body: Node) -> void:
	if body == touched_body:
		touched_body = null
		touching = false

func _on_grounded_area_body_entered(body: Node3D) -> void:
	if body == null:
		grounded_body = body
		grounded = true

func _on_grounded_area_body_exited(body: Node3D) -> void:
	if body == grounded_body:
		grounded_body = null
		grounded = false

func _on_bump_area_body_entered(body: Node3D) -> void:
	if body == null:
		bumped_body = body
		bumping = true

func _on_bump_area_body_exited(body: Node3D) -> void:
	if body == bumped_body:
		bumped_body = null
		bumping = false
