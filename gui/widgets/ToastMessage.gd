###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const LABEL_EXTRA_PADDING := 6
const FADE_IN_DURATION := 0.2
const FADE_OUT_DURATION := 0.1

var _tween: Tween = null
var _time_remaining: float = 0.0
var _label_offset: float = 0.0

@onready var _label: Label = $Label


func _ready() -> void:
	_label_offset = _label.get_combined_minimum_size().y
	_label.offset_top = LABEL_EXTRA_PADDING
	_label.offset_bottom = LABEL_EXTRA_PADDING + _label_offset
	
	if not Engine.is_editor_hint():
		Controller.status_updated.connect(show_message)


func _physics_process(delta: float) -> void:
	_time_remaining -= delta
	if _time_remaining <= 0:
		hide_message()
		return


func _get_minimum_size() -> Vector2:
	if not is_node_ready():
		return Vector2.ZERO
	
	return _label.get_combined_minimum_size()


func show_message(severity: Controller.StatusLevel, text: String, duration: float = 3.0) -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.set_parallel(true)
	
	# Hide existing message, if present.
	if _time_remaining > 0:
		_tween.tween_property(_label, "offset_top", LABEL_EXTRA_PADDING, FADE_OUT_DURATION)
		_tween.tween_property(_label, "offset_bottom", LABEL_EXTRA_PADDING + _label_offset, FADE_OUT_DURATION)
		
		_tween.tween_callback(func() -> void: 
			_label.text = text
			_label.theme_type_variation = _get_severity_theme_variation(severity)
		).set_delay(FADE_OUT_DURATION)
		_tween.tween_property(_label, "offset_top", 0, FADE_IN_DURATION).set_delay(FADE_OUT_DURATION)
		_tween.tween_property(_label, "offset_bottom", 0, FADE_IN_DURATION).set_delay(FADE_OUT_DURATION)
	else:
		_label.text = text
		_label.theme_type_variation = _get_severity_theme_variation(severity)
		_tween.tween_property(_label, "offset_top", 0, FADE_IN_DURATION)
		_tween.tween_property(_label, "offset_bottom", 0, FADE_IN_DURATION)
	
	_time_remaining = duration
	set_physics_process(true)


func hide_message() -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.set_parallel(true)
	
	_tween.tween_property(_label, "offset_top", LABEL_EXTRA_PADDING, FADE_OUT_DURATION)
	_tween.tween_property(_label, "offset_bottom", LABEL_EXTRA_PADDING + _label_offset, FADE_OUT_DURATION)
	
	_time_remaining = 0
	set_physics_process(false)


func _get_severity_theme_variation(severity: Controller.StatusLevel) -> String:
	match severity:
		Controller.StatusLevel.SUCCESS:
			return "ToastMessageSuccess"
		Controller.StatusLevel.WARNING:
			return "ToastMessageWarning"
		Controller.StatusLevel.ERROR:
			return "ToastMessageError"
	
	return "ToastMessageDefault"
