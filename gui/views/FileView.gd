###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

const CREDITS_POPUP_SCENE := preload("res://gui/widgets/popups/CreditsPopup.tscn")

enum ImportOption {
	IMPORT_MID,
}

enum ExportOption {
	EXPORT_WAV,
	EXPORT_MID,
	EXPORT_MML,
	EXPORT_XM
}

var _subtitle_easter_egg: bool = false

var _credits_popup: WindowPopup = null

@onready var _version_number: Label = %VersionNumber
@onready var _version_subtitle: Label = %VersionSubtitle

@onready var _credits_button: SquishyButton = %Credits
@onready var _help_button: SquishyButton = %Help

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


func _init() -> void:
	_credits_popup = CREDITS_POPUP_SCENE.instantiate()


func _ready() -> void:
	_credits_popup.add_button("Close", _credits_popup.close_popup)
	
	_update_version_flair()
	_populate_import_options()
	_populate_export_options()
	
	_version_subtitle.gui_input.connect(_subtitle_gui_input)
	
	_credits_button.pressed.connect(_show_credits)
	_help_button.pressed.connect(Controller.navigate_to.bind(Menu.NavigationTarget.GENERAL_HELP))
	
	_play_button.pressed.connect(Controller.music_player.start_playback)
	_pause_button.pressed.connect(Controller.music_player.pause_playback)
	_stop_button.pressed.connect(Controller.music_player.stop_playback)
	
	_create_song_button.pressed.connect(Controller.io_manager.create_new_song_safe)
	_load_song_button.pressed.connect(Controller.io_manager.load_ceol_song_safe)
	_save_song_button.pressed.connect(Controller.io_manager.save_ceol_song)
	
	_import_song_button.option_pressed.connect(_handle_import_options)
	_export_song_button.option_pressed.connect(_handle_export_option)
	
	_pattern_size_stepper.value_changed.connect(_change_pattern_size)
	_bar_size_stepper.value_changed.connect(_change_bar_size)
	_bpm_stepper.value_changed.connect(_change_bpm)
	
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_update_song_steppers)
		Controller.song_sizes_changed.connect(_update_song_steppers)
		Controller.song_bpm_changed.connect(_update_song_steppers)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_credits_popup):
			_credits_popup.queue_free()


func _subtitle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_subtitle_easter_egg = !_subtitle_easter_egg
			_update_version_subtitle()


func _update_version_flair() -> void:
	if not is_inside_tree():
		return
	
	# Update version label.
	
	var version_setting: String = ProjectSettings.get_setting("application/config/version")
	var flair_setting: String = ProjectSettings.get_setting("application/config/version_flair")
	
	var version_arr := version_setting.split(".")
	var version_string := "v%s.%s" % [ version_arr[0], version_arr[1] ]
	if version_arr.size() > 2 && version_arr[2] != "0":
		version_string += ".%s" % [ version_arr[2] ]
	
	var flair_string := ""
	if not flair_setting.is_empty():
		flair_string = " %s" % [ flair_setting ]
	
	_version_number.text = "%s%s" % [ version_string, flair_string ]
	
	# Update subtitle label.
	_update_version_subtitle()


func _update_version_subtitle() -> void:
	if not is_inside_tree():
		return
	
	_version_subtitle.text = "Albam Gorm" if _subtitle_easter_egg else "The Blue Album"


func _change_pattern_size() -> void:
	Controller.set_song_pattern_size(_pattern_size_stepper.value)


func _change_bar_size() -> void:
	Controller.set_song_bar_size(_bar_size_stepper.value)


func _change_bpm() -> void:
	Controller.set_song_bpm(_bpm_stepper.value)


func _update_song_steppers() -> void:
	if not Controller.current_song:
		_pattern_size_stepper.value = Song.DEFAULT_PATTERN_SIZE
		_bar_size_stepper.value = Song.DEFAULT_BAR_SIZE
		_bpm_stepper.value = Song.DEFAULT_BPM
		return
	
	_pattern_size_stepper.value = Controller.current_song.pattern_size
	_bar_size_stepper.value = Controller.current_song.bar_size
	_bpm_stepper.value = Controller.current_song.bpm


func _show_credits() -> void:
	# Extra size to compensate for some things.
	Controller.show_window_popup(_credits_popup, _credits_popup.custom_minimum_size + Vector2(10, 10))


# Import and export.

func _populate_import_options() -> void:
	var mid_item := OptionListPopup.Item.new()
	mid_item.id = ImportOption.IMPORT_MID
	mid_item.text = "IMPORT .mid"
	_import_song_button.options.push_back(mid_item)
	
	_import_song_button.commit_options()


func _handle_import_options(item: OptionListPopup.Item) -> void:
	match item.id:
		ImportOption.IMPORT_MID:
			Controller.io_manager.import_mid_song_safe()
		_:
			Controller.update_status("FORMAT NOT SUPPORTED (YET)", Controller.StatusLevel.WARNING)


func _populate_export_options() -> void:
	var wav_item := OptionListPopup.Item.new()
	wav_item.id = ExportOption.EXPORT_WAV
	wav_item.text = "EXPORT .wav"
	_export_song_button.options.push_back(wav_item)
	
	var mid_item := OptionListPopup.Item.new()
	mid_item.id = ExportOption.EXPORT_MID
	mid_item.text = "EXPORT .mid"
	_export_song_button.options.push_back(mid_item)
	
	var mml_item := OptionListPopup.Item.new()
	mml_item.id = ExportOption.EXPORT_MML
	mml_item.text = "EXPORT .mml"
	_export_song_button.options.push_back(mml_item)
	
	var xm_item := OptionListPopup.Item.new()
	xm_item.id = ExportOption.EXPORT_XM
	xm_item.text = "EXPORT .xm"
	_export_song_button.options.push_back(xm_item)
	
	_export_song_button.commit_options()


func _handle_export_option(item: OptionListPopup.Item) -> void:
	match item.id:
		ExportOption.EXPORT_WAV:
			Controller.io_manager.export_wav_song()
		ExportOption.EXPORT_MID:
			Controller.io_manager.export_mid_song()
		ExportOption.EXPORT_MML:
			Controller.io_manager.export_mml_song()
		ExportOption.EXPORT_XM:
			Controller.io_manager.export_xm_song()
		_:
			Controller.update_status("FORMAT NOT SUPPORTED (YET)", Controller.StatusLevel.WARNING)
