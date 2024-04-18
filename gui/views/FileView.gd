###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _play_button: Button = %Play
@onready var _pause_button: Button = %Pause
@onready var _stop_button: Button = %Stop

@onready var _pattern_size_stepper: Stepper = %PatternStepper
@onready var _bar_size_stepper: Stepper = %BarStepper
@onready var _bpm_stepper: Stepper = %BPMStepper


func _ready() -> void:
	_play_button.pressed.connect(Controller.music_player.start_playback)
	_pause_button.pressed.connect(Controller.music_player.pause_playback)
	_stop_button.pressed.connect(Controller.music_player.stop_playback)
	
	_pattern_size_stepper.value_changed.connect(_change_pattern_size)
	_bar_size_stepper.value_changed.connect(_change_bar_size)
	_bpm_stepper.value_changed.connect(_change_bpm)


func _change_pattern_size() -> void:
	Controller.set_pattern_size(_pattern_size_stepper.value)


func _change_bar_size() -> void:
	Controller.set_bar_size(_bar_size_stepper.value)


func _change_bpm() -> void:
	Controller.set_bpm(_bpm_stepper.value)
