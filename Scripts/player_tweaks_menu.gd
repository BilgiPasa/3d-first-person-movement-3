extends Control

signal go_back

@export var normal_speed_label: Label
@export var normal_speed_slider: HSlider
@export var jump_speed_label: Label
@export var jump_speed_slider: HSlider
@export var go_back_button: Button

func _ready() -> void:
	reset_player_tweaks()

func _on_visibility_changed() -> void:
	if visible:
		go_back_button.grab_focus()

func _on_n_spd_slider_value_changed(value: float) -> void:
	update_about_normal_speed(int(value))

func _on_j_spd_slider_value_changed(value: float) -> void:
	update_about_jump_speed(int(value))

func _on_reset_p_tweaks_btn_pressed() -> void:
	reset_player_tweaks()

func _on_go_back_button_pressed() -> void:
	go_back.emit()

func update_about_normal_speed(value: int) -> void:
	Globals.normal_speed = value
	normal_speed_label.text = "Normal Speed: %d" % value

func update_about_jump_speed(value: int) -> void:
	Globals.jump_speed = value
	jump_speed_label.text = "Jump Speed: %d" % value

func reset_player_tweaks() -> void:
	normal_speed_slider.value = Defaults.NORMAL_SPEED
	update_about_normal_speed(int(normal_speed_slider.value))
	jump_speed_slider.value = Defaults.JUMP_SPEED
	update_about_jump_speed(int(jump_speed_slider.value))
