###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends Node

signal song_loaded()
signal song_saved()

signal song_sizes_changed()
signal song_pattern_changed()
signal song_instrument_changed()

var voice_manager: VoiceManager = null
var music_player: MusicPlayer = null

## Current edited song.
var current_song: Song = null
## Current edited pattern in the song, by index.
var current_pattern_index: int = -1
## Current edited instrument in the song, by index.
var current_instrument_index: int = -1

var instrument_themes: Dictionary = {
	ColorPalette.PALETTE_BLUE:   preload("res://gui/theme/instrument_theme_blue.tres"),
	ColorPalette.PALETTE_PURPLE: preload("res://gui/theme/instrument_theme_purple.tres"),
	ColorPalette.PALETTE_RED:    preload("res://gui/theme/instrument_theme_red.tres"),
	ColorPalette.PALETTE_ORANGE: preload("res://gui/theme/instrument_theme_orange.tres"),
	ColorPalette.PALETTE_GREEN:  preload("res://gui/theme/instrument_theme_green.tres"),
	ColorPalette.PALETTE_CYAN:   preload("res://gui/theme/instrument_theme_cyan.tres"),
	ColorPalette.PALETTE_GRAY:   preload("res://gui/theme/instrument_theme_gray.tres"),
}

var _file_dialog: FileDialog = null


func _init() -> void:
	voice_manager = VoiceManager.new()
	music_player = MusicPlayer.new(self)


func _ready() -> void:
	# Driver must be ready by this time.
	music_player.initialize()
	create_new_song()


# File dialog management.

func _get_file_dialog() -> FileDialog:
	if not _file_dialog:
		_file_dialog = FileDialog.new()
		_file_dialog.use_native_dialog = true
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		
		_file_dialog.file_selected.connect(_unparent_file_dialog.unbind(1))
		_file_dialog.canceled.connect(_clear_file_dialog_connections)
		_file_dialog.canceled.connect(_unparent_file_dialog)
	
	return _file_dialog


func _clear_file_dialog_connections() -> void:
	var connections := _file_dialog.file_selected.get_connections()
	for connection : Dictionary in connections:
		if connection["callable"] != _unparent_file_dialog:
			_file_dialog.file_selected.disconnect(connection["callable"])


func _unparent_file_dialog() -> void:
	_file_dialog.get_parent().remove_child(_file_dialog)


# Song management.

func create_new_song() -> void:
	if music_player.is_playing():
		music_player.stop_playback()
	
	current_song = Song.create_default_song()
	current_pattern_index = 0
	current_instrument_index = 0
	
	music_player.reset_driver()
	music_player.start_playback()
	
	song_loaded.emit()


func create_new_song_safe() -> void:
	if current_song && current_song.is_dirty():
		# TODO: First ask to save the current one.
		pass
	
	create_new_song()


func load_ceol_song() -> void:
	var load_dialog := _get_file_dialog()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	load_dialog.file_selected.connect(_load_ceol_song_confirmed, CONNECT_ONE_SHOT)
	
	get_tree().root.add_child(load_dialog)
	load_dialog.popup_centered()


func _load_ceol_song_confirmed(path: String) -> void:
	var loaded_song: Song = SongLoader.load(path)
	if not loaded_song:
		# TODO: Show an error message.
		return
	print("Successfully loaded song from %s:\n  %s" % [ path, loaded_song ])
	
	if music_player.is_playing():
		music_player.stop_playback()
	
	current_song = loaded_song
	current_pattern_index = 0
	current_instrument_index = 0
	
	music_player.reset_driver()
	music_player.start_playback()
	
	song_loaded.emit()


func save_ceol_song() -> void:
	var load_dialog := _get_file_dialog()
	load_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	load_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	load_dialog.file_selected.connect(_save_ceol_song_confirmed, CONNECT_ONE_SHOT)
	
	get_tree().root.add_child(load_dialog)
	load_dialog.popup_centered()


func _save_ceol_song_confirmed(path: String) -> void:
	var success := SongSaver.save(current_song, path)
	if not success:
		# TODO: Show an error message.
		return
	print("Successfully saved song to %s." % [ path ])
	
	current_song.mark_clean()
	song_saved.emit()


# Song editing.

func get_current_pattern() -> Pattern:
	if not current_song:
		return null
	if current_pattern_index < 0 || current_pattern_index >= current_song.patterns.size():
		return null
	
	return current_song.patterns[current_pattern_index]


