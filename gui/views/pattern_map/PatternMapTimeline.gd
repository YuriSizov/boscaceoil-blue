###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const MAJOR_MARKER_SECONDS := 30
const MINOR_MARKER_SECONDS := 5

var pattern_width: float = 0
var scroll_offset: int = 0

# Theme cache.

var _background_color: Color = Color.WHITE
var _border_color: Color = Color.WHITE
var _border_width: float = 0.0

var _font: Font = null
var _font_size: int = 0
var _font_color: Color = Color.WHITE
var _shadow_size: Vector2 = Vector2.ZERO
var _shadow_color: Color = Color.WHITE


func _ready() -> void:
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme() -> void:
	_background_color = get_theme_color("track_border_color", "PatternMap")
	_border_color = get_theme_color("track_color", "PatternMap")
	_border_width = get_theme_constant("border_width", "PatternMap")
	
	_font = get_theme_default_font()
	_font_size = get_theme_font_size("track_font_size", "PatternMap")
	_font_color = get_theme_color("track_font_color", "PatternMap")
	_shadow_size = Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	_shadow_color = get_theme_color("track_shadow_color", "PatternMap")


func _draw() -> void:
	var available_rect: Rect2 = get_available_rect()
	
	draw_rect(Rect2(Vector2.ZERO, available_rect.size), _background_color)
	
	# Draw second/minute markers.
	
	if not Engine.is_editor_hint():
		var note_time := Controller.music_player.get_note_time_length()
		var note_width := pattern_width / Controller.current_song.pattern_size
		var second_width := note_width / note_time
		
		# Draw minor markers every MINOR_MARKER_SECONDS.
		
		var filled_width := 0.0
		var minor_marker_width := second_width * MINOR_MARKER_SECONDS
		var minor_tick_index := 0
		while filled_width < available_rect.size.x:
			var marker_x := minor_tick_index * minor_marker_width - scroll_offset * pattern_width
			if marker_x < 0:
				minor_tick_index += 1
				continue
			
			var marker_position := Vector2(marker_x, 0)
			var marker_size := Vector2(_border_width, 2.0 * available_rect.size.y / 5.0)
			var label_position := Vector2(marker_position.x, 0) + Vector2(12, available_rect.size.y - 4)
				
			# Skip minor markers which overlap major markers.
			if (minor_tick_index * MINOR_MARKER_SECONDS) % MAJOR_MARKER_SECONDS != 0:
				_draw_marker(Rect2(marker_position, marker_size), label_position, _border_color, minor_tick_index * MINOR_MARKER_SECONDS)
			
			filled_width += marker_size.x
			minor_tick_index += 1
		
		# Draw major markers every MAJOR_MARKER_SECONDS.
		
		filled_width = 0.0
		var major_marker_width := second_width * MAJOR_MARKER_SECONDS
		var major_tick_index := 0
		while filled_width < available_rect.size.x:
			var marker_x := major_tick_index * major_marker_width - scroll_offset * pattern_width
			if marker_x < 0:
				major_tick_index += 1
				continue
			
			var marker_position := Vector2(marker_x, 0)
			var marker_size := Vector2(_border_width, available_rect.size.y)
			var label_position := marker_position + Vector2(12, available_rect.size.y - 4)
			
			_draw_marker(Rect2(marker_position, marker_size), label_position, _font_color, major_tick_index * MAJOR_MARKER_SECONDS)
			
			filled_width += marker_size.x
			major_tick_index += 1


func _draw_marker(marker_rect: Rect2, label_position: Vector2, label_color: Color, time_value: int) -> void:
	draw_rect(marker_rect, _border_color)
	
	var minutes_value := int(time_value / 60.0)
	var seconds_value := time_value - minutes_value * 60.0
	var label_text := "%d:%02d" % [ minutes_value, seconds_value ]
	
	var shadow_position := label_position + _shadow_size
	draw_string(_font, shadow_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
	draw_string(_font, label_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, label_color)


func get_available_rect() -> Rect2:
	var available_rect := Rect2(Vector2.ZERO, size)
	if not is_inside_tree():
		return available_rect

	return available_rect
