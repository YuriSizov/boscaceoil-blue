###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PadSlider extends Control

signal changed()

enum AxisMode {
	AXIS_BOTH,
	AXIS_HORIZONTAL,
	AXIS_VERTICAL,
}

@export var default_value: Vector2i = Vector2i.ZERO:
	set(value):
		default_value = value
		_update_cursors()
@export var axis_mode: AxisMode = AxisMode.AXIS_BOTH:
	set(value):
		axis_mode = value
		_update_cursors()
@export var horizontal_range: Vector2i = Vector2i(0, 1):
	set(value):
		horizontal_range = value
		_update_cursors()
@export var vertical_range: Vector2i = Vector2i(0, 1):
	set(value):
		vertical_range = value
		_update_cursors()

var recording: bool = false:
	set = set_recording
var _recorded_values: Array[Vector2i] = []
var _recorded_positions: Array[Vector2] = []

var _position_area: Rect2 = Rect2()
var _default_position: Vector2 = Vector2.ZERO
var _cursor_position: Vector2 = Vector2.ZERO

var _last_value: Vector2i = Vector2i.ZERO
var _hovering: bool = false
var _dragging: bool = false


func _ready() -> void:
	set_physics_process(false)
	
	_update_cursors()
	resized.connect(_update_cursors)

	mouse_entered.connect(_start_hovering)
	mouse_exited.connect(_stop_hovering)


func _notification(what: int) -> void:
	if _dragging && what == NOTIFICATION_DRAG_END:
		_dragging = false
		set_physics_process(_hovering || _dragging)
		changed.emit()


func _physics_process(_delta: float) -> void:
	_process_dragging()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if _hovering && mb.button_index == MOUSE_BUTTON_LEFT && mb.pressed:
			_dragging = true
			_last_value = get_current_value()
		if mb.button_index == MOUSE_BUTTON_LEFT && not mb.pressed:
			_dragging = false
			set_physics_process(_hovering || _dragging)
			changed.emit()


func _draw() -> void:
	# Draw the background.
	var background_pattern := get_theme_stylebox("background_pattern", "PadSlider")
	draw_style_box(background_pattern, Rect2(Vector2.ZERO, size))
	
	# Draw the default value, recorded values, and the current value indicators.
	
	var cursor_width := get_theme_constant("cursor_size", "PadSlider")
	var cursor_outline_width := get_theme_constant("cursor_outline_width", "PadSlider")

	var default_color := get_theme_color("default_value_color", "PadSlider")
	var default_outline_color := get_theme_color("default_value_outline_color", "PadSlider")
	_draw_cursor(_default_position, cursor_width, cursor_outline_width, default_color, default_outline_color)
	
	if recording:
		var recorded_color := get_theme_color("recorded_value_color", "PadSlider")
		var recorded_outline_color := get_theme_color("recorded_value_outline_color", "PadSlider")
		var recorded_color_end := get_theme_color("recorded_value_color_end", "PadSlider")
		var recorded_outline_color_end := get_theme_color("recorded_value_outline_color_end", "PadSlider")
		
		for i in _recorded_positions.size():
			var recorded_position := _recorded_positions[i]
			var recorder_width := cursor_width / 2.0
			
			var final_position := recorded_position + Vector2(recorder_width, recorder_width) / 2.0
			var color_coefficient := float(i) / (_recorded_positions.size() - 1)
			var final_color := recorded_color.lerp(recorded_color_end, color_coefficient)
			var final_outline_color := recorded_outline_color.lerp(recorded_outline_color_end, color_coefficient)
			
			_draw_cursor(final_position, recorder_width, cursor_outline_width, final_color, final_outline_color)
	
	var cursor_color := get_theme_color("cursor_color", "PadSlider")
	var cursor_outline_color := get_theme_color("cursor_outline_color", "PadSlider")
	_draw_cursor(_cursor_position, cursor_width, cursor_outline_width, cursor_color, cursor_outline_color)
	
	# Draw recording overlay.
	if recording:
		var recording_overlay := get_theme_stylebox("recording_overlay", "PadSlider")
		draw_style_box(recording_overlay, Rect2(Vector2.ZERO, size))


func _draw_cursor(at_position: Vector2, width: float, outline_width: int, fill_color: Color, outline_color: Color) -> void:
	var inner_position := at_position + Vector2(outline_width, outline_width)
	var cursor_size := Vector2(width, width)
	var cursor_inner_size := cursor_size - 2 * Vector2(outline_width, outline_width)
	
	draw_rect(Rect2(at_position, cursor_size), outline_color)
	draw_rect(Rect2(inner_position, cursor_inner_size), fill_color)


