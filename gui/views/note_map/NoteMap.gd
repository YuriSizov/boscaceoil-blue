###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name NoteMap extends Control

const CENTER_OCTAVE := 3
const SMALLEST_PATTERN_SIZE := 8 # Must be power-of-2!

enum DrawingMode {
	DRAWING_OFF,
	DRAWING_ADD,
	DRAWING_REMOVE,
	MAX
}

## Current edited pattern.
var current_pattern: Pattern = null
## Current instrument of the edited pattern.
var current_instrument: Instrument = null
## Number of notes in a row.
var pattern_size: int = 1
## Number of notes in a bar.
var bar_size: int = 1

## Current scale layout.
var _scale_layout: Array[int] = []
## Mapping between note values (in C key) and their row indices, based on the current scale.
var _note_value_row_map: Dictionary = {}
var _note_row_value_map: Dictionary = {}

## Window-dependent horizontal size of a note, based on pattern_size.
var _note_width: float = 0
## Offset, in number of note rows.
var _scroll_offset: int = 0
## Window-size dependent limit, based on Pattern.MAX_NOTE_VALUE and the current scale.
var _max_scroll_offset: int = -1

var _note_rows: Array[NoteRow] = []
var _octave_rows: Array[OctaveRow] = []
var _active_notes: Array[ActiveNote] = []
var _note_cursor_visible: bool = false
var _note_cursor_size: int = 1

var _note_drawing_mode: DrawingMode = DrawingMode.DRAWING_OFF

@onready var _gutter: NoteMapGutter = $NoteMapGutter
@onready var _scrollbar: NoteMapScrollbar = $NoteMapScrollbar
@onready var _overlay: NoteMapOverlay = $NoteMapOverlay


func _ready() -> void:
	set_physics_process(false)
	
	_update_song_sizes()
	_update_playback_cursor()
	_edit_current_pattern()

	resized.connect(_update_song_sizes)
	resized.connect(_update_playback_cursor)
	resized.connect(_update_whole_grid)
	
	mouse_entered.connect(_show_note_cursor)
	mouse_exited.connect(_hide_note_cursor)

	_gutter.note_preview_requested.connect(_preview_note_at_cursor)
	_scrollbar.shifted_up.connect(_change_scroll_offset.bind(1))
	_scrollbar.shifted_down.connect(_change_scroll_offset.bind(-1))
	_scrollbar.centered.connect(_center_scroll_offset)
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_NOTEMAP, get_global_available_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_SCROLLBAR, _scrollbar.get_global_rect)
		
		Controller.song_loaded.connect(_update_song_sizes)
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_sizes_changed.connect(_update_song_sizes)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		
		Controller.music_player.playback_tick.connect(_update_playback_cursor)
		Controller.music_player.playback_stopped.connect(_update_playback_cursor)


func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return
	
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _note_drawing_mode != DrawingMode.DRAWING_OFF:
			_stop_drawing_notes()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if _note_cursor_visible && mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				if mb.ctrl_pressed:
					_resize_note_cursor(1)
				else:
					_change_scroll_offset(1)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if mb.ctrl_pressed:
					_resize_note_cursor(-1)
				else:
					_change_scroll_offset(-1)
			
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				_start_drawing_notes(DrawingMode.DRAWING_ADD)
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_start_drawing_notes(DrawingMode.DRAWING_REMOVE)
		
		if _note_drawing_mode != DrawingMode.DRAWING_OFF && not mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT || mb.button_index == MOUSE_BUTTON_RIGHT:
				_stop_drawing_notes()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("bosca_notemap_cursor_bigger", true, true):
		_resize_note_cursor(1)
	elif event.is_action_pressed("bosca_notemap_cursor_smaller", true, true):
		_resize_note_cursor(-1)


func _physics_process(_delta: float) -> void:
	_process_note_cursor()
	_process_note_drawing()


