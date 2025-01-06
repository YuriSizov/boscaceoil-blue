###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name OptionListPopup extends PopupManager.PopupControl

signal item_selected(item: Item)

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

var direction: PopupManager.Direction = PopupManager.Direction.BOTTOM_RIGHT
var _option_list: Array[Item] = []
var _popup_map: Dictionary = {}

# Item position and size.

var _item_origin: Vector2 = Vector2.ZERO
var _item_size: Vector2 = Vector2.ZERO
var _content_position: Vector2 = Vector2.ZERO
var _content_size: Vector2 = Vector2.ZERO

var _empty_label_buffer: TextLine = TextLine.new()
var _item_label_buffers: Array[TextLine] = []
var _largest_item_size: Vector2 = Vector2.ZERO

var _hovering: bool = false
var _hovered_item: int = -1
var _selected_item: int = -1

# Pager logic.

var _has_pager: bool = false
var _max_pages: int = 1
var _current_page: int = 0
var _hovered_pager: int = Pager.NO_PAGER

var _pager_left_label_buffer: TextLine = TextLine.new()
var _pager_right_label_buffer: TextLine = TextLine.new()

# Theme cache.

var _popup_background: StyleBox = null
var _item_margins: StyleBox = null

var _font: Font = null
var _font_size: int = 0
var _empty_font_color: Color = Color.WHITE

var _option_font_color: Color = Color.WHITE
var _option_hover_color: Color = Color.WHITE

var _sublist_font_color: Color = Color.WHITE
var _sublist_inactive_font_color: Color = Color.WHITE
var _sublist_color: Color = Color.WHITE
var _sublist_hover_color: Color = Color.WHITE
var _sublist_selected_color: Color = Color.WHITE


func _enter_tree() -> void:
	_update_theme()


func _ready() -> void:
	set_physics_process(false)
	
	theme_changed.connect(_update_theme)
	mouse_entered.connect(_hover_popup)
	mouse_exited.connect(_unhover_popup)
	about_to_popup.connect(_update_popup_size)
	about_to_hide.connect(_propagate_hide_popup)


func _update_theme() -> void:
	_popup_background = get_theme_stylebox("popup_panel", "OptionListPopup")
	_item_margins = get_theme_stylebox("item_margins", "OptionListPopup")
	
	_font = get_theme_default_font()
	_font_size = get_theme_font_size("option_font_size", "OptionListPopup")
	_empty_font_color = get_theme_color("empty_font_color", "OptionListPopup")
	
	_option_font_color = get_theme_color("option_font_color", "OptionListPopup")
	_option_hover_color = get_theme_color("option_hover_color", "OptionListPopup")
	
	_sublist_font_color = get_theme_color("sublist_font_color", "OptionListPopup")
	_sublist_inactive_font_color = get_theme_color("sublist_inactive_font_color", "OptionListPopup")
	_sublist_color = get_theme_color("sublist_color", "OptionListPopup")
	_sublist_hover_color = get_theme_color("sublist_hover_color", "OptionListPopup")
	_sublist_selected_color = get_theme_color("sublist_selected_color", "OptionListPopup")
	
	_update_popup_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up popups which are not currently mounted to the tree.
		for item_id: int in _popup_map:
			var sub_popup: OptionListPopup = _popup_map[item_id]
			if is_instance_valid(sub_popup):
				sub_popup.queue_free()


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
			if _has_pager && item_index == POPUP_MAX_ITEMS:
				var pager := _find_pager_at_pos(mb.position)
				if pager == Pager.PAGER_LEFT:
					_current_page -= 1
				elif pager == Pager.PAGER_RIGHT:
					_current_page += 1
				_current_page = clamp(_current_page, 0, _max_pages - 1)
				
				queue_redraw()
				
			# Clicked on an item.
			elif item_index >= 0:
				var item_adjusted_index := item_index + _current_page * POPUP_MAX_ITEMS
				if item_adjusted_index >= _option_list.size():
					return # Actually, clicked on an empty space.
				var item := _option_list[item_adjusted_index]
				
				# It's a sublist, toggle it.
				if item.is_sublist:
					_selected_item = item_index
					
					if _popup_map.has(item.id):
						var sublist_position := Vector2(0, _item_origin.y + _item_size.y * item_index)
						show_sub_popup(self, _popup_map[item.id], sublist_position)
				
				# It's a selectable item, select it.
				else:
					item_selected.emit(item)
				
				queue_redraw()
			return


