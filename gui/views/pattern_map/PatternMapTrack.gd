###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

signal loop_changed(starts_at: int, ends_at: int)
signal bar_inserted(at_index: int)
signal bar_removed(at_index: int)
signal bars_copied()
signal bars_pasted(at_index: int)

signal shifted_right()
signal shifted_left()

## Stepper is accelerated to make it easier to scroll through the range of values.
## These are arbitrary fine-tuned values, and can differ from ButtonHolder.
const SCROLL_THRESHOLDS := [ 0.3, 0.2, 0.088 ]

var arrangement_bars: Array[PatternMap.ArrangementBar] = []
var pattern_width: float = 0
var loop_start_index: int = -1
var loop_end_index: int = -1

var can_scroll_left: bool = false
var can_scroll_right: bool = false

## Position of the cursor for editing the loop.
var _loop_cursor_position: Vector2 = Vector2(-1, -1)

var _hovering: bool = false
var _dragging: bool = false
var _scrolling: bool = false

## Index of the column under the cursor.
var _hovered_col: int = -1

## Range of the drag span.
var _drag_span_range: Vector2i = Vector2i(-1, -1)
## Position of the drag span.
var _drag_span_position: Vector2 = Vector2(-1, -1)
## Size of the drag span.
var _drag_span_size: Vector2 = Vector2(-1, -1)
## Indices of columns during a drag event.
var _dragged_from_col: int = -1
var _dragged_to_col: int = -1

## Trackers for drag events that result in scrolling.
var _scroll_threshold_idx := 0
var _scroll_interval: float = 0
var _scroll_direction: int = 0


func _ready() -> void:
	set_physics_process(false)
	
	mouse_entered.connect(_show_loop_cursor)
	mouse_exited.connect(_hide_loop_cursor)


func _notification(what: int) -> void:
	if _dragging && what == NOTIFICATION_DRAG_END:
		_dragging = false
		set_physics_process(_hovering || _dragging)
		_stop_dragging()


