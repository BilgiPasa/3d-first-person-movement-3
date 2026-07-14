extends Control

signal go_back

@export var go_back_button: Button

func _on_visibility_changed() -> void:
	if visible:
		go_back_button.grab_focus()

func _on_go_back_button_pressed() -> void:
	go_back.emit()
