class_name SettingsSave
extends Resource

# PlayerAndCamera Camera FOV
@export var normal_fov: int = Defaults.NORMAL_FOV
@export var sprint_fov_change: int = Defaults.SPRINT_FOV_CHANGE

# PlayerAndCamera Camera Rotation
@export var mouse_sensitivity: int = Defaults.MOUSE_SENSITIVITY

# Max FPS Setting
@export var max_fps_setting: int = Defaults.MAX_FPS_SETTING

# Labels' Visibility Settings
var speed_label_visible: bool = true
var fps_label_visible: bool = true

const SAVE_PATH: String = "user://settings_save.tres"

func save() -> void:
	ResourceSaver.save(self, SAVE_PATH)

static func load_or_create() -> SettingsSave:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		return SettingsSave.new()
