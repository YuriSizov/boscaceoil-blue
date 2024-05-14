###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

var _default_window_title: String = ""
var _last_window_scale_factor: float = 1.0

@onready var _filler: Control = %Filler
@onready var _menu_bar: Control = %Menu

@onready var _pattern_editor: Control = %PatternEditor
@onready var _locked_indicator: Control = %LockedIndicator


func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	get_window().wrap_controls = true
	
	_default_window_title = get_window().title


func _ready() -> void:
	_update_window_size()
	
	Controller.settings_manager.gui_scale_changed.connect(_update_window_size)
	
	# A little trick to make sure the menu is on top of the pattern editor. We use a filler control
	# and make it fit the same area in the box container.
	_filler.custom_minimum_size = _menu_bar.get_combined_minimum_size()
	
	_pattern_editor.visible = true
	_locked_indicator.visible = false
	_edit_current_song()
	
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_edit_current_song)
		Controller.song_saved.connect(_update_window_title)
		
		Controller.controls_locked.connect(_show_locked_indicator)
		Controller.controls_unlocked.connect(_hide_locked_indicator)


func _edit_current_song() -> void:
	if Engine.is_editor_hint():
		return
	
	_update_window_title()
	if Controller.current_song:
		Controller.current_song.song_changed.connect(_update_window_title)


func _update_window_size() -> void:
	var main_window := get_window()
	var neutral_size := main_window.size / _last_window_scale_factor
	
	# HACK: This is a naive fix to an engine bug. For some reason, window's content scale factor
	# affects controls' combined required minimum size, making it smaller the larger the scale is.
	# This doesn't seem rational or logical, and the difference isn't even proportional to scale.
	#
	# Experimentally, I identified that the global transform matrix of this control (any fullscreen
	# control, really) helps to counter-act the issue. So here we are. 
	var content_minsize := (main_window.get_contents_minimum_size() * get_global_transform()).floor()
	main_window.min_size = content_minsize * main_window.content_scale_factor
	
	main_window.size = neutral_size * main_window.content_scale_factor
	_last_window_scale_factor = main_window.content_scale_factor


func _update_window_title() -> void:
	if Engine.is_editor_hint():
		return
	
	if not Controller.current_song:
		get_window().title = _default_window_title
		return
	
	var song_name := "<New Song>" if Controller.current_song.filename.is_empty() else Controller.current_song.filename.get_file()
	var song_dirty := "* " if Controller.current_song.is_dirty() else ""
	
	get_window().title = "%s%s - %s" % [ song_dirty, song_name, _default_window_title ]


func _show_locked_indicator(message: String) -> void:
	_pattern_editor.visible = false
	_locked_indicator.message = message
	_locked_indicator.visible = true


func _hide_locked_indicator() -> void:
	_pattern_editor.visible = true
	_locked_indicator.visible = false
