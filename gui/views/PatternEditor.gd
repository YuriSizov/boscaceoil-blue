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

@onready var _record_instrument: Button = %RecordInstrument
@onready var _record_instrument_label: Label = %RecordInstrumentLabel
@onready var _note_shift_up: Button = %NoteShiftUp
@onready var _note_shift_down: Button = %NoteShiftDown


func _ready() -> void:
	_update_scale_options()
	_update_key_options()
	
	_instrument_picker.selected.connect(_change_instrument)
	_scale_picker.selected.connect(_change_scale)
	_key_picker.selected.connect(_change_key)
	
	_record_instrument.toggled.connect(_toggle_record_instrument)
	_note_shift_up.pressed.connect(_shift_notes.bind(1))
	_note_shift_down.pressed.connect(_shift_notes.bind(-1))
	
	_edit_current_pattern()
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_VIEW, get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_INSTRUMENT_PICKER, _get_global_instrument_picker_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_KEY_SCALE_PICKERS, _get_global_pickers_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_NOTE_SHIFTER, _get_global_note_shifter_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.PATTERN_EDITOR_RECORD_BUTTON, _get_global_record_instrument_rect)
		
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		Controller.song_instrument_created.connect(_update_pattern_instrument)
		Controller.song_instrument_changed.connect(_update_pattern_instrument)


func _get_global_instrument_picker_rect() -> Rect2:
	return _instrument_picker.get_parent_control().get_global_rect()


func _get_global_pickers_rect() -> Rect2:
	var combined_rect := _scale_picker.get_parent_control().get_global_rect()
	combined_rect = combined_rect.expand(_key_picker.get_parent_control().get_global_rect().end)
	
	return combined_rect


func _get_global_note_shifter_rect() -> Rect2:
	var combined_rect := _note_shift_up.get_global_rect()
	combined_rect = combined_rect.expand(_note_shift_down.get_global_rect().end)
	
	return combined_rect


func _get_global_record_instrument_rect() -> Rect2:
	var combined_rect := _record_instrument_label.get_global_rect()
	combined_rect = combined_rect.grow_side(SIDE_LEFT, 4)
	combined_rect = combined_rect.expand(_record_instrument.get_global_rect().end)
	
	return combined_rect


func _update_scale_options() -> void:
	_scale_picker.options = []
	
	var selected_item: OptionListPopup.Item = null
	for i in Scale.MAX:
		var item := OptionListPopup.Item.new()
		item.id = i
		item.text = Scale.get_scale_name(i)

		if current_pattern && current_pattern.scale == i:
			selected_item = item

		_scale_picker.options.push_back(item)
	
	_scale_picker.commit_options()
	_scale_picker.set_selected(selected_item)


func _update_key_options() -> void:
	_key_picker.options = []
	
	var selected_item: OptionListPopup.Item = null
	for i in Note.MAX:
		var item := OptionListPopup.Item.new()
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
		current_pattern.scale_changed.disconnect(_update_pattern_widgets)
		current_pattern.key_changed.disconnect(_update_pattern_widgets)
		current_pattern.instrument_recording_toggled.disconnect(_update_pattern_widgets)
	
	current_pattern = Controller.get_current_pattern()
	
	if current_pattern:
		current_pattern.instrument_changed.connect(_update_pattern_instrument)
		current_pattern.scale_changed.connect(_update_pattern_widgets)
		current_pattern.key_changed.connect(_update_pattern_widgets)
		current_pattern.instrument_recording_toggled.connect(_update_pattern_widgets)
	
	_update_pattern_instrument()
	_update_pattern_widgets()


