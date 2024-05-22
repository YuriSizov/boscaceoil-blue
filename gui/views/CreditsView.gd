###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _navigate_back_button: SquishyButton = %NavigateBack


func _ready() -> void:
	_navigate_back_button.pressed.connect(Controller.navigate_to.bind(Menu.NavigationTarget.FILE))
