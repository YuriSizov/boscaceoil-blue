###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PatternMap extends Control

const PATTERN_WIDTH_MIN := 0.5
const PATTERN_WIDTH_MAX := 1.0
const PATTERN_WIDTH_STEP := 0.05

## Currently edited arrangement for the song.
var current_arrangement: Arrangement = null

## Control-size-dependent vertical size of a pattern.
var _pattern_height: float = 0
## Controllable scale for the horizontal size of a pattern.
var _pattern_width_scale: float = 1.0
var _pattern_width: float = 0
## Offset, in number of timeline bars/pattern columns.
var _scroll_offset: int = 0
## Window-size dependent limit.
var _max_scroll_offset: int = -1
## Flag whether the cursor for drawing patterns is visible.
var _pattern_cursor_visible: bool = false

var _pattern_rows: Array[PatternRow] = []
var _pattern_cols: Array[PatternCol] = []

@onready var _track: Control = $PatternMapTrack
@onready var _overlay: Control = $PatternMapOverlay
@onready var _dock: Control = $PatternMapDock


func _ready() -> void:
	set_physics_process(false)
	
	_update_pattern_sizes()
	_update_playback_cursor()
	_edit_current_arrangement()
	
	resized.connect(_update_pattern_sizes)
	resized.connect(_update_playback_cursor)
	resized.connect(_update_whole_grid)
	
	mouse_entered.connect(_show_pattern_cursor)
	mouse_exited.connect(_hide_pattern_cursor)
	
	_track.loop_changed.connect(_change_arrangement_loop)
	
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_edit_current_arrangement)
		
		Controller.music_player.playback_tick.connect(_update_playback_cursor)
		Controller.music_player.playback_stopped.connect(_update_playback_cursor)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if event.is_pressed():
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_resize_pattern_width(1)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_resize_pattern_width(-1)


func _physics_process(_delta: float) -> void:
	_process_pattern_cursor()


func _draw() -> void:
	var available_rect := get_available_rect()
	
	var row_odd_color := get_theme_color("row_odd_color", "PatternMap")
	var row_even_color := get_theme_color("row_even_color", "PatternMap")
	var border_width := get_theme_constant("border_width", "PatternMap")
	var border_color := get_theme_color("border_color", "PatternMap")

	# Draw the background.
	draw_rect(Rect2(Vector2.ZERO, size), row_odd_color)

	# Draw the rows.
	for row in _pattern_rows:
		var row_position := row.grid_position
		var row_size := Vector2(available_rect.size.x, _pattern_height)
		var row_color := row_even_color if row.row_index % 2 else row_odd_color
		draw_rect(Rect2(row_position, row_size), row_color)

	# Draw vertical lines.
	for pattern in _pattern_cols:
		var col_position := pattern.grid_position
		var border_size := Vector2(border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), border_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect

	if _dock:
		available_rect.size.x -= _dock.size.x
	if _track:
		available_rect.size.y -= _track.size.y

	return available_rect


# Scrolling.

func _update_max_scroll_offset() -> void:
	var available_rect := get_available_rect()
	var patterns_on_screen := floori(available_rect.size.x / _pattern_width)
	_max_scroll_offset = Arrangement.BAR_NUMBER - patterns_on_screen + 1

	_scroll_offset = clamp(_scroll_offset, 0, _max_scroll_offset)
	queue_redraw()


# State visualization.

func _update_pattern_sizes() -> void:
	_update_pattern_height()
	_resize_pattern_width(0)


func _update_pattern_height() -> void:
	var available_rect := get_available_rect()
	_pattern_height = available_rect.size.y / Arrangement.CHANNEL_NUMBER
	
	_overlay.pattern_height = _pattern_height
	
	queue_redraw()
	_overlay.queue_redraw()


func _update_whole_grid() -> void:
	_update_max_scroll_offset()
	_update_grid_layout()
	_update_active_patterns()
	_update_active_loop()


func _update_whole_grid_and_reset_scroll() -> void:
	_update_max_scroll_offset()
	_scroll_offset = 0
	_update_grid_layout()
	_update_active_patterns()
	_update_active_loop()


func _update_playback_cursor() -> void:
	if Engine.is_editor_hint():
		return
	
	if not Controller.current_song || not current_arrangement:
		_overlay.playback_cursor_position = -1
		_overlay.queue_redraw()
		return
	
	var available_rect := get_available_rect()
	var playback_note_index := Controller.music_player.get_pattern_time()
	var pattern_size := Controller.current_song.pattern_size
	var note_width := _pattern_width / float(pattern_size)
	
	# If the player is stopped, park the cursor on the left end of the loop range.
	# This is normally unreachable by playback, as when playing at index 0 we want
	# to display the cursor to the right of the first note.
	if playback_note_index < 0:
		_overlay.playback_cursor_position = available_rect.position.x + (current_arrangement.loop_start * pattern_size) * note_width
		_overlay.queue_redraw()
		return
	
	_overlay.playback_cursor_position = available_rect.position.x + (current_arrangement.current_bar_idx * pattern_size + playback_note_index) * note_width
	_overlay.queue_redraw()


