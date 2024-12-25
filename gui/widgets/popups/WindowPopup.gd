###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name WindowPopup extends PopupManager.PopupControl

const DEFAULT_TITLE := "Information"
const BUTTON_SCENE := preload("res://gui/widgets/SquishyButton.tscn")

@export var title: String = DEFAULT_TITLE:
	set = set_title

var _buttons: Array[SquishyButton] = []
var _button_spacers: Array[Control] = []

var button_autoswap: bool = true
var button_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT:
	set = set_button_alignment

var _dragging: bool = false

@onready var _title_label: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
# This node must be added by inheriting scenes.
@onready var _button_bar: HBoxContainer = get_node_or_null("%ButtonBar")


func _ready() -> void:
	_update_title()
	_update_buttons()
	
	_close_button.pressed.connect(close_popup)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		# Since this is a part of an instantiated scene, these nodes are immediately available.
		# This allows us to use them safely before ready.
		_title_label = %TitleLabel
		_close_button = %CloseButton
		_button_bar = get_node_or_null("%ButtonBar")
	
	elif _dragging && what == NOTIFICATION_DRAG_END:
		_dragging = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		var title_height := get_theme_constant("title_height")
		var title_rect := Rect2(Vector2.ZERO, Vector2(size.x, title_height))
		
		if title_rect.has_point(mb.position) && mb.button_index == MOUSE_BUTTON_LEFT && mb.pressed:
			_dragging = true
		elif mb.button_index == MOUSE_BUTTON_LEFT && not mb.pressed:
			_dragging = false
		
		mark_click_handled()
		accept_event()
	
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		
		if _dragging:
			PopupManager.move_popup(self, mm.relative)


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


func popup_anchored(anchor_position: Vector2, popup_size: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT, blocking: bool = true) -> void:
	size = popup_size
	_update_before_popup()
	PopupManager.show_popup_anchored(self, anchor_position, direction, blocking)


func transform_anchored(anchor_position: Vector2, popup_size: Vector2, direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT) -> void:
	PopupManager.transform_popup_anchored(self, anchor_position, popup_size, direction, true)


func close_popup() -> void:
	mark_click_handled()
	PopupManager.hide_popup(self)


func clear(keep_size: bool = false) -> void:
	title = DEFAULT_TITLE
	_clear_buttons()
	
	if not keep_size:
		custom_minimum_size = Vector2.ZERO
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE)
		size = Vector2.ZERO


# Content.

func _update_before_popup() -> void:
	if is_node_ready():
		_update_title()
		_update_buttons()


func set_title(value: String) -> void:
	title = value
	_update_title()


func _update_title() -> void:
	if not is_node_ready():
		return
	
	_title_label.text = title


# Buttons.

func add_button(text: String, callback: Callable) -> SquishyButton:
	if not _button_bar:
		printerr("WindowPopup: Missing the button bar control, make sure that you're using an inherited scene which adds one.")
		return
	
	var button := BUTTON_SCENE.instantiate()
	button.text = text
	button.pressed.connect(func() -> void:
		mark_click_handled()
		callback.call()
	)
	
	if button_autoswap && DisplayServer.get_swap_cancel_ok():
		_buttons.push_front(button)
	else:
		_buttons.push_back(button)
	
	if is_node_ready():
		var spacer: Control = null
		if _buttons.size() > 1:
			spacer = _button_bar.add_spacer(false)
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.visible = (button_alignment == HORIZONTAL_ALIGNMENT_FILL)
			_button_spacers.push_back(spacer)
		
		_button_bar.add_child(button)
		
		if button_autoswap && DisplayServer.get_swap_cancel_ok():
			if spacer:
				_button_bar.move_child(spacer, 0)
			_button_bar.move_child(button, 0)
		
		_button_bar.visible = true
	
	return button


func _update_buttons() -> void:
	if not _button_bar:
		return
	
	var i := 0
	for button in _buttons:
		if not button.get_parent():
			if i > 0:
				var spacer := _button_bar.add_spacer(false)
				spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				spacer.visible = (button_alignment == HORIZONTAL_ALIGNMENT_FILL)
				_button_spacers.push_back(spacer)
			
			_button_bar.add_child(button)
		
		i += 1
	
	_button_bar.visible = _buttons.size() > 0


func _clear_buttons() -> void:
	_buttons.clear()
	_button_spacers.clear()
	
	if _button_bar:
		while _button_bar.get_child_count() > 0:
			var child_node := _button_bar.get_child(_button_bar.get_child_count() - 1)
			_button_bar.remove_child(child_node)
			child_node.queue_free()
		
		_button_bar.visible = false


func set_button_alignment(value: HorizontalAlignment) -> void:
	if not _button_bar:
		printerr("WindowPopup: Missing the button bar control, make sure that you're using an inherited scene which adds one.")
		return
	
	button_alignment = value
	_update_button_alignment()


func _update_button_alignment() -> void:
	if not _button_bar:
		return
	
	match button_alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			_button_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
		
		HORIZONTAL_ALIGNMENT_RIGHT:
			_button_bar.alignment = BoxContainer.ALIGNMENT_END
		
		HORIZONTAL_ALIGNMENT_CENTER:
			_button_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		
		HORIZONTAL_ALIGNMENT_FILL:
			_button_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	
	if button_alignment == HORIZONTAL_ALIGNMENT_FILL:
		for spacer in _button_spacers:
			spacer.visible = true
	else:
		for spacer in _button_spacers:
			spacer.visible = false
