###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ItemDock extends Control

signal item_created()
signal item_selected(item_index: int)
signal item_deleted(item_index: int)

const UP_ARROW := preload("res://gui/theme/up_arrow_small.tres")
const DOWN_ARROW := preload("res://gui/theme/down_arrow_small.tres")

const DROP_OFFSET := 16
enum DropAlignment {
	CENTER,
	LEFT,
	RIGHT
}

@export var add_button_text: String = "ADD ITEM":
	set(value):
		add_button_text = value
		_update_button_label()

@export var drop_alignment: DropAlignment = DropAlignment.CENTER:
	set(value):
		drop_alignment = value
		_update_delete_area()

var _item_rects: Array[Rect2] = []
var _max_item_amount: int = 0
var _scroll_offset: int = 0
var _has_prev_pager: bool = false
var _has_next_pager: bool = false

var _hovering: bool = false
var _hovered_item: int = -1
var _drag_unique_hash: int = -1

@onready var _add_button: Button = %AddItem
@onready var _delete_area: DeleteArea = %DeleteArea


func _init() -> void:
	_drag_unique_hash = hash(get_canvas_item().get_id())


func _ready() -> void:
	set_physics_process(false)
	_update_button_label()
	_update_delete_area()
	
	_delete_area.set_drag_forwarding(Callable(), _can_drop_data_fw, _drop_data_fw)
	
	mouse_entered.connect(_start_hovering)
	mouse_exited.connect(_stop_hovering)
	
	_add_button.pressed.connect(item_created.emit)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		var mb := event as InputEventMouseButton
		
		var item_index := 0
		for item_rect in _item_rects:
			if item_rect.has_point(mb.position):
				if item_index == 0 && _has_prev_pager:
					_change_scroll_offset(-1)
				elif item_index == (_max_item_amount - 1) && _has_next_pager:
					_change_scroll_offset(1)
				else:
					item_selected.emit(item_index + _scroll_offset)
				break
			
			item_index += 1


func _physics_process(_delta: float) -> void:
	if not _hovering:
		return
	
	_hovered_item = -1
	var mouse_position := get_local_mouse_position()
	
	var item_index := 0
	for item_rect in _item_rects:
		if item_rect.has_point(mouse_position):
			_hovered_item = item_index
			break
		
		item_index += 1
	
	queue_redraw()


func _draw() -> void:
	var available_size := get_available_size()
	
	# Draw the background panel.
	var background_color := get_theme_color("dock_color", "ItemDock")
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	
	# Draw item blocks.
	
	_item_rects.clear()

	var item_height := get_theme_constant("item_height", "ItemDock")
	var content_margins := get_theme_stylebox("content_margins", "ItemDock")
	var item_origin := Vector2(content_margins.get_margin(SIDE_LEFT), content_margins.get_margin(SIDE_TOP))
	
	var total_item_amount := _get_total_item_amount()
	_max_item_amount = floori(available_size.y / float(item_height))
	_has_prev_pager = (total_item_amount > _max_item_amount && _scroll_offset > 0)
	_has_next_pager = (total_item_amount > _max_item_amount && _scroll_offset < (total_item_amount - _max_item_amount))
	
	var selected_rect := Rect2(-1, -1, -1, -1)
	var hovered_rect := Rect2(-1, -1, -1, -1)
	var visible_index := 0
	while visible_index < _max_item_amount:
		var item_index := visible_index + _scroll_offset
		if item_index >= total_item_amount:
			break
		
		var item_position := item_origin + Vector2(0, visible_index * item_height)
		var item_size := Vector2(available_size.x - content_margins.get_margin(SIDE_LEFT) - content_margins.get_margin(SIDE_RIGHT), item_height)
		var item_rect := Rect2(item_position, item_size)
		
		# Draw the pager instead of the first item.
		if visible_index == 0 && _has_prev_pager:
			_draw_pager(item_rect, UP_ARROW)
			if visible_index == _hovered_item:
				hovered_rect = item_rect
			
			_item_rects.push_back(item_rect)
			visible_index += 1
			continue

		# Draw the pager instead of the last item.
		if visible_index == (_max_item_amount - 1) && _has_next_pager:
			_draw_pager(item_rect, DOWN_ARROW)
			if visible_index == _hovered_item:
				hovered_rect = item_rect
			
			_item_rects.push_back(item_rect)
			visible_index += 1
			continue
		
		if visible_index == _hovered_item:
			hovered_rect = item_rect
		if item_index == _get_current_item_index():
			selected_rect = item_rect
		_item_rects.push_back(item_rect)

		_draw_item(self, item_index, item_rect)
		visible_index += 1
	
	# Draw the cursor for the selected item.
	if selected_rect.position.x >= 0 && selected_rect.position.y >= 0:
		_draw_selected_cursor(self, selected_rect)
	
	# Draw the cursor for the hovered item.
	if hovered_rect.position.x >= 0 && hovered_rect.position.y >= 0:
		var cursor_width := get_theme_constant("cursor_width", "ItemDock")
		var cursor_color := get_theme_color("cursor_color", "ItemDock")
		draw_rect(hovered_rect, cursor_color, false, cursor_width)


