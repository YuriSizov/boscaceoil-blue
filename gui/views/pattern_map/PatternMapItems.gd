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
var _selected_cursor_width: int = 0
var _selected_color: Color = Color.WHITE
var _selected_shadow_color: Color = Color.WHITE


func _ready() -> void:
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme() -> void:
	_font = get_theme_default_font()
	_font_size = get_theme_font_size("pattern_font_size", "PatternMap")
	_font_color = get_theme_color("font_color", "Label")
	_shadow_color = get_theme_color("shadow_color", "Label")
	_shadow_size = Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	
	_note_color = get_theme_color("active_note_color", "NoteMap")
	_selected_cursor_width = get_theme_constant("cursor_width", "ItemDock")
	_selected_color = get_theme_color("selected_color", "ItemDock")
	_selected_shadow_color = get_theme_color("selected_shadow_color", "ItemDock")


func _draw() -> void:
	var selected_rects: Array[Rect2] = []
	
	for pattern in active_patterns:
		if pattern.grid_positions.size() <= 0:
			continue
		
		for grid_position in pattern.grid_positions:
			var item_position := grid_position + pattern.item_position
			var notes_area_position := grid_position + pattern.notes_area.position
			var label_underline_position := grid_position + pattern.label_underline_area.position

			draw_rect(Rect2(item_position, pattern.item_size), pattern.gutter_color)
			draw_rect(Rect2(notes_area_position, pattern.notes_area.size), pattern.main_color)
			draw_rect(Rect2(label_underline_position, pattern.label_underline_area.size), pattern.main_color)

			# Draw gutter string.
			
			var string_position := grid_position + pattern.label_position
			var shadow_position := string_position + _shadow_size
			var gutter_string := "%d" % [ pattern.pattern_index + 1 ]
			draw_string(_font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
			draw_string(_font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)

			# Draw pattern note map.
			
			for note_rect in pattern.notes:
				var note_rect_position := grid_position + note_rect.position
				draw_rect(Rect2(note_rect_position, note_rect.size), _note_color)
			
			# Keep track of the selected pattern.
			
			if pattern.pattern_index == Controller.current_pattern_index:
				selected_rects.push_back(Rect2(item_position, pattern.item_size))
	
	# Draw selected indicator on top of everything.
	
	for item_rect in selected_rects:
		var border_size := Vector2(_selected_cursor_width, _selected_cursor_width)
		
		var cursor_position := item_rect.position + border_size * 0.5
		var cursor_size := item_rect.size - border_size
		var shadow_position := cursor_position + border_size
		var shadow_size := cursor_size - border_size * 2.0
		
		draw_rect(Rect2(cursor_position, cursor_size), _selected_color, false, _selected_cursor_width)
		draw_rect(Rect2(shadow_position, shadow_size), _selected_shadow_color, false, _selected_cursor_width)
