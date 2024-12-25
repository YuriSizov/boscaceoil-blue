###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends Node

signal song_loaded()
signal song_saved()

signal song_sizes_changed()
signal song_bpm_changed()
signal song_effect_changed()
signal song_swing_changed()

signal song_pattern_created()
signal song_pattern_changed()
signal song_instrument_created()
signal song_instrument_changed()

signal controls_locked(message: String)
signal controls_unlocked()
signal status_updated(level: StatusLevel, message: String)
signal navigation_requested(target: int)
signal navigation_succeeded(target: int)

const MAIN_WINDOW_SCRIPT := preload("res://gui/MainWindow.gd")
const INFO_POPUP_SCENE := preload("res://gui/widgets/popups/InfoPopup.tscn")

enum StatusLevel {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
}

enum DragSources {
	PATTERN_DOCK,
	INSTRUMENT_DOCK,
}

var debug_manager: DebugManager = null
var settings_manager: SettingsManager = null
var window_manager: WindowManager = null
var state_manager: StateManager = null
var voice_manager: VoiceManager = null
var music_player: MusicPlayer = null
var io_manager: IOManager = null
var help_manager: HelpManager = null

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
var _file_dialog_finalize_callable: Callable = Callable()
var _file_dialog_was_playing: bool = false
var _file_dialog_web: FileDialogNativeWeb = null
var _info_popup: InfoPopup = null
var _controls_blocker: PopupManager.PopupControl = null

var _controls_locked: bool = false


func _init() -> void:
	debug_manager = DebugManager.new()
	settings_manager = SettingsManager.new()
	window_manager = WindowManager.new()
	state_manager = StateManager.new()
	voice_manager = VoiceManager.new()
	music_player = MusicPlayer.new()
	io_manager = IOManager.new()
	help_manager = HelpManager.new()
	
	settings_manager.buffer_size_changed.connect(music_player.update_driver_buffer)
	settings_manager.load_settings()
	
	state_manager.state_changed.connect(func() -> void:
		# TODO: It would be nice to track the last saved state and if we undo changes to get to it, mark as clean instead.
		current_song.mark_dirty()
	)


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_window().set_script(MAIN_WINDOW_SCRIPT)
	
	music_player.initialize_driver()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		io_manager.check_song_on_exit()
	
	elif what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_file_dialog):
			_file_dialog.queue_free()
		if is_instance_valid(_file_dialog_web):
			_file_dialog_web.free()
		if is_instance_valid(_info_popup):
			_info_popup.queue_free()
		if is_instance_valid(_controls_blocker):
			_controls_blocker.queue_free()


func _shortcut_input(event: InputEvent) -> void:
	if _controls_locked:
		return
	
	if event.is_action_pressed("bosca_exit", false, true):
		# Ignore this shortcut on web, as it doesn't make much sense
		# when you can close the tab. Even in fullscreen this probably
		# isn't an expected path — Esc is usually used to exit the
		# fullscreen.
		
		if not OS.has_feature("web"):
			io_manager.check_song_on_exit(true)
	
	elif event.is_action_pressed("bosca_playstop", false, true):
		if music_player.is_playing():
			music_player.stop_playback()
		else:
			music_player.start_playback()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("bosca_pause", false, true):
		if music_player.is_playing():
			music_player.pause_playback()
		else:
			music_player.start_playback()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("bosca_new", false, true):
		io_manager.create_new_song_safe()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("bosca_open", false, true):
		io_manager.load_ceol_song_safe()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("bosca_save", false, true):
		if current_song:
			if current_song.filename.is_empty():
				io_manager.save_ceol_song()
			else:
				io_manager._save_ceol_song_confirmed(current_song.filename)
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("bosca_save_as", false, true):
		if current_song:
			io_manager.save_ceol_song(true)
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_undo", false, true):
		if current_song:
			state_manager.undo_state_change()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_redo", false, true):
		if current_song:
			state_manager.do_state_change()
		
		get_viewport().set_input_as_handled()

	else:
		var debug_actions: Array[String] = [ "bosca_debug_1" ]
		for i in debug_actions.size():
			var action_name := debug_actions[i]
			if event.is_action_pressed(action_name, false, true):
				debug_manager.activate_debug(i)


# Navigation.

