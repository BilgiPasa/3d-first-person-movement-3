class_name PlayerTweaksSave
extends Resource

# Player Movement
@export var normal_speed: int = Defaults.NORMAL_SPEED

# Player Jump
@export var jump_speed: int = Defaults.JUMP_SPEED

const SAVE_PATH: String = "user://player_tweaks_save.tres"

func save() -> void:
	ResourceSaver.save(self, SAVE_PATH)

static func load_or_create() -> PlayerTweaksSave:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		return PlayerTweaksSave.new()
