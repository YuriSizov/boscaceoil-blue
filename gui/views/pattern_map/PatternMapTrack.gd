###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

var pattern_cols: Array[PatternMap.PatternCol] = []


func _draw() -> void:
	var background_color := get_theme_color("track_color", "PatternMap")
	var border_color := get_theme_color("track_border_color", "PatternMap")
	var border_width := get_theme_constant("border_width", "PatternMap")
	
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	
	# Draw vertical lines.
	for pattern in pattern_cols:
		var col_position := pattern.grid_position
		var border_size := Vector2(border_width, size.y)
		draw_rect(Rect2(col_position, border_size), border_color)

