###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name InfoPopup extends WindowPopup

const BUTTON_SCENE := preload("res://gui/widgets/SquishyButton.tscn")

enum ImagePosition {
	HIDDEN,
	IMAGE_TOP,
	IMAGE_LEFT,
}

var content: String = "":
	set = set_content

var _ref_image: Texture2D = null
var _ref_image_size: Vector2 = Vector2.ZERO
var _ref_image_position: ImagePosition = ImagePosition.HIDDEN

var _buttons: Array[SquishyButton] = []
var _button_spacers: Array[Control] = []

var button_autoswap: bool = true
var button_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT:
	set = set_button_alignment

@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _top_image_node: TextureRect = %TopImage
@onready var _left_image_node: TextureRect = %LeftImage
@onready var _button_bar: HBoxContainer = %ButtonBar


func _ready() -> void:
	super()
	_update_content()
	_update_image()
	_update_buttons()


# Lifecycle.

## Override.
func clear() -> void:
	content = ""
	_ref_image = null
	_ref_image_size = Vector2.ZERO
	_ref_image_position = ImagePosition.HIDDEN
	
	_buttons.clear()
	_button_spacers.clear()
	
	if is_node_ready():
		_update_image()
		
		while _button_bar.get_child_count() > 0:
			var child_node := _button_bar.get_child(_button_bar.get_child_count() - 1)
			_button_bar.remove_child(child_node)
			child_node.queue_free()
		
		_button_bar.visible = false
	
	super()


# Content.

## Override.
func _update_before_popup() -> void:
	super()
	
	if is_node_ready():
		_update_content()
		_update_buttons()


func set_content(value: String) -> void:
	content = value
	_update_content()


func _update_content() -> void:
	if not is_node_ready():
		return
	
	_content_label.text = content


func add_image(texture: Texture2D, image_size: Vector2, image_position: ImagePosition) -> void:
	_ref_image = texture
	_ref_image_size = image_size
	_ref_image_position = image_position
	_update_image()


func _update_image() -> void:
	if not is_node_ready():
		return
	
	match _ref_image_position:
		ImagePosition.HIDDEN:
			_top_image_node.custom_minimum_size = Vector2.ZERO
			_top_image_node.visible = false
			_left_image_node.custom_minimum_size = Vector2.ZERO
			_left_image_node.visible = false
		
		ImagePosition.IMAGE_TOP:
			_top_image_node.texture = _ref_image
			
			_top_image_node.custom_minimum_size = _ref_image_size
			_top_image_node.visible = true
			_left_image_node.custom_minimum_size = Vector2.ZERO
			_left_image_node.visible = false
		
		ImagePosition.IMAGE_LEFT:
			_left_image_node.texture = _ref_image
			
			_top_image_node.custom_minimum_size = Vector2.ZERO
			_top_image_node.visible = false
			_left_image_node.custom_minimum_size = _ref_image_size
			_left_image_node.visible = true


# Buttons.

func add_button(text: String, callback: Callable) -> SquishyButton:
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
	if not is_node_ready():
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


func set_button_alignment(value: HorizontalAlignment) -> void:
	button_alignment = value
	_update_button_alignment()


func _update_button_alignment() -> void:
	if not is_node_ready():
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