func _physics_process(delta: float) -> void:
	_process_loop_cursor()
	_process_dragging()
	_process_scrolling(delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_dragging()
			else:
				_stop_dragging()
				set_physics_process(_hovering || _dragging)
		elif mb.button_index == MOUSE_BUTTON_RIGHT && mb.pressed:
			_remove_bar_at_cursor()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE && mb.pressed:
			_insert_bar_at_cursor()


func _shortcut_input(event: InputEvent) -> void:
	if not _hovering:
		return
	
	if event.is_action_pressed("ui_copy"):
		_copy_bars_in_loop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_paste"):
		_paste_bars_at_cursor()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var available_rect: Rect2 = get_available_rect()
	
	var background_color := get_theme_color("track_color", "PatternMap")
	var border_color := get_theme_color("track_border_color", "PatternMap")
	var border_width := get_theme_constant("border_width", "PatternMap")
	var half_border_width := float(border_width) / 2.0
	
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var font_color := get_theme_color("font_color", "Label")
	var shadow_color := get_theme_color("shadow_color", "Label")
	var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))

	var label_font_size := get_theme_font_size("track_font_size", "PatternMap")
	var label_font_color := get_theme_color("track_font_color", "PatternMap")
	var label_shadow_color := get_theme_color("track_shadow_color", "PatternMap")
	
	draw_rect(Rect2(Vector2.ZERO, available_rect.size), background_color)
	
	# Draw bar lines and labels.
	
	for bar in arrangement_bars:
		var col_position := bar.position
		var border_size := Vector2(border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), border_color)
		
		var label_position := col_position + Vector2(12, available_rect.size.y - 4)
		var shadow_position := label_position + shadow_size
		var label_text := "%d" % [ bar.bar_index + 1 ]
		
		draw_string(font, shadow_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_shadow_color)
		draw_string(font, label_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_font_color)
	
	# Draw loop cursors, either drag or hover.
	if pattern_width > 0 && (_hovering || _dragging):
		var cursor_color := get_theme_color("note_cursor_color", "NoteMap")
		var cursor_width := get_theme_constant("note_cursor_width", "NoteMap")
		var cursor_label_text := ""
	
		# Draw drag cursor.
		if _drag_span_position.x >= 0 && _drag_span_position.y >= 0:
			cursor_label_text = "%d:%d" % [ _drag_span_range.x + 1, _drag_span_range.y + 1 ]
			
			draw_rect(Rect2(_drag_span_position, _drag_span_size), cursor_color)
		
		# Draw hover cursor.
		elif _loop_cursor_position.x >= 0 && _loop_cursor_position.y >= 0:
			var cursor_position := _loop_cursor_position + Vector2(half_border_width, half_border_width)
			var cursor_size := Vector2(pattern_width, available_rect.size.y) - Vector2(border_width, border_width)
			cursor_label_text = "%d" % [ arrangement_bars[_hovered_col].bar_index + 1 ]
			
			draw_rect(Rect2(cursor_position, cursor_size), cursor_color, false, cursor_width)
		
		# Draw cursor label.
		if not cursor_label_text.is_empty() && _loop_cursor_position.x >= 0 && _loop_cursor_position.y >= 0:
			var label_position := _loop_cursor_position + Vector2(8, -6)
			var label_size := font.get_string_size(cursor_label_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
			if (label_position.x + label_size.x + 4) > available_rect.size.x:
				label_position.x = available_rect.size.x - label_size.x - 4
			
			var shadow_position := label_position + shadow_size
			
			draw_string(font, shadow_position, cursor_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
			draw_string(font, label_position, cursor_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)
	
	# Draw active loop.
	
	if loop_start_index >= 0 && loop_end_index > loop_start_index:
		var loop_end_normalized := loop_end_index - 1
		var first_visible_col := arrangement_bars[0].bar_index
		var last_visible_col := arrangement_bars[arrangement_bars.size() - 1].bar_index
		
		# Skip if loop is outside of the visible range.
		if loop_start_index <= last_visible_col && loop_end_normalized >= first_visible_col:
			var loop_color := get_theme_color("track_loop_color", "PatternMap")
			var loop_width := get_theme_constant("track_loop_width", "PatternMap")
			var loop_y := (available_rect.size.y - loop_width) / 2.0
			
			var loop_start_position := Vector2(-loop_width, loop_y)
			var loop_end_position := Vector2(available_rect.size.x + loop_width, loop_y)
		
			if loop_start_index >= first_visible_col:
				var loop_start_col := arrangement_bars[loop_start_index - first_visible_col]
				loop_start_position.x = loop_start_col.grid_position.x
			
			if loop_end_normalized <= last_visible_col:
				var loop_end_col := arrangement_bars[loop_end_normalized - first_visible_col]
				loop_end_position.x = loop_end_col.grid_position.x + pattern_width
			
			var loop_size := Vector2(loop_end_position.x - loop_start_position.x, loop_width)
			draw_rect(Rect2(loop_start_position, loop_size), loop_color)
			
			# Draw bookend ticks.
			
			var tick_height := available_rect.size.y - 2 * loop_width
			var tick_y := (available_rect.size.y - tick_height) / 2.0
			
			var left_tick_position := Vector2(loop_start_position.x, tick_y)
			var left_tick_size := Vector2(loop_width, tick_height)
			draw_rect(Rect2(left_tick_position, left_tick_size), loop_color)
			
			var right_tick_position := Vector2(loop_end_position.x - loop_width, tick_y)
			var right_tick_size := Vector2(loop_width, tick_height)
			draw_rect(Rect2(right_tick_position, right_tick_size), loop_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect
	
	return available_rect


# Loop cursor and editing.

func _get_cell_at_position(at_position: Vector2) -> Vector2i:
	var available_rect: Rect2 = get_available_rect()
	
	if not available_rect.has_point(at_position):
		return Vector2i(-1, -1)
	
	var position_normalized := at_position - available_rect.position
	var cell_indexed := Vector2i(0, 0)
	cell_indexed.x = clampi(floori(position_normalized.x / pattern_width), 0, Arrangement.BAR_NUMBER)
	return cell_indexed


func _get_cell_at_cursor() -> Vector2i:
	return _get_cell_at_position(get_local_mouse_position())


func _get_cell_position(cell_indexed: Vector2i) -> Vector2:
	var available_rect := get_available_rect()
	
	return Vector2(
		available_rect.position.x + cell_indexed.x * pattern_width,
		available_rect.position.y + cell_indexed.y * available_rect.size.y
	)


func _show_loop_cursor() -> void:
	_hovering = true
	_process_loop_cursor()
	set_physics_process(true)


func _hide_loop_cursor() -> void:
	_hovering = false
	set_physics_process(_hovering || _dragging)
	_process_loop_cursor()


func _process_loop_cursor() -> void:
	if not _hovering && not _dragging:
		_loop_cursor_position = Vector2(-1, -1)
		_hovered_col = -1
		queue_redraw()
		return
	
	var projected_position := get_local_mouse_position()
	projected_position.y = 0
	var cell_indexed := _get_cell_at_position(projected_position)
	if cell_indexed.x >= 0 && cell_indexed.y >= 0:
		_loop_cursor_position = _get_cell_position(cell_indexed)
		_hovered_col = cell_indexed.x
	else:
		_loop_cursor_position = Vector2(-1, -1)
		_hovered_col = -1
	
	queue_redraw()


func _remove_bar_at_cursor() -> void:
	var cell := _get_cell_at_cursor()
	bar_removed.emit(cell.x)


func _insert_bar_at_cursor() -> void:
	var cell := _get_cell_at_cursor()
	bar_inserted.emit(cell.x)


func _copy_bars_in_loop() -> void:
	bars_copied.emit()


func _paste_bars_at_cursor() -> void:
	var cell := _get_cell_at_cursor()
	bars_pasted.emit(cell.x)


# Interactions and drag.

func _update_drag_span() -> void:
	var available_rect: Rect2 = get_available_rect()
	
	if _dragged_from_col < 0 || _dragged_to_col < 0:
		_drag_span_position = Vector2(-1, -1)
		_drag_span_size = Vector2(-1, -1)
		queue_redraw()
		return
	
	# Flip the ends for the range, so it's always valid.
	_drag_span_range.x = _dragged_from_col
	_drag_span_range.y = _dragged_to_col
	if _dragged_from_col > _dragged_to_col:
		_drag_span_range.x = _dragged_to_col
		_drag_span_range.y = _dragged_from_col
	
	# Calculate the rect for the loop cursor.
	var current_scroll_offset := arrangement_bars[0].bar_index
	_drag_span_position = _get_cell_position(Vector2i(_drag_span_range.x - current_scroll_offset, 0))
	if _drag_span_position.x < 0:
		_drag_span_position.x = 0
	
	var drag_span_end := _get_cell_position(Vector2i(_drag_span_range.y - current_scroll_offset, 0))
	_drag_span_size = Vector2(
		drag_span_end.x - _drag_span_position.x + pattern_width,
		available_rect.size.y
	)
	
	queue_redraw()


func _start_dragging() -> void:
	var current_scroll_offset := arrangement_bars[0].bar_index
	_dragged_from_col = _hovered_col + current_scroll_offset
	_dragged_to_col = _hovered_col + current_scroll_offset
	_update_drag_span()

	_dragging = true


func _stop_dragging() -> void:
	_process_dragging() # Process one last time to update drag data when mouse doesn't move.
	_dragging = false
	
	loop_changed.emit(_drag_span_range.x, _drag_span_range.y + 1) # In song metadata the end is exclusive.
	
	_dragged_from_col = -1
	_dragged_to_col = -1
	_update_drag_span()
	
	_scrolling = false
	_scroll_threshold_idx = 0
	_scroll_interval = 0
	_scroll_direction = 0


func _process_dragging() -> void:
	if not _dragging:
		return
	
	# Check of we've dragged to the area where we should start scrolling.
	_test_for_scrolling()
	
	# Handle the rest of the drag.
	
	if _hovered_col == -1:
		return
	
	var current_scroll_offset := arrangement_bars[0].bar_index
	var hovered_bar := _hovered_col + current_scroll_offset
	if _dragged_to_col == hovered_bar:
		return
	
	_dragged_to_col = hovered_bar
	_update_drag_span()


func _test_for_scrolling() -> void:
	var available_rect := get_available_rect()
	var scroll_area_width := get_theme_constant("track_scroll_area_width", "PatternMap")
	
	var mouse_position := get_local_mouse_position()
	mouse_position.y = 0 # We only care about horizontal matches.
	
	var left_area := Rect2(
		available_rect.position,
		Vector2(scroll_area_width, available_rect.size.y)
	)
	var right_area := Rect2(
		Vector2(available_rect.size.x - scroll_area_width, available_rect.position.y),
		Vector2(scroll_area_width, available_rect.size.y)
	)
	
	if can_scroll_left && left_area.has_point(mouse_position):
		_scrolling = true
		_scroll_direction = -1
	elif can_scroll_right && right_area.has_point(mouse_position):
		_scrolling = true
		_scroll_direction = 1
	else:
		_scrolling = false
		_scroll_threshold_idx = 0
		_scroll_interval = 0
		_scroll_direction = 0


func _process_scrolling(delta: float) -> void:
	if not _dragging || not _scrolling:
		return
	
	_scroll_interval += delta
	if _scroll_interval >= SCROLL_THRESHOLDS[_scroll_threshold_idx]:
		_scroll_interval = 0
		if _scroll_threshold_idx < (SCROLL_THRESHOLDS.size() - 1):
			_scroll_threshold_idx += 1
		
		if _scroll_direction < 0:
			shifted_left.emit()
		elif _scroll_direction > 0:
			shifted_right.emit()
