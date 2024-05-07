###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name InfoPopup extends PopupManager.PopupControl

const BUTTON_SCENE := preload("res://gui/widgets/SquishyButton.tscn")
const DEFAULT_TITLE := "Information"

var title: String = DEFAULT_TITLE:
	set = set_title
var content: String = "":
	set = set_content

var _buttons: Array[SquishyButton] = []

@onready var _title_label: Label = %TitleLabel
@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _close_button: Button = %CloseButton
@onready var _button_bar: Control = %ButtonBar


func _ready() -> void:
	_update_title()
	_update_content()
	_update_buttons()
	
	_content_label.install_effect(AccentedContentEffect.new())
	
	_close_button.pressed.connect(close_popup)


func _draw() -> void:
	var popup_origin := Vector2.ZERO
	
	# Draw shadow.
	
	var shadow_color := get_theme_color("shadow_color", "InfoPopup")
	var shadow_offset := Vector2(get_theme_constant("shadow_offset_x", "InfoPopup"), get_theme_constant("shadow_offset_y", "InfoPopup"))
	var shadow_position := popup_origin + shadow_offset

	draw_rect(Rect2(shadow_position, size), shadow_color)
	
	# Draw border
	
	var border_color := get_theme_color("border_color", "InfoPopup")
	var border_width := get_theme_constant("border_width", "InfoPopup")
	var border_position := popup_origin - Vector2(border_width, border_width)
	var border_size := size + Vector2(border_width, border_width) * 2
	
	draw_rect(Rect2(border_position, border_size), border_color)
	
	# Draw content and title.
	
	var title_color := get_theme_color("title_color", "InfoPopup")
	var content_color := get_theme_color("content_color", "InfoPopup")
	var title_height := get_theme_constant("title_height", "InfoPopup")
	var title_size := Vector2(size.x, title_height)
	
	draw_rect(Rect2(popup_origin, size), content_color)
	draw_rect(Rect2(popup_origin, title_size), title_color)


func popup(center_position: Vector2) -> void:
	if is_node_ready():
		_update_title()
		_update_content()
		_update_buttons()
	
	var popup_position := center_position - size / 2.0
	PopupManager.show_popup(self, popup_position, PopupManager.Direction.BOTTOM_RIGHT)


func close_popup() -> void:
	PopupManager.hide_popup(self)


func clear() -> void:
	title = DEFAULT_TITLE
	content = ""
	
	for button in _buttons:
		if button.get_parent():
			button.get_parent().remove_child(button)
		button.queue_free()
	_buttons.clear()
	
	if is_node_ready():
		_button_bar.visible = false
	
	size = Vector2.ZERO


func set_title(value: String) -> void:
	title = value
	_update_title()


func _update_title() -> void:
	if not is_node_ready():
		return
	
	_title_label.text = title


func set_content(value: String) -> void:
	content = value
	_update_content()


func _update_content() -> void:
	if not is_node_ready():
		return
	
	_content_label.text = content


func add_button(text: String, callback: Callable) -> void:
	var button := BUTTON_SCENE.instantiate()
	button.text = text
	button.pressed.connect(callback)
	
	if DisplayServer.get_swap_cancel_ok():
		_buttons.push_front(button)
	else:
		_buttons.push_back(button)
	
	if is_node_ready():
		_button_bar.add_child(button)
		if DisplayServer.get_swap_cancel_ok():
			_button_bar.move_child(button, 0)
		
		_button_bar.visible = true


func _update_buttons() -> void:
	if not is_node_ready():
		return
	
	for button in _buttons:
		if not button.get_parent():
			_button_bar.add_child(button)
	
	_button_bar.visible = _buttons.size() > 0


class AccentedContentEffect extends RichTextEffect:
	var bbcode: String = "accent"
	
	func _process_custom_fx(char_fx: CharFXTransform) -> bool:
		char_fx.color = ThemeDB.get_project_theme().get_color("accent_color", "InfoPopup")
		return true
