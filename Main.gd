###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _filler: Control = %Filler
@onready var _menu_bar: Control = %Menu


func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	get_window().wrap_controls = true


func _ready() -> void:
	# A little trick to make sure the menu is on top of the pattern editor. We use a filler control
	# and make it fit the same area in the box container.
	_filler.custom_minimum_size = _menu_bar.get_combined_minimum_size()
