###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name OptionPicker extends MarginContainer

signal selected()

## Expand direction for the popup with options. Should be read as "In the direction to <DIRECTION OPTION>".
@export var direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT:
	set(value):
		direction = value
		_update_popup_direction()
		_update_icon()
## Placeholder text for when the control is empty (mostly used for in-editor visualization).
@export var placeholder_text: String = "":
	set(value):
		placeholder_text = value
		_update_label()

## Options/items for the control, must be applied manually after modifying, using commit_options().
var options: Array[OptionListPopup.Item] = []
## Linked map for quicker lookups, only contains selectable (non-sublist) items.
var _options_linked_map: Array[LinkedItem] = []
## Currently selected item, cannot be a sublist.
var _selected_option: OptionListPopup.Item = null

## The root popup control for the top level list of items. Contains sub-popups inside.
var _popup_control: OptionListPopup = null

@onready var _value_label: Label = $Layout/Label
@onready var _arrow_icon: TextureRect = $Layout/Arrow


func _init() -> void:
	_popup_control = OptionListPopup.new()
	_popup_control.item_selected.connect(_accept_selected)
	_update_popup_direction()


func _ready() -> void:
	commit_options()
	_update_label()
	_update_icon()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up popups which are not currently mounted to the tree.
		if is_instance_valid(_popup_control):
			_popup_control.queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT:
			_popup_control.show_popup(global_position, size)


# Properties.

func _update_popup_direction() -> void:
	if not is_instance_valid(_popup_control):
		return
	
	_popup_control.direction = direction


func _flatten_options(option_list: Array[OptionListPopup.Item]) -> void:
	for item in option_list:
		if item.is_sublist: # Ignore sublist items and only append their options to the flat list.
			_flatten_options(item.sublist_options)
			continue
		
		var linked_item := LinkedItem.new()
		linked_item.value = item
		_options_linked_map.push_back(linked_item)


func _link_options() -> void:
	_options_linked_map.clear()
	_flatten_options(options)
	if _options_linked_map.size() == 0:
		return
	
	var prev_linked_item: LinkedItem = _options_linked_map[_options_linked_map.size() - 1]
	for linked_item in _options_linked_map:
		linked_item.prev = prev_linked_item.value
		prev_linked_item.next = linked_item.value
		
		prev_linked_item = linked_item


func commit_options() -> void:
	_link_options()
	_popup_control.update_options(options)


func get_linked_options() -> Array[LinkedItem]:
	return _options_linked_map


# Visuals and drawables.

func _update_label() -> void:
	if not is_inside_tree():
		return

	if not _selected_option:
		_value_label.text = placeholder_text
		return

	_value_label.text = _selected_option.get_label_text()


func _update_icon() -> void:
	if not is_inside_tree():
		return

	if direction == PopupManager.Direction.TOP_RIGHT || direction == PopupManager.Direction.TOP_LEFT:
		_arrow_icon.texture = get_theme_icon("up_arrow", "OptionPicker")
	else:
		_arrow_icon.texture = get_theme_icon("down_arrow", "OptionPicker")


# Selection.

func _accept_selected(item: OptionListPopup.Item) -> void:
	var next_item := item if not item.is_sublist else null

	if next_item != _selected_option:
		_selected_option = next_item
		_update_label()
		selected.emit()
	
	if not item.is_sublist:
		PopupManager.hide_popup(_popup_control)


func get_selected() -> OptionListPopup.Item:
	return _selected_option


func set_selected(item: OptionListPopup.Item) -> void:
	_selected_option = item
	_update_label()


func select_next() -> void:
	if options.size() == 0: # Option list is empty, there is nothing to select.
		return
	if not _selected_option: # There is nothing selected right now, select first.
		_selected_option = options[0]
		_update_label()
		selected.emit()
		return
	
	for linked_item in _options_linked_map:
		if linked_item.value == _selected_option:
			if _selected_option == linked_item.next: # There is only one item, the change is moot.
				break
			
			_selected_option = linked_item.next
			_update_label()
			selected.emit()
			break


func select_previous() -> void:
	if options.size() == 0: # Option list is empty, there is nothing to select.
		return
	if not _selected_option: # There is nothing selected right now, select last.
		_selected_option = options[options.size() - 1]
		_update_label()
		selected.emit()
		return
	
	for linked_item in _options_linked_map:
		if linked_item.value == _selected_option:
			if _selected_option == linked_item.prev: # There is only one item, the change is moot.
				break
			
			_selected_option = linked_item.prev
			_update_label()
			selected.emit()
			break


func clear_selected() -> void:
	_selected_option = null
	_update_label()


class LinkedItem:
	var value: OptionListPopup.Item = null
	var next: OptionListPopup.Item = null
	var prev: OptionListPopup.Item = null
