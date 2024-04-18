###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const OCTAVE_BAR_INSET := 40

var note_unit_width: float = 0

var octave_rows: Array[NoteMap.OctaveRow] = []
var active_notes: Array[NoteMap.ActiveNote] = []
var playback_cursor_position: float = -1
var note_cursor_size: int = 1
var note_cursor_position: Vector2 = Vector2i(-1, -1)


func _draw() -> void:
	var note_height := get_theme_constant("note_height", "NoteMap")
	var border_width := get_theme_constant("border_width", "NoteMap")

	var label_font := get_theme_default_font()
	var label_font_size := get_theme_default_font_size()
	var label_font_color := get_theme_color("font_color", "Label")
	var label_shadow_color := get_theme_color("shadow_color", "Label")
	var label_shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))

	# Draw octave bars.
	
	var octave_bar_color := get_theme_color("octave_bar_color", "NoteMap")
	var octave_bar_shadow := get_theme_color("octave_bar_shadow_color", "NoteMap")
	
	for octave in octave_rows:
		var bar_position := octave.position + Vector2(OCTAVE_BAR_INSET, -(note_height + border_width / 2))
		var bar_size := Vector2(size.x - OCTAVE_BAR_INSET, border_width)

		var shadow_position := bar_position + Vector2(0, 2)
		draw_rect(Rect2(shadow_position, bar_size), octave_bar_shadow)
		draw_rect(Rect2(bar_position, bar_size), octave_bar_color)
	
	# Draw active notes.

	var note_color := get_theme_color("active_note_color", "NoteMap")
	var note_bevel_width := get_theme_constant("active_note_bevel_width", "NoteMap")
	var note_bevel_color := get_theme_color("active_note_bevel_color", "NoteMap")
	var note_overlap_texture := get_theme_icon("active_note_overlap", "NoteMap")
	var note_overlap_opacity := get_theme_constant("active_note_overlap_opacity", "NoteMap")

	var last_active_value := -1
	var spanning_active_indices := PackedInt32Array()
	for active_note in active_notes:
		# Make sure we don't track notes from other rows.
		if last_active_value != active_note.note_value:
			last_active_value = active_note.note_value
			spanning_active_indices.clear()
		
		var note_bevel_position := active_note.position + Vector2(border_width / 2, border_width / 2)
		var note_bevel_size := Vector2(note_unit_width * active_note.length, note_height)
		var note_position := note_bevel_position + Vector2(border_width, 0)
		var note_size := note_bevel_size - Vector2(note_bevel_width + border_width, note_bevel_width)

		draw_rect(Rect2(note_bevel_position, note_bevel_size), note_bevel_color)
		draw_rect(Rect2(note_position, note_size), note_color)
		
		# Check for overlaps with previous notes.
		var overlaps_with_index := -1
		for spanning_index in spanning_active_indices:
			# Check if there is a note that goes beyond this note's starting point; only track the longest overlap.
			if spanning_index > active_note.note_index && overlaps_with_index < spanning_index:
				overlaps_with_index = spanning_index
			# Check if we are beyond the bounds of the current note; that's far enough.
			if overlaps_with_index > (active_note.note_index + active_note.length):
				break
		
		if overlaps_with_index >= 0:
			var overlap_length := overlaps_with_index - active_note.note_index
			overlap_length = min(overlap_length, active_note.length)
			var overlap_position := note_position
			var overlap_size := Vector2(note_unit_width * overlap_length, note_height) - Vector2(note_bevel_width + border_width, note_bevel_width)
			var overlap_alpha := float(note_overlap_opacity) / 100.0
			draw_texture_rect(note_overlap_texture, Rect2(overlap_position, overlap_size), true, Color(1, 1, 1, overlap_alpha))
		
		if active_note.length > 1:
			spanning_active_indices.push_back(active_note.note_index + active_note.length)
		
		
		# Draw the size in the box if it goes off screen.
		if (note_position.x + note_size.x) >= size.x:
			var string_position := note_position + Vector2(8, note_height - 8)
			var shadow_position := string_position + label_shadow_size

			var cursor_label := "%d" % active_note.length
			# Colors are inverted on purpose, because the background is light here.
			draw_string(label_font, shadow_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_font_color)
			draw_string(label_font, string_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_shadow_color)
	
	# Draw the playback cursor.
	
	if playback_cursor_position >= 0:
		var playback_cursor_width := get_theme_constant("playback_cursor_width", "NoteMap")

		var cursor_position := Vector2(playback_cursor_position, 0)
		var cursor_size := Vector2(playback_cursor_width, size.y)
		var cursor_color := get_theme_color("playback_cursor_color", "NoteMap")
		
		var cursor_bevel_position := Vector2(playback_cursor_position + playback_cursor_width / 2, 0)
		var cursor_bevel_size := Vector2(playback_cursor_width / 2, size.y)
		var cursor_bevel_color := get_theme_color("playback_cursor_bevel_color", "NoteMap")
		
		draw_rect(Rect2(cursor_position, cursor_size), cursor_color)
		draw_rect(Rect2(cursor_bevel_position, cursor_bevel_size), cursor_bevel_color)
	
	# Draw the note cursor.
	
	if note_unit_width > 0 && note_cursor_position.x >= 0 && note_cursor_position.y >= 0:
		var note_position := note_cursor_position + Vector2(border_width / 2, border_width / 2)
		var note_size := Vector2(note_unit_width * note_cursor_size, note_height) - Vector2(border_width, border_width)
		var note_cursor_color := get_theme_color("note_cursor_color", "NoteMap")
		var note_cursor_width := get_theme_constant("note_cursor_width", "NoteMap")

		draw_rect(Rect2(note_position, note_size), note_cursor_color, false, note_cursor_width)
		
		# Draw the size in the box if it goes off screen.
		if (note_position.x + note_size.x) >= size.x:
			var string_position := note_position + Vector2(8, note_height - 8)
			var shadow_position := string_position + label_shadow_size

			var cursor_label := "%d" % note_cursor_size
			draw_string(label_font, shadow_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_shadow_color)
			draw_string(label_font, string_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_font_color)
