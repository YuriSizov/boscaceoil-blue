###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

@onready var _play_button: Button = %Play
@onready var _pause_button: Button = %Pause
@onready var _stop_button: Button = %Stop


func _ready() -> void:
	_play_button.pressed.connect(Controller.music_player.start_playback)
	_pause_button.pressed.connect(Controller.music_player.pause_playback)
	_stop_button.pressed.connect(Controller.music_player.stop_playback)
