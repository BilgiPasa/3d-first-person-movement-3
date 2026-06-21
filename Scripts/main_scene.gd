extends Node3D

@export var player_and_camera: PlayerAndCamera
@export var speed_label: Label
@export var pause_menu: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	speed_label.process_mode = Node.PROCESS_MODE_INHERIT
	speed_label.show()
	pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta) -> void:
	if speed_label.visible:
		speed_label.text = "Speed: %f" % player_and_camera.get_player_speed()

func pause() -> void:
	get_tree().paused = true
	speed_label.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.process_mode = Node.PROCESS_MODE_INHERIT
	pause_menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume() -> void:
	get_tree().paused = false

	if speed_label.visible:
		speed_label.process_mode = Node.PROCESS_MODE_INHERIT

	pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_pause_menu_resume_game() -> void:
	resume()

func _on_pause_menu_open_settings() -> void:
	pass # Replace with function body.