func _draw() -> void:
	# Draw the background panel.
	draw_style_box(_popup_background, Rect2(Vector2.ZERO, size))

	# Draw options.

	# Draw an empty placeholder if there are no options available.
	if _option_list.size() <= 0:
		var label_position := _item_origin + _content_position
		label_position.y += (_content_size.y - _empty_label_buffer.get_size().y) / 2.0
		_empty_label_buffer.draw(get_canvas_item(), label_position, _empty_font_color)
	else:
		# Either draw exactly POPUP_MAX_ITEMS + 1 items, or draw POPUP_MAX_ITEMS and then a pager.
		var max_items := _option_list.size()
		if _has_pager:
			max_items = POPUP_MAX_ITEMS
		
		# Draw the items, up to the limit.
		for item_index in max_items:
			var item_adjusted_index := item_index + _current_page * POPUP_MAX_ITEMS
			if item_adjusted_index >= _option_list.size():
				break
			
			var item := _option_list[item_adjusted_index]
			var item_text_buffer := _item_label_buffers[item_adjusted_index]
			var item_position := _item_origin + Vector2(0, _item_size.y * item_index)
			var item_rect := Rect2(item_position, _item_size)
			
			# Draw item background, either default or custom.
			if item.background_color.a > 0:
				draw_rect(item_rect, item.background_color)
			elif item.is_sublist:
				draw_rect(item_rect, _sublist_color)
			
			# Draw item's selected or hover indicator.
			if item.is_sublist && _selected_item == item_index:
				draw_rect(item_rect, _sublist_selected_color)
			if _hovered_item == item_index:
				var item_hover_color := _sublist_hover_color if item.is_sublist else _option_hover_color
				draw_rect(item_rect, item_hover_color)
			
			# Draw item label.
			var label_position := item_position + _content_position
			label_position.y += (_content_size.y - item_text_buffer.get_size().y) / 2.0
			var item_font_color := _sublist_font_color if item.is_sublist else _option_font_color
			item_text_buffer.draw(get_canvas_item(), label_position, item_font_color)
		
		# Draw the pager.
		if _has_pager:
			var popup_index := POPUP_MAX_ITEMS
			var pager_offset := Vector2(0, _item_size.y * popup_index)
			var pager_size := Vector2(_item_size.x / 2, _item_size.y)
			
			# Draw the left pager (previous page).
			
			var left_pager_rect := Rect2(_item_origin + pager_offset, pager_size)
			draw_rect(left_pager_rect, _sublist_color)
			if _current_page != 0 && _hovered_item == popup_index && _hovered_pager == Pager.PAGER_LEFT:
				draw_rect(left_pager_rect, _sublist_hover_color)
			
			var left_pager_label_position := left_pager_rect.position + _content_position
			left_pager_label_position.y += (_content_size.y - _pager_left_label_buffer.get_size().y) / 2.0
			var left_pager_color := _sublist_font_color if _current_page != 0 else _sublist_inactive_font_color
			_pager_left_label_buffer.draw(get_canvas_item(), left_pager_label_position, left_pager_color)
			
			# Draw the right pager (next page).
			
			var right_pager_rect := Rect2(left_pager_rect.position + Vector2(pager_size.x, 0), pager_size)
			draw_rect(right_pager_rect, _sublist_color)
			if _current_page != (_max_pages - 1) && _hovered_item == popup_index && _hovered_pager == Pager.PAGER_RIGHT:
				draw_rect(right_pager_rect, _sublist_hover_color)
			
			var right_pager_label_position := left_pager_rect.position + _content_position # Using left margin for symmetry.
			right_pager_label_position.x += _content_size.x - _pager_right_label_buffer.get_size().x + (_item_margins.get_margin(SIDE_RIGHT) - _item_margins.get_margin(SIDE_LEFT))
			right_pager_label_position.y += (_content_size.y - _pager_right_label_buffer.get_size().y) / 2.0
			var right_pager_color := _sublist_font_color if _current_page != (_max_pages - 1) else _sublist_inactive_font_color
			_pager_right_label_buffer.draw(get_canvas_item(), right_pager_label_position, right_pager_color)


func _update_popup_size() -> void:
	if not is_inside_tree():
		return
	
	_shape_permanent_text()
	_shape_item_text()
	
	_content_size = Vector2.ZERO
	var item_count := 0
	
	# Find the minimum required size using the longest option text, the pager, and the empty label.
	
	if _option_list.size() <= 0:
		_content_size = _empty_label_buffer.get_size()
		item_count = 1
	else:
		_content_size = _largest_item_size
		item_count = mini(POPUP_MAX_ITEMS + 1, _option_list.size()) # Reserve one item slot for navigation.
	
	if _has_pager:
		var pager_min_width := maxf(_pager_left_label_buffer.get_size().x, _pager_right_label_buffer.get_size().x) * 2
		var pager_min_height := maxf(_pager_left_label_buffer.get_size().y, _pager_right_label_buffer.get_size().y)
		_content_size.x = maxf(_content_size.x, pager_min_width)
		_content_size.y = maxf(_content_size.y, pager_min_height)
	
	# Calculate additional sizes.
	
	_content_position = Vector2(
		_item_margins.get_margin(SIDE_LEFT),
		_item_margins.get_margin(SIDE_TOP)
	)
	_item_size = _content_size + Vector2(
		_item_margins.get_margin(SIDE_LEFT) + _item_margins.get_margin(SIDE_RIGHT),
		_item_margins.get_margin(SIDE_TOP) + _item_margins.get_margin(SIDE_BOTTOM)
	)
	
	_item_origin = Vector2(
		_popup_background.border_width_left,
		_popup_background.border_width_top
	)
	var border_size := Vector2(
		_popup_background.border_width_left + _popup_background.border_width_right,
		_popup_background.border_width_top + _popup_background.border_width_bottom
	)
	
	size = Vector2(
		maxf(POPUP_MIN_SIZE.x, _item_size.x + border_size.x),
		maxf(POPUP_MIN_SIZE.y, _item_size.y * item_count + border_size.y)
	)


