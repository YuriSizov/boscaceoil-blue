###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends MarginContainer

const SIZE_CHANGES_SAVE_DELAY := 0.3

var _default_window_title: String = ""

@onready var _filler: Control = %Filler
@onready var _menu_bar: Control = %Menu

@onready var _pattern_editor: Control = %PatternEditor
@onready var _locked_indicator: Control = %LockedIndicator
@onready var _save_timer: Timer = %SaveTimer
@onready var _highlight_manager: CanvasLayer = %HighlightManager


func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	get_window().wrap_controls = true
	
	_default_window_title = get_window().title


func _ready() -> void:
	_restore_window_size()
	_update_window_size()
	
	_save_timer.wait_time = SIZE_CHANGES_SAVE_DELAY
	_save_timer.autostart = false
	_save_timer.one_shot = true
	_save_timer.timeout.connect(_save_window_size_debounced)
	get_window().size_changed.connect(_save_window_size)
	
	# A little trick to make sure the menu is on top of the pattern editor. We use a filler control
	# and make it fit the same area in the box container.
	_filler.custom_minimum_size = _menu_bar.get_combined_minimum_size()
	
	_pattern_editor.visible = true
	_locked_indicator.visible = false
	Controller.io_manager.initialize_song()
	_edit_current_song()
	
	if not Engine.is_editor_hint():
		if Controller.settings_manager.is_first_time():
			Controller.show_welcome_message()
		
		Controller.settings_manager.gui_scale_changed.connect(_update_window_size)
		Controller.settings_manager.fullscreen_changed.connect(_update_window_size)
		
		Controller.song_loaded.connect(_edit_current_song)
		Controller.song_saved.connect(_update_window_title)
		
		Controller.controls_locked.connect(_show_locked_indicator)
		Controller.controls_unlocked.connect(_hide_locked_indicator)
		
		Controller.help_manager.highlight_requested.connect(_set_highlighted_node)
		Controller.help_manager.highlight_cleared.connect(_clear_highlighted_node)


# Window decorations.

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


# Sizing and window modes.

func _update_window_size() -> void:
	_update_window_mode()
	
	#From RikK:
	#Looks like I bypass/used properly window.content_scale_factor bag
	#It's also properly sets max/min window sizes
	#Maybe you'll need to merge this func and "_fit_window_size" func...
	#Saved becouse I don't know it's needs to be separated or not.
	
	var main_window := get_window()
	var screen_index := main_window.current_screen
	var scale_factor := Controller.settings_manager.get_gui_scale_factor()
	var min_size := get_combined_minimum_size() * scale_factor
	var max_size := DisplayServer.screen_get_size(screen_index)
	
	min_size.x = min(min_size.x, max_size.x)
	min_size.y = min(min_size.y, max_size.y - 80) #80 - represents OS toolbar height
	
	main_window.content_scale_factor = scale_factor
	main_window.min_size = min_size
	main_window.max_size = max_size
	
	_fit_window_size(main_window.size)


func _fit_window_size(window_size: Vector2) -> void:
	var main_window := get_window()
	var window_mode := main_window.mode
	var screen_index := main_window.current_screen
	
	if OS.has_feature("web"): return
	
	if OS.has_feature("android"):
		main_window.size = DisplayServer.screen_get_size(screen_index)
		return
	
	#From RikK:
	#Code below get rid unwanted mouse position offset after UI scale change.
	if window_mode == Window.MODE_MAXIMIZED || window_mode == Window.MODE_FULLSCREEN || window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		main_window.mode = Window.MODE_WINDOWED
		await get_tree().create_timer(0.2).timeout
		main_window.mode = window_mode
		return
	
	Controller.settings_manager.set_windowed_size(main_window.size)


func _update_window_mode() -> void:
	var main_window := get_window()
	var is_actually_fullscreen := main_window.mode == Window.MODE_FULLSCREEN || main_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	
	if Controller.settings_manager.is_fullscreen() == is_actually_fullscreen:
		return
	
	if Controller.settings_manager.is_fullscreen():
		main_window.mode = Window.MODE_FULLSCREEN
	else:
		main_window.mode = Window.MODE_WINDOWED
		main_window.size = Controller.settings_manager.get_windowed_size()
		if Controller.settings_manager.is_windowed_maximized():
			main_window.mode = Window.MODE_MAXIMIZED


func _restore_window_size() -> void:
	var main_window := get_window()
	main_window.content_scale_factor = Controller.settings_manager.get_gui_scale_factor()
	main_window.size = Controller.settings_manager.get_windowed_size()
	
	if Controller.settings_manager.is_windowed_maximized():
		main_window.mode = Window.MODE_MAXIMIZED
	
	if Controller.settings_manager.is_fullscreen():
		main_window.mode = Window.MODE_FULLSCREEN


func _save_window_size() -> void:
	_save_timer.start()


func _save_window_size_debounced() -> void:
	var main_window := get_window()
	
	if main_window.mode == Window.MODE_WINDOWED:
		Controller.settings_manager.set_windowed_size(main_window.size)
	
	Controller.settings_manager.set_windowed_maximized(main_window.mode == Window.MODE_MAXIMIZED)
	Controller.settings_manager.set_fullscreen(main_window.mode == Window.MODE_FULLSCREEN || main_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, true)


# Editor locking.

func _show_locked_indicator(message: String) -> void:
	_pattern_editor.visible = false
	_locked_indicator.message = message
	_locked_indicator.visible = true


func _hide_locked_indicator() -> void:
	_pattern_editor.visible = true
	_locked_indicator.visible = false


# Node highlighting.

func _set_highlighted_node(rect_getter: Callable) -> void:
	if rect_getter.is_valid():
		_highlight_manager.highlight_rect_getter = rect_getter
	else:
		_highlight_manager.highlight_rect_getter = Callable()
	
	_highlight_manager.update_highlight()


func _clear_highlighted_node() -> void:
	_highlight_manager.highlight_rect_getter = Callable()
	
	_highlight_manager.update_highlight()
