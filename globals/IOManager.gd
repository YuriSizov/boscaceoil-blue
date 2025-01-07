###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Song management component responsible for loading, saving, importing, and
## exporting of songs.
class_name IOManager extends RefCounted

const IMPORT_MASTER_POPUP_SCENE := preload("res://gui/widgets/popups/ImportMasterPopup.tscn")
const EXPORT_MASTER_POPUP_SCENE := preload("res://gui/widgets/popups/ExportMasterPopup.tscn")

var _import_master_popup: ImportMasterPopup = null
var _export_master_popup: ExportMasterPopup = null
# We must keep references around, otherwise they get silently destroyed.
# JavaScriptBridge doesn't tick the reference counter, it seems.
var _check_song_on_browser_close_ref: JavaScriptObject = null


func _init() -> void:
	if OS.has_feature("web"):
		_connect_to_browser_close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_import_master_popup):
			_import_master_popup.queue_free()
		if is_instance_valid(_export_master_popup):
			_export_master_popup.queue_free()


# Popup management.

func get_import_master_popup() -> ImportMasterPopup:
	if not _import_master_popup:
		_import_master_popup = IMPORT_MASTER_POPUP_SCENE.instantiate()
	
	if _import_master_popup.is_visible_in_tree():
		_import_master_popup.close_popup()
	
	_import_master_popup.clear()
	return _import_master_popup


func get_export_master_popup() -> ExportMasterPopup:
	if not _export_master_popup:
		_export_master_popup = EXPORT_MASTER_POPUP_SCENE.instantiate()
	
	if _export_master_popup.is_visible_in_tree():
		_export_master_popup.close_popup()
	
	_export_master_popup.clear()
	return _export_master_popup


# Creation.

func initialize_song() -> void:
	if not _try_load_song_from_args():
		create_new_song(true)


func _try_load_song_from_args() -> bool:
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.ends_with(".ceol"):
			return _load_ceol_song_confirmed(arg)
	
	return false


func create_new_song(silent: bool = false) -> void:
	Controller.music_player.stop_playback()
	
	var new_song := Song.create_default_song()
	Controller.set_current_song(new_song)
	
	if not silent:
		Controller.update_status("NEW SONG CREATED", Controller.StatusLevel.SUCCESS)


func create_new_song_safe() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		if not unsaved_warning:
			return # Popup is busy.
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to create a new one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			unsaved_warning.close_popup()
			create_new_song()
		)
		
		Controller.show_window_popup(unsaved_warning, Vector2(600, 190))
		return
	
	create_new_song()


# Ceol loading and saving.

func load_ceol_song() -> void:
	if OS.has_feature("web"):
		var load_dialog_web := Controller.get_file_dialog_web()
		load_dialog_web.add_filter(".ceol")
		load_dialog_web.file_selected.connect(_load_ceol_song_confirmed, CONNECT_ONE_SHOT)
		
		load_dialog_web.popup()
		return
	
	var load_dialog := Controller.get_file_dialog()
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.title = "Load .ceol Song"
	load_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	load_dialog.current_file = ""
	load_dialog.file_selected.connect(_load_ceol_song_confirmed, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(load_dialog)


func load_ceol_song_safe() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		if not unsaved_warning:
			return # Popup is busy.
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to load a different one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			unsaved_warning.close_popup()
			load_ceol_song()
		)
		
		Controller.show_window_popup(unsaved_warning, Vector2(640, 190))
		return
	
	load_ceol_song()


func _load_ceol_song_confirmed(path: String) -> bool:
	var loaded_song: Song = SongLoader.load(path)
	if not loaded_song:
		Controller.update_status("FAILED TO LOAD SONG", Controller.StatusLevel.ERROR)
		return false
	
	Controller.music_player.stop_playback()
	
	Controller.set_current_song(loaded_song)
	Controller.update_status("SONG LOADED", Controller.StatusLevel.SUCCESS)
	print("Successfully loaded song from %s:\n  %s" % [ path, loaded_song ])
	return true


func save_ceol_song(save_as: bool = false) -> void:
	if not Controller.current_song:
		return
	
	var file_name := Controller.current_song.get_safe_filename()
	
	# On web we don't show a file dialog, since it can only access a virtual
	# file system.
	if OS.has_feature("web"):
		_save_ceol_song_confirmed("/tmp/" + file_name)
		return
	
	var save_dialog := Controller.get_file_dialog()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.title = "Save .ceol Song As" if save_as else "Save .ceol Song"
	save_dialog.add_filter("*.ceol", "Bosca Ceoil Song")
	save_dialog.current_file = file_name
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


