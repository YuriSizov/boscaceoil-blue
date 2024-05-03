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

## Currently edited pattern.
var current_pattern: Pattern = null
## Currently edited arrangement for the song.
var current_arrangement: Arrangement = null

var _hovering: bool = false

## Control-size-dependent vertical size of a pattern.
var _pattern_height: float = 0
## Controllable scale for the horizontal size of a pattern.
var _pattern_width_scale: float = 1.0
var _pattern_width: float = 0
## Offset, in number of timeline bars/pattern columns.
var _scroll_offset: int = 0
## Window-size dependent limit.
var _max_scroll_offset: int = -1

var _arrangement_channels: Array[ArrangementChannel] = []
var _arrangement_bars: Array[ArrangementBar] = []
var _active_patterns: Array[ActivePattern] = []

# Theme cache.

var _row_odd_color: Color = Color.WHITE
var _row_even_color: Color = Color.WHITE
var _border_width: int = 0
var _border_color: Color = Color.WHITE

var _pattern_base_width: int = 0
var _item_gutter_width: float = 0.0
var _note_border_width: int = 0

@onready var _track: Control = %PatternMapTrack
@onready var _timeline: Control = %PatternMapTimeline
@onready var _items: Control = %PatternMapItems
@onready var _overlay: Control = %PatternMapOverlay
@onready var _scrollbar: Control = %PatternMapScrollbar
@onready var _dock: Control = %PatternMapDock


func _ready() -> void:
	set_physics_process(false)
	
	_scrollbar.set_button_offset(_timeline.size.y, -_track.size.y)
	_update_theme()

	theme_changed.connect(_update_theme)
	theme_changed.connect(_update_pattern_sizes)
	theme_changed.connect(_update_playback_cursor)
	theme_changed.connect(_update_whole_grid)
	
	_update_pattern_sizes()
	_update_playback_cursor()
	_edit_current_arrangement()
	
	resized.connect(_update_pattern_sizes)
	resized.connect(_update_playback_cursor)
	resized.connect(_update_whole_grid)
	
	mouse_entered.connect(_start_hovering)
	mouse_exited.connect(_stop_hovering)
	
	if not Engine.is_editor_hint():
		_track.loop_changed.connect(_change_arrangement_loop)
		_scrollbar.shifted_right.connect(_change_scroll_offset.bind(1))
		_scrollbar.shifted_left.connect(_change_scroll_offset.bind(-1))
		
		Controller.song_loaded.connect(_edit_current_arrangement)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		
		Controller.music_player.playback_tick.connect(_update_playback_cursor)
		Controller.music_player.playback_stopped.connect(_update_playback_cursor)


func _update_theme() -> void:
	_row_odd_color = get_theme_color("row_odd_color", "PatternMap")
	_row_even_color = get_theme_color("row_even_color", "PatternMap")
	_border_width = get_theme_constant("border_width", "PatternMap")
	_border_color = get_theme_color("border_color", "PatternMap")
	
	_pattern_base_width = get_theme_constant("pattern_width", "PatternMap")
	
	var font := get_theme_default_font()
	var font_size := get_theme_font_size("pattern_font_size", "PatternMap")
	var item_gutter_size := font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(20, 0)
	_item_gutter_width = item_gutter_size.x
	
	_note_border_width = get_theme_constant("note_border_width", "PatternMap")


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
	_process_scrollbar_hover()


func _draw() -> void:
	var available_rect := get_available_rect()
	
	# Draw the background.
	draw_rect(Rect2(Vector2.ZERO, size), _row_odd_color)

	# Draw the rows.
	for channel in _arrangement_channels:
		var row_position := channel.grid_position
		var row_size := Vector2(available_rect.size.x, _pattern_height)
		var row_color := _row_even_color if channel.channel_index % 2 else _row_odd_color
		draw_rect(Rect2(row_position, row_size), row_color)

	# Draw vertical lines.
	for bar in _arrangement_bars:
		var col_position := bar.grid_position
		var border_size := Vector2(_border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), _border_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect

	if _dock:
		available_rect.size.x -= _dock.get_minimum_size().x
	if _track:
		available_rect.size.y -= _track.size.y
	if _timeline:
		available_rect.size.y -= _timeline.size.y
		available_rect.position.y += _timeline.size.y

	return available_rect


# Scrolling.

func _change_scroll_offset(delta: int) ->  void:
	_scroll_offset = clampi(_scroll_offset + delta, 0, _max_scroll_offset)
	
	_timeline.scroll_offset = _scroll_offset
	
	_update_playback_cursor()
	_update_whole_grid()


