class_name PlayerTweaksSave
extends Resource

@export var normal_speed: int = Defaults.NORMAL_SPEED
@export var jump_speed: int = Defaults.JUMP_SPEED

const SAVE_PATH: String = "user://player_tweaks_save.tres" # I'm using .tres because I want to make it easily modifiable.

func save() -> void:
	normal_speed = Globals.normal_speed
	jump_speed = Globals.jump_speed
	ResourceSaver.save(self, SAVE_PATH)

static func load_or_create() -> PlayerTweaksSave:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		return PlayerTweaksSave.new()
