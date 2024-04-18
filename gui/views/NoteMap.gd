###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name NoteMap extends Control

const NOTE_BASE_COLOR := Color(0.23137255012989, 0.15294118225574, 0.93333333730698)
const NOTE_SHARP_COLOR := Color(0.16862745583057, 0.1294117718935, 0.59215688705444)
const BORDER_COLOR := Color(0.01960784383118, 0.0274509806186, 0.12549020349979)

const OCTAVE_SIZE := 12

enum DrawingMode {
	DRAWING_OFF,
	DRAWING_ADD,
	DRAWING_REMOVE,
	MAX
}

## Current edited pattern.
var current_pattern: Pattern = null
## Number of rows in the piano roll.
var note_count: int = 128:
	set(value):
		note_count = value
		_update_scroll_offset()
## Number of notes in a row.
var pattern_size: int = 1
## Number of notes in a bar.
var bar_size: int = 1

## Window-dependent horizontal size of a note, based on pattern_size.
var _note_width: float = 0

## Offset, in number of note rows.
var scroll_offset: int = 0
## Window-size dependent limit, based on note_count
var _max_scroll_offset: int = -1

var _note_rows: Array[NoteRow] = []
var _octave_rows: Array[OctaveRow] = []
var _active_notes: Array[ActiveNote] = []
var _note_cursor_visible: bool = false
var _note_cursor_size: int = 1
var _note_drawing_mode: DrawingMode = DrawingMode.DRAWING_OFF

@onready var _gutter: Control = $NoteMapGutter
@onready var _scrollbar: Control = $NoteMapScrollbar
@onready var _overlay: Control = $NoteMapOverlay


func _ready() -> void:
	set_physics_process(false)
	
	_update_note_width()
	_update_scroll_offset()
	_update_playback_cursor()
	resized.connect(_update_note_width)
	resized.connect(_update_scroll_offset)
	resized.connect(_update_playback_cursor)
	
	mouse_entered.connect(_show_note_cursor)
	mouse_exited.connect(_hide_note_cursor)

	_scrollbar.shifted_up.connect(_change_offset.bind(1))
	_scrollbar.shifted_down.connect(_change_offset.bind(-1))
	
	_update_pattern_size()
	_edit_current_pattern()
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_update_pattern_size)
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_update_pattern_size)
		Controller.music_player.playback_tick.connect(_update_playback_cursor)
		Controller.music_player.playback_stopped.connect(_update_playback_cursor)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if _note_cursor_visible && event.is_pressed():
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_resize_note_cursor(1)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_resize_note_cursor(-1)
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				_start_drawing_notes(DrawingMode.DRAWING_ADD)
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_start_drawing_notes(DrawingMode.DRAWING_REMOVE)
		
		if _note_drawing_mode != DrawingMode.DRAWING_OFF && !event.is_pressed():
			if mb.button_index == MOUSE_BUTTON_LEFT || mb.button_index == MOUSE_BUTTON_RIGHT:
				_stop_drawing_notes()


func _physics_process(_delta: float) -> void:
	_update_note_cursor()
	_draw_note()


func _draw() -> void:
	_update_grid()

	var available_rect := get_available_rect()
	# Point of origin is at the bottom.
	var origin := Vector2(available_rect.position.x, available_rect.size.y)
	var note_height := get_theme_constant("note_height", "NoteMap")
	var border_width := get_theme_constant("border_width", "NoteMap")

	# Draw the rows.
	for note in _note_rows:
		var note_position := note.grid_position - Vector2(0, note_height)
		var note_size := Vector2(available_rect.size.x, note_height)
		var note_color := NOTE_SHARP_COLOR if note.sharp else NOTE_BASE_COLOR
		draw_rect(Rect2(note_position, note_size), note_color)

	# Draw horizontal lines.
	for note in _note_rows:
		var border_size := Vector2(available_rect.size.x, border_width)
		draw_rect(Rect2(note.grid_position, border_size), BORDER_COLOR)

	# Draw vertical lines.
	var col_index := 0
	var last_col_x := 0
	while col_index < (pattern_size + 1):
		var col_position := origin + Vector2(_note_width * col_index, -available_rect.size.y)
		var border_size := Vector2(border_width, available_rect.size.y)
		if col_index % bar_size == 0: # Draw bars twice as thick.
			border_size.x = border_width * 2

		draw_rect(Rect2(col_position, border_size), BORDER_COLOR)
		
		col_index += 1
		last_col_x = col_position.x
	
	# Draw an extra cover on top of inactive bars.
	if last_col_x < available_rect.end.x:
		var cover_position := Vector2(last_col_x, origin.y - available_rect.size.y)
		var cover_size := Vector2(available_rect.end.x - last_col_x, available_rect.size.y)
		var cover_alpha := float(get_theme_constant("border_cover_opacity", "NoteMap")) / 100.0
		var cover_color := Color(BORDER_COLOR, cover_alpha)
		
		draw_rect(Rect2(cover_position, cover_size), cover_color)


