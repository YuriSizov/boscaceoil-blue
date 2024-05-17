###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SettingsManager extends RefCounted

signal buffer_size_changed()
signal gui_scale_changed()
signal fullscreen_changed()

enum BufferSize {
	BUFFER_SMALL  = 2048,
	BUFFER_MEDIUM = 4096,
	BUFFER_LARGE  = 8192,
}

const _buffer_size_descriptions := {
	BufferSize.BUFFER_SMALL:  "default, high performance",
	BufferSize.BUFFER_MEDIUM: "try if you get cracking on .wav exports",
	BufferSize.BUFFER_LARGE:  "slow, not recommended",
}

enum GUIScalePreset {
	GUI_SCALE_NORMAL = 1,
	GUI_SCALE_LARGE = 2,
}

const _gui_scale_factors := {
	GUIScalePreset.GUI_SCALE_NORMAL: 1.0,
	GUIScalePreset.GUI_SCALE_LARGE:  1.25,
}

# Stored properties.

var _stored_file: ConfigFile = null
var _buffer_size: int = BufferSize.BUFFER_SMALL
var _gui_scale_preset: int = GUIScalePreset.GUI_SCALE_NORMAL
var _fullscreen: bool = false
var _windowed_size: Vector2 = Vector2.ZERO
var _windowed_maximized: bool = false


# Persistence.

func load_settings() -> void:
	pass


func save_settings() -> void:
	pass


func _save_settings_debounced() -> void:
	pass


# Settings management.

func get_buffer_size() -> int:
	return _buffer_size


func get_buffer_size_text(value: int) -> String:
	if _buffer_size_descriptions.has(value):
		return "%d (%s)" % [ value, _buffer_size_descriptions[value] ]
	return "%d" % [ value ]


func set_buffer_size(value: int) -> void:
	_set_buffer_size_safe(value)
	buffer_size_changed.emit()
	save_settings()


func _set_buffer_size_safe(value: int) -> void:
	for key: String in BufferSize:
		if value == BufferSize[key]:
			_buffer_size = value
			return
	
	_buffer_size = BufferSize.BUFFER_SMALL


func get_gui_scale_factor() -> float:
	return _gui_scale_factors[_gui_scale_preset]


func set_gui_scale(preset: int) -> void:
	_set_gui_scale_safe(preset)
	gui_scale_changed.emit()
	save_settings()


func _set_gui_scale_safe(preset: int) -> void:
	if _gui_scale_factors.has(preset):
		_gui_scale_preset = preset
	else:
		_gui_scale_preset = GUIScalePreset.GUI_SCALE_NORMAL


func is_fullscreen() -> bool:
	return _fullscreen


func set_fullscreen(value: bool, silent: bool = false) -> void:
	_fullscreen = value
	if not silent:
		fullscreen_changed.emit()
	save_settings()


func toggle_fullscreen() -> void:
	set_fullscreen(!_fullscreen)


func get_windowed_size() -> Vector2:
	return _windowed_size


func set_windowed_size(value: Vector2) -> void:
	_set_windowed_size_safe(value)
	save_settings()


func _set_windowed_size_safe(value: Vector2) -> void:
	_windowed_size.x = maxf(0, value.x)
	_windowed_size.y = maxf(0, value.y)


func is_windowed_maximized() -> bool:
	return _windowed_maximized


func set_windowed_maximized(value: bool) -> void:
	_windowed_maximized = value
	save_settings()
