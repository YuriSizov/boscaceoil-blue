###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends VBoxContainer

var _current_tab: int = 0

@onready var _contents_root: Control = $Contents
@onready var _tab_buttons: ButtonGroup = load("res://gui/theme/navigation_buttons.tres")
@onready var _file_tab_button: Button = %FileTab
@onready var _arrangement_tab_button: Button = %ArrangementTab
@onready var _instrument_tab_button: Button = %InstrumentTab
@onready var _advanced_tab_button: Button = %AdvancedTab


func _ready() -> void:
	_update_current_tab()
	
	_tab_buttons.pressed.connect(_handle_navigation_changed)
	
	if not Engine.is_editor_hint():
		Controller.music_player.export_started.connect(_navigate.bind(_arrangement_tab_button))


func _navigate(button: Button) -> void:
	button.set_pressed(true)


func _handle_navigation_changed(button: Button) -> void:
	_current_tab = button.get_index()
	_update_current_tab()


func _update_current_tab() -> void:
	for child in _contents_root.get_children():
		child.visible = child.get_index() == _current_tab