func _shape_permanent_text() -> void:
	_empty_label_buffer.clear()
	_empty_label_buffer.add_string(POPUP_EMPTY_LABEL, _font, _font_size)
	
	_pager_left_label_buffer.clear()
	_pager_left_label_buffer.add_string(PAGER_LEFT_LABEL, _font, _font_size)
	_pager_right_label_buffer.clear()
	_pager_right_label_buffer.add_string(PAGER_RIGHT_LABEL, _font, _font_size)


func _shape_item_text() -> void:
	_item_label_buffers.clear()
	_largest_item_size = Vector2.ZERO
	
	for item in _option_list:
		var text_buffer := TextLine.new()
		var text := item.get_option_text()
		text_buffer.add_string(text, _font, _font_size)
		
		if text_buffer.get_size().x > _largest_item_size.x:
			_largest_item_size.x = text_buffer.get_size().x
		if text_buffer.get_size().y > _largest_item_size.y:
			_largest_item_size.y = text_buffer.get_size().y
		
		_item_label_buffers.push_back(text_buffer)


# Interactions.

func _hover_popup() -> void:
	_check_hover_popup()
	_hovering = true
	set_physics_process(true)


func _check_hover_popup() -> void:
	var next_item := _hovered_item
	var mouse_position := get_local_mouse_position()
	
	if _option_list.size() == 0:
		next_item = -1
	else:
		next_item = _find_item_at_pos(mouse_position)
	
	if _has_pager && next_item == POPUP_MAX_ITEMS:
		_hovered_item = next_item
		
		var next_pager := _find_pager_at_pos(mouse_position)
		if next_pager != _hovered_pager:
			_hovered_pager = next_pager
			queue_redraw()
	
	elif next_item != _hovered_item:
		_hovered_item = next_item
		_hovered_pager = Pager.NO_PAGER
		queue_redraw()


func _unhover_popup() -> void:
	set_physics_process(false)
	_hovering = false
	_hovered_item = -1
	queue_redraw()


func _propagate_hide_popup() -> void:
	_hovering = false
	_hovered_item = -1
	_selected_item = -1
	_hovered_pager = Pager.NO_PAGER
	
	for item_id: int in _popup_map:
		var sub_popup: OptionListPopup = _popup_map[item_id]
		if sub_popup.is_inside_tree() && sub_popup.is_visible():
			PopupManager.hide_popup(sub_popup)


func _find_item_at_pos(at_position: Vector2) -> int:
	var item_index := 0
	for item in _option_list:
		var item_offset := Vector2(0, _item_size.y * item_index)
		var item_position := _item_origin + item_offset
		if Rect2(item_position, _item_size).has_point(at_position):
			return item_index
		
		item_index += 1
	
	return -1


func _find_pager_at_pos(at_position: Vector2) -> Pager:
	return Pager.PAGER_LEFT if at_position.x < (_item_size.x / 2) else Pager.PAGER_RIGHT


# Popup management.

func show_popup(base_position: Vector2, snap_size: Vector2) -> void:
	var popup_position := Vector2.ZERO
	match direction:
		PopupManager.Direction.BOTTOM_RIGHT:
			popup_position = Vector2(0, snap_size.y)
		PopupManager.Direction.BOTTOM_LEFT:
			popup_position = Vector2(snap_size.x, snap_size.y)
		PopupManager.Direction.TOP_RIGHT:
			popup_position = Vector2(0, 0)
		PopupManager.Direction.TOP_LEFT:
			popup_position = Vector2(snap_size.x, 0)

	PopupManager.show_popup(self, base_position + popup_position, direction)


func show_sub_popup(base_popup: OptionListPopup, sub_popup: OptionListPopup, base_position: Vector2) -> void:
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


# Option list management.

func update_options(options: Array[Item]) -> Array[OptionListPopup]:
	_option_list = options
	
	# Update pager metadata.
	_current_page = 0
	_has_pager = _option_list.size() > (POPUP_MAX_ITEMS + 1)
	if _has_pager:
		_max_pages = ceili(_option_list.size() / float(POPUP_MAX_ITEMS))
	else:
		_max_pages = 1
	
	_update_popup_size()
	
	# Create sub-popups for each sublist item.
	for item in _option_list:
		if not item.is_sublist:
			continue
		
		var sub_popup: OptionListPopup
		if _popup_map.has(item.id):
			sub_popup = _popup_map[item.id]
		else:
			sub_popup = OptionListPopup.new()
			sub_popup.item_selected.connect(item_selected.emit)
			
			_popup_map[item.id] = sub_popup
		
		sub_popup.update_options(item.sublist_options)
	
	return []


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
