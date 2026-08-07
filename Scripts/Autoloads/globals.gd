extends Node

# Save Variables
var settings_save: SettingsSave
var player_tweaks_save: PlayerTweaksSave

# SettingsSave Variables
var normal_fov: int
var sprint_fov_change: int
var mouse_sensitivity: int
var max_fps_setting: int
var speed_label_visible: bool
var fps_label_visible: bool

# PlayerTweaksSave Variables
var normal_speed: int
var jump_speed: int

func _ready() -> void:
	settings_save = SettingsSave.load_or_create()
	player_tweaks_save = PlayerTweaksSave.load_or_create()

	# For SettingsSave
	normal_fov = settings_save.normal_fov
	sprint_fov_change = settings_save.sprint_fov_change
	mouse_sensitivity = settings_save.mouse_sensitivity
	max_fps_setting = settings_save.max_fps_setting
	speed_label_visible = settings_save.speed_label_visible
	fps_label_visible = settings_save.fps_label_visible

	# For PlayerTweaksSave
	normal_speed = player_tweaks_save.normal_speed
	jump_speed = player_tweaks_save.jump_speed