func _update_max_scroll_offset() -> void:
	var available_rect := get_available_rect()
	var bars_on_screen := floori(available_rect.size.x / _pattern_width)
	_max_scroll_offset = Arrangement.BAR_NUMBER - bars_on_screen + 1

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
		var visible_bar_index := current_arrangement.loop_start - _scroll_offset
		_overlay.playback_cursor_position = available_rect.position.x + (visible_bar_index * pattern_size) * note_width
		_overlay.queue_redraw()
	else:
		var visible_bar_index := current_arrangement.current_bar_idx - _scroll_offset
		_overlay.playback_cursor_position = available_rect.position.x + (visible_bar_index * pattern_size + playback_note_index) * note_width
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
	if not is_inside_tree():
		return
	
	_pattern_width_scale = clampf(_pattern_width_scale + value_sign * PATTERN_WIDTH_STEP, PATTERN_WIDTH_MIN, PATTERN_WIDTH_MAX)
	_pattern_width = _pattern_base_width * _pattern_width_scale

	_track.pattern_width = _pattern_width
	_timeline.pattern_width = _pattern_width
	_overlay.pattern_width = _pattern_width
	
	_update_playback_cursor()
	_update_whole_grid()


func _update_grid_layout() -> void:
	# Reset collections.
	_arrangement_channels.clear()
	_arrangement_bars.clear()

	# Get reference data.
	var available_rect := get_available_rect()

	# Iterate through all the patterns and complete collections.
	var filled_width := 0.0
	var index := 0
	while filled_width < (available_rect.size.x + 2 * _pattern_width): # Give it some buffer.
		var bar_index: int = index + _scroll_offset
		if bar_index > Arrangement.BAR_NUMBER:
			break

		# Create bar column data.
		var bar := ArrangementBar.new()
		bar.bar_index = bar_index
		bar.position = Vector2(index * _pattern_width, 0)
		bar.grid_position = bar.position + available_rect.position

		_arrangement_bars.push_back(bar)
		
		# Update counters.
		filled_width += _pattern_width
		index += 1
	
	for i in Arrangement.CHANNEL_NUMBER:
		var channel := ArrangementChannel.new()
		channel.channel_index = i
		channel.position = Vector2(0, i * _pattern_height)
		channel.grid_position = channel.position + available_rect.position
		channel.label_position = channel.position + Vector2(0, -6)
		
		_arrangement_channels.push_back(channel)
	
	# Update children with the new data.
	_track.arrangement_bars = _arrangement_bars
	
	queue_redraw()
	_track.queue_redraw()
	_timeline.queue_redraw()
	_items.queue_redraw()
	_overlay.queue_redraw()


func _update_active_patterns() -> void:
	if Engine.is_editor_hint():
		return
	
	_active_patterns.clear()
	
	if Controller.current_song:
		var available_rect := get_available_rect()
		
		for i in Controller.current_song.patterns.size():
			var active_pattern := ActivePattern.new()
			active_pattern.pattern_index = i
			
			var pattern := Controller.current_song.patterns[i]
			var instrument := Controller.current_song.instruments[pattern.instrument_idx]
			
			var item_theme := Controller.get_instrument_theme(instrument)
			active_pattern.main_color = item_theme.get_color("item_color", "InstrumentDock")
			active_pattern.gutter_color = item_theme.get_color("item_gutter_color", "InstrumentDock")
			
			active_pattern.item_position = Vector2(0, 0)
			active_pattern.item_size = Vector2(_pattern_width, _pattern_height)
			
			active_pattern.label_underline_area = Rect2(
				active_pattern.item_position + Vector2(0, 3.0 * active_pattern.item_size.y / 5.0),
				Vector2(_item_gutter_width - _note_border_width, 2.0 * active_pattern.item_size.y / 5.0)
			)
			active_pattern.label_position = active_pattern.item_position + Vector2(8, active_pattern.item_size.y - 10)

			active_pattern.notes_area = Rect2(
				active_pattern.item_position + Vector2(_item_gutter_width + _note_border_width, _note_border_width),
				Vector2(active_pattern.item_size.x - _item_gutter_width - 2 * _note_border_width, active_pattern.item_size.y - 2 * _note_border_width)
			)
			
			if pattern.note_amount > 0:
				var note_span := pattern.get_active_note_span_size()
				var note_width := active_pattern.notes_area.size.x / Controller.current_song.pattern_size
				var note_height := active_pattern.notes_area.size.y / note_span
				
				var note_origin := active_pattern.notes_area.position
				var note_span_height := active_pattern.notes_area.size.y
				
				# If the span is too small, adjust everything to center the notes.
				if note_height > _note_border_width:
					note_height = _note_border_width
					note_span_height = note_height * note_span
					note_origin.y += (active_pattern.notes_area.size.y - note_span_height) / 2.0
				
				var note_value_offset := pattern.active_note_span[0]
				for j in pattern.note_amount:
					var note := pattern.notes[j]
					var note_index := note.x - note_value_offset
					var note_position := note_origin + Vector2(note_width * note.y, note_span_height - note_height * (note_index + 1))
					var note_size := Vector2(note_width * note.z, note_height)
					
					active_pattern.notes.push_back(Rect2(note_position, note_size))
			
			_active_patterns.push_back(active_pattern)
		
		if current_arrangement:
			for i in current_arrangement.timeline_bars.size():
				var bar := current_arrangement.timeline_bars[i]
				
				for j in bar.size():
					var pattern_index := bar[j]
					if pattern_index < 0:
						continue
					
					var active_pattern := _active_patterns[pattern_index]
					var pattern_position := _get_cell_position(Vector2i(i - _scroll_offset, j))
					if pattern_position.x < 0 || (pattern_position.x + _pattern_width) > available_rect.size.x:
						continue # Skip patterns outside of the visible area.
					
					active_pattern.grid_positions.push_back(pattern_position)
	
	_items.active_patterns = _active_patterns
	_items.queue_redraw()


