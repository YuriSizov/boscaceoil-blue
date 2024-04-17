###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

var note_rows: Array[NoteMap.NoteRow] = []


func _draw() -> void:
	# Draw background.
	var gutter_rect := Rect2(Vector2.ZERO, size)
	draw_rect(gutter_rect, get_theme_color("gutter_color", "NoteMap"))

	# Draw note labels.
	
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var font_color := get_theme_color("font_color", "Label")
	var shadow_color := get_theme_color("shadow_color", "Label")
	var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))

	for note in note_rows:
		var string_position := note.label_position + Vector2(8, 0)
		var shadow_position := string_position + shadow_size

		draw_string(font, shadow_position, note.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
		draw_string(font, string_position, note.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)
