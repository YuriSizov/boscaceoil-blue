###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends ItemDock

## Current edited song.
var current_song: Song = null

# Theme cache.

var _font: Font = null
var _font_size: int = -1
var _font_color: Color = Color.WHITE
var _shadow_color: Color = Color.WHITE
var _shadow_size: Vector2 = Vector2.ZERO

var _item_height: int = -1
var _item_label_offset: Vector2 = Vector2.ZERO
var _item_gutter_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	super()
	drag_source_id = Controller.DragSources.INSTRUMENT_DOCK
	
	_edit_current_song()
	
	_update_theme()
	theme_changed.connect(_update_theme)
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_ADD_NEW, _add_button.get_global_visual_rect)
		
		item_created.connect(Controller.create_and_edit_instrument)
		item_selected.connect(Controller.edit_instrument)
		item_deleted.connect(Controller.delete_instrument)
		
		Controller.song_loaded.connect(_edit_current_song)
		Controller.song_instrument_created.connect(queue_redraw)
		Controller.song_instrument_changed.connect(queue_redraw)


func _update_theme() -> void:
	_font = get_theme_default_font()
	_font_size = get_theme_default_font_size()
	_font_color = get_theme_color("font_color", "Label")
	_shadow_color = get_theme_color("shadow_color", "Label")
	_shadow_size = Vector2(get_theme_constant("shadow_offset_x", "Label"), get_theme_constant("shadow_offset_y", "Label"))
	
	_item_height = get_theme_constant("item_height", "ItemDock")
	_item_label_offset.x = get_theme_constant("item_label_offset_x", "ItemDock")
	_item_label_offset.y = get_theme_constant("item_label_offset_y", "ItemDock")
	_item_gutter_size = _font.get_string_size("00", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size) + Vector2(20, 0)
	_item_gutter_size.y = _item_height


func _draw_item(on_control: Control, item_index: int, item_rect: Rect2) -> void:
	var instrument := Controller.current_song.instruments[item_index]

	# Draw instrument background and gutter.

	var item_theme := Controller.get_instrument_theme(instrument)
	var item_color := item_theme.get_color("item_color", "InstrumentDock")
	var item_gutter_color := item_theme.get_color("item_gutter_color", "InstrumentDock")
	
	on_control.draw_rect(item_rect, item_color)
	on_control.draw_rect(Rect2(item_rect.position, _item_gutter_size), item_gutter_color)

	# Draw gutter string.
	
	var string_position := item_rect.position + _item_label_offset + Vector2(0, item_rect.size.y)
	var shadow_position := string_position + _shadow_size
	var gutter_string := "%d" % [ item_index + 1 ]
	on_control.draw_string(_font, shadow_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
	on_control.draw_string(_font, string_position, gutter_string, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)

	# Draw instrument name.
	
	string_position.x += _item_gutter_size.x
	shadow_position = string_position + _shadow_size
	on_control.draw_string(_font, shadow_position, instrument.name, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _shadow_color)
	on_control.draw_string(_font, string_position, instrument.name, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _font_color)


# Data.

func _get_total_item_amount() -> int:
	if Engine.is_editor_hint() || not Controller.current_song:
		return 0
	
	return Controller.current_song.instruments.size()


func _get_current_item_index() -> int:
	if Engine.is_editor_hint() || not Controller.current_song:
		return -1
	
	return Controller.current_instrument_index


func _edit_current_song() -> void:
	if Engine.is_editor_hint():
		return
	
	if current_song:
		current_song.instrument_added.disconnect(queue_redraw.unbind(1))
		current_song.instrument_removed.disconnect(queue_redraw.unbind(1))
	
	if not Controller.current_song:
		return
	
	current_song = Controller.current_song
	
	if current_song:
		current_song.instrument_added.connect(queue_redraw.unbind(1))
		current_song.instrument_removed.connect(queue_redraw.unbind(1))
	
	queue_redraw()