func _update_active_loop() -> void:
	if Engine.is_editor_hint():
		return
	if not current_arrangement:
		return
	
	_track.loop_start_index = current_arrangement.loop_start
	_track.loop_end_index = current_arrangement.loop_end
	
	_track.queue_redraw()


# Hovering.

func _start_hovering() -> void:
	_hovering = true
	_process_pattern_cursor()
	_process_scrollbar_hover()
	set_physics_process(true)


func _stop_hovering() -> void:
	_hovering = false
	set_physics_process(false)
	_process_pattern_cursor()
	_process_scrollbar_hover()


func _process_scrollbar_hover() -> void:
	_scrollbar.test_mouse_position()


# Pattern cursor and drawing.

func _process_pattern_cursor() -> void:
	if not _hovering:
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
	if current_pattern:
		current_pattern.key_changed.disconnect(_update_active_patterns)
		current_pattern.scale_changed.disconnect(_update_active_patterns)
		current_pattern.instrument_changed.disconnect(_update_active_patterns)
		current_pattern.notes_changed.disconnect(_update_active_patterns)
	
	current_arrangement = Controller.current_song.arrangement
	current_pattern = Controller.get_current_pattern()

	if current_arrangement:
		current_arrangement.loop_changed.connect(_update_active_loop)
		current_arrangement.loop_changed.connect(_update_playback_cursor)
	if current_pattern:
		current_pattern.key_changed.connect(_update_active_patterns)
		current_pattern.scale_changed.connect(_update_active_patterns)
		current_pattern.instrument_changed.connect(_update_active_patterns)
		current_pattern.notes_changed.connect(_update_active_patterns)
	
	_update_whole_grid_and_reset_scroll()
	_update_playback_cursor()


func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_pattern:
		current_pattern.key_changed.disconnect(_update_active_patterns)
		current_pattern.scale_changed.disconnect(_update_active_patterns)
		current_pattern.instrument_changed.disconnect(_update_active_patterns)
		current_pattern.notes_changed.disconnect(_update_active_patterns)
	
	current_pattern = Controller.get_current_pattern()
	
	if current_pattern:
		current_pattern.key_changed.connect(_update_active_patterns)
		current_pattern.scale_changed.connect(_update_active_patterns)
		current_pattern.instrument_changed.connect(_update_active_patterns)
		current_pattern.notes_changed.connect(_update_active_patterns)
	
	_update_active_patterns()

func _change_arrangement_loop(starts_at: int, ends_at: int) -> void:
	if not current_arrangement:
		return
	
	current_arrangement.set_loop(starts_at, ends_at)
	Controller.current_song.mark_dirty()


class ArrangementChannel:
	var channel_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO


class ArrangementBar:
	var bar_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO


class ActivePattern:
	var pattern_index: int = -1
	var main_color: Color = Color.BLACK
	var gutter_color: Color = Color.BLACK
	
	var item_position: Vector2 = Vector2.ZERO
	var item_size: Vector2 = Vector2.ZERO
	var label_underline_area: Rect2 = Rect2()
	var label_position: Vector2 = Vector2.ZERO
	var notes_area: Rect2 = Rect2()
	var notes: Array[Rect2] = []
	
	var grid_positions: PackedVector2Array = PackedVector2Array()
