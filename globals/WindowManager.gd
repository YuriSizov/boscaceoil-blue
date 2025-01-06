###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name WindowManager extends RefCounted

const SIZE_CHANGES_SAVE_DELAY := 0.3

const MAIN_WINDOW_SCRIPT := preload("res://gui/MainWindow.gd")
const THEME_FONT_NORMAL := preload("res://assets/fonts/fff-aquarius-bold-condensed.normal.ttf")
const THEME_FONT_MSDF := preload("res://assets/fonts/fff-aquarius-bold-condensed.msdf.ttf")

var _project_theme: Theme = null
var _main_window: Window = null
var _save_timer: Timer = null


func _init() -> void:
	_project_theme = load("res://gui/theme/project_theme.tres") # By magic of Godot, this is a shared reference.


# Public methods.

func register_window() -> void:
	_main_window = Controller.get_window()
	_main_window.set_script(MAIN_WINDOW_SCRIPT)

	_save_timer = Timer.new()
	_save_timer.name = "WindowManagerSaveTimer"
	_save_timer.wait_time = SIZE_CHANGES_SAVE_DELAY
	_save_timer.autostart = false
	_save_timer.one_shot = true
	Controller.add_child(_save_timer)

	_save_timer.timeout.connect(_save_window_size_debounced)
	_main_window.size_changed.connect(_save_window_size)

	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	_main_window.wrap_controls = true

	if not Engine.is_editor_hint():
		Controller.settings_manager.gui_scale_changed.connect(_update_window_size)
		Controller.settings_manager.fullscreen_changed.connect(_update_window_size)
		Controller.settings_manager.gui_scale_changed.connect(_update_project_theme)


func restore_window() -> void:
	_restore_window_size()
	_update_window_size()
	_update_project_theme()


# Window state management.

func _restore_window_size() -> void:
	# On web the size is dictated by the browser window, we have no control over it.
	if not OS.has_feature("web"):
		_main_window.size = Controller.settings_manager.get_windowed_size()
	
	_main_window.content_scale_factor = Controller.settings_manager.get_gui_scale_factor()

	if Controller.settings_manager.is_windowed_maximized():
		_main_window.mode = Window.MODE_MAXIMIZED

	if Controller.settings_manager.is_fullscreen():
		_main_window.mode = Window.MODE_FULLSCREEN

	# On web the position is meaningless and should be zero, if it's not then mouse position becomes misaligned.
	if not OS.has_feature("web"):
		_main_window.move_to_center()


func _fit_window_size(window_size: Vector2) -> void:
	var window_mode := _main_window.mode
	if window_mode == Window.MODE_MAXIMIZED || OS.has_feature("web"):
		return

	var screen_index := _main_window.current_screen

	# Under certain conditions just set the window to the full screen size.
	if window_mode == Window.MODE_FULLSCREEN || window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN || OS.has_feature("android"):
		_main_window.size = DisplayServer.screen_get_size(screen_index)
		return

	# Make sure our windowed mode window is displayed fully on screen.
	# First, adjust the window size to fit the screen size (minus system flair).

	var screen_size := DisplayServer.screen_get_usable_rect(screen_index).size
	window_size.x = minf(window_size.x, screen_size.x)
	window_size.y = minf(window_size.y, screen_size.y)

	_main_window.size = window_size
	Controller.settings_manager.set_windowed_size(_main_window.size)

	# Last, adjust the position (accounting for window decorations).

	var window_position := _main_window.get_position_with_decorations()

	if window_position.x < 0:
		_main_window.position.x -= window_position.x
	elif (window_position.x + _main_window.size.x) > screen_size.x:
		_main_window.position.x -= (window_position.x + _main_window.size.x) - screen_size.x

	if window_position.y < 0:
		_main_window.position.y -= window_position.y
	elif (window_position.y + _main_window.size.y) > screen_size.y:
		_main_window.position.y -= (window_position.y + _main_window.size.y) - screen_size.y


func _update_window_size() -> void:
	_update_window_mode()

	var neutral_size := _main_window.size / _main_window.content_scale_factor
	_main_window.content_scale_factor = Controller.settings_manager.get_gui_scale_factor()

	# We want to ensure that the UI always fits the screen, and downscale everything if we're
	# exceeding the bounds.

	var window_minsize := _main_window.get_contents_minimum_size()
	var screen_size := DisplayServer.screen_get_usable_rect(_main_window.current_screen).size

	if window_minsize.x > screen_size.x || window_minsize.y > screen_size.y:
		var scale_factor_adjustment := minf(float(screen_size.x) / window_minsize.x, float(screen_size.y) / window_minsize.y)
		scale_factor_adjustment = floorf(scale_factor_adjustment * 100.0) / 100.0 # Truncate excessive precision.

		_main_window.content_scale_factor = _main_window.content_scale_factor * scale_factor_adjustment

	_main_window.min_size = _main_window.get_contents_minimum_size()
	_fit_window_size(neutral_size * _main_window.content_scale_factor)


func _update_window_mode() -> void:
	var is_actually_fullscreen := _main_window.mode == Window.MODE_FULLSCREEN || _main_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN

	if Controller.settings_manager.is_fullscreen() == is_actually_fullscreen:
		return

	if Controller.settings_manager.is_fullscreen():
		_main_window.mode = Window.MODE_FULLSCREEN
	else:
		_main_window.mode = Window.MODE_WINDOWED
		_main_window.size = Controller.settings_manager.get_windowed_size()
		if Controller.settings_manager.is_windowed_maximized():
			_main_window.mode = Window.MODE_MAXIMIZED


func _save_window_size() -> void:
	_save_timer.start()


func _save_window_size_debounced() -> void:
	if _main_window.mode == Window.MODE_WINDOWED:
		Controller.settings_manager.set_windowed_size(_main_window.size)

	Controller.settings_manager.set_windowed_maximized(_main_window.mode == Window.MODE_MAXIMIZED)
	Controller.settings_manager.set_fullscreen(_main_window.mode == Window.MODE_FULLSCREEN || _main_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN, true)


# Project theme and fonts management.

func _update_project_theme() -> void:
	if not _project_theme:
		return

	var scale_factor := Controller.settings_manager.get_gui_scale_factor()
	if scale_factor < 1.0:
		_project_theme.default_font.base_font = THEME_FONT_NORMAL
	else:
		_project_theme.default_font.base_font = THEME_FONT_MSDF

	for type_name in _project_theme.get_font_type_list():
		for font_key in _project_theme.get_font_list(type_name):
			var font_variation: FontVariation = _project_theme.get_font(font_key, type_name)
			font_variation.base_font = _project_theme.default_font.base_font
