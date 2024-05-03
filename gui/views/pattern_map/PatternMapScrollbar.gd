###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends Control

signal shifted_right()
signal shifted_left()

const FADE_DURATION := 0.06

var _button_holder: ButtonHolder = null
var _tween: Tween = null
var _left_visible: bool = false
var _right_visible: bool = false

var _left_default_size: float = 0.0
var _right_default_size: float = 0.0

@onready var _right_button: Button = %RightButton
@onready var _left_button: Button = %LeftButton


func _ready() -> void:
	_button_holder = ButtonHolder.new(self, _right_button, _left_button)
	_button_holder.set_press_callback(_emit_hold_signal)
	
	_left_default_size = _left_button.size.x
	_right_default_size = _right_button.size.x
	
	_left_button.offset_left = -_left_default_size
	_left_button.offset_right = 0
	_right_button.offset_left = 0
	_right_button.offset_right = _right_default_size
	
	_left_button.mouse_exited.connect(test_mouse_position)
	_right_button.mouse_exited.connect(test_mouse_position)


func _process(delta: float) -> void:
	_button_holder.process(delta)


# Buttons.

func set_button_offset(top_offset: float, bottom_offset: float) -> void:
	_left_button.offset_top = top_offset
	_left_button.offset_bottom = bottom_offset
	_right_button.offset_top = top_offset
	_right_button.offset_bottom = bottom_offset


func test_mouse_position() -> void:
	var mouse_position := get_local_mouse_position()
	var left_area := Rect2(Vector2(0, _left_button.position.y), Vector2(_left_default_size, _left_button.size.y))
	var right_area := Rect2(Vector2(size.x - _right_default_size, _right_button.position.y), Vector2(_right_default_size, _right_button.size.y))

	if not _left_visible && left_area.has_point(mouse_position):
		_left_visible = true
		_right_visible = false
	elif not _right_visible && right_area.has_point(mouse_position):
		_left_visible = false
		_right_visible = true
	elif (_left_visible || _right_visible) && (not left_area.has_point(mouse_position) && not right_area.has_point(mouse_position)):
		_left_visible = false
		_right_visible = false
	else:
		return # Nothing to do.
	
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	
	if _left_visible:
		_tween.tween_property(_left_button, "offset_left", 0, FADE_DURATION)
	else:
		_tween.tween_property(_left_button, "offset_left", -_left_default_size, FADE_DURATION)
	
	if _right_visible:
		_tween.tween_property(_right_button, "offset_right", 0, FADE_DURATION)
	else:
		_tween.tween_property(_right_button, "offset_right", _right_default_size, FADE_DURATION)


func _emit_hold_signal(hold_button: Button) -> void:
	if not hold_button:
		return
	
	if hold_button == _right_button:
		shifted_right.emit()
	elif hold_button == _left_button:
		shifted_left.emit()
