###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Menu extends VBoxContainer

enum NavigationTarget {
	KEEP_CURRENT = -1, # Special case when used as an option list enumeration.
	
	FILE = 0,
	ARRANGEMENT = 1,
	INSTRUMENT = 2,
	ADVANCED = 3,
	CREDITS = 4,
	THIRD_PARTY = 5,
	LEGACY_CREDITS = 6,
	GENERAL_HELP = 7,
	PATTERN_HELP = 8,
	ARRANGEMENT_HELP = 9,
}

@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _contents_root: TabContainer = $Contents
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
	_update_fullscreen_button()
	
	#_tab_buttons.pressed.connect(_request_navigation)
	#Using binding individual signals instead of mass connection through ButtonGroup
	#For more safe and predictable tabing
	
	_file_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.FILE))
	_arrangement_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.ARRANGEMENT))
	_instrument_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.INSTRUMENT))
	_advanced_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.ADVANCED))
	_credits_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.CREDITS))
	_thirdparty_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.THIRD_PARTY))
	_legacy_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.LEGACY_CREDITS))
	_general_help_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.GENERAL_HELP))
	_pattern_help_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.PATTERN_HELP))
	_arrangement_help_tab_button.pressed.connect(_request_navigation.bind(NavigationTarget.ARRANGEMENT_HELP))
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_FILE, _file_tab_button.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_ARRANGEMENT, _arrangement_tab_button.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.NAVIGATION_INSTRUMENT, _instrument_tab_button.get_global_rect)
		
		_fullscreen_toggle.pressed.connect(Controller.settings_manager.toggle_fullscreen)
		get_window().size_changed.connect(_update_fullscreen_button)
		
		Controller.navigation_requested.connect(_navigate)
		Controller.music_player.export_started.connect(_navigate.bind(NavigationTarget.ARRANGEMENT))
	
	_request_navigation(NavigationTarget.FILE)


func _request_navigation(target: NavigationTarget) -> void:
	# A little run around so all navigation requests emit a global signal.
	Controller.navigate_to(target)


func _navigate(target: NavigationTarget) -> void:
	#From RikK:
	#_current_tab varible replaced with built-in in TabContainer
	#It's just simpleer to handle menu's visibility
	
	if target == NavigationTarget.KEEP_CURRENT || (_contents_root.current_tab == target):
		return
	
	var old_button := _tab_buttons.get_pressed_button()
	
	if old_button:
		old_button.set_pressed_no_signal(false)
	
	_contents_root.current_tab = target
	
	if _tab_buttons.get_buttons().size() > target && target > -1:
		var button := _tab_buttons.get_buttons()[_contents_root.current_tab]
		button.set_pressed_no_signal(true)
	
		if button in MAIN_MENU:
			_update_menu_collection(MAIN_MENU)
		elif button in CREDITS_MENU:
			_update_menu_collection(CREDITS_MENU)
		elif button in HELP_MENU:
			_update_menu_collection(HELP_MENU)
		
		Controller.mark_navigation_succeeded(target)
	elif _contents_root.current_tab != target:
		_request_navigation(_contents_root.current_tab as NavigationTarget)
		printerr("Menu navigation to " + str(target) + " failed.")


func _update_menu_collection(menu_buttons: Array[Button]) -> void:
	for button in _tab_buttons.get_buttons():
		button.visible = false
	
	for button in menu_buttons:
		button.visible = true


func _update_fullscreen_button() -> void:
	if Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	
	if get_window().mode == Window.MODE_FULLSCREEN:
		_fullscreen_toggle.icon = get_theme_icon("fullscreen_off", "Menu")
	else:
		_fullscreen_toggle.icon = get_theme_icon("fullscreen_on", "Menu")