func navigate_to(target: Menu.NavigationTarget) -> void:
	navigation_requested.emit(target)


func mark_navigation_succeeded(target: Menu.NavigationTarget) -> void:
	navigation_succeeded.emit(target)


# Dialog and popup management.

func get_file_dialog() -> FileDialog:
	if not _file_dialog:
		_file_dialog = FileDialog.new()
		_file_dialog.use_native_dialog = true
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		
		# HACK: While it should be possible to compare this _finalize_file_dialog.unbind(1) with
		# another _finalize_file_dialog.unbind(1) later on, in actuality the check in the engine
		# is faulty and explicitly returns NOT EQUAL for two equal custom callables. So we do this.
		_file_dialog_finalize_callable = _finalize_file_dialog.unbind(1)
		_file_dialog.file_selected.connect(_file_dialog_finalize_callable)
		_file_dialog.canceled.connect(_clear_file_dialog_connections)
		_file_dialog.canceled.connect(_finalize_file_dialog)
	
	_file_dialog.clear_filters()
	_file_dialog.current_dir = settings_manager.get_last_opened_folder()
	return _file_dialog


func show_file_dialog(dialog: FileDialog) -> void:
	# Temporarily pausing playback can prevent issues with the synthesizer, as
	# the file dialog blocks the execution of the main window.
	_file_dialog_was_playing = music_player.is_playing()
	music_player.pause_playback(true)
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()


func _clear_file_dialog_connections() -> void:
	var connections := _file_dialog.file_selected.get_connections()
	for connection: Dictionary in connections:
		if connection["callable"] != _file_dialog_finalize_callable:
			_file_dialog.file_selected.disconnect(connection["callable"])


func _finalize_file_dialog() -> void:
	_file_dialog.get_parent().remove_child(_file_dialog)
	
	if _file_dialog_was_playing:
		_file_dialog_was_playing = false
		music_player.start_playback()
	
	settings_manager.set_last_opened_folder(_file_dialog.current_dir)


# Godot doesn't support native file dialogs on web yet.
func get_file_dialog_web() -> FileDialogNativeWeb:
	if not _file_dialog_web:
		_file_dialog_web = FileDialogNativeWeb.new()
		_file_dialog_web.canceled.connect(_clear_file_dialog_web_connections)
	
	_file_dialog_web.clear_filters()
	return _file_dialog_web


func _clear_file_dialog_web_connections() -> void:
	var connections := _file_dialog_web.file_selected.get_connections()
	for connection: Dictionary in connections:
		_file_dialog_web.file_selected.disconnect(connection["callable"])


func get_info_popup() -> InfoPopup:
	if not _info_popup:
		_info_popup = INFO_POPUP_SCENE.instantiate()
	
	if _info_popup.is_visible_in_tree():
		return null
	
	_info_popup.clear()
	return _info_popup


func show_window_popup(popup: WindowPopup, popup_size: Vector2) -> void:
	popup.popup_anchored(Vector2(0.5, 0.5), popup_size, PopupManager.Direction.OMNI, true)


func show_welcome_message() -> void:
	var welcome_message := get_info_popup()
	if not welcome_message:
		return # Popup is busy.
	
	welcome_message.title = "WELCOME to Bosca Ceoil"
	welcome_message.content = "Looks like this is your [accent]FIRST TIME[/accent]!\nWould you like a quick introduction?\n\n(You can access this tour later by clicking [accent]HELP[/accent].)"
	welcome_message.add_button("NO", welcome_message.close_popup)
	welcome_message.add_button("YES", func() -> void:
		welcome_message.close_popup()
		help_manager.start_guide(HelpManager.GuideType.BASIC_GUIDE)
	)
	
	show_window_popup(welcome_message, Vector2(600, 200))


func show_blocker() -> void:
	if not _controls_blocker:
		_controls_blocker = PopupManager.PopupControl.new()
	
	_controls_blocker.size = get_window().size
	PopupManager.show_popup(_controls_blocker, Vector2.ZERO, PopupManager.Direction.BOTTOM_RIGHT)


func hide_blocker() -> void:
	if not _controls_blocker:
		return
	
	PopupManager.hide_popup(_controls_blocker)


func update_status(message: String, level: StatusLevel = StatusLevel.INFO) -> void:
	status_updated.emit(level, message)


