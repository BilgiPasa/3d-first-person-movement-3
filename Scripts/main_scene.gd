extends Node3D

@export var player_and_camera: PlayerAndCamera
@export var speed_label: Label
@export var pause_menu: Control
@export var settings_menu: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	speed_label.process_mode = Node.PROCESS_MODE_INHERIT
	speed_label.show()
	pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.hide()
	settings_menu.process_mode = Node.PROCESS_MODE_DISABLED
	settings_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # If "esc" key pressed
		if !get_tree().paused:
			pause()
		else:
			if !settings_menu.visible:
				resume()
			else:
				close_settings()

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

func open_settings() -> void:
	pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
	settings_menu.process_mode = Node.PROCESS_MODE_INHERIT
	settings_menu.show()
	pause_menu.hide()

func close_settings() -> void:
	settings_menu.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.process_mode = Node.PROCESS_MODE_INHERIT
	pause_menu.show()
	settings_menu.hide()

func _on_pause_menu_resume_game() -> void:
	resume()

func _on_pause_menu_open_settings() -> void:
	open_settings()

func _on_settings_menu_go_back() -> void:
	close_settings()
