###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name InfoPopup extends WindowPopup

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

@onready var _content_label: RichTextLabel = %ContentLabel
@onready var _top_image_node: TextureRect = %TopImage
@onready var _left_image_node: TextureRect = %LeftImage


func _ready() -> void:
	super()
	_update_content()
	_update_image()


# Lifecycle.

## Override.
func clear() -> void:
	content = ""
	_ref_image = null
	_ref_image_size = Vector2.ZERO
	_ref_image_position = ImagePosition.HIDDEN
	
	if is_node_ready():
		_update_image()
	
	super()


# Content.

## Override.
func _update_before_popup() -> void:
	super()
	
	if is_node_ready():
		_update_content()


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
