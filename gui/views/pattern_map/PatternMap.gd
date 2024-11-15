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
## Whether to follow the playback cursor with scroll or not.
var _following_playback_cursor: bool = false

var _arrangement_channels: Array[ArrangementChannel] = []
# FIXME: Godot enters a dead loop if this array is typed.
# Bisection points to https://github.com/godotengine/godot/pull/92609.
var _arrangement_bars: Array[] = [] # of ArrangementBar
var _active_patterns: Array[ActivePattern] = []

# Theme cache.

var _row_odd_color: Color = Color.WHITE
var _row_even_color: Color = Color.WHITE
var _border_width: int = 0
var _border_color: Color = Color.WHITE
var _border_cover_opacity: float = 1.0

var _pattern_base_width: int = 0
var _pattern_label_offset: Vector2 = Vector2.ZERO
var _item_gutter_width: float = 0.0
var _note_border_width: int = 0

@onready var _track: Control = %PatternMapTrack
@onready var _timeline: Control = %PatternMapTimeline
@onready var _items: Control = %PatternMapItems
@onready var _overlay: Control = %PatternMapOverlay
@onready var _scrollbar: Control = %PatternMapScrollbar


func _ready() -> void:
	set_physics_process(false)
	
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
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.ARRANGEMENT_EDITOR_PATTERNMAP, get_global_available_rect)
		
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.ARRANGEMENT_EDITOR_TIMELINE, _track.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.ARRANGEMENT_EDITOR_TIMELINE_SINGLE_BAR, _get_global_track_bar_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.ARRANGEMENT_EDITOR_TIMELINE_BAR_SPAN, _get_global_track_span_rect)
		
		_scrollbar.set_button_offset(_timeline.size.y, -_track.size.y)
		
		_track.loop_changed.connect(_change_arrangement_loop)
		_track.loop_changed_to_end.connect(_change_arrangement_loop_to_end)
		_track.bar_inserted.connect(_insert_timeline_bar)
		_track.bar_removed.connect(_remove_timeline_bar)
		_track.bars_copied.connect(_copy_timeline_bars)
		_track.bars_pasted.connect(_paste_timeline_bars)
		
		_scrollbar.shifted_right.connect(_change_scroll_offset.bind(1))
		_scrollbar.shifted_left.connect(_change_scroll_offset.bind(-1))
		_track.shifted_right.connect(_change_scroll_offset.bind(1))
		_track.shifted_left.connect(_change_scroll_offset.bind(-1))
		
		Controller.song_loaded.connect(_edit_current_arrangement)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		
		Controller.music_player.playback_tick.connect(_update_playback_cursor)
		Controller.music_player.playback_stopped.connect(_update_playback_cursor)
		Controller.music_player.export_started.connect(func() -> void: _following_playback_cursor = true)
		Controller.music_player.export_ended.connect(func() -> void: _following_playback_cursor = false)


