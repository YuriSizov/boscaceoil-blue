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
	
	var text_color := get_theme_color("font_color", "NavigationButton")
	if not button_pressed:
		text_color = get_theme_color("font_inactive_color", "NavigationButton")
	
	_label.text = label_text
	_label.add_theme_color_override("font_color", text_color)
	_label.queue_redraw()


func _toggled(_toggled_on: bool) -> void:
	_update_label()