func update_status_notes_dropped(dropped_amount: int) -> void:
	if dropped_amount <= 0:
		return
	
	if dropped_amount == 1:
		update_status("%d NOTE WAS REMOVED (CTRL + Z TO UNDO)" % [ dropped_amount ], Controller.StatusLevel.WARNING)
	else:
		update_status("%d NOTES WERE REMOVED (CTRL + Z TO UNDO)" % [ dropped_amount ], Controller.StatusLevel.WARNING)


# Song editing.

func set_current_song(song: Song) -> void:
	state_manager.clear_state_memory()
	
	current_song = song
	_change_current_pattern(0, false, true)
	_change_current_instrument(0, false)
	
	music_player.reset_driver()
	music_player.start_playback()
	
	song_loaded.emit()


func mark_song_saved() -> void:
	current_song.mark_clean()
	song_saved.emit()


func lock_song_editing(message: String) -> void:
	_controls_locked = true
	show_blocker()
	controls_locked.emit(message)


func unlock_song_editing() -> void:
	_controls_locked = false
	hide_blocker()
	controls_unlocked.emit()


func is_song_editing_locked() -> bool:
	return _controls_locked


# Pattern editing.

func _change_current_pattern(pattern_index: int, notify: bool = true, force: bool = false) -> void:
	if current_pattern_index == pattern_index && not force:
		return
	
	if current_song && current_pattern_index < current_song.patterns.size():
		var current_pattern := current_song.patterns[current_pattern_index]
		if current_pattern.note_added.is_connected(_handle_pattern_note_added):
			current_pattern.note_added.disconnect(_handle_pattern_note_added)
	
	current_pattern_index = pattern_index
	
	if current_song && current_pattern_index < current_song.patterns.size():
		var current_pattern := current_song.patterns[current_pattern_index]
		if not current_pattern.note_added.is_connected(_handle_pattern_note_added):
			current_pattern.note_added.connect(_handle_pattern_note_added)
	
	if notify:
		song_pattern_changed.emit()


func _untrack_pattern_changes(pattern_index: int) -> void:
	if not current_song || pattern_index >= current_song.patterns.size():
		return
	
	var pattern := current_song.patterns[pattern_index]
	if pattern.note_added.is_connected(_handle_pattern_note_added):
		pattern.note_added.disconnect(_handle_pattern_note_added)


func create_pattern() -> void:
	if not current_song:
		return
	if current_song.patterns.size() >= Song.MAX_PATTERN_COUNT:
		return
	
	var instrument_idx := current_instrument_index
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	var state_context := song_state.get_context()
	state_context["id"] = -1
	
	song_state.add_do_action(func() -> void:
		state_context.id = create_pattern_nocheck(instrument_idx)
		song_pattern_created.emit()
	)
	song_state.add_undo_action(func() -> void:
		delete_pattern_nocheck(state_context.id)
	)
	
	state_manager.commit_state_change(song_state)


func create_pattern_nocheck(instrument_index: int) -> int:
	var pattern_index := current_song.patterns.size()
	
	var pattern := Pattern.new()
	pattern.instrument_idx = instrument_index
	current_song.add_pattern(pattern)
	
	return pattern_index


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


func can_clone_pattern(pattern_index: int) -> bool:
	if not current_song:
		return false
	if current_song.patterns.size() >= Song.MAX_PATTERN_COUNT:
		return false
	
	var pattern_index_ := ValueValidator.index(pattern_index, current_song.patterns.size())
	if pattern_index != pattern_index_:
		return false
	
	return true


func clone_pattern_nocheck(pattern_index: int) -> int:
	var cloned_index := current_song.patterns.size()
	var pattern := current_song.patterns[pattern_index].clone()
	current_song.add_pattern(pattern)

	_change_current_pattern(cloned_index)
	return cloned_index


