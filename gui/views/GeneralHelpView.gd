###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

const SHORCUTS_POPUP_SCENE := preload("res://gui/widgets/popups/ShortcutHelpPopup.tscn")

var _shortcut_help: WindowPopup = null

@onready var _navigate_back_button: SquishyButton = %NavigateBack
@onready var _basic_guide_button: SquishyButton = %StartBasicGuide
@onready var _advanced_guide_button: SquishyButton = %StartAdvancedGuide
@onready var _show_shortcuts_button: SquishyButton = %ShowShortcutsButton
@onready var _short_shortcut_list: VBoxContainer = %ShortShortcutList


func _init() -> void:
	_shortcut_help = SHORCUTS_POPUP_SCENE.instantiate()


func _ready() -> void:
	_shortcut_help.add_button("Close", _shortcut_help.close_popup)
	
	_navigate_back_button.pressed.connect(Controller.navigate_to.bind(Menu.NavigationTarget.FILE))
	_basic_guide_button.pressed.connect(Controller.help_manager.start_guide.bind(HelpManager.GuideType.BASIC_GUIDE))
	_advanced_guide_button.pressed.connect(Controller.help_manager.start_guide.bind(HelpManager.GuideType.ADVANCED_GUIDE))
	_show_shortcuts_button.pressed.connect(_show_shortcuts)
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.HELP_VIEW, get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.HELP_SHORTCUT_SHORTLIST, _short_shortcut_list.get_global_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_shortcut_help):
			_shortcut_help.queue_free()


func _show_shortcuts() -> void:
	# Extra size to compensate for some things.
	Controller.show_window_popup(_shortcut_help, _shortcut_help.custom_minimum_size + Vector2(10, 10))
