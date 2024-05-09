###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

enum ExportOptions {
	EXPORT_WAV,
	EXPORT_MID,
	EXPORT_MML,
	EXPORT_XM
}

@onready var _play_button: Button = %Play
@onready var _pause_button: Button = %Pause
@onready var _stop_button: Button = %Stop

@onready var _create_song_button: SquishyButton = %CreateSong
@onready var _load_song_button: SquishyButton = %LoadSong
@onready var _save_song_button: SquishyButton = %SaveSong
@onready var _import_song_button: SquishyButton = %ImportSong
@onready var _export_song_button: SquishyButton = %ExportSong

@onready var _pattern_size_stepper: Stepper = %PatternStepper
@onready var _bar_size_stepper: Stepper = %BarStepper
@onready var _bpm_stepper: Stepper = %BPMStepper


func _ready() -> void:
	_populate_export_options()
	
	_play_button.pressed.connect(Controller.music_player.start_playback)
	_pause_button.pressed.connect(Controller.music_player.pause_playback)
	_stop_button.pressed.connect(Controller.music_player.stop_playback)
	
	_create_song_button.pressed.connect(Controller.io_manager.create_new_song_safe)
	_load_song_button.pressed.connect(Controller.io_manager.load_ceol_song_safe)
	_save_song_button.pressed.connect(Controller.io_manager.save_ceol_song)
	
	_export_song_button.option_pressed.connect(_handle_export_option)
	
	_pattern_size_stepper.value_changed.connect(_change_pattern_size)
	_bar_size_stepper.value_changed.connect(_change_bar_size)
	_bpm_stepper.value_changed.connect(_change_bpm)
	
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_update_song_steppers)


func _change_pattern_size() -> void:
	Controller.set_pattern_size(_pattern_size_stepper.value)


func _change_bar_size() -> void:
	Controller.set_bar_size(_bar_size_stepper.value)


func _change_bpm() -> void:
	Controller.set_bpm(_bpm_stepper.value)


func _update_song_steppers() -> void:
	if not Controller.current_song:
		_pattern_size_stepper.value = Song.DEFAULT_PATTERN_SIZE
		_bar_size_stepper.value = Song.DEFAULT_BAR_SIZE
		_bpm_stepper.value = Song.DEFAULT_BPM
		return
	
	_pattern_size_stepper.value = Controller.current_song.pattern_size
	_bar_size_stepper.value = Controller.current_song.bar_size
	_bpm_stepper.value = Controller.current_song.bpm


func _populate_export_options() -> void:
	var wav_item := OptionListPopup.Item.new()
	wav_item.id = ExportOptions.EXPORT_WAV
	wav_item.text = "EXPORT .wav"
	_export_song_button.options.push_back(wav_item)
	
	var mid_item := OptionListPopup.Item.new()
	mid_item.id = ExportOptions.EXPORT_MID
	mid_item.text = "EXPORT .mid"
	_export_song_button.options.push_back(mid_item)
	
	var mml_item := OptionListPopup.Item.new()
	mml_item.id = ExportOptions.EXPORT_MML
	mml_item.text = "EXPORT .mml (Experimental)"
	_export_song_button.options.push_back(mml_item)
	
	var xm_item := OptionListPopup.Item.new()
	xm_item.id = ExportOptions.EXPORT_XM
	xm_item.text = "EXPORT .xm (Experimental)"
	_export_song_button.options.push_back(xm_item)
	
	_export_song_button.commit_options()


func _handle_export_option(item: OptionListPopup.Item) -> void:
	match item.id:
		ExportOptions.EXPORT_WAV:
			Controller.io_manager.export_wav_song()
		_:
			Controller.update_status("FORMAT NOT SUPPORTED (YET)", Controller.StatusLevel.WARNING)
