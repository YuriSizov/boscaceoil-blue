###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Menu extends VBoxContainer

enum NavigationTargets {
	FILE,
	ARRANGEMENT,
	INSTRUMENT,
	ADVANCED,
	CREDITS,
	THIRD_PARTY,
	LEGACY_CREDITS,
	HELP,
}

var _current_tab: int = 0

@onready var _contents_root: Control = $Contents
@onready var _tab_buttons: ButtonGroup = load("res://gui/theme/navigation_buttons.tres")

@onready var _file_tab_button: Button = %FileTab
@onready var _arrangement_tab_button: Button = %ArrangementTab
@onready var _instrument_tab_button: Button = %InstrumentTab
@onready var _advanced_tab_button: Button = %AdvancedTab

@onready var _credits_tab_button: Button = %CreditsTab
@onready var _thirdparty_tab_button: Button = %ThirdPartyTab
@onready var _legacy_tab_button: Button = %LegacyTab

@onready var _help_tab_button: Button = %HelpTab

# Menu collections.

@onready var MAIN_MENU: Array[Button] = [
	_file_tab_button,
	_arrangement_tab_button,
	_instrument_tab_button,
	_advanced_tab_button,
]
@onready var CREDITS_MENU: Array[Button] = [
	_credits_tab_button,
	_thirdparty_tab_button,
	_legacy_tab_button,
]
@onready var HELP_MENU: Array[Button] = [
	_help_tab_button,
]


func _ready() -> void:
	_update_current_tab()
	
	_tab_buttons.pressed.connect(_handle_navigation_changed)
	
	if not Engine.is_editor_hint():
		Controller.navigation_requested.connect(_navigate)
		Controller.music_player.export_started.connect(_navigate.bind(NavigationTargets.ARRANGEMENT))


func _navigate(target: NavigationTargets) -> void:
	var button := _tab_buttons.get_buttons()[target]
	button.set_pressed(true)
	
	if button in MAIN_MENU:
		_update_menu_collection(MAIN_MENU)
	elif button in CREDITS_MENU:
		_update_menu_collection(CREDITS_MENU)
	elif button in HELP_MENU:
		_update_menu_collection(HELP_MENU)


func _handle_navigation_changed(button: Button) -> void:
	_current_tab = button.get_index()
	_update_current_tab()


func _update_menu_collection(menu_buttons: Array[Button]) -> void:
	for button in _tab_buttons.get_buttons():
		button.visible = false
	
	for button in menu_buttons:
		button.visible = true


func _update_current_tab() -> void:
	for child in _contents_root.get_children():
		child.visible = child.get_index() == _current_tab
