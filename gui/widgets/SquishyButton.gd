###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SquishyButton extends BaseButton

const PRESS_FADE_DURATION := 0.1
const UNPRESS_FADE_DURATION := 0.04

@export var text: String = "":
	set = set_text

var _text_shaped: bool = true
var _text_buffer: TextLine = TextLine.new()

var _tween: Tween = null
var _is_currently_pressed: bool = false
var _panel_position: Vector2 = Vector2.ZERO:
	set(value):
		_panel_position = value
		queue_redraw()

# Theme cache.

var _font: Font = null
var _font_size: int = -1
var _font_color: Color = Color.WHITE
var _font_pressed_color: Color = Color.WHITE
var _font_hover_color: Color = Color.WHITE
var _font_disabled_color: Color = Color.WHITE
var _font_shadow_color: Color = Color.BLACK
var _font_shadow_size: Vector2 = Vector2.ZERO

var _normal_style: StyleBox = null
var _pressed_style: StyleBox = null
var _hover_style: StyleBox = null
var _disabled_style: StyleBox = null


func _enter_tree() -> void:
	_update_theme()
	
	_panel_position = Vector2.ZERO - _normal_style.shadow_offset * _normal_style.shadow_size


func _ready() -> void:
	theme_changed.connect(_update_theme)


func _update_theme() -> void:
	_font = get_theme_font("font", "Button")
	_font_size = get_theme_font_size("font_size", "Button")
	_shape_text()
	
	_font_color = get_theme_color("font_color", "Button")
	_font_pressed_color = get_theme_color("font_pressed_color", "Button")
	_font_hover_color = get_theme_color("font_hover_color", "Button")
	_font_disabled_color = get_theme_color("font_disabled_color", "Button")
	_font_shadow_color = get_theme_color("font_shadow_color", "Button")
	_font_shadow_size = Vector2(get_theme_constant("font_shadow_offset_x", "Button"), get_theme_constant("font_shadow_offset_y", "Button"))
	
	_normal_style = get_theme_stylebox("normal", "Button")
	_pressed_style = get_theme_stylebox("pressed", "Button")
	_hover_style = get_theme_stylebox("hover", "Button")
	_disabled_style = get_theme_stylebox("disabled", "Button")


# Sizing and drawing.

func _draw() -> void:
	if _is_currently_pressed != is_pressed():
		_change_pressed_state(is_pressed())
	
	var current_style := _normal_style
	var current_font_color := _font_color
	
	if is_disabled():
		current_style = _disabled_style
		current_font_color = _font_disabled_color
	elif is_pressed():
		current_style = _pressed_style
		current_font_color = _font_pressed_color
	elif is_hovered():
		current_style = _hover_style
		current_font_color = _font_hover_color
	
	if _normal_style.shadow_size > 0:
		draw_rect(Rect2(Vector2.ZERO, size), current_style.shadow_color)
	draw_rect(Rect2(_panel_position, size), current_style.bg_color)
	
	var content_position := Vector2(current_style.get_margin(SIDE_LEFT), current_style.get_margin(SIDE_TOP))
	var content_size := size - content_position - Vector2(current_style.get_margin(SIDE_RIGHT), current_style.get_margin(SIDE_BOTTOM))
	
	var text_size := _text_buffer.get_size()
	var text_position := _panel_position + content_position + (content_size - text_size) / 2.0
	var text_shadow_position := text_position + _font_shadow_size
	
	if not is_disabled():
		_text_buffer.draw(get_canvas_item(), text_shadow_position, _font_shadow_color)
	_text_buffer.draw(get_canvas_item(), text_position, current_font_color)


func _get_minimum_size() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	
	var min_size := Vector2.ZERO
	
	# Account for the text.
	var text_size := _text_buffer.get_size()
	min_size.x = maxf(min_size.x, text_size.x)
	min_size.y = maxf(min_size.y, text_size.y)
	
	# Account for the panel style.
	if _normal_style:
		min_size.x += _normal_style.get_margin(SIDE_LEFT) + _normal_style.get_margin(SIDE_RIGHT)
		min_size.y += _normal_style.get_margin(SIDE_TOP) + _normal_style.get_margin(SIDE_BOTTOM)
	
	return min_size


# Text.

func set_text(value: String) -> void:
	if text == value:
		return
	
	text = value
	_text_shaped = false
	_shape_text()
	
	queue_redraw()
	update_minimum_size()


func _shape_text() -> void:
	if _text_shaped:
		return
	if not _font || _font_size <= 0:
		return # Can't shape right now.
	
	_text_buffer.clear()
	_text_buffer.add_string(text, _font, _font_size)
	_text_shaped = true


# Interactions.

func _change_pressed_state(_next_pressed: bool) -> void:
	_is_currently_pressed = _next_pressed
	
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	
	if _next_pressed: # Start pressing.
		_tween.tween_property(self, "_panel_position", Vector2.ZERO, PRESS_FADE_DURATION)
	else: # Stop pressing.
		_tween.tween_property(self, "_panel_position", Vector2.ZERO - _normal_style.shadow_offset * _normal_style.shadow_size, UNPRESS_FADE_DURATION)
