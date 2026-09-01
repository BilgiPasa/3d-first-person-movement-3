extends Node

# SettingsSave Variables
var settings_save: SettingsSave
var normal_fov: int
var sprint_fov_change: int
var mouse_sensitivity: int
var max_fps_setting: int
var speed_label_visible: bool
var fps_label_visible: bool

# PlayerTweaksSave Variables
var player_tweaks_save: PlayerTweaksSave
var normal_speed: int
var jump_speed: int

func _ready() -> void:
	# For SettingsSave
	settings_save = SettingsSave.load_or_create()
	normal_fov = settings_save.normal_fov
	sprint_fov_change = settings_save.sprint_fov_change
	mouse_sensitivity = settings_save.mouse_sensitivity
	max_fps_setting = settings_save.max_fps_setting
	speed_label_visible = settings_save.speed_label_visible
	fps_label_visible = settings_save.fps_label_visible

	# For PlayerTweaksSave
	player_tweaks_save = PlayerTweaksSave.load_or_create()
	normal_speed = player_tweaks_save.normal_speed
	jump_speed = player_tweaks_save.jump_speed
