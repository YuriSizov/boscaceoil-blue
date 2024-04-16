###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends Node

var voice_manager: VoiceManager = null
var music_player: MusicPlayer = null

## Current edited song.
var current_song: Song = Song.new()


func _init() -> void:
	voice_manager = VoiceManager.new()
	music_player = MusicPlayer.new(self)


func _ready() -> void:
	# Driver must be ready by this time.

	music_player.initialize()


	## TEMP
	var voice_data := Controller.voice_manager.get_voice_data("MIDI", "Grand Piano")
	var temp_instrument := SingleVoiceInstrument.new(voice_data)
	current_song.instruments.push_back(temp_instrument)

	var test_pattern := Pattern.new()
	test_pattern.instrument_idx = 0
	test_pattern.add_note(43, 3, 1)
	test_pattern.add_note(41, 7, 2)
	current_song.patterns.push_back(test_pattern)
	## TEMP


	music_player.start_driver()
	music_player.start_playback()