func _draw() -> void:
	var available_rect := get_available_rect()
	# Point of origin is at the bottom.
	var origin := Vector2(available_rect.position.x, available_rect.size.y)
	var note_height := get_theme_constant("note_height", "NoteMap")
	var border_width := get_theme_constant("border_width", "NoteMap")
	
	# Instrument-dependent colors.
	var note_base_color := get_theme_color("note_color", "NoteMap")
	var note_sharp_color := get_theme_color("note_sharp_color", "NoteMap")
	var light_border_color := get_theme_color("border_color", "NoteMap")
	var dark_border_color := get_theme_color("border_dark_color", "NoteMap")

	# Draw the rows.
	for note in _note_rows:
		var note_position := note.grid_position - Vector2(0, note_height)
		var note_size := Vector2(available_rect.size.x, note_height)
		var note_color := note_sharp_color if note.sharp else note_base_color
		draw_rect(Rect2(note_position, note_size), note_color)

	# Draw horizontal lines.
	for note in _note_rows:
		var border_size := Vector2(available_rect.size.x, border_width)
		draw_rect(Rect2(note.grid_position, border_size), dark_border_color)

	# Draw vertical lines.
	var col_index := 0
	var last_col_x := 0.0
	while col_index < (pattern_size + 1):
		var col_position := origin + Vector2(_note_width * col_index, -available_rect.size.y)
		var border_size := Vector2(border_width, available_rect.size.y)

		var thick_bar := col_index % bar_size == 0
		if thick_bar:
			var border_thick_size := border_size + Vector2(border_width, 0)
			var border_dark_position := col_position + Vector2(border_width, 0)
			
			draw_rect(Rect2(col_position, border_thick_size), light_border_color)
			draw_rect(Rect2(border_dark_position, border_size), dark_border_color)
		else:
			draw_rect(Rect2(col_position, border_size), light_border_color)
		
		col_index += 1
		last_col_x = col_position.x
	
	# Draw an extra cover on top of inactive bars.
	if last_col_x < available_rect.end.x:
		var cover_position := Vector2(last_col_x, origin.y - available_rect.size.y)
		var cover_size := Vector2(available_rect.end.x - last_col_x, available_rect.size.y)
		var cover_alpha := float(get_theme_constant("border_cover_opacity", "NoteMap")) / 100.0
		var cover_color := Color(light_border_color, cover_alpha)
		
		draw_rect(Rect2(cover_position, cover_size), cover_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect
	
	if _gutter:
		available_rect.position.x += _gutter.size.x
		available_rect.size.x -= _gutter.size.x
	if _scrollbar:
		available_rect.size.x -= _scrollbar.size.x
	
	return available_rect


func get_global_available_rect() -> Rect2:
	var available_rect := get_available_rect()
	available_rect.position += global_position
	return available_rect


# Scrolling.

func _update_max_scroll_offset() -> void:
	var available_rect := get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	var notes_on_screen := floori(available_rect.size.y / note_height)
	_max_scroll_offset = maxi(0, _note_row_value_map.size() - notes_on_screen)
	_scroll_offset = clampi(_scroll_offset, 0, _max_scroll_offset)


func _change_scroll_offset(delta: int) ->  void:
	_scroll_offset = clampi(_scroll_offset + delta, 0, _max_scroll_offset)
	_update_scrollables()


func _center_scroll_offset() -> void:
	var note_offset := _scroll_offset
	
	if current_pattern && current_pattern.note_amount > 0:
		var available_rect := get_available_rect()
		var note_height := get_theme_constant("note_height", "NoteMap")
		var notes_on_screen := floori(available_rect.size.y / note_height)
	
		var central_note_index := current_pattern.active_note_span[floori(current_pattern.active_note_span.size() / 2.0)]
		note_offset = _note_value_row_map[central_note_index] - roundi(notes_on_screen / 2.0)
	else:
		var scale_size := _scale_layout.size()
		note_offset = scale_size * CENTER_OCTAVE - 2
	
	_scroll_offset = clampi(note_offset, 0, _max_scroll_offset)
	_update_scrollables()


func _reset_scroll_offset() -> void:
	_scroll_offset = 0
	_update_scrollables()


# Editing and state visualization.

func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_pattern:
		current_pattern.key_changed.disconnect(_update_whole_grid)
		current_pattern.scale_changed.disconnect(_update_whole_grid_and_center)
		current_pattern.instrument_changed.disconnect(_update_pattern_instrument)
		current_pattern.notes_changed.disconnect(_update_active_notes)
	
	current_pattern = Controller.get_current_pattern()
	current_instrument = null

	if current_pattern:
		current_pattern.key_changed.connect(_update_whole_grid)
		current_pattern.scale_changed.connect(_update_whole_grid_and_center)
		current_pattern.instrument_changed.connect(_update_pattern_instrument)
		current_pattern.notes_changed.connect(_update_active_notes)
		
		current_instrument = Controller.current_song.instruments[current_pattern.instrument_idx]
	
	theme = Controller.get_instrument_theme(current_instrument)
	_update_whole_grid_and_center()
	_update_playback_cursor()


func _update_note_maps() -> void:
	_note_value_row_map.clear()
	_note_row_value_map.clear()
	
	if current_instrument && current_instrument.type == Instrument.InstrumentType.INSTRUMENT_DRUMKIT:
		var drumkit_instrument := current_instrument as DrumkitInstrument
		
		# For drumkits scale has no effect.
		for note_value in drumkit_instrument.voices.size():
			_note_value_row_map[note_value] = note_value
			_note_row_value_map[note_value] = note_value
		
		return

	_scale_layout = Scale.get_scale_layout(current_pattern.scale if current_pattern else Scale.SCALE_NORMAL)
	var scale_size := _scale_layout.size()
	var scale_index := 0
	var next_valid_note := 0
	var row_index := 0

	for note_value in Pattern.MAX_NOTE_VALUE:
		if next_valid_note != note_value:
			_note_value_row_map[note_value] = -1
			continue
		
		_note_value_row_map[note_value] = row_index
		_note_row_value_map[row_index] = note_value
		
		row_index += 1
		next_valid_note += _scale_layout[scale_index]
		scale_index += 1
		if scale_index >= scale_size:
			scale_index = 0


func _update_song_sizes() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	pattern_size = Controller.current_song.pattern_size
	bar_size = Controller.current_song.bar_size
	
	var available_rect := get_available_rect()
	
	# Round it up to the closes power-of-two, but no smaller than SMALLEST_PATTERN_SIZE.
	var effective_pattern_size := SMALLEST_PATTERN_SIZE
	while effective_pattern_size < pattern_size:
		effective_pattern_size <<= 1
	
	_note_width = available_rect.size.x / effective_pattern_size
	_overlay.note_unit_width = _note_width
	
	_resize_note_cursor(0)
	_update_active_notes()
	queue_redraw()


func _update_scrollables() -> void:
	_update_grid_layout()
	_update_active_notes()


func _update_whole_grid() -> void:
	_update_note_maps()
	_update_max_scroll_offset()
	_update_scrollables()


func _update_whole_grid_and_center() -> void:
	_update_note_maps()
	_update_max_scroll_offset()
	_center_scroll_offset()


func _update_whole_grid_and_reset_scroll() -> void:
	_update_note_maps()
	_update_max_scroll_offset()
	_reset_scroll_offset()


func _update_pattern_instrument() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song || not current_pattern:
		return
	
	var old_instrument_type := current_instrument.type if current_instrument else -1
	current_instrument = Controller.current_song.instruments[current_pattern.instrument_idx]
	theme = Controller.get_instrument_theme(current_instrument)
	
	if current_instrument.type == Instrument.InstrumentType.INSTRUMENT_DRUMKIT:
		_update_whole_grid_and_reset_scroll()
	elif old_instrument_type != current_instrument.type:
		_update_whole_grid_and_center()
	else:
		queue_redraw()
		_overlay.queue_redraw()


func _update_playback_cursor() -> void:
	if Engine.is_editor_hint():
		return
	
	# Only display the cursor when it's the current pattern that's playing.
	if not current_pattern || not current_pattern.is_playing:
		_overlay.playback_cursor_position = -1
		_overlay.queue_redraw()
		return
	
	var available_rect := get_available_rect()
	var playback_note_index := Controller.music_player.get_pattern_time()
	
	# If the player is stopped, park the cursor all the way to the left.
	# This is normally unreachable by playback, as when playing at index 0 we want
	# to display the cursor to the right of the first note.
	if playback_note_index < 0:
		_overlay.playback_cursor_position = available_rect.position.x
		_overlay.queue_redraw()
		return
	
	_overlay.playback_cursor_position = available_rect.position.x + playback_note_index * _note_width
	_overlay.queue_redraw()


# Grid layout and coordinates.

func _get_cell_at_cursor() -> Vector2i:
	var available_rect: Rect2 = get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	
	var mouse_position := get_local_mouse_position()
	if not available_rect.has_point(mouse_position):
		return Vector2i(-1, -1)
	
	var mouse_normalized := mouse_position - available_rect.position
	var cell_indexed := Vector2i(0, 0)
	cell_indexed.x = clampi(floori(mouse_normalized.x / _note_width), 0, pattern_size - 1)
	cell_indexed.y = clampi(floori((available_rect.size.y - mouse_normalized.y) / note_height), 0, _note_rows.size() - 1)
	return cell_indexed


func _get_cell_position(cell_indexed: Vector2i) -> Vector2:
	var available_rect := get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	
	return Vector2(
		available_rect.position.x + cell_indexed.x * _note_width,
		available_rect.size.y - (cell_indexed.y + 1) * note_height + available_rect.position.y
	)


func _update_grid_layout() -> void:
	# Reset collections.
	_note_rows.clear()
	_octave_rows.clear()

	var drumkit_instrument: DrumkitInstrument
	if current_instrument && current_instrument.type == Instrument.InstrumentType.INSTRUMENT_DRUMKIT:
		drumkit_instrument = current_instrument as DrumkitInstrument

	# Get reference data.
	var available_rect := get_available_rect()
	var scrollbar_available_rect: Rect2 = _scrollbar.get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	# Point of origin is at the bottom.
	var origin := Vector2(0, available_rect.size.y)

	var scale_size := _scale_layout.size()
	var current_key := current_pattern.key if current_pattern else 0

	# Iterate through all the notes and complete collections.
	
	var filled_height := 0
	var target_height := available_rect.size.y + Pattern.OCTAVE_SIZE * note_height # Give it some buffer.
	var row_index := 0
	var first_octave_index := -1
	var last_octave_index := -1
	
	# Keep rendering until we fill the screen, or reach the end of notes.
	while (row_index + _scroll_offset) < _note_row_value_map.size() && filled_height < target_height:
		var note_index: int = _note_row_value_map[row_index + _scroll_offset]
		var note_in_key := note_index % Pattern.OCTAVE_SIZE + current_key
		if note_in_key < 0:
			note_in_key = Pattern.OCTAVE_SIZE + note_in_key
		elif note_in_key >= Pattern.OCTAVE_SIZE:
			note_in_key = note_in_key - Pattern.OCTAVE_SIZE

		# Create data for a row of the grid, corresponding to one note value.
		
		var note := NoteRow.new()
		note.note_index = note_index
		note.label = Note.get_note_name(note_in_key)
		note.sharp = false
		note.position = origin - Vector2(0, row_index * note_height)
		note.grid_position = note.position + available_rect.position
		note.label_position = note.position + Vector2(0, -6)

		if note.label.ends_with("#"):
			note.sharp = true
		if drumkit_instrument:
			note.label = drumkit_instrument.get_note_name(note_index)
			note.sharp = (note_index + 1) % 2

		_note_rows.push_back(note)
		
		# Create data for octane rows that group spans of notes visually.
		# We do this as we go through notes, so we only create octaves which have visible notes
		# in them. Each unique octave is only created once.
		
		@warning_ignore("integer_division")
		var octave_index := note_index / Pattern.OCTAVE_SIZE
		if not drumkit_instrument && octave_index != last_octave_index:
			last_octave_index = octave_index
			if first_octave_index == -1:
				first_octave_index = octave_index
			
			var octave_ref_note := (last_octave_index - first_octave_index + 1) * scale_size - _scroll_offset % scale_size - 1
			
			var octave := OctaveRow.new()
			octave.octave_index = octave_index
			octave.position = origin - Vector2(0, octave_ref_note * note_height)
			octave.label_position = octave.position
			
			# Make the label position sticky.
			var prev_octave_position := origin - Vector2(0, (octave_ref_note - scale_size) * note_height)
			if (octave.position.y - note_height) < scrollbar_available_rect.position.y:
				if (prev_octave_position.y - note_height) > (scrollbar_available_rect.position.y + note_height):
					octave.label_position.y = scrollbar_available_rect.position.y + note_height
				else:
					octave.label_position.y = prev_octave_position.y - note_height
			
			octave.label_position += Vector2(0, -6)
			
			_octave_rows.push_back(octave)
		
		# Update counters.
		
		filled_height += note_height
		row_index += 1
	
	# Update children with the new data.
	_gutter.note_rows = _note_rows
	_scrollbar.octave_rows = _octave_rows
	_overlay.octave_rows = _octave_rows
	
	queue_redraw()
	_gutter.queue_redraw()
	_scrollbar.queue_redraw()
	_overlay.queue_redraw()


func _update_active_notes() -> void:
	# Reset the collection
	_active_notes.clear()
	if not current_pattern:
		_overlay.active_notes = _active_notes
		return

	for i in current_pattern.note_amount:
		var note_data := current_pattern.notes[i]
		if not current_pattern.is_note_valid(note_data, pattern_size):
			continue # Outside of the pattern bounds, or too short to play.
		
		var note_value_normalized := note_data.x - current_pattern.key # Shift to its C-key equivalent.
		if note_value_normalized < 0 || note_value_normalized >= _note_value_row_map.size():
			continue # Outside of the valid note range.
		
		var row_index: int = _note_value_row_map[note_value_normalized]
		if row_index < 0:
			continue # Doesn't fit the scale.
		
		var note := ActiveNote.new()
		note.note_value = note_value_normalized
		note.note_index = note_data.y
		note.position = _get_cell_position(Vector2i(note_data.y, row_index - _scroll_offset))
		note.length = note_data.z
		_active_notes.push_back(note)
	
	
	# Update children with the new data.
	_overlay.active_notes = _active_notes
	_overlay.queue_redraw()


# Note cursor and drawing.

func _show_note_cursor() -> void:
	_note_cursor_visible = true
	_process_note_cursor()
	set_physics_process(true)


func _hide_note_cursor() -> void:
	set_physics_process(false)
	_note_cursor_visible = false
	_process_note_cursor()


func _resize_note_cursor(delta: int) -> void:
	_note_cursor_size = clamp(_note_cursor_size + delta, 1, Pattern.MAX_NOTE_LENGTH)
	_overlay.note_cursor_size = _note_cursor_size
	_overlay.queue_redraw()


func _process_note_cursor() -> void:
	if not _note_cursor_visible:
		_overlay.note_cursor_position = Vector2(-1, -1)
		_overlay.queue_redraw()
		return
	
	var note_indexed := _get_cell_at_cursor()
	if note_indexed.x >= 0 && note_indexed.y >= 0:
		_overlay.note_cursor_position = _get_cell_position(note_indexed)
	else:
		_overlay.note_cursor_position = Vector2(-1, -1)
	
	_overlay.queue_redraw()


func _start_drawing_notes(mode: int) -> void:
	_note_drawing_mode = ValueValidator.index(mode, DrawingMode.MAX) as DrawingMode
	_process_note_drawing()


func _stop_drawing_notes() -> void:
	_note_drawing_mode = DrawingMode.DRAWING_OFF


func _process_note_drawing() -> void:
	if _note_drawing_mode == DrawingMode.DRAWING_ADD:
		_add_note_at_cursor()
	elif _note_drawing_mode == DrawingMode.DRAWING_REMOVE:
		_remove_note_at_cursor()


func _add_note_at_cursor() -> void:
	if not Controller.current_song || not current_pattern:
		return

	var note_indexed := _get_cell_at_cursor()
	if note_indexed.x < 0 || note_indexed.y < 0:
		return
	var note_value_index := note_indexed.y + _scroll_offset
	if note_value_index >= _note_row_value_map.size():
		return
	
	var note_value: int = _note_row_value_map[note_value_index] + current_pattern.key
	if current_pattern.has_note(note_value, note_indexed.x, true):
		return # Space is already occupied.
	
	var note_data := Vector3i(note_value, note_indexed.x, _note_cursor_size)
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.add_note(note_data.x, note_data.y, note_data.z)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.remove_note(note_data.x, note_data.y, true)
	)
	
	Controller.state_manager.commit_state_change(pattern_state)


