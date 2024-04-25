###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends Control

const UP_ARROW := preload("res://gui/theme/up_arrow_small.tres")
const DOWN_ARROW := preload("res://gui/theme/down_arrow_small.tres")

var _item_rects: Array[Rect2] = []
var _max_item_amount: int = 0

var _hovering: bool = false
var _hovered_item: int = -1

var _scroll_offset: int = 0
var _has_prev_pager: bool = false
var _has_next_pager: bool = false

@onready var _add_button: Button = %AddInstrument
@onready var _delete_area: DeleteArea = %DeleteArea


func _ready() -> void:
	set_physics_process(false)
	_delete_area.set_drag_forwarding(Callable(), _can_drop_data_fw, _drop_data_fw)
	
	mouse_entered.connect(_start_hovering)
	mouse_exited.connect(_stop_hovering)
	
	_add_button.pressed.connect(_add_new_instrument)
	
	if not Engine.is_editor_hint():
		Controller.song_instrument_changed.connect(queue_redraw)


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
					Controller.edit_instrument(item_index + _scroll_offset)
				break
			
			item_index += 1


func _physics_process(_delta: float) -> void:
	if not _hovering:
		return
	
	_hovered_item = -1
	var mouse_position := get_local_mouse_position()
	
	var instrument_index := 0
	for item_rect in _item_rects:
		if item_rect.has_point(mouse_position):
			_hovered_item = instrument_index
			break
		
		instrument_index += 1
	
	queue_redraw()


func _draw() -> void:
	var available_size := get_available_size()
	
	# Draw the background panel.
	var background_color := get_theme_color("dock_color", "InstrumentDock")
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	
	# Draw instrument blocks.
	
	_item_rects.clear()
	if not Engine.is_editor_hint() && Controller.current_song:
		var item_height := get_theme_constant("item_height", "InstrumentDock")
		var content_margins := get_theme_stylebox("content_margins", "InstrumentDock")
		
		var font := get_theme_default_font()
		var font_size := get_theme_default_font_size()
		var font_color := get_theme_color("font_color", "Label")
		var shadow_color := get_theme_color("shadow_color", "Label")
		var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
		
		var item_origin := Vector2(content_margins.get_margin(SIDE_LEFT), content_margins.get_margin(SIDE_TOP))
		var item_gutter_size := font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(20, 0)
		item_gutter_size.y = item_height
		
		var total_item_amount := Controller.current_song.instruments.size()
		_max_item_amount = floori(available_size.y / float(item_height))
		_has_prev_pager = (total_item_amount > _max_item_amount && _scroll_offset > 0)
		_has_next_pager = (total_item_amount > _max_item_amount && _scroll_offset < (total_item_amount - _max_item_amount))
		
		var selected_rect := Rect2(-1, -1, -1, -1)
		var hovered_rect := Rect2(-1, -1, -1, -1)
		var item_index := 0
		while item_index < _max_item_amount:
			var instrument_index := item_index + _scroll_offset
			if instrument_index >= total_item_amount:
				break
			
			var item_position := item_origin + Vector2(0, item_index * item_height)
			var item_size := Vector2(available_size.x - content_margins.get_margin(SIDE_LEFT) - content_margins.get_margin(SIDE_RIGHT), item_height)
			var item_rect := Rect2(item_position, item_size)
			
			# Draw the pager instead of the first item.
			if item_index == 0 && _has_prev_pager:
				_draw_pager(item_rect, UP_ARROW)
				if item_index == _hovered_item:
					hovered_rect = item_rect
				
				_item_rects.push_back(item_rect)
				item_index += 1
				continue

			# Draw the pager instead of the last item.
			if item_index == (_max_item_amount - 1) && _has_next_pager:
				_draw_pager(item_rect, DOWN_ARROW)
				if item_index == _hovered_item:
					hovered_rect = item_rect
				
				_item_rects.push_back(item_rect)
				item_index += 1
				continue
			
			if item_index == _hovered_item:
				hovered_rect = item_rect
			if instrument_index == Controller.current_instrument_index:
				selected_rect = item_rect
			_item_rects.push_back(item_rect)

			_draw_item(self, instrument_index, item_rect, item_gutter_size, font, font_size, font_color, shadow_size, shadow_color)
			item_index += 1
		
		# Draw the cursor for the selected instrument.
		if selected_rect.position.x >= 0 && selected_rect.position.y >= 0:
			_draw_selected_cursor(self, selected_rect)
		
		# Draw the cursor for the hovered item.
		if hovered_rect.position.x >= 0 && hovered_rect.position.y >= 0:
			var cursor_width := get_theme_constant("cursor_width", "InstrumentDock")
			var cursor_color := get_theme_color("cursor_color", "InstrumentDock")
			draw_rect(hovered_rect, cursor_color, false, cursor_width)


