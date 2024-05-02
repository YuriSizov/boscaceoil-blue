###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

var pattern_height: float = 0
var pattern_width: float = 0
var playback_cursor_position: float = -1
var pattern_cursor_position: Vector2 = Vector2i(-1, -1)


func _draw() -> void:
	var border_width := get_theme_constant("border_width", "PatternMap")
	var half_border_width := float(border_width) / 2.0
	
	# Draw active patterns.
	
	# Draw the playback cursor.
	
	if playback_cursor_position >= 0:
		var playback_cursor_width := get_theme_constant("playback_cursor_width", "NoteMap")

		var cursor_position := Vector2(playback_cursor_position, 0)
		var cursor_size := Vector2(playback_cursor_width, size.y)
		var cursor_color := get_theme_color("playback_cursor_color", "NoteMap")
		
		var half_cursor_width := float(playback_cursor_width) / 2.0
		var cursor_bevel_position := Vector2(playback_cursor_position + half_cursor_width, 0)
		var cursor_bevel_size := Vector2(half_cursor_width, size.y)
		var cursor_bevel_color := get_theme_color("playback_cursor_bevel_color", "NoteMap")
		
		draw_rect(Rect2(cursor_position, cursor_size), cursor_color)
		draw_rect(Rect2(cursor_bevel_position, cursor_bevel_size), cursor_bevel_color)
	
	# Draw the pattern cursor.
	
	if pattern_width > 0 && pattern_cursor_position.x >= 0 && pattern_cursor_position.y >= 0:
		var pattern_position := pattern_cursor_position + Vector2(half_border_width, half_border_width)
		var pattern_size := Vector2(pattern_width, pattern_height) - Vector2(border_width, border_width)
		var pattern_cursor_color := get_theme_color("note_cursor_color", "NoteMap")
		var pattern_cursor_width := get_theme_constant("note_cursor_width", "NoteMap")

		draw_rect(Rect2(pattern_position, pattern_size), pattern_cursor_color, false, pattern_cursor_width)