# Drawables and visuals.

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


func _update_note_width() -> void:
	var available_rect := get_available_rect()
	var effective_pattern_size := 16 if pattern_size <= 16 else 32
	
	_note_width = available_rect.size.x / effective_pattern_size
	_overlay.note_unit_width = _note_width
	
	queue_redraw()
	_overlay.queue_redraw()


func _update_pattern_size() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	pattern_size = Controller.current_song.pattern_size
	bar_size = Controller.current_song.bar_size
	_update_note_width()
	_update_active_notes()


func _change_offset(delta: int) ->  void:
	scroll_offset += delta

	scroll_offset = clamp(scroll_offset, 0, _max_scroll_offset)
	_update_active_notes()
	queue_redraw()
	_gutter.queue_redraw()
	_scrollbar.queue_redraw()
	_overlay.queue_redraw()


func _update_scroll_offset() -> void:
	_max_scroll_offset = note_count

	var available_rect := get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	var notes_on_screen := floori(available_rect.size.y / note_height)
	_max_scroll_offset -= notes_on_screen - 1

	scroll_offset = clamp(scroll_offset, 0, _max_scroll_offset)
	_update_active_notes()
	queue_redraw()
	_gutter.queue_redraw()
	_scrollbar.queue_redraw()
	_overlay.queue_redraw()


func _update_grid() -> void:
	# Reset collections.
	_note_rows.clear()
	_octave_rows.clear()

	# Get reference data.
	var available_rect := get_available_rect()
	var scrollbar_available_rect: Rect2 = _scrollbar.get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	# Point of origin is at the bottom.
	var origin := Vector2(0, available_rect.size.y)

	# Iterate through all the notes and complete collections.
	var filled_height := 0
	var index := 0
	var first_octave_index := -1
	var last_octave_index := -1
	while filled_height < (available_rect.size.y + OCTAVE_SIZE * note_height): # Give it some buffer.
		var note_index: int = index + scroll_offset
		if note_index > note_count:
			break

		var note_normalized := note_index % OCTAVE_SIZE
		var note_names := [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ]

		# Create note row data.
		var note := NoteRow.new()
		note.note_index = note_index
		note.label = note_names[note_normalized]
		note.sharp = false
		note.position = origin - Vector2(0, index * note_height)
		note.grid_position = note.position + Vector2(available_rect.position.x, 0)
		note.label_position = note.position + Vector2(0, -6)

		if note.label.ends_with("#"):
			note.sharp = true

		_note_rows.push_back(note)
		
		# Create octave row data.
		@warning_ignore("integer_division")
		var octave_index := note_index / OCTAVE_SIZE
		if octave_index != last_octave_index:
			last_octave_index = octave_index
			if first_octave_index == -1:
				first_octave_index = octave_index
			
			var octave_ref_note := (last_octave_index - first_octave_index + 1) * OCTAVE_SIZE - scroll_offset % 12 - 1
			
			var octave := OctaveRow.new()
			octave.octave_index = octave_index
			octave.position = origin - Vector2(0, octave_ref_note * note_height)
			octave.label_position = octave.position
			
			# Make the label position sticky.
			var prev_octave_position := origin - Vector2(0, (octave_ref_note - OCTAVE_SIZE) * note_height)
			if (octave.position.y - note_height) < scrollbar_available_rect.position.y:
				if (prev_octave_position.y - note_height) > (scrollbar_available_rect.position.y + note_height):
					octave.label_position.y = scrollbar_available_rect.position.y + note_height
				else:
					octave.label_position.y = prev_octave_position.y - note_height
			
			octave.label_position += Vector2(0, -6)
			
			_octave_rows.push_back(octave)
		
		# Update counters.
		filled_height += note_height
		index += 1
	
	# Update children with the new data.
	_gutter.note_rows = _note_rows
	_scrollbar.octave_rows = _octave_rows
	_overlay.octave_rows = _octave_rows


func _get_note_at_cursor() -> Vector2i:
	var available_rect: Rect2 = get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	
	var mouse_position := get_local_mouse_position()
	if available_rect.has_point(mouse_position):
		var mouse_normalized := mouse_position - available_rect.position
		var note_indexed := Vector2i(0,0)
		note_indexed.x = clampi(floori(mouse_normalized.x / _note_width), 0, pattern_size - 1)
		note_indexed.y = floori((available_rect.size.y - mouse_normalized.y) / note_height)
		return note_indexed

	return Vector2i(-1, -1)