# Grid layout and coordinates.

func _get_cell_at_cursor() -> Vector2i:
	var available_rect: Rect2 = get_available_rect()
	
	var mouse_position := get_local_mouse_position()
	if not available_rect.has_point(mouse_position):
		return Vector2i(-1, -1)
	
	var mouse_normalized := mouse_position - available_rect.position
	var cell_indexed := Vector2i(0, 0)
	cell_indexed.x = clampi(floori(mouse_normalized.x / _pattern_width), 0, Arrangement.BAR_NUMBER)
	cell_indexed.y = clampi(floori(mouse_normalized.y / _pattern_height), 0, Arrangement.CHANNEL_NUMBER)
	return cell_indexed


func _get_cell_position(cell_indexed: Vector2i) -> Vector2:
	var available_rect := get_available_rect()
	
	return Vector2(
		available_rect.position.x + cell_indexed.x * _pattern_width,
		available_rect.position.y + cell_indexed.y * _pattern_height
	)


func _resize_pattern_width(value_sign: int) -> void:
	_pattern_width_scale = clampf(_pattern_width_scale + value_sign * PATTERN_WIDTH_STEP, PATTERN_WIDTH_MIN, PATTERN_WIDTH_MAX)
	_pattern_width = get_theme_constant("pattern_width", "PatternMap") * _pattern_width_scale

	_overlay.pattern_width = _pattern_width
	_track.pattern_width = _pattern_width
	
	_update_playback_cursor()
	_update_whole_grid()


func _update_grid_layout() -> void:
	# Reset collections.
	_pattern_rows.clear()
	_pattern_cols.clear()

	# Get reference data.
	var available_rect := get_available_rect()

	# Iterate through all the patterns and complete collections.
	var filled_width := 0.0
	var index := 0
	while filled_width < (available_rect.size.x + 2 * _pattern_width): # Give it some buffer.
		var pattern_index: int = index + _scroll_offset
		if pattern_index > Arrangement.BAR_NUMBER:
			break

		# Create pattern column data.
		var pattern := PatternCol.new()
		pattern.pattern_index = pattern_index
		pattern.position = Vector2(index * _pattern_width, 0)
		pattern.grid_position = pattern.position + available_rect.position

		_pattern_cols.push_back(pattern)
		
		# Update counters.
		filled_width += _pattern_width
		index += 1
	
	for i in Arrangement.CHANNEL_NUMBER:
		var row := PatternRow.new()
		row.row_index = i
		row.position = Vector2(0, available_rect.position.y + i * _pattern_height)
		row.grid_position = row.position + available_rect.position
		row.label_position = row.position + Vector2(0, -6)
		
		_pattern_rows.push_back(row)
	
	# Update children with the new data.
	_track.pattern_cols = _pattern_cols
	
	queue_redraw()
	_track.queue_redraw()
	_overlay.queue_redraw()


func _update_active_patterns() -> void:
	pass


func _update_active_loop() -> void:
	if Engine.is_editor_hint():
		return
	if not current_arrangement:
		return
	
	_track.loop_start_index = current_arrangement.loop_start
	_track.loop_end_index = current_arrangement.loop_end
	
	_track.queue_redraw()


# Pattern cursor and drawing.

func _show_pattern_cursor() -> void:
	_pattern_cursor_visible = true
	_process_pattern_cursor()
	set_physics_process(true)


func _hide_pattern_cursor() -> void:
	set_physics_process(false)
	_pattern_cursor_visible = false
	_process_pattern_cursor()


func _process_pattern_cursor() -> void:
	if not _pattern_cursor_visible:
		_overlay.pattern_cursor_position = Vector2(-1, -1)
		_overlay.queue_redraw()
		return
	
	var cell_indexed := _get_cell_at_cursor()
	if cell_indexed.x >= 0 && cell_indexed.y >= 0:
		_overlay.pattern_cursor_position = _get_cell_position(cell_indexed)
	else:
		_overlay.pattern_cursor_position = Vector2(-1, -1)
	
	_overlay.queue_redraw()


# Editing.

func _edit_current_arrangement() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_arrangement:
		current_arrangement.loop_changed.disconnect(_update_active_loop)
		current_arrangement.loop_changed.disconnect(_update_playback_cursor)
	
	current_arrangement = Controller.current_song.arrangement

	if current_arrangement:
		current_arrangement.loop_changed.connect(_update_active_loop)
		current_arrangement.loop_changed.connect(_update_playback_cursor)
	
	_update_whole_grid_and_reset_scroll()
	_update_playback_cursor()


func _change_arrangement_loop(starts_at: int, ends_at: int) -> void:
	if not current_arrangement:
		return
	
	current_arrangement.set_loop(starts_at, ends_at)


class PatternRow:
	var row_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO


class PatternCol:
	var pattern_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
