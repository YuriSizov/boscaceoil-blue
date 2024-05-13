###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name LinkLabel extends Label

## URL opened by clicking the label.
@export var url: String = ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			OS.shell_open(url)
