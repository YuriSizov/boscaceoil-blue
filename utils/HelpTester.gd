###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A special scene and script to visualize steps from help guides in the editor.
@tool
extends Control

@export var refresh: bool = false:
	set(value):
		_update_guide_step()
var _guide_resource: HelpGuide = null
var _guide_step_index: int = -1
var _guide_step: HelpGuideStep = null

var _presave_guide_step: int = -1

@onready var _popup: InfoPopup = $Popup


func _ready() -> void:
	_popup.button_autoswap = false
	_popup.button_alignment = HORIZONTAL_ALIGNMENT_FILL


func _notification(what: int) -> void:
	# Keeps the commit history clean.
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_presave_guide_step = _guide_step_index
		set_guide_step(-1)
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		if _presave_guide_step != -1:
			set_guide_step(_presave_guide_step)
			_presave_guide_step = -1


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	
	props.push_back({
		"name": "guide_resource",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "HelpGuide"
	})
	
	var steps_count := 0
	if _guide_resource:
		steps_count = _guide_resource.steps.size()
	
	props.push_back({
		"name": "guide_step",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "%d,%d,%d" % [ -1, steps_count - 1, 1 ]
	})
	props.push_back({
		"name": "guide_step_data",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "HelpGuideStep"
	})
	
	return props


func _get(property: StringName) -> Variant:
	if property == "guide_resource":
		return _guide_resource
	if property == "guide_step":
		return _guide_step_index
	if property == "guide_step_data":
		if _guide_step_index < 0:
			return null
		
		return _guide_step
	
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == "guide_resource":
		set_guide_resource(value)
		return true
	
	if property == "guide_step":
		set_guide_step(value)
		return true
	
	return false


func set_guide_resource(value: HelpGuide) -> void:
	if _guide_resource:
		_guide_resource.changed.disconnect(notify_property_list_changed)
	
	_guide_resource = value
	
	if _guide_resource:
		_guide_resource.changed.connect(notify_property_list_changed)
	
	notify_property_list_changed()


func set_guide_step(value: int) -> void:
	_guide_step_index = value
	notify_property_list_changed()
	
	if _guide_step:
		_guide_step.changed.disconnect(_update_guide_step)
	
	if not _guide_resource || _guide_step_index < 0 || _guide_step_index >= _guide_resource.steps.size():
		_guide_step = null
		_populate_step_popup(HelpGuideStep.new())
		_popup.hide()
		return
	
	_guide_step = _guide_resource.steps[_guide_step_index]
	if not _guide_step:
		_populate_step_popup(HelpGuideStep.new())
		_popup.hide()
		return
	
	if _guide_step:
		_guide_step.changed.connect(_update_guide_step)
	
	_update_guide_step()
	_popup.show()


func _update_guide_step() -> void:
	if not _guide_step:
		_populate_step_popup(HelpGuideStep.new())
		_popup.hide()
		return
	
	_populate_step_popup(_guide_step)
	
	if _guide_step.ref_image && _guide_step.ref_image_position != InfoPopup.ImagePosition.HIDDEN:
		_popup.add_image(_guide_step.ref_image, _guide_step.ref_image_size, _guide_step.ref_image_position)
	
	var button_prev := _popup.add_button("PREVIOUS", _empty_callable)
	button_prev.visible = _guide_step_index > 0
	
	if _guide_step_index < (_guide_resource.steps.size() - 1):
		_popup.add_button("NEXT", _empty_callable)
	else:
		_popup.add_button("FINISH", _empty_callable)


func _populate_step_popup(step: HelpGuideStep) -> void:
	_popup.clear()
	
	_popup.custom_minimum_size = step.size
	_popup.title = step.title
	_popup.content = step.description
	
	_popup.anchor_left = step.position_anchor.x
	_popup.anchor_right = step.position_anchor.x
	_popup.anchor_top = step.position_anchor.y
	_popup.anchor_bottom = step.position_anchor.y
	_popup.offset_left = 0
	_popup.offset_right = 0
	_popup.offset_top = 0
	_popup.offset_bottom = 0
	
	match step.position_direction:
		PopupManager.Direction.BOTTOM_RIGHT:
			_popup.grow_horizontal = Control.GROW_DIRECTION_END
			_popup.grow_vertical = Control.GROW_DIRECTION_END
		
		PopupManager.Direction.BOTTOM_LEFT:
			_popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			_popup.grow_vertical = Control.GROW_DIRECTION_END
		
		PopupManager.Direction.TOP_RIGHT:
			_popup.grow_horizontal = Control.GROW_DIRECTION_END
			_popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
		
		PopupManager.Direction.TOP_LEFT:
			_popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			_popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
		
		PopupManager.Direction.OMNI:
			_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
			_popup.grow_vertical = Control.GROW_DIRECTION_BOTH


func _empty_callable() -> void:
	pass
