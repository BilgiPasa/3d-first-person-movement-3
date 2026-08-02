extends Control

signal show_speed_label
signal hide_speed_label
signal show_fps_label
signal hide_fps_label
signal open_player_tweaks_menu
signal go_back

@export var fov_label: Label
@export var fov_slider: HSlider
@export var max_fps_label: Label
@export var max_fps_slider: HSlider
@export var mouse_sensitivity_label: Label
@export var mouse_sensitivity_slider: HSlider
@export var sprint_fov_change_label: Label
@export var sprint_fov_change_slider: HSlider
@export var speed_label_on_off_button: Button
@export var fps_label_on_off_button: Button
@export var go_back_button: Button
var speed_label_visible: bool = true
var fps_label_visible: bool = true

func _ready() -> void:
	reset_settings()

func _on_visibility_changed() -> void:
	if visible:
		go_back_button.grab_focus()

func _on_fov_slider_value_changed(value: float) -> void:
	update_about_fov(int(value))

func _on_max_fps_sldr_value_changed(value: float) -> void:
	update_about_max_fps(int(value))

func _on_m_s_slider_value_changed(value: float) -> void:
	update_about_mouse_sensitivity(int(value))

func _on_s_fov_c_sldr_value_changed(value: float) -> void:
	update_about_sprint_fov_change(int(value))

func _on_spd_lbl_on_off_btn_pressed() -> void:
	if speed_label_visible:
		speed_label_visible = false
		hide_speed_label.emit()
		speed_label_on_off_button.text = "Show Speed Label"
	else:
		speed_label_visible = true
		show_speed_label.emit()
		speed_label_on_off_button.text = "Hide Speed Label"

func _on_fps_lbl_on_off_btn_pressed() -> void:
	if fps_label_visible:
		fps_label_visible = false
		hide_fps_label.emit()
		fps_label_on_off_button.text = "Show FPS Label"
	else:
		fps_label_visible = true
		show_fps_label.emit()
		fps_label_on_off_button.text = "Hide FPS Label"

func _on_player_tweaks_btn_pressed() -> void:
	open_player_tweaks_menu.emit()

func _on_reset_settings_btn_pressed() -> void:
	reset_settings()

func _on_go_back_button_pressed() -> void:
	go_back.emit()

func update_about_fov(value: int) -> void:
	Globals.normal_fov = value

	match value:
		90:
			fov_label.text = "FOV: Normal"
		110:
			fov_label.text = "FOV: WIDE"
		30:
			fov_label.text = "FOV: Telescope"
		_:
			fov_label.text = "FOV: %d" % value

func update_about_max_fps(value: int) -> void:
	match value:
		8:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 0
			max_fps_label.text = "Max FPS: Unlimited"
		7:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 1)
			Engine.max_fps = 0
			max_fps_label.text = "Max FPS: V-Sync"
		6:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 240
			max_fps_label.text = "Max FPS: 240"
		5:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 180
			max_fps_label.text = "Max FPS: 180"
		4:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 165
			max_fps_label.text = "Max FPS: 165"
		3:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 144
			max_fps_label.text = "Max FPS: 144"
		2:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 120
			max_fps_label.text = "Max FPS: 120"
		1:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 75
			max_fps_label.text = "Max FPS: 75"
		0:
			ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
			Engine.max_fps = 60
			max_fps_label.text = "Max FPS: 60"

func update_about_mouse_sensitivity(value: int) -> void:
	Globals.mouse_sensitivity = value

	match value:
		100:
			mouse_sensitivity_label.text = "Mouse Sensitivity: Normal"
		200:
			mouse_sensitivity_label.text = "Mouse Sensitivity: FAST"
		1:
			mouse_sensitivity_label.text = "Mouse Sensitivity: Snail"
		_:
			mouse_sensitivity_label.text = "Mouse Sensitivity: %d" % value

func update_about_sprint_fov_change(value: int) -> void:
	Globals.sprint_fov_change = value

	match value:
		0:
			sprint_fov_change_label.text = "Sprint FOV Change: Disabled"
		_:
			sprint_fov_change_label.text = "Sprint FOV Change: %d" % value

func reset_settings() -> void:
	fov_slider.value = Defaults.NORMAL_FOV
	update_about_fov(int(fov_slider.value))
	max_fps_slider.value = Defaults.MAX_FPS_SETTING
	update_about_max_fps(int(max_fps_slider.value))
	mouse_sensitivity_slider.value = Defaults.MOUSE_SENSITIVITY
	update_about_mouse_sensitivity(int(mouse_sensitivity_slider.value))
	sprint_fov_change_slider.value = Defaults.SPRINT_FOV_CHANGE
	update_about_sprint_fov_change(int(sprint_fov_change_slider.value))

	if !Defaults.SPEED_LABEL_VISIBLE:
		speed_label_visible = false
		hide_speed_label.emit()
		speed_label_on_off_button.text = "Show Speed Label"
	else:
		speed_label_visible = true
		show_speed_label.emit()
		speed_label_on_off_button.text = "Hide Speed Label"

	if !Defaults.FPS_LABEL_VISIBLE:
		fps_label_visible = false
		hide_fps_label.emit()
		fps_label_on_off_button.text = "Show FPS Label"
	else:
		fps_label_visible = true
		show_fps_label.emit()
		fps_label_on_off_button.text = "Hide FPS Label"
