###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _swing_stepper: Stepper = %SwingStepper


func _ready() -> void:
	_swing_stepper.value_changed.connect(_change_swing)


func _change_swing() -> void:
	Controller.set_song_swing(_swing_stepper.value)
