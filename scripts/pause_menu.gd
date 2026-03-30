extends Control

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume()
		else:
			_pause()

func _pause() -> void:
	visible = true
	get_tree().paused = true
	%ResumeButton.grab_focus()

func _resume() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_button_pressed() -> void:
	_resume()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