func _get_minimum_size() -> Vector2:
	var cursor_width := get_theme_constant("cursor_size", "PadSlider")
	return Vector2(cursor_width, cursor_width)


# Dragging.

func _start_hovering() -> void:
	_hovering = true
	set_physics_process(true)


func _stop_hovering() -> void:
	_hovering = false
	set_physics_process(_hovering || _dragging)


func _process_dragging() -> void:
	if not _dragging:
		return
	
	# Double conversion allows to normalize the value and snap it to the step.
	var current_value := _convert_position_to_value(get_local_mouse_position() - _position_area.position)
	if current_value.x == _last_value.x && current_value.y == _last_value.y && not recording:
		return # No change (unless we're in recording mode).
	
	_last_value = current_value
	_cursor_position = _convert_value_to_position(current_value)
	queue_redraw()
	changed.emit()


# Value and cursor management.

func _normalize_range(value_range: Vector2i) -> Vector2i:
	if value_range.x <= value_range.y:
		return value_range
	
	return Vector2(value_range.y, value_range.x)


func _normalize_value(value: int, value_range: Vector2i) -> int:
	if value_range.x <= value_range.y:
		return value
	
	# Leftmost value is bigger than rightmost, invert it for correct visuals.
	return value_range.x - value


func _convert_value_to_position(value: Vector2i) -> Vector2:
	var value_position := Vector2.ZERO
	
	var hor_range := _normalize_range(horizontal_range)
	var hor_span := maxi(1, hor_range.y - hor_range.x)
	var hor_size_unit := _position_area.size.x / float(hor_span)

	var hor_value := _normalize_value(clampi(value.x, hor_range.x, hor_range.y), horizontal_range)
	value_position.x = hor_value * hor_size_unit
	
	var ver_range := _normalize_range(vertical_range)
	var ver_span := maxi(1, ver_range.y - ver_range.x)
	var ver_size_unit := _position_area.size.y / float(ver_span)

	var ver_value := _normalize_value(clampi(value.y, ver_range.x, ver_range.y), vertical_range)
	value_position.y = ver_value * ver_size_unit
	
	return value_position


func _convert_position_to_value(value_position: Vector2) -> Vector2i:
	var value := Vector2i.ZERO
	
	var hor_range := _normalize_range(horizontal_range)
	var hor_span := maxi(1, hor_range.y - hor_range.x)
	var hor_size_unit := _position_area.size.x / float(hor_span)
	
	var hor_value := _normalize_value(roundi(value_position.x / hor_size_unit), horizontal_range)
	value.x = clampi(hor_value, hor_range.x, hor_range.y)
	
	var ver_range := _normalize_range(vertical_range)
	var ver_span := maxi(1, ver_range.y - ver_range.x)
	var ver_size_unit := _position_area.size.y / float(ver_span)
	
	var ver_value := _normalize_value(roundi(value_position.y / ver_size_unit), vertical_range)
	value.y = clampi(ver_value, ver_range.x, ver_range.y)
	
	return value


func _update_cursors() -> void:
	var cursor_width := get_theme_constant("cursor_size", "PadSlider")
	var position_offset := Vector2(cursor_width, cursor_width) / 2.0

	# Preserve the cursor value in case of a resize.
	var cursor_value := _convert_position_to_value(_cursor_position)

	_position_area = Rect2()
	_position_area.position = position_offset
	_position_area.size = size - position_offset * 2
	
	_default_position = _convert_value_to_position(default_value)
	_cursor_position = _convert_value_to_position(cursor_value)
	
	queue_redraw()


func get_current_value() -> Vector2i:
	return _convert_position_to_value(_cursor_position)


func set_current_value(value: Vector2i) -> void:
	_cursor_position = _convert_value_to_position(value)
	
	if not _dragging:
		queue_redraw()


func set_recorded_values(values: Array[Vector2i]) -> void:
	_recorded_values = values
	_recorded_positions.clear()
	
	for record in _recorded_values:
		_recorded_positions.push_back(_convert_value_to_position(record))
	
	if not _dragging:
		queue_redraw()


# Recording mode.

func set_recording(value: bool) -> void:
	recording = value
	queue_redraw()
