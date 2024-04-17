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

## Number of rows in the piano roll.
var note_count: int = 128:
	set(value):
		note_count = value
		_update_scroll_offset()
## Number of notes in a row.
var pattern_size: int = 16
## Number of notes in a bar.
var bar_size: int = 4

## Offset, in number of note rows.
var scroll_offset: int = 0
## Window-size dependent limit, based on note_count
var _max_scroll_offset: int = -1

var _note_rows: Array[NoteRow] = []
var _octave_rows: Array[OctaveRow] = []
var _note_cursor_visible: bool = false

@onready var _gutter: Control = $NoteMapGutter
@onready var _scrollbar: Control = $NoteMapScrollbar
@onready var _overlay: Control = $NoteMapOverlay


func _ready() -> void:
	set_process(false)
	
	_update_scroll_offset()
	resized.connect(_update_scroll_offset)
	
	mouse_entered.connect(_show_note_cursor)
	mouse_exited.connect(_hide_note_cursor)

	_scrollbar.shifted_up.connect(_change_offset.bind(1))
	_scrollbar.shifted_down.connect(_change_offset.bind(-1))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_overlay.resize_note_cursor(1)
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_overlay.resize_note_cursor(-1)


func _process(_delta: float) -> void:
	_update_note_cursor()


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
	var note_width := available_rect.size.x / pattern_size
	var col_index := 0
	while col_index < pattern_size:
		var col_position := origin + Vector2(note_width * col_index, -available_rect.size.y)
		var border_size := Vector2(border_width, available_rect.size.y)
		if col_index % bar_size == 0: # Draw bars twice as thick.
			border_size.x = border_width * 2

		draw_rect(Rect2(col_position, border_size), BORDER_COLOR)
		col_index += 1


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


func _change_offset(delta: int) ->  void:
	scroll_offset += delta

	scroll_offset = clamp(scroll_offset, 0, _max_scroll_offset)
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


func _show_note_cursor() -> void:
	_note_cursor_visible = true
	_update_note_cursor()
	set_process(true)


func _hide_note_cursor() -> void:
	set_process(false)
	_note_cursor_visible = false
	_update_note_cursor()


func _update_note_cursor() -> void:
	if not _note_cursor_visible:
		_overlay.note_cursor_unit_width = 0
		_overlay.note_cursor_position = Vector2(-1, -1)
		_overlay.queue_redraw()
		return
	
	var available_rect: Rect2 = get_available_rect()
	var note_width := available_rect.size.x / pattern_size
	var note_height := get_theme_constant("note_height", "NoteMap")
	
	var mouse_position := get_local_mouse_position()
	if available_rect.has_point(mouse_position):
		var mouse_normalized := mouse_position - available_rect.position
		var note_indexed := Vector2i(0,0)
		note_indexed.x = floori(mouse_normalized.x / note_width)
		note_indexed.y = floori((available_rect.size.y - mouse_normalized.y) / note_height)
		
		_overlay.note_cursor_unit_width = note_width
		_overlay.note_cursor_position = Vector2(
			note_indexed.x * note_width + available_rect.position.x,
			available_rect.size.y - (note_indexed.y + 1) * note_height + available_rect.position.y
		)
	else:
		_overlay.note_cursor_unit_width = 0
		_overlay.note_cursor_position = Vector2(-1, -1)
	
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
