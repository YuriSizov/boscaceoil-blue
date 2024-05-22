###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _navigate_back_button: SquishyButton = %NavigateBack
@onready var _basic_guide_button: SquishyButton = %StartBasicGuide
@onready var _advanced_guide_button: SquishyButton = %StartAdvancedGuide


func _ready() -> void:
	_navigate_back_button.pressed.connect(Controller.navigate_to.bind(Menu.NavigationTarget.FILE))
	_basic_guide_button.pressed.connect(Controller.help_manager.start_guide.bind(HelpManager.GuideType.BASIC_GUIDE))
	_advanced_guide_button.pressed.connect(Controller.help_manager.start_guide.bind(HelpManager.GuideType.ADVANCED_GUIDE))
