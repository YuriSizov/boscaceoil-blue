###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name WindowPopup extends PopupManager.PopupControl

const DEFAULT_TITLE := "Information"

var title: String = DEFAULT_TITLE:
	set = set_title

@onready var _title_label: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_update_title()
	
	_close_button.pressed.connect(close_popup)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		mark_click_handled()
		accept_event()


func _draw() -> void:
	var popup_origin := Vector2.ZERO
	
	# Draw shadow.
	
	var shadow_color := get_theme_color("shadow_color")
	var shadow_offset := Vector2(get_theme_constant("shadow_offset_x"), get_theme_constant("shadow_offset_y"))
	var shadow_position := popup_origin + shadow_offset

	draw_rect(Rect2(shadow_position, size), shadow_color)
	
	# Draw border
	
	var border_color := get_theme_color("border_color")
	var border_width := get_theme_constant("border_width")
	var border_position := popup_origin - Vector2(border_width, border_width)
	var border_size := size + Vector2(border_width, border_width) * 2
	
	draw_rect(Rect2(border_position, border_size), border_color)
	
	# Draw content and title.
	
	var title_color := get_theme_color("title_color")
	var content_color := get_theme_color("content_color")
	var title_height := get_theme_constant("title_height")
	var title_size := Vector2(size.x, title_height)
	
	draw_rect(Rect2(popup_origin, size), content_color)
	draw_rect(Rect2(popup_origin, title_size), title_color)


# Lifecycle.

func is_popped() -> bool:
	if not is_node_ready() || not is_inside_tree():
		return false
	
	return PopupManager.is_popup_shown(self)


func popup_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
	_update_before_popup()
	PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func move_anchored(anchor_position: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT) -> void:
	PopupManager.move_popup_anchored(self, anchor_position, direction)


func close_popup() -> void:
	mark_click_handled()
	PopupManager.hide_popup(self)


func clear() -> void:
	title = DEFAULT_TITLE
	
	custom_minimum_size = Vector2.ZERO
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
	size = Vector2.ZERO


# Content.

func _update_before_popup() -> void:
	if is_node_ready():
		_update_title()


func set_title(value: String) -> void:
	title = value
	_update_title()


func _update_title() -> void:
	if not is_node_ready():
		return
	
	_title_label.text = title