func _update_pattern_instrument() -> void:
	_instrument_picker.options = []
	_instrument_picker.clear_selected()
	if not Controller.current_song:
		_instrument_picker.commit_options()
		return
	
	var instrument_index := 0
	var selected_item: OptionListPopup.Item = null
	var selected_instrument: Instrument = null
	for instrument in Controller.current_song.instruments:
		var item := OptionListPopup.Item.new()
		item.id = instrument_index
		item.text = "%d %s" % [ instrument_index + 1, instrument.name ]
		var instrument_theme := Controller.get_instrument_theme(instrument)
		item.background_color = instrument_theme.get_color("item_color", "InstrumentDock")
		
		if current_pattern && current_pattern.instrument_idx == instrument_index:
			selected_item = item
			selected_instrument = instrument
		
		_instrument_picker.options.push_back(item)
		instrument_index += 1
	
	_instrument_picker.commit_options()
	if selected_item:
		_instrument_picker.set_selected(selected_item)

	if selected_instrument:
		_scale_picker.get_parent().visible = selected_instrument.type != Instrument.InstrumentType.INSTRUMENT_DRUMKIT
		_key_picker.get_parent().visible = selected_instrument.type != Instrument.InstrumentType.INSTRUMENT_DRUMKIT


func _update_pattern_widgets() -> void:
	if current_pattern:
		_scale_picker.set_selected(_scale_picker.options[current_pattern.scale])
		_key_picker.set_selected(_key_picker.options[current_pattern.key])
		_record_instrument.set_pressed_no_signal(current_pattern.record_instrument)
	else:
		_scale_picker.clear_selected()
		_key_picker.clear_selected()
		_record_instrument.set_pressed_no_signal(false)


func _change_instrument() -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	var selected_item := _instrument_picker.get_selected()
	if not selected_item:
		return
	
	var instrument_idx := selected_item.id
	var old_instrument_idx := current_pattern.instrument_idx
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	var state_context := pattern_state.get_context()
	state_context["affected"] = []
	
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		var pattern_instrument := Controller.current_song.instruments[instrument_idx]
		
		state_context.affected = reference_pattern.change_instrument(instrument_idx, pattern_instrument)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		var pattern_instrument := Controller.current_song.instruments[old_instrument_idx]
		
		reference_pattern.change_instrument(old_instrument_idx, pattern_instrument)
		
		for note_data: Vector3i in state_context.affected:
			reference_pattern.add_note(note_data.x, note_data.y, note_data.z, false)
		
		reference_pattern.sort_notes()
		reference_pattern.reindex_active_notes()
		reference_pattern.notes_changed.emit()
	)
	
	Controller.state_manager.commit_state_change(pattern_state)


func _change_scale() -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	var selected_item := _scale_picker.get_selected()
	if not selected_item:
		return
	
	var scale_id := selected_item.id
	var old_scale_id := current_pattern.scale
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	var state_context := pattern_state.get_context()
	state_context["affected"] = []
	
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		state_context.affected = reference_pattern.change_scale(scale_id)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.change_scale(old_scale_id)
		
		for note_data: Vector3i in state_context.affected:
			reference_pattern.add_note(note_data.x, note_data.y, note_data.z, false)
		
		reference_pattern.sort_notes()
		reference_pattern.reindex_active_notes()
		reference_pattern.notes_changed.emit()
	)
	
	Controller.state_manager.commit_state_change(pattern_state)


func _change_key() -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	var selected_item := _key_picker.get_selected()
	if not selected_item:
		return
	
	var key_id := selected_item.id
	var old_key_id := current_pattern.key
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.change_key(key_id)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.change_key(old_key_id)
	)
	
	Controller.state_manager.commit_state_change(pattern_state)


func _toggle_record_instrument(enabled: bool) -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	var old_enabled := current_pattern.record_instrument
	
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.toggle_record_instrument(enabled)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.toggle_record_instrument(old_enabled)
	)
	
	Controller.state_manager.commit_state_change(pattern_state)
	
	# Only switch on the initial toggle, but not on undo/redo.
	if enabled:
		Controller.navigate_to(Menu.NavigationTarget.INSTRUMENT)
		Controller.edit_instrument(current_pattern.instrument_idx)


func _shift_notes(offset: int) -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	var old_notes := current_pattern.notes.duplicate()
	
	# FIXME: This technically can produce empty steps because we don't check if shift will do anything.
	var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index)
	pattern_state.add_do_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		reference_pattern.shift_notes(offset)
	)
	pattern_state.add_undo_action(func() -> void:
		var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
		
		for i in old_notes.size():
			reference_pattern.notes[i] = old_notes[i]
		
		reference_pattern.reindex_active_notes()
		reference_pattern.notes_changed.emit()
	)
	
	Controller.state_manager.commit_state_change(pattern_state)
