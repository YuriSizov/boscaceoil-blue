###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Menu extends VBoxContainer

enum NavigationTarget {
	KEEP_CURRENT, # Special case when used as an option list enumeration.
	
	FILE,
	ARRANGEMENT,
	INSTRUMENT,
	ADVANCED,
	CREDITS,
	THIRD_PARTY,
	LEGACY_CREDITS,
	GENERAL_HELP,
	PATTERN_HELP,
	ARRANGEMENT_HELP,
}

var _current_tab: int = 0

@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _contents_root: Control = $Contents
@onready var _tab_buttons: ButtonGroup = load("res://gui/theme/navigation_buttons.tres")

@onready var _file_tab_button: Button = %FileTab
@onready var _arrangement_tab_button: Button = %ArrangementTab
@onready var _instrument_tab_button: Button = %InstrumentTab
@onready var _advanced_tab_button: Button = %AdvancedTab

@onready var _credits_tab_button: Button = %CreditsTab
@onready var _thirdparty_tab_button: Button = %ThirdPartyTab
@onready var _legacy_tab_button: Button = %LegacyTab

@onready var _general_help_tab_button: Button = %GeneralHelpTab
@onready var _pattern_help_tab_button: Button = %PatternHelpTab
@onready var _arrangement_help_tab_button: Button = %ArrangementHelpTab

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
	_general_help_tab_button,
	_pattern_help_tab_button,
	_arrangement_help_tab_button,
]


func _ready() -> void:
	_update_current_tab()
	
	_tab_buttons.pressed.connect(_request_navigation)
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_FILE, _file_tab_button.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_ARRANGEMENT, _arrangement_tab_button.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_INSTRUMENT, _instrument_tab_button.get_global_rect)
		
		_fullscreen_toggle.pressed.connect(Controller.settings_manager.toggle_fullscreen)
		
		Controller.navigation_requested.connect(_navigate)
		Controller.music_player.export_started.connect(_navigate.bind(NavigationTarget.ARRANGEMENT))


func _request_navigation(button: Button) -> void:
	# A little run around so all navigation requests emit a global signal.
	var target: NavigationTarget = (button.get_index() + 1) as NavigationTarget
	Controller.navigate_to(target)


func _navigate(target: NavigationTarget) -> void:
	if target == NavigationTarget.KEEP_CURRENT || (_current_tab == target - 1):
		return
	
	var old_button := _tab_buttons.get_pressed_button()
	if old_button:
		old_button.set_pressed_no_signal(false)
	
	_current_tab = target - 1
	var button := _tab_buttons.get_buttons()[_current_tab]
	button.set_pressed_no_signal(true)
	_update_current_tab()
	
	if button in MAIN_MENU:
		_update_menu_collection(MAIN_MENU)
	elif button in CREDITS_MENU:
		_update_menu_collection(CREDITS_MENU)
	elif button in HELP_MENU:
		_update_menu_collection(HELP_MENU)
	
	Controller.mark_navigation_succeeded(target)


func _update_menu_collection(menu_buttons: Array[Button]) -> void:
	for button in _tab_buttons.get_buttons():
		button.visible = false
	
	for button in menu_buttons:
		button.visible = true


func _update_current_tab() -> void:
	for child in _contents_root.get_children():
		child.visible = child.get_index() == _current_tab
