class_name SettingsSave
extends Resource

@export var normal_fov: int = Defaults.NORMAL_FOV
@export var max_fps_setting: int = Defaults.MAX_FPS_SETTING
@export var mouse_sensitivity: int = Defaults.MOUSE_SENSITIVITY
@export var sprint_fov_change: int = Defaults.SPRINT_FOV_CHANGE
@export var speed_label_visible: bool = Defaults.SPEED_LABEL_VISIBLE
@export var fps_label_visible: bool = Defaults.FPS_LABEL_VISIBLE

const SAVE_PATH: String = "user://settings_save.tres" # I'm using .tres because I want to make it easily modifiable.

func save() -> void:
	normal_fov = Globals.normal_fov
	max_fps_setting = Globals.max_fps_setting
	mouse_sensitivity = Globals.mouse_sensitivity
	sprint_fov_change = Globals.sprint_fov_change
	speed_label_visible = Globals.speed_label_visible
	fps_label_visible = Globals.fps_label_visible
	ResourceSaver.save(self, SAVE_PATH)

static func load_or_create() -> SettingsSave:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		return SettingsSave.new()
