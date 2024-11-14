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


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_label_color()
	elif what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_label_color()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_label_color()


func _update_label() -> void:
	if not is_node_ready():
		return

	_update_label_color()
	_label.text = label_text
	_label.queue_redraw()


func _update_label_color() -> void:
	if not is_node_ready():
		return

	var text_color := get_theme_color("font_color")
	if not button_pressed:
		text_color = get_theme_color("font_inactive_color")
	
	_label.add_theme_color_override("font_color", text_color)


func _clear_label_color() -> void:
	if not is_node_ready():
		return
	
	_label.remove_theme_color_override("font_color")


func _toggled(_toggled_on: bool) -> void:
	_update_label()
