###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

var _default_window_title: String = ""

@onready var _filler: Control = %Filler
@onready var _menu_bar: Control = %Menu


func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	get_window().wrap_controls = true
	
	_default_window_title = get_window().title


func _ready() -> void:
	# A little trick to make sure the menu is on top of the pattern editor. We use a filler control
	# and make it fit the same area in the box container.
	_filler.custom_minimum_size = _menu_bar.get_combined_minimum_size()
	
	_edit_current_song()
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_edit_current_song)
		Controller.song_saved.connect(_update_window_title)


func _edit_current_song() -> void:
	if Engine.is_editor_hint():
		return
	
	_update_window_title()
	if Controller.current_song:
		Controller.current_song.song_changed.connect(_update_window_title)


func _update_window_title() -> void:
	if Engine.is_editor_hint():
		return
	
	if not Controller.current_song:
		get_window().title = _default_window_title
		return
	
	var song_name := "<New Song>" if Controller.current_song.filename.is_empty() else Controller.current_song.filename.get_file()
	var song_dirty := "* " if Controller.current_song.is_dirty() else ""
	
	get_window().title = "%s%s - %s" % [ song_dirty, song_name, _default_window_title ]