func _draw_item(on_control: Control, instrument_index: int, item_rect: Rect2, item_gutter_size: Vector2, font: Font, font_size: int, font_color: Color, shadow_size: Vector2, shadow_color: Color) -> void:
	var instrument := Controller.current_song.instruments[instrument_index]

	# Draw instrument background and gutter.

	var item_theme := Controller.get_instrument_theme(instrument)
	var item_color := item_theme.get_color("item_color", "InstrumentDock")
	var item_gutter_color := item_theme.get_color("item_gutter_color", "InstrumentDock")
	
	on_control.draw_rect(item_rect, item_color)
	on_control.draw_rect(Rect2(item_rect.position, item_gutter_size), item_gutter_color)

	# Draw gutter string.
	
	var string_position := item_rect.position + Vector2(8, item_rect.size.y - 10)
	var shadow_position := string_position + shadow_size
	var gutter_string := "%d" % [ instrument_index + 1 ]
	on_control.draw_string(font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
	on_control.draw_string(font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

	# Draw instrument name.
	
	string_position.x += item_gutter_size.x
	shadow_position = string_position + shadow_size
	on_control.draw_string(font, shadow_position, instrument.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
	on_control.draw_string(font, string_position, instrument.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)


func _draw_item_preview(preview: InstrumentDragPreview) -> void:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var font_color := get_theme_color("font_color", "Label")
	var shadow_color := get_theme_color("shadow_color", "Label")
	var shadow_size := Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	
	var item_gutter_size := font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(20, 0)
	item_gutter_size.y = preview.size.y
	var item_rect := Rect2(Vector2.ZERO, preview.size)

	_draw_item(preview, preview.instrument_index, item_rect, item_gutter_size, font, font_size, font_color, shadow_size, shadow_color)
	_draw_selected_cursor(preview, item_rect)


func _draw_pager(item_rect: Rect2, arrow: Texture2D) -> void:
	var texture_size := arrow.get_size()
	var texture_ratio := texture_size.x / texture_size.y

	var icon_width := get_theme_constant("pager_icon_width", "InstrumentDock")
	var icon_size := Vector2(icon_width, icon_width / texture_ratio)
	var icon_position := item_rect.position + item_rect.size / 2 - texture_size / 2
	
	draw_texture_rect(arrow, Rect2(icon_position, icon_size), false)


func _draw_selected_cursor(on_control: Control, item_rect: Rect2) -> void:
	var cursor_width := get_theme_constant("cursor_width", "InstrumentDock")
	var selected_color := get_theme_color("selected_color", "InstrumentDock")
	var selected_shadow_color := get_theme_color("selected_shadow_color", "InstrumentDock")
	
	var cursor_shadow_position := item_rect.position + Vector2(cursor_width, cursor_width)
	var cursor_shadow_size := item_rect.size - Vector2(cursor_width, cursor_width) * 2
	
	on_control.draw_rect(item_rect, selected_color, false, cursor_width)
	on_control.draw_rect(Rect2(cursor_shadow_position, cursor_shadow_size), selected_shadow_color, false, cursor_width)


func get_available_size() -> Vector2:
	var available_size := size
	if not is_inside_tree():
		return available_size
	
	if _add_button:
		available_size.y -= (size.y - _add_button.position.y)
	
	return available_size


# Interactions.

func _change_scroll_offset(delta: int) -> void:
	var total_item_amount := Controller.current_song.instruments.size()
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
	var item_index := 0
	for item_rect in _item_rects:
		if item_rect.has_point(at_position):
			if item_index == 0 && _has_prev_pager:
				return null
			if item_index == (_max_item_amount - 1) && _has_next_pager:
				return null
			
			var drag_data := InstrumentDragData.new()
			drag_data.instrument_index = item_index + _scroll_offset
			
			var preview := InstrumentDragPreview.new()
			preview.instrument_index = item_index + _scroll_offset
			preview.size = item_rect.size
			preview.draw.connect(_draw_item_preview.bind(preview))
			preview.drag_ended.connect(func() -> void: _delete_area.fade_out())
			set_drag_preview(preview)
			
			_delete_area.fade_in()
			
			return drag_data
		
		item_index += 1
	return null


func _can_drop_data_fw(_at_position: Vector2, data: Variant) -> bool:
	if data is InstrumentDragData:
		return true
	return false


func _drop_data_fw(_at_position: Vector2, data: Variant) -> void:
	if data is InstrumentDragData:
		var instrument_data := data as InstrumentDragData
		_delete_instrument(instrument_data.instrument_index)


# Management.

func _add_new_instrument() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	Controller.create_and_edit_instrument()


func _delete_instrument(instrument_index: int) -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	Controller.delete_instrument(instrument_index)


class InstrumentDragData:
	var instrument_index: int = -1


class InstrumentDragPreview extends Control:
	signal drag_ended()
	
	var instrument_index: int = -1
	
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			drag_ended.emit()
