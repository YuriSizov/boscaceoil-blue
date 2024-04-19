###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control


func _draw() -> void:
	var background_color := get_theme_color("dock_color", "PatternMap")
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
