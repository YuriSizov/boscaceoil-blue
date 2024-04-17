###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const OCTAVE_BAR_INSET := 40

var octave_rows: Array[NoteMap.OctaveRow] = []
var playback_cursor_position: int = -1
var note_cursor_size: int = 1
var note_cursor_unit_width: float = 0
var note_cursor_position: Vector2 = Vector2i(-1, -1)


func _draw() -> void:
	var note_height := get_theme_constant("note_height", "NoteMap")
	var border_width := get_theme_constant("border_width", "NoteMap")

	# Draw octave bars.
	
	var octave_bar_color := get_theme_color("octave_bar_color", "NoteMap")
	var octave_bar_shadow := get_theme_color("octave_bar_shadow_color", "NoteMap")
	
	for octave in octave_rows:
		var bar_position := octave.position + Vector2(OCTAVE_BAR_INSET, -(note_height + border_width / 2))
		var bar_size := Vector2(size.x - OCTAVE_BAR_INSET, border_width)

		var shadow_position := bar_position + Vector2(0, 2)
		draw_rect(Rect2(shadow_position, bar_size), octave_bar_shadow)
		draw_rect(Rect2(bar_position, bar_size), octave_bar_color)
	
	# Draw the playback cursor.
	
	pass
	
	# Draw the note cursor.
	
	if note_cursor_unit_width > 0 && note_cursor_position.x >= 0 && note_cursor_position.y >= 0:
		var note_position := note_cursor_position + Vector2(border_width / 2, border_width / 2)
		var note_size := Vector2(note_cursor_unit_width * note_cursor_size, note_height) - Vector2(border_width, border_width)
		var note_cursor_color := get_theme_color("note_cursor_color", "NoteMap")
		var note_cursor_width := get_theme_constant("note_cursor_width", "NoteMap")

		draw_rect(Rect2(note_position, note_size), note_cursor_color, false, note_cursor_width)
		
		# Draw the size in the box if it goes off screen.
		if (note_position.x + note_size.x) >= size.x:
			var font := get_theme_default_font()
			var font_size := get_theme_default_font_size()
			var font_color := get_theme_color("font_color", "Label")
			var shadow_color := get_theme_color("shadow_color", "Label")
			var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
			
			var string_position := note_position + Vector2(8, note_height - 8)
			var shadow_position := string_position + shadow_size

			var cursor_label := "%d" % note_cursor_size
			draw_string(font, shadow_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
			draw_string(font, string_position, cursor_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)



func resize_note_cursor(delta: int) -> void:
	var max_size: int = get_parent().pattern_size
	note_cursor_size = clamp(note_cursor_size + delta, 1, max_size)
	queue_redraw()
