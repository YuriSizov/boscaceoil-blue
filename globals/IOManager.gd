###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Song management component responsible for loading, saving, importing, and
## exporting of songs.
class_name IOManager extends RefCounted


# Creation.

func create_new_song() -> void:
	if Controller.music_player.is_playing():
		Controller.music_player.stop_playback()
	
	var new_song := Song.create_default_song()
	Controller.set_current_song(new_song)
	Controller.update_status("NEW SONG CREATED", Controller.StatusLevel.SUCCESS)


func create_new_song_safe() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to create a new one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			unsaved_warning.close_popup()
			create_new_song()
		)
		
		Controller.show_info_popup(unsaved_warning, Vector2(640, 220))
		return
	
	create_new_song()


# Ceol loading and saving.

func load_ceol_song() -> void:
	var load_dialog := Controller.get_file_dialog()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.title = "Load .ceol Song"
	load_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	load_dialog.file_selected.connect(_load_ceol_song_confirmed, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(load_dialog)


func load_ceol_song_safe() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to load a different one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			unsaved_warning.close_popup()
			load_ceol_song()
		)
		
		Controller.show_info_popup(unsaved_warning, Vector2(660, 220))
		return
	
	load_ceol_song()


func _load_ceol_song_confirmed(path: String) -> void:
	var loaded_song: Song = SongLoader.load(path)
	if not loaded_song:
		Controller.update_status("FAILED TO LOAD SONG", Controller.StatusLevel.ERROR)
		return
	
	if Controller.music_player.is_playing():
		Controller.music_player.stop_playback()
	
	Controller.set_current_song(loaded_song)
	Controller.update_status("SONG LOADED", Controller.StatusLevel.SUCCESS)
	print("Successfully loaded song from %s:\n  %s" % [ path, loaded_song ])


func save_ceol_song() -> void:
	var save_dialog := Controller.get_file_dialog()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.title = "Save .ceol Song"
	save_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	save_dialog.file_selected.connect(_save_ceol_song_confirmed, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(save_dialog)


func _save_ceol_song_confirmed(path: String) -> void:
	if not Controller.current_song:
		return
	
	var success := SongSaver.save(Controller.current_song, path)
	if not success:
		Controller.update_status("FAILED TO SAVE SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.mark_song_saved()
	Controller.update_status("SONG SAVED", Controller.StatusLevel.SUCCESS)
	print("Successfully saved song to %s." % [ path ])


func check_song_on_exit() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to quit?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			Controller.get_tree().quit()
		)
		
		Controller.show_info_popup(unsaved_warning, Vector2(600, 220))
		return
	
	Controller.get_tree().quit()


# External format import and export.

func export_wav_song() -> void:
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export .wav File"
	export_dialog.add_filter("*.wav", "Waveform Audio File")
	export_dialog.file_selected.connect(_export_wav_song_confirmed, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_wav_song_confirmed(path: String) -> void:
	if not Controller.current_song:
		return
	
	var exporter := WavExporter.new()
	var path_valid := exporter.set_export_path(path)
	if not path_valid:
		Controller.update_status("FAILED TO EXPORT SONG: INVALID FILENAME", Controller.StatusLevel.ERROR)
		return
	
	Controller.lock_song_editing()
	Controller.music_player.stop_playback()
	
	Controller.current_song.arrangement.set_loop(0, Controller.current_song.arrangement.timeline_length)
	Controller.current_song.reset_arrangement()
	
	Controller.music_player.export_ended.connect(_save_wav_song.bind(exporter), CONNECT_ONE_SHOT)
	Controller.music_player.start_exporting(_process_wav_song.bind(exporter))


func _process_wav_song(event: SiONEvent, exporter: WavExporter) -> void:
	exporter.append_data(event.get_stream_buffer())


func _save_wav_song(exporter: WavExporter) -> void:
	var success := exporter.save()
	if not success:
		Controller.update_status("FAILED TO EXPORT SONG", Controller.StatusLevel.ERROR)
		Controller.unlock_song_editing()
		return
	
	Controller.unlock_song_editing()
	Controller.update_status("SONG EXPORTED AS WAV", Controller.StatusLevel.SUCCESS)
	print("Successfully exported song to %s." % [ exporter.get_export_path() ])


func export_mid_song() -> void:
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export .mid File"
	export_dialog.add_filter("*.mid", "MIDI File")
	export_dialog.file_selected.connect(_export_mid_song_confirmed, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_mid_song_confirmed(path: String) -> void:
	if not Controller.current_song:
		return
	
	var success := MidiExporter.save(Controller.current_song, path)
	if not success:
		Controller.update_status("FAILED TO EXPORT SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.update_status("SONG EXPORTED AS MIDI", Controller.StatusLevel.SUCCESS)
	print("Successfully exported song to %s." % [ path ])