func instance_instrument_by_voice(voice_data: VoiceManager.VoiceData) -> Instrument:
	var instrument: Instrument = null
	
	if voice_data is VoiceManager.DrumkitData:
		instrument = DrumkitInstrument.new(voice_data)
	else:
		instrument = SingleVoiceInstrument.new(voice_data)
	
	return instrument


func create_instrument() -> void:
	if not current_song:
		return
	if current_song.instruments.size() >= Song.MAX_INSTRUMENT_COUNT:
		return
	
	var voice_data := voice_manager.get_random_voice_data()
	var instrument := instance_instrument_by_voice(voice_data)
	current_song.instruments.push_back(instrument)
	current_song.mark_dirty()


func create_and_edit_instrument() -> void:
	if not current_song:
		return
	if current_song.instruments.size() >= Song.MAX_INSTRUMENT_COUNT:
		return
	
	create_instrument()
	current_instrument_index = current_song.instruments.size() - 1
	song_instrument_changed.emit()


func edit_instrument(instrument_index: int) -> void:
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return
	
	current_instrument_index = instrument_index
	song_instrument_changed.emit()


func delete_instrument(instrument_index: int) -> void:
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return
	
	current_song.instruments.remove_at(instrument_index)
	if current_song.instruments.size() == 0: # There is nothing left, create a new one.
		create_instrument()
	
	var current_pattern := get_current_pattern()
	var current_pattern_affected := false
	for pattern in current_song.patterns:
		# If we delete this instrument, set the pattern to the first available.
		if pattern.instrument_idx == instrument_index:
			pattern.instrument_idx = 0
			if pattern == current_pattern:
				current_pattern_affected = true
		
		# If we delete an instrument before this one in the list, shift the index.
		elif pattern.instrument_idx > instrument_index:
			pattern.instrument_idx -= 1
			if pattern == current_pattern:
				current_pattern_affected = true
	
	if current_instrument_index >= current_song.instruments.size():
		current_instrument_index = current_song.instruments.size() - 1
	song_instrument_changed.emit()
	
	if current_pattern && current_pattern_affected:
		var instrument := current_song.instruments[current_pattern.instrument_idx]
		current_pattern.change_instrument(current_pattern.instrument_idx, instrument)
	
	current_song.mark_dirty()


func get_current_instrument() -> Instrument:
	if not current_song:
		return null
	if current_instrument_index < 0 || current_instrument_index >= current_song.instruments.size():
		return null
	
	return current_song.instruments[current_instrument_index]


func _set_current_instrument_by_voice(voice_data: VoiceManager.VoiceData) -> void:
	if not voice_data:
		return
	
	var instrument := instance_instrument_by_voice(voice_data)
	current_song.instruments[current_instrument_index] = instrument
	song_instrument_changed.emit()
	
	var current_pattern := get_current_pattern()
	if current_pattern && current_pattern.instrument_idx == current_instrument_index:
		current_pattern.change_instrument(current_instrument_index, instrument)
	
	current_song.mark_dirty()


func set_current_instrument(category: String, instrument_name: String) -> void:
	if not current_song:
		return
	if current_instrument_index < 0 || current_instrument_index >= current_song.instruments.size():
		return
	
	var voice_data := Controller.voice_manager.get_voice_data(category, instrument_name)
	_set_current_instrument_by_voice(voice_data)


func set_current_instrument_by_category(category: String) -> void:
	if not current_song:
		return
	if current_instrument_index < 0 || current_instrument_index >= current_song.instruments.size():
		return
	
	var voice_data := Controller.voice_manager.get_first_voice_data(category)
	_set_current_instrument_by_voice(voice_data)


func get_current_instrument_theme() -> Theme:
	var current_instrument := get_current_instrument()
	if not current_instrument || not instrument_themes.has(current_instrument.color_palette):
		return instrument_themes[ColorPalette.PALETTE_GRAY]
	
	return instrument_themes[current_instrument.color_palette]


func get_instrument_theme(instrument: Instrument) -> Theme:
	if not instrument_themes.has(instrument.color_palette):
		return instrument_themes[ColorPalette.PALETTE_GRAY]
	
	return instrument_themes[instrument.color_palette]


func set_pattern_size(value: int) -> void:
	if not current_song:
		return
	
	current_song.pattern_size = value
	current_song.mark_dirty()
	song_sizes_changed.emit()


func set_bar_size(value: int) -> void:
	if not current_song:
		return
	
	current_song.bar_size = value
	current_song.mark_dirty()
	song_sizes_changed.emit()


func set_bpm(value: int) -> void:
	if not current_song:
		return
	
	current_song.bpm = value
	current_song.mark_dirty()
	music_player.update_driver_bpm()
