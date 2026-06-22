class_name Player
extends RigidBody3D

var bumping: bool = false
var bumped_body: Node3D = null
var move_vector: Vector2 # X is X, Y is -Z.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(_delta: float) -> void:
	# move_vector's X is X in 3D, Y is -Z in 3D. Also, it is normalized.
	move_vector = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward")).normalized()

func _on_bump_area_body_entered(body: Node3D) -> void:
	if body == null:
		bumped_body = body
		bumping = true

func _on_bump_area_body_exited(body: Node3D) -> void:
	if body == bumped_body:
		bumped_body = null
		bumping = false