func _get_indexed_note_position(indexed: Vector2i) -> Vector2:
	var available_rect := get_available_rect()
	var note_height := get_theme_constant("note_height", "NoteMap")
	
	return Vector2(
		available_rect.position.x + indexed.x * _note_width,
		available_rect.size.y - (indexed.y + 1) * note_height + available_rect.position.y
	)


func _update_active_notes() -> void:
	# Reset the collection
	_active_notes.clear()
	if not current_pattern:
		_overlay.active_notes = _active_notes
		return

	for i in current_pattern.note_amount:
		var note_data := current_pattern.notes[i]
		if note_data.x < 0 || note_data.y < 0 || note_data.y >= pattern_size || note_data.z < 1:
			continue # Outside of the grid, or too short.
		var note_value := note_data.x - scroll_offset
		
		var note := ActiveNote.new()
		note.note_value = note_data.x
		note.note_index = note_data.y
		note.position = _get_indexed_note_position(Vector2i(note_data.y, note_value))
		note.length = note_data.z
		_active_notes.push_back(note)
	
	
	# Update children with the new data.
	_overlay.active_notes = _active_notes


func _update_playback_cursor() -> void:
	if Engine.is_editor_hint():
		return
	
	var available_rect := get_available_rect()
	
	# If the player is paused or stopped, park the cursor on the leftmost bar.
	# This is normally unreachable for normal playback, as at index 0 we want
	# to display the cursor to the right of the first note.
	if not Controller.music_player.is_playing():
		_overlay.playback_cursor_position = available_rect.position.x
		_overlay.queue_redraw()
		return
	
	var playback_note_index := Controller.music_player.get_pattern_time()
	_overlay.playback_cursor_position = available_rect.position.x + playback_note_index * _note_width
	_overlay.queue_redraw()


func _show_note_cursor() -> void:
	_note_cursor_visible = true
	_update_note_cursor()
	set_physics_process(true)


func _hide_note_cursor() -> void:
	set_physics_process(false)
	_note_cursor_visible = false
	_update_note_cursor()


func _resize_note_cursor(delta: int) -> void:
	_note_cursor_size = clamp(_note_cursor_size + delta, 1, pattern_size)
	_overlay.note_cursor_size = _note_cursor_size
	_overlay.queue_redraw()


func _update_note_cursor() -> void:
	if not _note_cursor_visible:
		_overlay.note_cursor_position = Vector2(-1, -1)
		_overlay.queue_redraw()
		return
	
	var note_indexed := _get_note_at_cursor()
	if note_indexed.x >= 0 && note_indexed.y >= 0:
		_overlay.note_cursor_position = _get_indexed_note_position(note_indexed)
	else:
		_overlay.note_cursor_position = Vector2(-1, -1)
	
	_overlay.queue_redraw()


# Logic and editing.

func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	current_pattern = Controller.get_current_pattern()
	_update_active_notes()
	queue_redraw()
	_overlay.queue_redraw()


func _start_drawing_notes(mode: int) -> void:
	_note_drawing_mode = ValueValidator.index(mode, DrawingMode.MAX) as DrawingMode
	_draw_note()


func _stop_drawing_notes() -> void:
	_note_drawing_mode = DrawingMode.DRAWING_OFF


func _draw_note() -> void:
	if _note_drawing_mode == DrawingMode.DRAWING_ADD:
		_add_note_at_cursor()
	elif _note_drawing_mode == DrawingMode.DRAWING_REMOVE:
		_remove_note_at_cursor()


func _add_note_at_cursor() -> void:
	if not current_pattern:
		return
	var note_indexed := _get_note_at_cursor()
	if note_indexed.x < 0 || note_indexed.y < 0:
		return
	
	var note_value := note_indexed.y + scroll_offset
	if current_pattern.has_note(note_value, note_indexed.x, true):
		return # Space is already occupied.
	
	current_pattern.add_note(note_value, note_indexed.x, _note_cursor_size)
	_update_active_notes()
	_overlay.queue_redraw()


func _remove_note_at_cursor() -> void:
	if not current_pattern:
		return
	var note_indexed := _get_note_at_cursor()
	if note_indexed.x < 0 || note_indexed.y < 0:
		return
	
	var note_value := note_indexed.y + scroll_offset
	current_pattern.remove_note(note_value, note_indexed.x, true)
	_update_active_notes()
	_overlay.queue_redraw()


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
