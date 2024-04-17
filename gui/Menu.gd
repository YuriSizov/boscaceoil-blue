###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends VBoxContainer

var _current_tab: int = 0

@onready var _tab_buttons: ButtonGroup = load("res://gui/theme/navigation_buttons.tres")
@onready var _contents_root: Control = $Contents


func _ready() -> void:
	_update_current_tab()
	
	_tab_buttons.pressed.connect(_handle_navigation_changed)


func _handle_navigation_changed(button: Button) -> void:
	_current_tab = button.get_index()
	_update_current_tab()


func _update_current_tab() -> void:
	for child in _contents_root.get_children():
		child.visible = child.get_index() == _current_tab
