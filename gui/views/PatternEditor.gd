###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends VBoxContainer

## Current edited pattern.
var current_pattern: Pattern = null

@onready var _instrument_picker: OptionPicker = %InstrumentPicker
@onready var _scale_picker: OptionPicker = %ScalePicker
@onready var _key_picker: OptionPicker = %KeyPicker
@onready var _note_shift_up: Button = %NoteShiftUp
@onready var _note_shift_down: Button = %NoteShiftDown


func _ready() -> void:
	_update_scale_options()
	_update_key_options()
	
	_instrument_picker.selected.connect(_change_instrument)
	_scale_picker.selected.connect(_change_scale)
	_key_picker.selected.connect(_change_key)
	
	_note_shift_up.pressed.connect(_shift_notes.bind(1))
	_note_shift_down.pressed.connect(_shift_notes.bind(-1))

	_edit_current_pattern()
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_update_pattern_properties)
		Controller.song_instrument_changed.connect(_update_pattern_instrument)


func _update_scale_options() -> void:
	_scale_picker.options = []
	
	var selected_item: OptionPicker.Item = null
	for i in Scale.MAX:
		var item := OptionPicker.Item.new()
		item.id = i
		item.text = Scale.get_scale_name(i)

		if current_pattern && current_pattern.scale == i:
			selected_item = item

		_scale_picker.options.push_back(item)
	
	_scale_picker.commit_options()
	_scale_picker.set_selected(selected_item)


func _update_key_options() -> void:
	_key_picker.options = []
	
	var selected_item: OptionPicker.Item = null
	for i in Note.MAX:
		var item := OptionPicker.Item.new()
		item.id = i
		item.text = Note.get_note_name(i)

		if current_pattern && current_pattern.key == i:
			selected_item = item
		
		_key_picker.options.push_back(item)
	
	_key_picker.commit_options()
	_scale_picker.set_selected(selected_item)


func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_pattern:
		current_pattern.instrument_changed.disconnect(_update_pattern_instrument)
	
	current_pattern = Controller.get_current_pattern()

	if current_pattern:
		current_pattern.instrument_changed.connect(_update_pattern_instrument)

	_update_pattern_instrument()
	
	if current_pattern:
		_scale_picker.set_selected(_scale_picker.options[current_pattern.scale])
		_key_picker.set_selected(_key_picker.options[current_pattern.key])
	else:
		_scale_picker.clear_selected()
		_key_picker.clear_selected()


func _update_pattern_properties() -> void:
	pass


func _update_pattern_instrument() -> void:
	_instrument_picker.options = []
	_instrument_picker.clear_selected()
	if not Controller.current_song:
		_instrument_picker.commit_options()
		return
	
	var instrument_index := 0
	var selected_item: OptionPicker.Item = null
	for instrument in Controller.current_song.instruments:
		var item := OptionPicker.Item.new()
		item.id = instrument_index
		item.text = "%d %s" % [ instrument_index + 1, instrument.name ]
		var instrument_theme := Controller.get_instrument_theme(instrument)
		item.background_color = instrument_theme.get_color("item_color", "InstrumentDock")
		
		if current_pattern && current_pattern.instrument_idx == instrument_index:
			selected_item = item
		
		_instrument_picker.options.push_back(item)
		instrument_index += 1
	
	_instrument_picker.commit_options()
	_instrument_picker.set_selected(selected_item)


func _change_instrument() -> void:
	if not current_pattern:
		return
	
	var selected_item := _instrument_picker.get_selected()
	if not selected_item:
		return
	current_pattern.change_instrument(selected_item.id)


func _change_scale() -> void:
	if not current_pattern:
		return
	
	var selected_item := _scale_picker.get_selected()
	if not selected_item:
		return
	current_pattern.change_scale(selected_item.id)


func _change_key() -> void:
	if not current_pattern:
		return
	
	var selected_item := _key_picker.get_selected()
	if not selected_item:
		return
	current_pattern.change_key(selected_item.id)


func _shift_notes(offset: int) -> void:
	if not current_pattern:
		return
	
	current_pattern.shift_notes(offset)