func check_song_on_exit(always_confirm: bool = false) -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		if not unsaved_warning:
			return # Popup is busy.
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to quit?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			Controller.get_tree().quit()
		)
		
		Controller.show_window_popup(unsaved_warning, Vector2(560, 190))
		return
	
	if always_confirm:
		var final_warning := Controller.get_info_popup()
		if not final_warning:
			return # Popup is busy.
		
		final_warning.title = "Quitting Bosca Ceoil"
		final_warning.content = "Are you sure you want to quit?"
		final_warning.add_button("Cancel", final_warning.close_popup)
		final_warning.add_button("I'm sure!", func() -> void:
			Controller.get_tree().quit()
		)
		
		Controller.show_window_popup(final_warning, Vector2(420, 160))
		return
	
	Controller.get_tree().quit()


func _connect_to_browser_close() -> void:
	if not OS.has_feature("web"):
		return
	
	_check_song_on_browser_close_ref = JavaScriptBridge.create_callback(func(args: Array) -> void:
		_check_song_on_browser_close.call(args[0]) # The event object.
	)
	
	var window := JavaScriptBridge.get_interface("window")
	window.addEventListener("beforeunload", _check_song_on_browser_close_ref)


func _check_song_on_browser_close(event: JavaScriptObject) -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		# This may not work in every browser.
		event.returnValue = "Current song has UNSAVED CHANGES.\n\nAre you sure you want to quit?"
		# But this will always work, just with the standard message.
		event.preventDefault()


# External format import.


func import_song() -> void:
	var import_dialog := get_import_master_popup()
	import_dialog.title = "Import from external format"
	import_dialog.add_button("Cancel", import_dialog.close_popup)
	import_dialog.add_button("Import", func() -> void:
		var import_config: ImportMasterPopup.ImportConfig = import_dialog.get_import_config()
		if import_config.path.is_empty():
			Controller.update_status("PLEASE SELECT A FILE TO IMPORT", Controller.StatusLevel.WARNING)
			return
		
		import_dialog.close_popup()
		_import_song_confirmed(import_config)
	)
	
	Controller.music_player.stop_playback()
	Controller.show_window_popup(import_dialog, Vector2(680, 400))


func import_song_safe() -> void:
	if Controller.current_song && Controller.current_song.is_dirty():
		var unsaved_warning := Controller.get_info_popup()
		if not unsaved_warning:
			return # Popup is busy.
		
		unsaved_warning.title = "WARNING — Unsaved changes"
		unsaved_warning.content = "Current song has [accent]UNSAVED CHANGES[/accent].\n\nAre you sure you want to import a different one?"
		unsaved_warning.add_button("Cancel", unsaved_warning.close_popup)
		unsaved_warning.add_button("I'm sure!", func() -> void:
			unsaved_warning.close_popup()
			import_song()
		)
		
		Controller.show_window_popup(unsaved_warning, Vector2(640, 190))
		return
	
	import_song()


func _import_song_confirmed(import_config: ImportMasterPopup.ImportConfig) -> void:
	match import_config.type:
		ImportMasterPopup.ImportType.IMPORT_MIDI:
			_import_mid_song(import_config)
		
		_:
			Controller.update_status("FORMAT NOT SUPPORTED (YET)", Controller.StatusLevel.WARNING)


