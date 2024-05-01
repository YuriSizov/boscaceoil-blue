###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends ItemDock

## Current edited pattern.
var current_pattern: Pattern = null

# Theme cache.

var _font: Font = null
var _font_size: int = -1
var _font_color: Color = Color.WHITE
var _shadow_color: Color = Color.WHITE
var _shadow_size: Vector2 = Vector2.ZERO

var _item_height: int = -1
var _item_gutter_size: Vector2 = Vector2.ZERO

var _note_border_width: int = 0
var _note_color: Color = Color.WHITE


func _ready() -> void:
	super()
	
	_edit_current_pattern()
	
	if not Engine.is_editor_hint():
		item_created.connect(Controller.create_and_edit_pattern)
		item_selected.connect(Controller.edit_pattern)
		item_deleted.connect(Controller.delete_pattern)

		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		Controller.song_instrument_changed.connect(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()


func _update_theme() -> void:
	_font = get_theme_default_font()
	_font_size = get_theme_default_font_size()
	_font_color = get_theme_color("font_color", "Label")
	_shadow_color = get_theme_color("shadow_color", "Label")
	_shadow_size = Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	
	_item_height = get_theme_constant("item_height", "ItemDock")
	_item_gutter_size = _font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size) + Vector2(20, 0)
	_item_gutter_size.y = _item_height
	
	_note_border_width = get_theme_constant("note_border_width", "PatternMap")
	_note_color = get_theme_color("active_note_color", "NoteMap")


func _draw_item(on_control: Control, item_index: int, item_rect: Rect2) -> void:
	var pattern := Controller.current_song.patterns[item_index]
	var instrument := Controller.current_song.instruments[pattern.instrument_idx]

	var note_area := Rect2(
		item_rect.position + Vector2(_item_gutter_size.x + _note_border_width, _note_border_width),
		Vector2(item_rect.size.x - _item_gutter_size.x - 2 * _note_border_width, item_rect.size.y - 2 * _note_border_width)
	)
	
	# Draw instrument-themed background and gutter.

	var item_theme := Controller.get_instrument_theme(instrument)
	var item_color := item_theme.get_color("item_color", "InstrumentDock")
	var item_gutter_color := item_theme.get_color("item_gutter_color", "InstrumentDock")
	
	on_control.draw_rect(item_rect, item_gutter_color)
	on_control.draw_rect(note_area, item_color)
	
	var label_underline := Rect2(
		item_rect.position + Vector2(0, 3.0 * _item_height / 5.0),
		Vector2(_item_gutter_size.x - _note_border_width, 2.0 * _item_height / 5.0)
	)
	on_control.draw_rect(label_underline, item_color)

	# Draw gutter string.
	
	var string_position := item_rect.position + Vector2(8, item_rect.size.y - 10)
	var shadow_position := string_position + _shadow_size
	var gutter_string := "%d" % [ item_index + 1 ]
	on_control.draw_string(_font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
	on_control.draw_string(_font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)

	# Draw pattern note map.
	
	if pattern.note_amount > 0:
		var note_span := pattern.get_active_note_span_size()
		var note_width := note_area.size.x / Controller.current_song.pattern_size
		var note_height := note_area.size.y / note_span
		
		var note_origin := note_area.position
		var note_span_height := note_area.size.y
		
		# If the span is too small, adjust everything to center the notes.
		if note_height > _note_border_width:
			note_height = _note_border_width
			note_span_height = note_height * note_span
			note_origin.y += (note_area.size.y - note_span_height) / 2.0
		
		var note_value_offset := pattern.active_note_span[0]
		
		for i in pattern.note_amount:
			var note := pattern.notes[i]
			var note_index := note.x - note_value_offset
			var note_position := note_origin + Vector2(note_width * note.y, note_span_height - note_height * (note_index + 1))
			var note_size := Vector2(note_width * note.z, note_height)
			
			on_control.draw_rect(Rect2(note_position, note_size), _note_color)


# Data.

func _get_total_item_amount() -> int:
	if Engine.is_editor_hint() || not Controller.current_song:
		return 0
	
	return Controller.current_song.patterns.size()


func _get_current_item_index() -> int:
	if Engine.is_editor_hint() || not Controller.current_song:
		return -1
	
	return Controller.current_pattern_index


func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_pattern:
		current_pattern.instrument_changed.disconnect(queue_redraw)
		current_pattern.notes_changed.disconnect(queue_redraw)
	
	current_pattern = Controller.get_current_pattern()

	if current_pattern:
		current_pattern.instrument_changed.connect(queue_redraw)
		current_pattern.notes_changed.connect(queue_redraw)
	
	queue_redraw()
