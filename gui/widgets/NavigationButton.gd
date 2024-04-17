###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Button

@export var label_text: String = "":
	set(value):
		label_text = value
		_update_label()

@onready var _label: Label = $Label


func _ready() -> void:
	_label.offset_left = get_theme_stylebox("normal").get_margin(SIDE_LEFT)
	_label.offset_right = -get_theme_stylebox("normal").get_margin(SIDE_RIGHT)
	_label.offset_top = get_theme_stylebox("normal").get_margin(SIDE_TOP)
	_label.offset_bottom = -get_theme_stylebox("normal").get_margin(SIDE_BOTTOM)
	
	_update_label()


func _update_label() -> void:
	if not _label:
		return
	
	_label.text = label_text
	_label.modulate.a = 1.0 if button_pressed else 0.65
	_label.queue_redraw()


func _toggled(_toggled_on: bool) -> void:
	_update_label()
