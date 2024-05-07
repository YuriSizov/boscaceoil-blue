###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name OptionPicker extends MarginContainer

signal selected()

enum Pager {
	NO_PAGER = -1,
	PAGER_LEFT,
	PAGER_RIGHT,
}

const POPUP_MIN_SIZE := Vector2(10, 10)
const POPUP_MAX_ITEMS := 15 # TODO: Possibly make this adjustible to always fit the screen?

const POPUP_EMPTY_LABEL := "No options."
const PAGER_LEFT_LABEL := "<< Prev"
const PAGER_RIGHT_LABEL := "Next >>"

## Expand direction for the popup with options. Should be read as "In the direction to <DIRECTION OPTION>".
@export var direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT:
	set(value):
		direction = value
		_update_icon()
## Placeholder text for when the control is empty (mostly used for in-editor visualization).
@export var placeholder_text: String = "":
	set(value):
		placeholder_text = value
		_update_label()

## Options/items for the control, must be applied manually after modifying, using commit_options().
var options: Array[Item] = []
## Linked map for quicker lookups, only contains selectable (non-sublist) items.
var _options_linked_map: Array[LinkedItem] = []
## Currently selected item, cannot be a sublist.
var _selected_option: Item = null

## True when at least one popup is showing.
var _is_expanded: bool = false
## The root popup control for the top level list of items. Contains sub-popups inside.
var _popup_control: ItemPopup = null

@onready var _value_label: Label = $Layout/Label
@onready var _arrow_icon: TextureRect = $Layout/Arrow


func _init() -> void:
	_popup_control = ItemPopup.new()
	_init_popup(_popup_control)


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
			_show_popup()


# Popup lifecycle.

func _init_popup(popup: ItemPopup) -> void:
	popup.init_callback = _init_popup
	popup.resize_callback = _update_popup_size
	
	popup.draw.connect(_draw_popup.bind(popup))
	popup.item_selected.connect(_accept_selected)
	popup.sublist_selected.connect(_show_sub_popup.bind(popup))


func _draw_popup(popup: ItemPopup) -> void:
	# Draw the background panel.
	var popup_background := get_theme_stylebox("popup_panel", "OptionPicker")
	popup.draw_style_box(popup_background, Rect2(Vector2.ZERO, popup.size))

	# Draw options.

	var font := get_theme_font("font", "Label")
	var option_font_size := get_theme_font_size("option_font_size", "OptionPicker")
	var empty_font_color := get_theme_color("empty_font_color", "OptionPicker")

	var option_font_color := get_theme_color("option_font_color", "OptionPicker")
	var sublist_font_color := get_theme_color("sublist_font_color", "OptionPicker")
	var sublist_inactive_font_color := get_theme_color("sublist_inactive_font_color", "OptionPicker")
	var sublist_color := get_theme_color("sublist_color", "OptionPicker")
	var option_hover_color := get_theme_color("option_hover_color", "OptionPicker")
	var sublist_hover_color := get_theme_color("sublist_hover_color", "OptionPicker")
	var sublist_selected_color := get_theme_color("sublist_selected_color", "OptionPicker")

	# Draw an empty placeholder if there are no options available.
	if not popup.has_options():
		var label_position := popup.item_origin + popup.label_position
		popup.draw_string(font, label_position, POPUP_EMPTY_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size, empty_font_color)
	else:
		var popup_options := popup.get_options()
		# Either draw exactly POPUP_MAX_ITEMS + 1 items, or draw POPUP_MAX_ITEMS and then a pager.
		var max_items := popup_options.size()
		if popup.has_pager:
			max_items = POPUP_MAX_ITEMS
		
		# Draw the items, up to the limit.
		for item_index in max_items:
			var item_adjusted_index := item_index + popup.current_page * POPUP_MAX_ITEMS
			if item_adjusted_index >= popup_options.size():
				break
			var item := popup_options[item_adjusted_index]

			var item_offset := Vector2(0, popup.item_size.y * item_index)
			var item_position := popup.item_origin + item_offset
			var label_position := popup.item_origin + popup.label_position + item_offset

			if item.background_color.a > 0:
				popup.draw_rect(Rect2(item_position, popup.item_size), item.background_color)
			elif item.is_sublist:
				popup.draw_rect(Rect2(item_position, popup.item_size), sublist_color)

			if item.is_sublist && popup.selected_item == item_index:
				popup.draw_rect(Rect2(item_position, popup.item_size), sublist_selected_color)
			if popup.hovered_item == item_index:
				var item_hover_color := sublist_hover_color if item.is_sublist else option_hover_color
				popup.draw_rect(Rect2(item_position, popup.item_size), item_hover_color)

			var item_font_color := sublist_font_color if item.is_sublist else option_font_color
			popup.draw_string(font, label_position, item.get_option_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size, item_font_color)

		# Draw the pager.
		if popup.has_pager:
			var popup_index := POPUP_MAX_ITEMS
			var pager_offset := Vector2(0, popup.item_size.y * popup_index)
			var pager_size := Vector2(popup.item_size.x / 2, popup.item_size.y)
			
			# Draw the left pager (previous page).
			
			var left_pager_position := popup.item_origin + pager_offset
			popup.draw_rect(Rect2(left_pager_position, pager_size), sublist_color)
			if popup.current_page != 0 && popup.hovered_item == popup_index && popup.hovered_pager == Pager.PAGER_LEFT:
				popup.draw_rect(Rect2(left_pager_position, pager_size), sublist_hover_color)
			
			var left_pager_label_position := popup.item_origin + popup.pager_left_label_position + pager_offset
			var left_pager_color := sublist_font_color if popup.current_page != 0 else sublist_inactive_font_color
			popup.draw_string(font, left_pager_label_position, PAGER_LEFT_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size, left_pager_color)
			
			# Draw the right pager (next page).
			
			var right_pager_position := left_pager_position + Vector2(pager_size.x, 0)
			popup.draw_rect(Rect2(right_pager_position, pager_size), sublist_color)
			if popup.current_page != (popup.max_pages - 1) && popup.hovered_item == popup_index && popup.hovered_pager == Pager.PAGER_RIGHT:
				popup.draw_rect(Rect2(right_pager_position, pager_size), sublist_hover_color)
			
			var right_pager_label_position := popup.item_origin + popup.pager_right_label_position + pager_offset
			var right_pager_color := sublist_font_color if popup.current_page != (popup.max_pages - 1) else sublist_inactive_font_color
			popup.draw_string(font, right_pager_label_position, PAGER_RIGHT_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size, right_pager_color)