func delete_pattern(pattern_index: int) -> void:
	if not current_song:
		return
	
	var pattern_index_ := ValueValidator.index(pattern_index, current_song.patterns.size())
	if pattern_index != pattern_index_:
		return
	
	var instrument_idx := current_instrument_index
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	var state_context := song_state.get_context()
	state_context["pattern"] = null
	state_context["deleted_last"] = false
	state_context["cleared_bars"] = []
	state_context["shifted_bars"] = []
	
	song_state.add_do_action(func() -> void:
		# Delete the pattern itself from the list.
		state_context.pattern = current_song.patterns[pattern_index]
		_untrack_pattern_changes(pattern_index)
		current_song.remove_pattern(pattern_index)
		
		# There is nothing left, create a new one.
		if current_song.patterns.is_empty():
			create_pattern_nocheck(instrument_idx)
			state_context.deleted_last = true
		else:
			state_context.deleted_last = false
		
		# Make sure the edited pattern is valid.
		if current_pattern_index >= current_song.patterns.size():
			_change_current_pattern(current_song.patterns.size() - 1, false)
		
		state_context.cleared_bars.clear()
		state_context.shifted_bars.clear()
		
		# Validate the arrangement.
		for bar_idx in current_song.arrangement.timeline_bars.size():
			var bar := current_song.arrangement.timeline_bars[bar_idx]
			
			for i in Arrangement.CHANNEL_NUMBER:
				# If we deleted this pattern, clear the channel.
				if bar[i] == pattern_index:
					bar[i] = -1
					state_context.cleared_bars.push_back(Vector2i(bar_idx, i))
				
				# If we deleted a pattern before this one in the list, shift the index. 
				elif bar[i] > pattern_index:
					bar[i] = bar[i] - 1
					state_context.shifted_bars.push_back(Vector2i(bar_idx, i))
		
		current_song.arrangement.update_timeline_length()
		song_pattern_changed.emit()
	)
	song_state.add_undo_action(func() -> void:
		# Delete the replacement pattern, if it was created.
		if state_context.deleted_last:
			_untrack_pattern_changes(0)
			current_song.remove_pattern(0)
		
		# Restore the original pattern.
		current_song.add_pattern(state_context.pattern, pattern_index)
		
		# Restore cleared and shifted bars.
		for key: Vector2i in state_context.cleared_bars:
			current_song.arrangement.timeline_bars[key.x][key.y] = pattern_index
		for key: Vector2i in state_context.shifted_bars:
			current_song.arrangement.timeline_bars[key.x][key.y] = current_song.arrangement.timeline_bars[key.x][key.y] + 1
		
		current_song.arrangement.update_timeline_length()
		song_pattern_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func delete_pattern_nocheck(pattern_index: int) -> void:
	_untrack_pattern_changes(pattern_index)
	current_song.remove_pattern(pattern_index)
	
	# Make sure the edited pattern is valid.
	if current_pattern_index >= current_song.patterns.size():
		_change_current_pattern(current_song.patterns.size() - 1)


func get_current_pattern() -> Pattern:
	if not current_song:
		return null
	if current_pattern_index < 0 || current_pattern_index >= current_song.patterns.size():
		return null
	
	return current_song.patterns[current_pattern_index]


func refresh_current_pattern_instrument() -> void:
	var current_pattern := get_current_pattern()
	var instrument := current_song.instruments[current_pattern.instrument_idx]
	
	current_pattern.change_instrument(current_pattern.instrument_idx, instrument)


func preview_pattern_note(value: int, length: int) -> void:
	var note_data := Vector3i(value, music_player.get_pattern_time(), length)
	if note_data.y < 0:
		note_data.y = 0 # A small fix for when the playback is completely stopped.
	
	var current_pattern := get_current_pattern()
	if current_pattern:
		music_player.play_note(current_pattern, note_data)


func _handle_pattern_note_added(note_data: Vector3i) -> void:
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
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	var state_context := song_state.get_context()
	state_context["id"] = -1
	
	song_state.add_do_action(func() -> void:
		state_context.id = create_instrument_nocheck(voice_data)
		song_instrument_created.emit()
	)
	song_state.add_undo_action(func() -> void:
		delete_instrument_nocheck(state_context.id)
	)
	
	state_manager.commit_state_change(song_state)


func create_instrument_nocheck(voice_data: VoiceManager.VoiceData) -> int:
	var instrument_index := current_song.instruments.size()
	
	var instrument := instance_instrument_by_voice(voice_data)
	current_song.add_instrument(instrument)
	
	return instrument_index


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


func randomize_current_instrument() -> void:
	randomize_instrument(current_instrument_index)


func randomize_instrument(instrument_index: int) -> void:
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return

	var voice_data := voice_manager.get_random_voice_data()
	_set_current_instrument_by_voice(voice_data)


func delete_instrument(instrument_index: int) -> void:
	if not current_song:
		return
	
	var instrument_index_ := ValueValidator.index(instrument_index, current_song.instruments.size())
	if instrument_index != instrument_index_:
		return
	
	var voice_data := voice_manager.get_random_voice_data()
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	var state_context := song_state.get_context()
	state_context["instrument"] = null
	state_context["deleted_last"] = false
	state_context["reset_patterns"] = []
	state_context["reset_patterns_keys"] = []
	state_context["reset_patterns_affected"] = []
	state_context["shifted_patterns"] = []
	
	song_state.add_do_action(func() -> void:
		# Delete the instrument itself from the list.
		state_context.instrument = current_song.instruments[instrument_index]
		current_song.remove_instrument(instrument_index)
		
		# There is nothing left, create a new one.
		if current_song.instruments.is_empty():
			create_instrument_nocheck(voice_data)
			state_context.deleted_last = true
		else:
			state_context.deleted_last = false
		
		# Make sure the edited instrument is valid.
		if current_instrument_index >= current_song.instruments.size():
			_change_current_instrument(current_song.instruments.size() - 1, false)
		
		state_context.reset_patterns.clear()
		state_context.reset_patterns_keys.clear()
		state_context.reset_patterns_affected.clear()
		state_context.shifted_patterns.clear()
		
		var total_affected_count := 0
		
		# Validate instruments in available patterns.
		
		# Note that we actually want the current pattern here, not the one that was current when we
		# created this state. Same applies to undo.
		var current_pattern_affected := false
		for pattern_idx in current_song.patterns.size():
			var pattern := current_song.patterns[pattern_idx]
			
			# If we deleted this instrument, set the pattern to the first available.
			if pattern.instrument_idx == instrument_index:
				state_context.reset_patterns_keys.push_back(pattern.key) # When changing to a drumkit, this is reset.
				
				var affected := pattern.change_instrument(0, current_song.instruments[0])
				state_context.reset_patterns.push_back(pattern_idx)
				state_context.reset_patterns_affected.push_back(affected)
				total_affected_count += affected.size()
				
				if pattern_idx == current_pattern_index:
					current_pattern_affected = true
			
			# If we deleted an instrument before this one in the list, shift the index.
			elif pattern.instrument_idx > instrument_index:
				pattern.instrument_idx -= 1
				state_context.shifted_patterns.push_back(pattern_idx)
				
				if pattern_idx == current_pattern_index:
					current_pattern_affected = true
		
		song_instrument_changed.emit()
		
		if total_affected_count > 0:
			update_status_notes_dropped(total_affected_count)
		
		# Properly signal that the instrument has changed for the currently edited pattern.
		if current_pattern_affected:
			refresh_current_pattern_instrument()
	)
	song_state.add_undo_action(func() -> void:
		# Delete the replacement instrument, if it was created.
		if state_context.deleted_last:
			current_song.remove_instrument(0)
		
		# Restore the original instrument.
		current_song.add_instrument(state_context.instrument, instrument_index)
		
		# Restore reset and shifted patterns.
		
		# Note that we actually want the current pattern here, not the one that was current when we
		# created this state. Same applies to do.
		var current_pattern_affected := false
		
		for i: int in state_context.reset_patterns.size():
			var pattern_idx: int = state_context.reset_patterns[i]
			current_song.patterns[pattern_idx].change_instrument(instrument_index, current_song.instruments[instrument_index])
			
			var affected: Array[Vector3i] = state_context.reset_patterns_affected[i]
			current_song.patterns[pattern_idx].restore_notes(affected)

			var pattern_key: int = state_context.reset_patterns_keys[i]
			current_song.patterns[pattern_idx].change_key(pattern_key)

			if pattern_idx == current_pattern_index:
				current_pattern_affected = true
		
		for pattern_idx: int in state_context.shifted_patterns:
			current_song.patterns[pattern_idx].instrument_idx += 1
			
			if pattern_idx == current_pattern_index:
				current_pattern_affected = true
		
		# Properly signal that the instrument has changed for the currently edited pattern.
		if current_pattern_affected:
			refresh_current_pattern_instrument()
		
		song_instrument_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func delete_instrument_nocheck(instrument_index: int) -> void:
	current_song.remove_instrument(instrument_index)
	
	# Make sure the edited instrument is valid.
	if current_instrument_index >= current_song.instruments.size():
		_change_current_instrument(current_song.instruments.size() - 1)


func get_current_instrument() -> Instrument:
	if not current_song:
		return null
	if current_instrument_index < 0 || current_instrument_index >= current_song.instruments.size():
		return null
	
	return current_song.instruments[current_instrument_index]


func _set_current_instrument_by_voice(voice_data: VoiceManager.VoiceData) -> void:
	if not voice_data:
		return
	
	var instrument_idx := current_instrument_index
	var old_instrument := current_song.instruments[instrument_idx]
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	var state_context := song_state.get_context()
	state_context["reset_patterns"] = []
	state_context["reset_patterns_keys"] = []
	state_context["reset_patterns_affected"] = []

	song_state.add_do_action(func() -> void:
		var instrument := instance_instrument_by_voice(voice_data)
		current_song.instruments[instrument_idx] = instrument
		
		state_context.reset_patterns.clear()
		state_context.reset_patterns_keys.clear()
		state_context.reset_patterns_affected.clear()
		
		var total_affected_count := 0
		
		# Validate instruments in available patterns.
		for pattern_idx in current_song.patterns.size():
			var pattern := current_song.patterns[pattern_idx]
			
			if pattern.instrument_idx == instrument_idx:
				state_context.reset_patterns_keys.push_back(pattern.key) # When changing to a drumkit, this is reset.
				
				var affected := pattern.change_instrument(instrument_idx, instrument)
				state_context.reset_patterns.push_back(pattern_idx)
				state_context.reset_patterns_affected.push_back(affected)
				total_affected_count += affected.size()
		
		song_instrument_changed.emit()
		
		if total_affected_count > 0:
			update_status_notes_dropped(total_affected_count)
	)
	song_state.add_undo_action(func() -> void:
		current_song.instruments[instrument_idx] = old_instrument
		song_instrument_changed.emit()
		
		# Restore affected patterns and notes.
		for i: int in state_context.reset_patterns.size():
			var pattern_idx: int = state_context.reset_patterns[i]
			current_song.patterns[pattern_idx].change_instrument(instrument_idx, old_instrument)
			
			var affected: Array[Vector3i] = state_context.reset_patterns_affected[i]
			current_song.patterns[pattern_idx].restore_notes(affected)

			var pattern_key: int = state_context.reset_patterns_keys[i]
			current_song.patterns[pattern_idx].change_key(pattern_key)
	)
	
	state_manager.commit_state_change(song_state)


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
	if not instrument || not instrument_themes.has(instrument.color_palette):
		return instrument_themes[ColorPalette.PALETTE_GRAY]
	
	return instrument_themes[instrument.color_palette]


# Song properties editing.

func set_song_pattern_size(value: int) -> void:
	if not current_song:
		return
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	song_state.add_property(current_song, "pattern_size", value)
	song_state.add_action(
		func() -> void:
			song_sizes_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func set_song_bar_size(value: int) -> void:
	if not current_song:
		return
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	song_state.add_property(current_song, "bar_size", value)
	song_state.add_action(
		func() -> void:
			song_sizes_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func set_song_bpm(value: int) -> void:
	if not current_song:
		return
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	song_state.add_property(current_song, "bpm", value)
	song_state.add_action(
		func() -> void:
			music_player.update_driver_bpm()
			song_bpm_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func set_song_global_effect(effect: int, power: int) -> void:
	if not current_song:
		return
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG, -1, "song_global_effect")
	song_state.add_property(current_song, "global_effect", effect)
	song_state.add_property(current_song, "global_effect_power", power)
	song_state.add_action(
		func() -> void:
			music_player.update_driver_effects()
			song_effect_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)


func set_song_swing(value: int) -> void:
	if not current_song:
		return
	
	var song_state := state_manager.create_state_change(StateManager.StateChangeType.SONG)
	song_state.add_property(current_song, "swing", value)
	song_state.add_action(
		func() -> void:
			song_swing_changed.emit()
	)
	
	state_manager.commit_state_change(song_state)
