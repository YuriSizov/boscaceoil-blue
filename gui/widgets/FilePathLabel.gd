###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name FilePathLabel extends Control

@export var text: String = "":
	set = set_text

var _text_buffer: TextLine = TextLine.new()
var _rendered_buffer: TextLine = TextLine.new()


func _ready() -> void:
	_update_buffers()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_buffers()
	
	elif what == NOTIFICATION_RESIZED:
		_update_rendered_buffer()


func _draw() -> void:
	var font_color := get_theme_color("font_color")
	var font_shadow_color := get_theme_color("font_shadow_color")
	var font_shadow_offset := Vector2(
		get_theme_constant("font_shadow_offset_x"),
		get_theme_constant("font_shadow_offset_y")
	)
	
	if _rendered_buffer:
		_rendered_buffer.draw(get_canvas_item(), font_shadow_offset, font_shadow_color)
		_rendered_buffer.draw(get_canvas_item(), Vector2.ZERO, font_color)


func _get_minimum_size() -> Vector2:
	var min_size := Vector2.ZERO
	
	var background_panel := get_theme_stylebox("panel")
	if background_panel:
		min_size += background_panel.get_minimum_size()
	
	if _text_buffer:
		min_size.y += _text_buffer.get_size().y
	
	return min_size


func set_text(value: String) -> void:
	# Remove extra whitespaces and Windows-ness.
	var normalized_value := value.strip_edges().replace("\\", "/")
	if text == normalized_value:
		return
	
	text = normalized_value
	_update_buffers()


func _update_buffers() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	
	_text_buffer.clear()
	_text_buffer.add_string(text, font, font_size)
	_update_rendered_buffer()
	
	minimum_size_changed.emit()
	queue_redraw()


func _update_rendered_buffer() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	
	# Simplest case: the whole string fits, render as is.
	
	if _text_buffer.get_size().x < size.x:
		_rendered_buffer.clear()
		_rendered_buffer.add_string(text, font, font_size)
		queue_redraw()
		return
	
	# If not, try to reduce it by removing less significant parts. Preserve
	# the root at first, but gradually remove every other path segment.
	
	var path_bits := _split_path(text)
	if path_bits.size() > 2:
		var reduceable_bits := path_bits.slice(1, -1)
		while not reduceable_bits.is_empty():
			reduceable_bits.pop_front()
			
			var rendered_text := path_bits[0].path_join("..")
			if not reduceable_bits.is_empty():
				rendered_text = rendered_text.path_join("/".join(reduceable_bits))
			rendered_text = rendered_text.path_join(path_bits[-1])
			
			_rendered_buffer.clear()
			_rendered_buffer.add_string(rendered_text, font, font_size)
			if _rendered_buffer.get_size().x < size.x:
				queue_redraw()
				return
	
	# Last resort, render just "../filename.ext". The filename must be visible,
	# if it doesn't fit even then, it's a layout issue.
	
	_rendered_buffer.clear()
	_rendered_buffer.add_string("..".path_join(path_bits[-1]), font, font_size)
	queue_redraw()


func _split_path(path: String) -> Array[String]:
	var path_bits: Array[String] = []
	
	var remainder := path
	while true:
		var next := remainder.get_base_dir()
		
		if next.is_empty() || next == remainder: # Reached the root.
			if not next.is_empty():
				next = next.trim_prefix("/").trim_suffix("/")
				path_bits.push_back(next)
			break
		
		var bit := remainder.substr(next.length())
		bit = bit.trim_prefix("/").trim_suffix("/")
		path_bits.push_back(bit)
		remainder = next
	
	path_bits.reverse()
	return path_bits
