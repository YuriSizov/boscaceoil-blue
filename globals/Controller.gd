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

const INFO_POPUP_SCENE := preload("res://gui/widgets/InfoPopup.tscn")

enum DragSources {
	PATTERN_DOCK,
	INSTRUMENT_DOCK,
}

var voice_manager: VoiceManager = null
var music_player: MusicPlayer = null

## Current edited song.
var current_song: Song = null
## Current edited pattern in the song, by index.
var current_pattern_index: int = -1
## Current edited instrument in the song, by index.
var current_instrument_index: int = -1

var instrument_themes: Dictionary = {
	ColorPalette.PALETTE_BLUE:   preload("res://gui/theme/instruments/instrument_theme_blue.tres"),
	ColorPalette.PALETTE_PURPLE: preload("res://gui/theme/instruments/instrument_theme_purple.tres"),
	ColorPalette.PALETTE_RED:    preload("res://gui/theme/instruments/instrument_theme_red.tres"),
	ColorPalette.PALETTE_ORANGE: preload("res://gui/theme/instruments/instrument_theme_orange.tres"),
	ColorPalette.PALETTE_GREEN:  preload("res://gui/theme/instruments/instrument_theme_green.tres"),
	ColorPalette.PALETTE_CYAN:   preload("res://gui/theme/instruments/instrument_theme_cyan.tres"),
	ColorPalette.PALETTE_GRAY:   preload("res://gui/theme/instruments/instrument_theme_gray.tres"),
}

var _file_dialog: FileDialog = null
var _info_popup: InfoPopup = null


func _init() -> void:
	voice_manager = VoiceManager.new()
	music_player = MusicPlayer.new(self)


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	# Driver must be ready by this time.
	music_player.initialize()
	create_new_song()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_check_song_on_exit()
	elif what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_file_dialog):
			_file_dialog.queue_free()
		if is_instance_valid(_info_popup):
			_info_popup.queue_free()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("bosca_pause"):
		if music_player.is_playing():
			music_player.pause_playback()
		else:
			music_player.start_playback()
		get_viewport().set_input_as_handled()


# Dialog management.

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


func _get_info_popup() -> InfoPopup:
	if not _info_popup:
		_info_popup = INFO_POPUP_SCENE.instantiate()
	
	_info_popup.clear()
	return _info_popup


# Song management.

func create_new_song() -> void:
	if music_player.is_playing():
		music_player.stop_playback()
	
	current_song = Song.create_default_song()
	_change_current_pattern(0, false)
	_change_current_instrument(0, false)
	
	music_player.reset_driver()
	music_player.start_playback()
	
	song_loaded.emit()


func create_new_song_safe() -> void:
	if current_song && current_song.is_dirty():
		var unsaved_warning := _get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to create a new one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func():
			unsaved_warning.close_popup()
			create_new_song()
		)
		
		unsaved_warning.size = Vector2(640, 220)
		unsaved_warning.popup(get_window().size / 2)
		return
	
	create_new_song()


func load_ceol_song_safe() -> void:
	if current_song && current_song.is_dirty():
		var unsaved_warning := _get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to load a different one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func():
			unsaved_warning.close_popup()
			load_ceol_song()
		)
		
		unsaved_warning.size = Vector2(660, 220)
		unsaved_warning.popup(get_window().size / 2)
		return
	
	load_ceol_song()


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
	_change_current_pattern(0, false)
	_change_current_instrument(0, false)
	
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


func _check_song_on_exit() -> void:
	if current_song && current_song.is_dirty():
		var unsaved_warning := _get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to quit?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func():
			get_tree().quit()
		)
		
		unsaved_warning.size = Vector2(600, 220)
		unsaved_warning.popup(get_window().size / 2)
		return
	
	get_tree().quit()


# Pattern editing.

func _change_current_pattern(pattern_index: int, notify: bool = true) -> void:
	if current_pattern_index == pattern_index:
		return
	
	if current_song && current_pattern_index < current_song.patterns.size():
		var current_pattern := current_song.patterns[current_pattern_index]
		if current_pattern.note_added.is_connected(_handle_pattern_note_added):
			current_pattern.note_added.disconnect(_handle_pattern_note_added)
	
	current_pattern_index = pattern_index
	
	if current_song && current_pattern_index < current_song.patterns.size():
		var current_pattern := current_song.patterns[current_pattern_index]
		current_pattern.note_added.connect(_handle_pattern_note_added)

	if notify:
		song_pattern_changed.emit()


