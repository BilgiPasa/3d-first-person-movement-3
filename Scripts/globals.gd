extends Node

# Save Variables
var settings_save: SettingsSave
var player_tweaks_save: PlayerTweaksSave

func _ready() -> void:
	settings_save = SettingsSave.load_or_create()
	player_tweaks_save = PlayerTweaksSave.load_or_create()