func _update_popup_size(popup: ItemPopup) -> void:
	var font := get_theme_font("font", "Label")
	var option_font_size := get_theme_font_size("option_font_size", "OptionPicker")
	var item_margins := get_theme_stylebox("item_margins", "OptionPicker")
	# Our font contributes excessive height, and content margins cannot be negative, so this is how we fix it.
	var item_height_adjustment := get_theme_constant("item_height_adjustment", "OptionPicker")
	var popup_background: StyleBoxFlat = get_theme_stylebox("popup_panel", "OptionPicker")

	# Calculate the minimum needed width using the longest option text.
	var longest_item := 0.0
	var item_count := 0
	if not popup.has_options():
		longest_item = font.get_string_size(POPUP_EMPTY_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size).x
		item_count = 1
	else:
		for item in popup.get_options():
			var text := item.get_option_text()
			var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, option_font_size)
			if text_size.x > longest_item:
				longest_item = text_size.x

		item_count = min(POPUP_MAX_ITEMS + 1, popup.get_options().size()) # Reserve one item slot for navigation.

	# Calculate final item size.
	# Reference the minimum width from the above, the height of any capital character, and the minimum size
	# needed by the pager.

	var item_height := font.get_char_size("C".unicode_at(0), option_font_size).y

	var left_label_size := font.get_string_size(PAGER_LEFT_LABEL, HORIZONTAL_ALIGNMENT_RIGHT, -1, option_font_size)
	var right_label_size := font.get_string_size(PAGER_RIGHT_LABEL, HORIZONTAL_ALIGNMENT_RIGHT, -1, option_font_size)
	if popup.has_pager:
		var pager_min_width := maxf(left_label_size.x, right_label_size.x) * 2
		longest_item = max(longest_item, pager_min_width)

	var item_size := Vector2(
		item_margins.get_margin(SIDE_LEFT) + item_margins.get_margin(SIDE_RIGHT) + longest_item,
		item_margins.get_margin(SIDE_TOP) + item_margins.get_margin(SIDE_BOTTOM) + item_height + item_height_adjustment
	)
	popup.item_size = item_size
	popup.label_position = Vector2(
		item_margins.get_margin(SIDE_LEFT),
		item_size.y - item_margins.get_margin(SIDE_BOTTOM)
	)

	var border_size := Vector2(
		popup_background.border_width_left + popup_background.border_width_right,
		popup_background.border_width_top + popup_background.border_width_bottom
	)
	popup.item_origin = Vector2(popup_background.border_width_left, popup_background.border_width_top)

	popup.size = Vector2(
		max(POPUP_MIN_SIZE.x, item_size.x + border_size.x),
		max(POPUP_MIN_SIZE.y, item_size.y * item_count + border_size.y)
	)
	
	# Update pager sizes.
	
	popup.pager_left_label_position = popup.label_position
	popup.pager_right_label_position = Vector2(
		item_size.x - item_margins.get_margin(SIDE_LEFT) - right_label_size.x, # Right offset may be assymetrical.
		item_size.y - item_margins.get_margin(SIDE_BOTTOM)
	)