func _remove_note_at_cursor() -> void:
	if not Controller.current_song || not current_pattern:
		return

	var note_indexed := _get_cell_at_cursor()
	if note_indexed.x < 0 || note_indexed.y < 0:
		return
	var note_value_index := note_indexed.y + _scroll_offset
	if note_value_index >= _note_row_value_map.size():
		return
	
	var note_value: int = _note_row_value_map[note_value_index] + current_pattern.key
	if not current_pattern.has_note(note_value, note_indexed.x, true):
		return # Space is empty.
	
	var note_data := Vector3i(note_value, note_indexed.x, 0)
	note_data.z = current_pattern.get_note_length(note_data.x, note_data.y)
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.remove_note(note_data.x, note_data.y, true)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.add_note(note_data.x, note_data.y, note_data.z)
	)
	
	Controller.state_manager.commit_state_change(pattern_state)


func _preview_note_at_cursor(row_index: int) -> void:
	if not Controller.current_song || not current_pattern:
		return

	var note := _note_rows[row_index]
	var note_value := note.note_index + current_pattern.key
	Controller.preview_pattern_note(note_value, _note_cursor_size)


class NoteRow:
	var note_index: int = -1
	var label: String = ""
	var sharp: bool = false
	var position: Vector2 = Vector2.ZERO
	var grid_position: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO


class OctaveRow:
	var octave_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO


class ActiveNote:
	var note_value: int = -1
	var note_index: int = -1
	var position: Vector2 = Vector2.ZERO
	var length: int = 1