func _import_mid_song(import_config: ImportMasterPopup.ImportConfig) -> void:
	var imported_song := MidiImporter.import(import_config)
	if not imported_song:
		Controller.update_status("FAILED TO IMPORT SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.set_current_song(imported_song)
	Controller.update_status("SONG IMPORTED FROM MIDI", Controller.StatusLevel.SUCCESS)
	print("Successfully imported song from %s:\n  %s" % [ import_config.path, imported_song ])


# External format export.

func export_song() -> void:
	if not Controller.current_song:
		return
	
	var export_dialog := get_export_master_popup()
	export_dialog.title = "Export to external format"
	export_dialog.add_button("Cancel", export_dialog.close_popup)
	export_dialog.add_button("Export", func() -> void:
		var export_config: ExportMasterPopup.ExportConfig = export_dialog.get_export_config()
		
		export_dialog.close_popup()
		_export_song_confirmed(export_config)
	)
	
	export_dialog.set_song(Controller.current_song)
	
	Controller.music_player.stop_playback()
	Controller.show_window_popup(export_dialog, Vector2(680, 450))


func _export_song_confirmed(export_config: ExportMasterPopup.ExportConfig) -> void:
	match export_config.type:
		ExportMasterPopup.ExportType.EXPORT_WAV:
			_export_wav_song(export_config)
		ExportMasterPopup.ExportType.EXPORT_MIDI:
			_export_mid_song(export_config)
		ExportMasterPopup.ExportType.EXPORT_MML:
			_export_mml_song(export_config)
		ExportMasterPopup.ExportType.EXPORT_XM:
			_export_xm_song(export_config)
		
		_:
			Controller.update_status("FORMAT NOT SUPPORTED (YET)", Controller.StatusLevel.WARNING)


func _export_wav_song(export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var file_name := Controller.current_song.get_safe_filename("wav")
	
	# On web we don't show a file dialog, since it can only access a virtual
	# file system.
	if OS.has_feature("web"):
		_export_wav_song_confirmed("/tmp/" + file_name, export_config)
		return
	
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export .wav File"
	export_dialog.add_filter("*.wav", "Waveform Audio File")
	export_dialog.current_file = file_name
	export_dialog.file_selected.connect(_export_wav_song_confirmed.bind(export_config), CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_wav_song_confirmed(path: String, export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var exporter := WavExporter.new()
	var path_valid := exporter.set_export_path(path)
	if not path_valid:
		Controller.update_status("FAILED TO EXPORT SONG: INVALID FILENAME", Controller.StatusLevel.ERROR)
		return
	
	Controller.lock_song_editing("NOW EXPORTING AS WAV, PLEASE WAIT")
	
	Controller.current_song.arrangement.set_loop(export_config.loop_start, export_config.loop_end)
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


func _export_mid_song(export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var file_name := Controller.current_song.get_safe_filename("mid")
	
	# On web we don't show a file dialog, since it can only access a virtual
	# file system.
	if OS.has_feature("web"):
		_export_mid_song_confirmed("/tmp/" + file_name, export_config)
		return
	
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export .mid File"
	export_dialog.add_filter("*.mid", "MIDI File")
	export_dialog.current_file = file_name
	export_dialog.file_selected.connect(_export_mid_song_confirmed.bind(export_config), CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_mid_song_confirmed(path: String, export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var success := MidiExporter.save(Controller.current_song, path, export_config)
	if not success:
		Controller.update_status("FAILED TO EXPORT SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.update_status("SONG EXPORTED AS MIDI", Controller.StatusLevel.SUCCESS)
	print("Successfully exported song to %s." % [ path ])


func _export_mml_song(export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var file_name := Controller.current_song.get_safe_filename("mml")
	
	# On web we don't show a file dialog, since it can only access a virtual
	# file system.
	if OS.has_feature("web"):
		_export_mml_song_confirmed("/tmp/" + file_name, export_config)
		return
	
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export SiON .mml File"
	export_dialog.add_filter("*.mml", "MML File")
	export_dialog.current_file = file_name
	export_dialog.file_selected.connect(_export_mml_song_confirmed.bind(export_config), CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_mml_song_confirmed(path: String, export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var success := MMLExporter.save(Controller.current_song, path, export_config)
	if not success:
		Controller.update_status("FAILED TO EXPORT SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.update_status("SONG EXPORTED AS MML", Controller.StatusLevel.SUCCESS)
	print("Successfully exported song to %s." % [ path ])


func _export_xm_song(export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var file_name := Controller.current_song.get_safe_filename("xm")
	
	# On web we don't show a file dialog, since it can only access a virtual
	# file system.
	if OS.has_feature("web"):
		_export_xm_song_confirmed("/tmp/" + file_name, export_config)
		return
	
	var export_dialog := Controller.get_file_dialog()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.title = "Export .xm File"
	export_dialog.add_filter("*.xm", "XM Tracker File")
	export_dialog.current_file = file_name
	export_dialog.file_selected.connect(_export_xm_song_confirmed.bind(export_config), CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(export_dialog)


func _export_xm_song_confirmed(path: String, export_config: ExportMasterPopup.ExportConfig) -> void:
	if not Controller.current_song:
		return
	
	var success := XMExporter.save(Controller.current_song, path, export_config)
	if not success:
		Controller.update_status("FAILED TO EXPORT SONG", Controller.StatusLevel.ERROR)
		return
	
	Controller.update_status("SONG EXPORTED AS XM", Controller.StatusLevel.SUCCESS)
	print("Successfully exported song to %s." % [ path ])