func _draw_item(_on_control: Control, _item_index: int, _item_rect: Rect2) -> void:
	pass


func _draw_item_preview(preview: ItemDragPreview, item_index: int) -> void:
	var item_rect := Rect2(Vector2.ZERO, preview.size)
	_draw_item(preview, item_index, item_rect)
	_draw_selected_cursor(preview, item_rect)


func _draw_pager(item_rect: Rect2, arrow: Texture2D) -> void:
	var texture_size := arrow.get_size()
	var texture_ratio := texture_size.x / texture_size.y

	var icon_width := get_theme_constant("pager_icon_width", "ItemDock")
	var icon_size := Vector2(icon_width, icon_width / texture_ratio)
	var icon_position := item_rect.position + item_rect.size / 2 - texture_size / 2
	
	draw_texture_rect(arrow, Rect2(icon_position, icon_size), false)


func _draw_selected_cursor(on_control: Control, item_rect: Rect2) -> void:
	var cursor_width := get_theme_constant("cursor_width", "ItemDock")
	var selected_color := get_theme_color("selected_color", "ItemDock")
	var selected_shadow_color := get_theme_color("selected_shadow_color", "ItemDock")
	
	var cursor_shadow_position := item_rect.position + Vector2(cursor_width, cursor_width)
	var cursor_shadow_size := item_rect.size - Vector2(cursor_width, cursor_width) * 2
	
	on_control.draw_rect(item_rect, selected_color, false, cursor_width)
	on_control.draw_rect(Rect2(cursor_shadow_position, cursor_shadow_size), selected_shadow_color, false, cursor_width)


func _update_button_label() -> void:
	if not is_inside_tree():
		return
	
	_add_button.text = add_button_text


func _update_delete_area() -> void:
	if not is_inside_tree():
		return
	
	match drop_alignment:
		DropAlignment.CENTER:
			_delete_area.grow_horizontal = Control.GROW_DIRECTION_BOTH
			_delete_area.offset_left = DROP_OFFSET
			_delete_area.offset_right = -DROP_OFFSET
		DropAlignment.LEFT:
			_delete_area.grow_horizontal = Control.GROW_DIRECTION_END
			_delete_area.offset_left = 0
			_delete_area.offset_right = -DROP_OFFSET
		DropAlignment.RIGHT:
			_delete_area.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			_delete_area.offset_left = DROP_OFFSET
			_delete_area.offset_right = 0


func get_available_size() -> Vector2:
	var available_size := size
	if not is_inside_tree():
		return available_size
	
	if _add_button:
		available_size.y -= (size.y - _add_button.position.y)
	
	return available_size


# Data.

func _get_total_item_amount() -> int:
	return 0


func _get_current_item_index() -> int:
	return -1


# Interactions.

func _change_scroll_offset(delta: int) -> void:
	var total_item_amount := _get_total_item_amount()
	_scroll_offset = clampi(_scroll_offset + delta, 0, total_item_amount - _max_item_amount)
	queue_redraw()


func _start_hovering() -> void:
	_hovered_item = -1
	_hovering = true
	set_physics_process(true)
	
	queue_redraw()


func _stop_hovering() -> void:
	set_physics_process(false)
	_hovered_item = -1
	_hovering = false
	
	queue_redraw()


func _get_drag_data(at_position: Vector2) -> Variant:
	var visual_index := 0
	for item_rect in _item_rects:
		if item_rect.has_point(at_position):
			if visual_index == 0 && _has_prev_pager:
				return null
			if visual_index == (_max_item_amount - 1) && _has_next_pager:
				return null
			
			var item_index := visual_index + _scroll_offset
			
			var drag_data := ItemDragData.new()
			drag_data.unique_hash = _drag_unique_hash
			drag_data.item_index = item_index
			
			var preview := ItemDragPreview.new()
			preview.size = item_rect.size
			preview.draw.connect(_draw_item_preview.bind(preview, item_index))
			preview.drag_ended.connect(func() -> void: _delete_area.fade_out())
			set_drag_preview(preview)
			
			_delete_area.fade_in()
			
			return drag_data
		
		visual_index += 1
	return null


func _can_drop_data_fw(_at_position: Vector2, data: Variant) -> bool:
	if data is ItemDragData && (data as ItemDragData).unique_hash == _drag_unique_hash:
		return true
	return false


func _drop_data_fw(_at_position: Vector2, data: Variant) -> void:
	if data is ItemDragData && (data as ItemDragData).unique_hash == _drag_unique_hash:
		var item_data := data as ItemDragData
		item_deleted.emit(item_data.item_index)


class ItemDragData:
	## Helps to identify own drag data.
	var unique_hash: int = -1
	var item_index: int = -1


class ItemDragPreview extends Control:
	signal drag_ended()
	
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			drag_ended.emit()
