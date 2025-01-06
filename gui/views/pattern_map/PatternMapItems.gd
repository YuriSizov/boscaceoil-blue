###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
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
			draw_item(self, pattern, grid_position)
			
			# Keep track of the selected pattern.
			
			if pattern.pattern_index == Controller.current_pattern_index:
				var item_position := grid_position + pattern.item_position
				selected_rects.push_back(Rect2(item_position, pattern.item_size))
	
	# Draw selected indicator on top of everything.
	
	for item_rect in selected_rects:
		_draw_selected_outline(self, item_rect)


func draw_item(on_control: Control, pattern: PatternMap.ActivePattern, item_origin: Vector2, draw_selected: bool = false) -> void:
	var item_position := item_origin + pattern.item_position
	var notes_area_position := item_origin + pattern.notes_area.position
	var label_underline_position := item_origin + pattern.label_underline_area.position
	
	on_control.draw_rect(Rect2(item_position, pattern.item_size), pattern.gutter_color)
	on_control.draw_rect(Rect2(notes_area_position, pattern.notes_area.size), pattern.main_color)
	on_control.draw_rect(Rect2(label_underline_position, pattern.label_underline_area.size), pattern.main_color)
	
	# Draw gutter string.
	
	var string_position := item_origin + pattern.label_position
	var shadow_position := string_position + _shadow_size
	var gutter_string := "%d" % [ pattern.pattern_index + 1 ]
	
	# A bit of a hack, but it lets us use any Control-derivative for drawing. If it has
	# this property, we use it. If not, then not.
	if on_control.get("cloned"):
		gutter_string += "*"
	
	on_control.draw_string(_font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
	on_control.draw_string(_font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)
	
	# Draw pattern note map.
	
	for note_rect in pattern.notes:
		var note_rect_position := item_origin + note_rect.position
		on_control.draw_rect(Rect2(note_rect_position, note_rect.size), _note_color)
	
	if draw_selected:
		_draw_selected_outline(on_control, Rect2(item_position, pattern.item_size))


func _draw_selected_outline(on_control: Control, item_rect: Rect2) -> void:
	var border_size := Vector2(_selected_cursor_width, _selected_cursor_width)
	
	var cursor_position := item_rect.position + border_size * 0.5
	var cursor_size := item_rect.size - border_size
	var shadow_position := cursor_position + border_size
	var shadow_size := cursor_size - border_size * 2.0
	
	on_control.draw_rect(Rect2(cursor_position, cursor_size), _selected_color, false, _selected_cursor_width)
	on_control.draw_rect(Rect2(shadow_position, shadow_size), _selected_shadow_color, false, _selected_cursor_width)