func _show_popup() -> void:
	_is_expanded = true

	var popup_position := Vector2.ZERO
	match direction:
		PopupManager.Direction.BOTTOM_RIGHT:
			popup_position = Vector2(0, size.y)
		PopupManager.Direction.BOTTOM_LEFT:
			popup_position = Vector2(size.x, size.y)
		PopupManager.Direction.TOP_RIGHT:
			popup_position = Vector2(0, 0)
		PopupManager.Direction.TOP_LEFT:
			popup_position = Vector2(size.x, 0)

	PopupManager.show_popup(_popup_control, global_position + popup_position, direction)


func _show_sub_popup(sub_popup: ItemPopup, base_position: Vector2, base_popup: ItemPopup) -> void:
	var popup_position := base_position
	match direction:
		PopupManager.Direction.BOTTOM_RIGHT:
			popup_position += Vector2(base_popup.size.x, 0)
		PopupManager.Direction.BOTTOM_LEFT:
			popup_position += Vector2(0, 0)
		PopupManager.Direction.TOP_RIGHT:
			popup_position += Vector2(base_popup.size.x, base_popup.size.y)
		PopupManager.Direction.TOP_LEFT:
			popup_position = Vector2(0, base_popup.size.y)

	PopupManager.show_popup(sub_popup, base_popup.global_position + popup_position, direction)
	queue_redraw()


func _flatten_options(option_list: Array[Item]) -> void:
	for item in option_list:
		if item.is_sublist: # Ignore sublist items and only append their options to the flat list.
			_flatten_options(item.sublist_options)
			continue
		
		var linked_item := LinkedItem.new()
		linked_item.value = item
		_options_linked_map.push_back(linked_item)


func _link_options() -> void:
	_flatten_options(options)
	if _options_linked_map.size() == 0:
		return
	
	var prev_linked_item: LinkedItem = _options_linked_map[_options_linked_map.size() - 1]
	for linked_item in _options_linked_map:
		linked_item.prev = prev_linked_item.value
		prev_linked_item.next = linked_item.value
		
		prev_linked_item = linked_item


func commit_options() -> void:
	_options_linked_map.clear()
	_link_options()
	
	_popup_control.update_options(options)


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

func _accept_selected(item: Item) -> void:
	var next_item := item if not item.is_sublist else null

	if next_item != _selected_option:
		_selected_option = next_item
		_update_label()
		selected.emit()
	
	if not item.is_sublist:
		PopupManager.hide_popup(_popup_control)
		_is_expanded = false


func get_selected() -> Item:
	return _selected_option


func set_selected(item: Item) -> void:
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


class Item:
	var id: int = -1
	var text: String = ""
	var text_extended: String = ""
	var background_color: Color = Color(0, 0, 0, 0)

	var is_sublist: bool = false
	var sublist_options: Array[Item] = []


	func get_label_text() -> String:
		return text


	func get_option_text() -> String:
		var raw_text := text_extended if not text_extended.is_empty() else text
		if is_sublist:
			raw_text = "> " + raw_text

		return raw_text


class LinkedItem:
	var value: Item = null
	var next: Item = null
	var prev: Item = null


