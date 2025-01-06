###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SquishyButton extends BaseButton

signal option_pressed(item: OptionListPopup.Item)

const PRESS_FADE_DURATION := 0.1
const UNPRESS_FADE_DURATION := 0.04

enum OperationMode {
	ACTIVATE,
	OPTION_LIST,
}

@export var text: String = "":
	set = set_text
@export var operation_mode: OperationMode = OperationMode.ACTIVATE:
	set = set_operation_mode

var _text_shaped: bool = true
var _text_buffer: TextLine = TextLine.new()

var options: Array[OptionListPopup.Item] = []

var _tween: Tween = null
var _is_currently_pressed: bool = false
var _panel_position: Vector2 = Vector2.ZERO:
	set(value):
		_panel_position = value
		queue_redraw()
var _popup_control: OptionListPopup = null

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


func _init() -> void:
	_popup_control = OptionListPopup.new()
	_popup_control.item_selected.connect(_handle_option_selected)


func _enter_tree() -> void:
	_update_theme()
	
	_panel_position = Vector2.ZERO - _normal_style.shadow_offset * _normal_style.shadow_size


func _ready() -> void:
	theme_changed.connect(_update_theme)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up popups which are not currently mounted to the tree.
		if is_instance_valid(_popup_control):
			_popup_control.queue_free()


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


func _has_point(point: Vector2) -> bool:
	var visual_rect := Rect2(Vector2.ZERO, size).expand(_panel_position)
	return visual_rect.has_point(point)


func get_global_visual_rect() -> Rect2:
	var visual_rect := Rect2(Vector2.ZERO, size).expand(_panel_position)
	visual_rect.position += global_position
	
	return visual_rect


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


# Operation modes.

func set_operation_mode(mode: OperationMode) -> void:
	if operation_mode == mode:
		return
	
	if operation_mode == OperationMode.OPTION_LIST:
		pressed.disconnect(_show_options_popup)
	
	operation_mode = mode
	
	if operation_mode == OperationMode.OPTION_LIST:
		pressed.connect(_show_options_popup)


func _show_options_popup() -> void:
	if operation_mode != OperationMode.OPTION_LIST:
		return
	
	_popup_control.show_popup(global_position, size)


func commit_options() -> void:
	_popup_control.update_options(options)


func _handle_option_selected(item: OptionListPopup.Item) -> void:
	if item.is_sublist:
		return
	
	option_pressed.emit(item)
	PopupManager.hide_popup(_popup_control)


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
