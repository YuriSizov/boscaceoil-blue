###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

var active_patterns: Array[PatternMap.ActivePattern] = []

# Theme cache.

var _font: Font = null
var _font_size: int = -1
var _font_color: Color = Color.WHITE
var _shadow_color: Color = Color.WHITE
var _shadow_size: Vector2 = Vector2.ZERO

var _note_color: Color = Color.WHITE


func _ready() -> void:
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme() -> void:
	_font = get_theme_default_font()
	_font_size = get_theme_default_font_size()
	_font_color = get_theme_color("font_color", "Label")
	_shadow_color = get_theme_color("shadow_color", "Label")
	_shadow_size = Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	
	_note_color = get_theme_color("active_note_color", "NoteMap")


func _draw() -> void:
	for pattern in active_patterns:
		if pattern.grid_positions.size() <= 0:
			continue
		
		for position in pattern.grid_positions:
			var item_position := position + pattern.item_position
			var notes_area_position := position + pattern.notes_area.position
			var label_underline_position := position + pattern.label_underline_area.position

			draw_rect(Rect2(item_position, pattern.item_size), pattern.gutter_color)
			draw_rect(Rect2(notes_area_position, pattern.notes_area.size), pattern.main_color)
			draw_rect(Rect2(label_underline_position, pattern.label_underline_area.size), pattern.main_color)

			# Draw gutter string.
			
			var string_position := position + pattern.label_position
			var shadow_position := string_position + _shadow_size
			var gutter_string := "%d" % [ pattern.pattern_index + 1 ]
			draw_string(_font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
			draw_string(_font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)

			# Draw pattern note map.
			
			for note_rect in pattern.notes:
				var note_rect_position := position + note_rect.position
				draw_rect(Rect2(note_rect_position, note_rect.size), _note_color)
