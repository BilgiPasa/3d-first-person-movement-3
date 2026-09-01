extends Node3D

# Timer Seconds Constants
const MOVE_UP_PLAYER_TIMER_SECONDS: int = 2
const FPS_LABEL_TIMER_SECONDS: float = 0.5

# @export Variables
@export var player: Player
@export var move_up_player_timer: Timer
@export var fps_label_timer: Timer
@export var speed_label: Label
@export var fps_label: Label
@export var crosshair: TextureRect
@export var pause_menu: Control
@export var settings_menu: Control
@export var player_tweaks_menu: Control
@export var fps_label_initial_position: Vector2

func _ready() -> void:
	# Initialize the process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Initialize the mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Initialize @export variables
	player.position = Vector3(0, player.PLAYER_HEIGHT / 2, 0)
	move_up_player_timer.wait_time = MOVE_UP_PLAYER_TIMER_SECONDS
	move_up_player_timer.start()
	fps_label_timer.wait_time = FPS_LABEL_TIMER_SECONDS
	fps_label_timer.start()
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	crosshair.modulate = Color.BLACK
	pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
	pause_menu.hide()
	settings_menu.process_mode = Node.PROCESS_MODE_DISABLED
	settings_menu.hide()
	player_tweaks_menu.process_mode = Node.PROCESS_MODE_DISABLED
	player_tweaks_menu.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # If "esc" key pressed
		if !get_tree().paused:
			pause()
		else:
			if settings_menu.visible:
				close_settings()
			elif player_tweaks_menu.visible:
				close_player_tweaks()
			else:
				resume()

func _physics_process(_delta) -> void:
	if speed_label.visible:
		speed_label.text = "Speed: %f" % player.get_flat_speed()

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
	pause_menu.hide()
	settings_menu.process_mode = Node.PROCESS_MODE_INHERIT
	settings_menu.show()

func close_settings() -> void:
	Globals.settings_save.save()
	pause_menu.process_mode = Node.PROCESS_MODE_INHERIT
	pause_menu.show()
	settings_menu.process_mode = Node.PROCESS_MODE_DISABLED
	settings_menu.hide()

func open_player_tweaks() -> void:
	settings_menu.process_mode = Node.PROCESS_MODE_DISABLED
	settings_menu.hide()
	player_tweaks_menu.process_mode = Node.PROCESS_MODE_INHERIT
	player_tweaks_menu.show()

func close_player_tweaks() -> void:
	Globals.player_tweaks_save.save()
	settings_menu.process_mode = Node.PROCESS_MODE_INHERIT
	settings_menu.show()
	player_tweaks_menu.hide()
	player_tweaks_menu.process_mode = Node.PROCESS_MODE_DISABLED

func _on_pause_menu_resume_game() -> void:
	resume()

func _on_pause_menu_open_settings() -> void:
	open_settings()

func _on_settings_menu_go_back() -> void:
	close_settings()

func _on_move_up_p_timer_timeout() -> void: # _on_move_up_player_timer_timeout
	if player.global_position.y < -200:
		player.global_position = Vector3(0, 300, 0)

# The FPS Label update is in a timer because Engine.get_frames_per_second() does not update very often.
func _on_fps_label_timer_timeout() -> void:
	if fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _on_settings_menu_show_spd_lbl() -> void: # _on_settings_menu_show_speed_label
	speed_label.show()
	fps_label.position = fps_label_initial_position

func _on_settings_menu_show_fps_lbl() -> void: # _on_settings_menu_show_fps_label
	fps_label.show()

	if speed_label.visible:
		fps_label.position = fps_label_initial_position
	else:
		fps_label.position = speed_label.position

func _on_settings_menu_hide_spd_lbl() -> void: # _on_settings_menu_hide_speed_label
	speed_label.hide()
	fps_label.position = speed_label.position

func _on_settings_menu_hide_fps_lbl() -> void: # _on_settings_menu_hide_fps_label
	fps_label.hide()

func _on_settings_menu_open_p_t_m() -> void: # _on_settings_menu_open_player_tweaks_menu
	open_player_tweaks()

func _on_player_tweaks_menu_go_back() -> void:
	close_player_tweaks()

func _on_player_set_crosshair_color(crosshair_color: Color) -> void:
	crosshair.modulate = crosshair_color