func create_pattern() -> void:
	if not current_song:
		return
	if current_song.patterns.size() >= Song.MAX_PATTERN_COUNT:
		return
	
	var pattern := Pattern.new()
	pattern.instrument_idx = current_instrument_index
	current_song.patterns.push_back(pattern)
	current_song.mark_dirty()


func create_and_edit_pattern() -> void:
	if not current_song:
		return
	if current_song.patterns.size() >= Song.MAX_PATTERN_COUNT:
		return
	
	create_pattern()
	_change_current_pattern(current_song.patterns.size() - 1)


func edit_pattern(pattern_index: int) -> void:
	if not current_song:
		return
	
	var pattern_index_ := ValueValidator.index(pattern_index, current_song.patterns.size())
	if pattern_index != pattern_index_:
		return
	
	_change_current_pattern(pattern_index)


func clone_pattern(pattern_index: int) -> int:
	if not current_song:
		return -1
	if current_song.patterns.size() >= Song.MAX_PATTERN_COUNT:
		return -1
	
	var pattern_index_ := ValueValidator.index(pattern_index, current_song.patterns.size())
	if pattern_index != pattern_index_:
		return -1
	
	var cloned_index := current_song.patterns.size()
	var pattern := current_song.patterns[pattern_index].clone()
	current_song.patterns.push_back(pattern)

	_change_current_pattern(cloned_index)
	return cloned_index


func delete_pattern(pattern_index: int) -> void:
	var pattern_index_ := ValueValidator.index(pattern_index, current_song.patterns.size())
	if pattern_index != pattern_index_:
		return
	
	current_song.patterns.remove_at(pattern_index)
	if current_song.patterns.size() == 0: # There is nothing left, create a new one.
		create_pattern()
	
	# Validate the arrangement.
	
	for bar in current_song.arrangement.timeline_bars:
		for i in Arrangement.CHANNEL_NUMBER:
			# If we delete this pattern, clear the channel.
			if bar[i] == pattern_index:
				bar[i] = -1
			
			# If we delete a pattern before this one in the list, shift the index. 
			elif bar[i] > pattern_index:
				bar[i] = bar[i] - 1
	
	# Make sure the edited pattern is valid.
	if current_pattern_index >= current_song.patterns.size():
		_change_current_pattern(current_song.patterns.size() - 1, false)
	song_pattern_changed.emit()
	
	current_song.mark_dirty()


func get_current_pattern() -> Pattern:
	if not current_song:
		return null
	if current_pattern_index < 0 || current_pattern_index >= current_song.patterns.size():
		return null
	
	return current_song.patterns[current_pattern_index]


func _handle_pattern_note_added(note_data: Vector3) -> void:
	# Play the added note immediately if the song is not playing.
	if music_player.is_playing():
		return
	
	var current_pattern := get_current_pattern()
	if current_pattern:
		music_player.play_note(current_pattern, note_data)


# Instrument editing.

func _change_current_instrument(instrument_index: int, notify: bool = true) -> void:
	if current_instrument_index == instrument_index:
		return
	
	current_instrument_index = instrument_index
	
	if notify:
		song_instrument_changed.emit()


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
	_change_current_instrument(current_song.instruments.size() - 1)


func edit_instrument(instrument_index: int) -> void:
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return
	
	_change_current_instrument(instrument_index)


func delete_instrument(instrument_index: int) -> void:
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return
	
	current_song.instruments.remove_at(instrument_index)
	if current_song.instruments.size() == 0: # There is nothing left, create a new one.
		create_instrument()
	
	# Validate instruments in available patterns.
	
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
	
	# Make sure the edited instrument is valid.
	if current_instrument_index >= current_song.instruments.size():
		_change_current_instrument(current_song.instruments.size() - 1, false)
	song_instrument_changed.emit()
	
	# Properly signal that the instrument has changed for the edited pattern.
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
	
	var voice_data := voice_manager.get_voice_data(category, instrument_name)
	_set_current_instrument_by_voice(voice_data)


func set_current_instrument_by_category(category: String) -> void:
	if not current_song:
		return
	if current_instrument_index < 0 || current_instrument_index >= current_song.instruments.size():
		return
	
	var voice_data := voice_manager.get_first_voice_data(category)
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


# Song properties editing.

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
