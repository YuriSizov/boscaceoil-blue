###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control


func _draw() -> void:
	# Draw the background.
	var background_pattern := get_theme_stylebox("background_pattern", "PadSlider")
	draw_style_box(background_pattern, Rect2(Vector2.ZERO, size))
	
	# Draw the cursor.
	
	var cursor_color := get_theme_color("cursor_color", "PadSlider")
	var cursor_outline_color := get_theme_color("cursor_outline_color", "PadSlider")
	var cursor_width := get_theme_constant("cursor_size", "PadSlider")
	var cursor_outline_width := get_theme_constant("cursor_outline_width", "PadSlider")
	
	var cursor_position := Vector2.ZERO
	var cursor_inner_position := cursor_position + Vector2(cursor_outline_width, cursor_outline_width)
	var cursor_size := Vector2(cursor_width, cursor_width)
	var cursor_inner_size := cursor_size - 2 * Vector2(cursor_outline_width, cursor_outline_width)
	
	draw_rect(Rect2(cursor_position, cursor_size), cursor_outline_color)
	draw_rect(Rect2(cursor_inner_position, cursor_inner_size), cursor_color)