class ItemPopup extends PopupManager.PopupControl:
	signal item_selected(item: Item)
	signal sublist_selected(popup: ItemPopup, item_position: Vector2)
	
	var init_callback: Callable
	var resize_callback: Callable

	var _option_list: Array[Item] = []
	var _popup_map: Dictionary = {}

	var _hovering: bool = false
	var hovered_item: int = -1
	var selected_item: int = -1

	var has_pager: bool = false
	var max_pages: int = 1
	var current_page: int = 0
	var hovered_pager: int = OptionPicker.Pager.NO_PAGER

	var item_origin: Vector2 = Vector2.ZERO
	var item_size: Vector2 = Vector2.ZERO
	var label_position: Vector2 = Vector2.ZERO
	
	var pager_left_label_position: Vector2 = Vector2.ZERO
	var pager_right_label_position: Vector2 = Vector2.ZERO


	func _ready() -> void:
		set_physics_process(false)
		mouse_entered.connect(_hover_popup)
		mouse_exited.connect(_unhover_popup)
		about_to_hide.connect(_propagate_hide_popup)


	func _physics_process(_delta: float) -> void:
		if not _hovering:
			return

		_check_hover_popup()


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton && not event.is_pressed(): # Activate on mouse release.
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				mark_click_handled()
				accept_event()

				var item_index := _find_item_at_pos(mb.position)
				
				# Clicked on a pager.
				if has_pager && item_index == OptionPicker.POPUP_MAX_ITEMS:
					var pager := _find_pager_at_pos(mb.position)
					if pager == OptionPicker.Pager.PAGER_LEFT:
						current_page -= 1
					elif pager == OptionPicker.Pager.PAGER_RIGHT:
						current_page += 1
					current_page = clamp(current_page, 0, max_pages - 1)
					
					queue_redraw()
					
				# Clicked on an item.
				elif item_index >= 0:
					var item_adjusted_index := item_index + current_page * OptionPicker.POPUP_MAX_ITEMS
					if item_adjusted_index >= _option_list.size():
						return # Actually, clicked on an empty space.
					var item := _option_list[item_adjusted_index]
	
					# It's a sublist, toggle it.
					if item.is_sublist:
						selected_item = item_index
						
						if _popup_map.has(item.id):
							var sublist_position := Vector2(0, item_origin.y + item_size.y * item_index)
							sublist_selected.emit(_popup_map[item.id], sublist_position)
					
					# It's a selectable item, select it.
					else:
						item_selected.emit(item)
				return


	func _hover_popup() -> void:
		_check_hover_popup()
		_hovering = true
		set_physics_process(true)


	func _check_hover_popup() -> void:
		var next_item := hovered_item
		var mouse_position := get_local_mouse_position()

		if _option_list.size() == 0:
			next_item = -1
		else:
			next_item = _find_item_at_pos(mouse_position)

		if has_pager && next_item == OptionPicker.POPUP_MAX_ITEMS:
			hovered_item = next_item
			
			var next_pager := _find_pager_at_pos(mouse_position)
			if next_pager != hovered_pager:
				hovered_pager = next_pager
				queue_redraw()
		
		elif next_item != hovered_item:
			hovered_item = next_item
			hovered_pager = OptionPicker.Pager.NO_PAGER
			queue_redraw()


	func _unhover_popup() -> void:
		set_physics_process(false)
		_hovering = false
		hovered_item = -1
		queue_redraw()


	func _propagate_hide_popup() -> void:
		_hovering = false
		hovered_item = -1
		selected_item = -1
		hovered_pager = OptionPicker.Pager.NO_PAGER
		
		for item_id: int in _popup_map:
			var sub_popup: ItemPopup = _popup_map[item_id]
			if sub_popup.is_inside_tree() && sub_popup.is_visible():
				PopupManager.hide_popup(sub_popup)


	func _find_item_at_pos(at_position: Vector2) -> int:
		var item_index := 0
		for item in _option_list:
			var item_offset := Vector2(0, item_size.y * item_index)
			var item_position := item_origin + item_offset
			if Rect2(item_position, item_size).has_point(at_position):
				return item_index

			item_index += 1

		return -1


	func _find_pager_at_pos(at_position: Vector2) -> OptionPicker.Pager:
		return OptionPicker.Pager.PAGER_LEFT if at_position.x < (item_size.x / 2) else OptionPicker.Pager.PAGER_RIGHT


	# Option list management.

	func update_options(options: Array[Item]) -> Array[ItemPopup]:
		_option_list = options
		
		# Update pager metadata.
		current_page = 0
		has_pager = _option_list.size() > (OptionPicker.POPUP_MAX_ITEMS + 1)
		if has_pager:
			max_pages = ceili(_option_list.size() / float(OptionPicker.POPUP_MAX_ITEMS))
		else:
			max_pages = 1
		
		if resize_callback.is_valid():
			resize_callback.call(self)
		
		# Create sub-popups for each sublist item.
		for item in _option_list:
			if not item.is_sublist:
				continue
			
			var sub_popup: ItemPopup
			if _popup_map.has(item.id):
				sub_popup = _popup_map[item.id]
			else:
				sub_popup = ItemPopup.new()
				if init_callback.is_valid():
					init_callback.call(sub_popup)
				_popup_map[item.id] = sub_popup

			sub_popup.update_options(item.sublist_options)
		
		return []


	func get_options() -> Array[Item]:
		return _option_list


	func has_options() -> bool:
		return _option_list.size() > 0