func _update_theme() -> void:
	_row_odd_color = get_theme_color("row_odd_color", "PatternMap")
	_row_even_color = get_theme_color("row_even_color", "PatternMap")
	_border_width = get_theme_constant("border_width", "PatternMap")
	_border_color = get_theme_color("border_color", "PatternMap")
	_border_cover_opacity = float(get_theme_constant("border_cover_opacity", "PatternMap")) / 100.0
	
	_pattern_base_width = get_theme_constant("pattern_width", "PatternMap")
	_pattern_label_offset.x = get_theme_constant("pattern_label_offset_x", "PatternMap")
	_pattern_label_offset.y = get_theme_constant("pattern_label_offset_y", "PatternMap")
	
	var font := get_theme_default_font()
	var font_size := get_theme_font_size("pattern_font_size", "PatternMap")
	var item_gutter_size := font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(20, 0)
	_item_gutter_width = item_gutter_size.x
	
	_note_border_width = get_theme_constant("note_border_width", "PatternMap")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_resize_pattern_width(1)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_resize_pattern_width(-1)
			elif mb.button_index == MOUSE_BUTTON_LEFT && not mb.shift_pressed:
				_select_pattern_at_cursor()
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_clear_pattern_at_cursor()
			elif mb.button_index == MOUSE_BUTTON_MIDDLE || (mb.button_index == MOUSE_BUTTON_LEFT && mb.shift_pressed):
				_clone_pattern_at_cursor()


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
	var last_col_x := 0.0
	for bar in _arrangement_bars:
		var col_position := bar.grid_position
		var border_size := Vector2(_border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), _border_color)
		
		last_col_x = col_position.x + _pattern_width
	
	# Draw an extra cover on top of inactive bars.
	if last_col_x < available_rect.end.x:
		var col_position := Vector2(last_col_x, available_rect.position.y)
		
		# Also draw the final bar line.
		var border_size := Vector2(_border_width, available_rect.size.y)
		draw_rect(Rect2(col_position, border_size), _border_color)
		
		var cover_position := col_position + Vector2(_border_width, 0)
		var cover_size := Vector2(available_rect.end.x - last_col_x, available_rect.size.y)
		var cover_color := Color(_border_color, _border_cover_opacity)
		draw_rect(Rect2(cover_position, cover_size), cover_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect
	
	if _track:
		available_rect.size.y -= _track.size.y
	if _timeline:
		available_rect.size.y -= _timeline.size.y
		available_rect.position.y += _timeline.size.y

	return available_rect


func get_global_available_rect() -> Rect2:
	var available_rect := get_available_rect()
	available_rect.position += global_position
	return available_rect


func _get_global_track_bar_rect() -> Rect2:
	var track_rect := _track.get_global_rect()
	
	var arbitrary_bar := _arrangement_bars[2]
	track_rect.position.x += arbitrary_bar.grid_position.x
	track_rect.size.x = _pattern_width
	
	return track_rect


func _get_global_track_span_rect() -> Rect2:
	var track_rect := _track.get_global_rect()
	
	var arbitrary_bar := _arrangement_bars[2]
	track_rect.position.x += arbitrary_bar.grid_position.x
	track_rect.size.x = _pattern_width * 3
	
	return track_rect


# Scrolling.

func _change_scroll_offset(delta: int) ->  void:
	_scroll_offset = clampi(_scroll_offset + delta, 0, _max_scroll_offset)
	
	_update_scrollbar()
	_update_playback_cursor()
	_update_whole_grid()


func _update_max_scroll_offset() -> void:
	var available_rect := get_available_rect()
	var bars_on_screen := floori(available_rect.size.x / _pattern_width)
	_max_scroll_offset = Arrangement.BAR_NUMBER - bars_on_screen

	_scroll_offset = clampi(_scroll_offset, 0, _max_scroll_offset)
	_update_scrollbar()
	queue_redraw()


func _update_scrollbar() -> void:
	if Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	
	_scrollbar.can_scroll_left = _scroll_offset > 0
	_scrollbar.can_scroll_right = _scroll_offset < _max_scroll_offset
	
	_track.can_scroll_left = _scrollbar.can_scroll_left
	_track.can_scroll_right = _scrollbar.can_scroll_right
	
	_timeline.scroll_offset = _scroll_offset
	
	_scrollbar.queue_redraw()
	_timeline.queue_redraw()
	_track.queue_redraw()


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
	var reference_bar := -1
	var extra_notes := 0
	
	if playback_note_index < 0:
		# If the player is stopped, park the cursor on the left end of the loop range.
		# This is normally unreachable by playback, as when playing at index 0 we want
		# to display the cursor to the right of the first note.
		reference_bar = current_arrangement.loop_start
	
	elif Controller.music_player.is_playing_residue():
		# When exporting and playing residual notes, continue moving the cursor beyond
		# the last bar.
		reference_bar = current_arrangement.loop_end
		extra_notes = Controller.music_player.get_residue_time()
	
	else:
		reference_bar = current_arrangement.current_bar_idx
		extra_notes = playback_note_index
	
	# If following cursor enabled, update scroll offset when passing roughly 3/4ths
	# of the visible bar.
	if _following_playback_cursor:
		var bars_on_screen := floori(available_rect.size.x / _pattern_width)
		var threshold_bar := int(bars_on_screen * 3.0 / 4.0)
		
		if reference_bar < _scroll_offset || reference_bar > (_scroll_offset + threshold_bar):
			_scroll_offset = reference_bar
			_update_scrollbar()
			_update_whole_grid()
	
	var pattern_size := Controller.current_song.pattern_size
	var note_width := _pattern_width / float(pattern_size)
	var note_count := (reference_bar - _scroll_offset) * pattern_size + extra_notes
	
	_overlay.playback_cursor_position = available_rect.position.x + note_count * note_width
	_overlay.queue_redraw()


# Grid layout and coordinates.

func _get_cell_at_cursor() -> Vector2i:
	var available_rect: Rect2 = get_available_rect()
	
	var mouse_position := get_local_mouse_position()
	if not available_rect.has_point(mouse_position):
		return Vector2i(-1, -1)
	
	var mouse_normalized := mouse_position - available_rect.position
	var cell_indexed := Vector2i(0, 0)
	cell_indexed.x = clampi(floori(mouse_normalized.x / _pattern_width), 0, _arrangement_bars.size() - 1)
	cell_indexed.y = clampi(floori(mouse_normalized.y / _pattern_height), 0, Arrangement.CHANNEL_NUMBER - 1)
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
		if bar_index >= Arrangement.BAR_NUMBER:
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
			active_pattern.label_position = active_pattern.item_position + _pattern_label_offset + Vector2(0, active_pattern.item_size.y)

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
					if pattern_position.x < 0 || pattern_position.x > available_rect.size.x:
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


func _get_drag_data(_at_position: Vector2) -> Variant:
	var pattern_idx := _get_pattern_at_cursor()
	if pattern_idx < 0:
		return null
	
	var drag_data := DraggedPattern.new()
	drag_data.pattern_index = pattern_idx
	
	var pattern := _active_patterns[pattern_idx]
	var preview := Control.new()
	preview.size = pattern.item_size
	preview.draw.connect(_items.draw_item.bind(preview, pattern, Vector2.ZERO, true))
	set_drag_preview(preview)
	
	return drag_data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is ItemDock.ItemDragData && (data as ItemDock.ItemDragData).source_id == Controller.DragSources.PATTERN_DOCK:
		return true
	
	if data is DraggedPattern:
		return true
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is ItemDock.ItemDragData && (data as ItemDock.ItemDragData).source_id == Controller.DragSources.PATTERN_DOCK:
		var item_data := data as ItemDock.ItemDragData
		_set_pattern_at_cursor(item_data.item_index)
	
	if data is DraggedPattern:
		var pattern_data := data as DraggedPattern
		_set_pattern_at_cursor(pattern_data.pattern_index)


# Editing.

func _edit_current_arrangement() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_arrangement:
		current_arrangement.patterns_changed.disconnect(_update_active_patterns)
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
		current_arrangement.patterns_changed.connect(_update_active_patterns)
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


func _get_pattern_at_cursor() -> int:
	if not current_arrangement:
		return -1
	
	var cell := _get_cell_at_cursor()
	var bar_index := cell.x + _scroll_offset
	if bar_index < 0 || bar_index >= current_arrangement.timeline_length:
		return -1
	if cell.y < 0 || cell.y >= Arrangement.CHANNEL_NUMBER:
		return -1
	
	return current_arrangement.timeline_bars[bar_index][cell.y]


func _set_pattern_at_cursor(pattern_idx: int) -> void:
	if not current_arrangement || not Controller.current_song:
		return
	
	var cell := _get_cell_at_cursor()
	var bar_index := cell.x + _scroll_offset
	if bar_index < 0 || bar_index >= Arrangement.BAR_NUMBER:
		return
	if cell.y < 0 || cell.y >= Arrangement.CHANNEL_NUMBER:
		return
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_setget_property(current_arrangement, "pattern", pattern_idx,
		# Getter.
		func() -> int:
			return current_arrangement.get_pattern(bar_index, cell.y)
			,
		# Setter.
		func(value: int) -> void:
			if value == -1:
				current_arrangement.clear_pattern(bar_index, cell.y)
			else:
				current_arrangement.set_pattern(bar_index, cell.y, value)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _select_pattern_at_cursor() -> void:
	if not current_arrangement || not Controller.current_song:
		return
	
	var pattern_idx := _get_pattern_at_cursor()
	if pattern_idx < 0:
		return
	
	Controller.edit_pattern(pattern_idx)


func _clear_pattern_at_cursor() -> void:
	if not current_arrangement || not Controller.current_song:
		return
	
	var pattern_idx := _get_pattern_at_cursor()
	if pattern_idx < 0:
		return
	
	var cell := _get_cell_at_cursor()
	var bar_index := cell.x + _scroll_offset
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_setget_property(current_arrangement, "pattern", -1,
		# Getter.
		func() -> int:
			return current_arrangement.get_pattern(bar_index, cell.y)
			,
		# Setter.
		func(value: int) -> void:
			if value == -1:
				current_arrangement.clear_pattern(bar_index, cell.y)
			else:
				current_arrangement.set_pattern(bar_index, cell.y, value)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _clone_pattern_at_cursor() -> void:
	if not current_arrangement || not Controller.current_song:
		return
	
	var pattern_idx := _get_pattern_at_cursor()
	if pattern_idx < 0:
		return
	if not Controller.can_clone_pattern(pattern_idx):
		return
	
	var cell := _get_cell_at_cursor()
	var bar_index := cell.x + _scroll_offset
	
	var old_value := current_arrangement.get_pattern(bar_index, cell.y)
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	var state_context := arrangement_state.get_context()
	state_context["id"] = -1
	
	arrangement_state.add_do_action(func() -> void:
		state_context.id = Controller.clone_pattern_nocheck(pattern_idx)
		current_arrangement.set_pattern(bar_index, cell.y, state_context.id)
	)
	arrangement_state.add_undo_action(func() -> void:
		if old_value == -1:
			current_arrangement.clear_pattern(bar_index, cell.y)
		else:
			current_arrangement.set_pattern(bar_index, cell.y, old_value)
		
		Controller.delete_pattern_nocheck(state_context.id)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _change_arrangement_loop(starts_at: int, ends_at: int) -> void:
	if not current_arrangement:
		return
	
	var old_loop_start := current_arrangement.loop_start
	var old_loop_end := current_arrangement.loop_end
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_do_action(func() -> void:
		current_arrangement.set_loop(starts_at, ends_at)
	)
	arrangement_state.add_undo_action(func() -> void:
		current_arrangement.set_loop(old_loop_start, old_loop_end)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _change_arrangement_loop_to_end(starts_at: int) -> void:
	if not current_arrangement:
		return
	
	var ends_at := starts_at + 1
	if starts_at < current_arrangement.timeline_length:
		ends_at = current_arrangement.timeline_length
	
	var old_loop_start := current_arrangement.loop_start
	var old_loop_end := current_arrangement.loop_end
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_do_action(func() -> void:
		current_arrangement.set_loop(starts_at, ends_at)
	)
	arrangement_state.add_undo_action(func() -> void:
		current_arrangement.set_loop(old_loop_start, old_loop_end)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _insert_timeline_bar(at_index: int) -> void:
	if not current_arrangement:
		return
	
	var bar_index := at_index + _scroll_offset
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_do_action(func() -> void:
		current_arrangement.insert_bar(bar_index)
	)
	arrangement_state.add_undo_action(func() -> void:
		current_arrangement.remove_bar(bar_index)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _remove_timeline_bar(at_index: int) -> void:
	if not current_arrangement:
		return
	if current_arrangement.timeline_length <= 0:
		return
	
	var bar_index := at_index + _scroll_offset
	var bar_patterns := current_arrangement.timeline_bars[bar_index].duplicate()
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	arrangement_state.add_do_action(func() -> void:
		current_arrangement.remove_bar(bar_index)
	)
	arrangement_state.add_undo_action(func() -> void:
		current_arrangement.insert_bar(bar_index)
		
		for i: int in bar_patterns.size():
			current_arrangement.set_pattern(bar_index, i, bar_patterns[i])
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


func _copy_timeline_bars() -> void:
	if not current_arrangement:
		return
	
	current_arrangement.copy_bar_range(current_arrangement.loop_start, current_arrangement.loop_end)
	Controller.update_status("SELECTED BARS COPIED", Controller.StatusLevel.INFO)


func _paste_timeline_bars(at_index: int) -> void:
	if not current_arrangement:
		return
	
	var copied_data := current_arrangement.get_copied_bar_range().duplicate()
	if copied_data.is_empty():
		return
	
	var bar_index := at_index + _scroll_offset
	
	var arrangement_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.ARRANGEMENT)
	var state_context := arrangement_state.get_context()
	state_context["affected"] = 0
	
	arrangement_state.add_do_action(func() -> void:
		state_context.affected = current_arrangement.paste_bar_range(bar_index, copied_data)
	)
	arrangement_state.add_undo_action(func() -> void:
		for i: int in range(state_context.affected, 0, -1): # Iterate backwards, so deletions are cheaper.
			current_arrangement.remove_bar(bar_index + i - 1)
	)
	
	Controller.state_manager.commit_state_change(arrangement_state)


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


class DraggedPattern:
	var pattern_index: int = -1
