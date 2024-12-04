###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends PanelContainer

var current_instrument: Instrument = null
var current_pattern: Pattern = null

@onready var _instrument_label: Label = %InstrumentLabel
@onready var _pickers_container: Control = %Pickers

@onready var _category_picker: OptionPicker = %CategoryPicker
@onready var _instrument_picker: OptionPicker = %InstrumentPicker
@onready var _prev_instrument_button: Button = %PrevInstrument
@onready var _next_instrument_button: Button = %NextInstrument
@onready var _randomize_instrument_button: Button = %RandomizeInstrument

@onready var _lowpass_slider: PadSlider = %LowPassSlider
@onready var _volume_slider: PadSlider = %VolumeSlider
@onready var _recording_label: Label = %RecordingLabel


func _ready() -> void:
	_set_category_options()
	_update_recording_state()
	
	_category_picker.selected.connect(_category_selected)
	_instrument_picker.selected.connect(_instrument_selected)
	_prev_instrument_button.pressed.connect(_instrument_picker.select_previous)
	_next_instrument_button.pressed.connect(_instrument_picker.select_next)
	_randomize_instrument_button.pressed.connect(_instrument_randomized)
	
	_lowpass_slider.changed.connect(_instrument_filter_changed)
	_volume_slider.changed.connect(_instrument_volume_changed)
	
	_edit_current_instrument()
	_edit_current_pattern()
	
	if not Engine.is_editor_hint():
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_BOTH_PICKERS, _pickers_container.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_VOLUME_SLIDER, _volume_slider.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_FILTER_PAD, _lowpass_slider.get_global_rect)
		Controller.help_manager.reference_node(HelpManager.StepNodeRef.INSTRUMENT_EDITOR_BOTH_PAD_SLIDERS, _get_global_sliders_rect)
		
		Controller.song_loaded.connect(_edit_current_instrument)
		Controller.song_instrument_changed.connect(_edit_current_instrument)
		Controller.song_loaded.connect(_edit_current_pattern)
		Controller.song_pattern_changed.connect(_edit_current_pattern)
		
		Controller.music_player.playback_tick.connect(_update_sliders)


func _get_global_sliders_rect() -> Rect2:
	var combined_rect := _lowpass_slider.get_global_rect()
	combined_rect = combined_rect.expand(_volume_slider.get_global_rect().end)
	
	return combined_rect


# Data.

func _edit_current_instrument() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	var next_instrument := Controller.get_current_instrument()
	if next_instrument == current_instrument:
		return
	
	# Update the label.
	_instrument_label.text = "INSTRUMENT %d" % [ Controller.current_instrument_index + 1 ]
	
	# Update the instrument reference and pickers.
	
	var category_changed := true
	if next_instrument && current_instrument && next_instrument.category == current_instrument.category:
		category_changed = false
	
	current_instrument = next_instrument
	theme = Controller.get_current_instrument_theme()
	
	if category_changed:
		_update_selected_category()
		_set_instrument_options()
	else:
		_update_selected_instrument()
	
	# Update sliders.
	_update_recording_state()
	_update_sliders()


func _edit_current_pattern() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	if current_pattern:
		current_pattern.instrument_recording_toggled.disconnect(_update_recording_state)
	
	current_pattern = Controller.get_current_pattern()
	
	if current_pattern:
		current_pattern.instrument_recording_toggled.connect(_update_recording_state)
	
	_update_recording_state()
	_update_sliders()


# Instrument editing.

func _set_category_options() -> void:
	var categories := Controller.voice_manager.get_categories()
	var category_id := 0
	for category in categories:
		var item := OptionListPopup.Item.new()
		item.id = category_id
		item.text = category
		
		_category_picker.options.push_back(item)
		category_id += 1
	_category_picker.commit_options()


func _set_instrument_options() -> void:
	_instrument_picker.options = []
	_instrument_picker.clear_selected()
	
	if not current_instrument:
		_instrument_picker.commit_options()
		return
	
	# Update the instrument picker.
	
	var sub_categories := Controller.voice_manager.get_sub_categories(current_instrument.category)
	var sub_category_id := 1000000
	var selected_item: OptionListPopup.Item = null
	for subcat in sub_categories:
		if subcat.name.is_empty(): # This is a top-level subcategory.
			for instrument in subcat.voices:
				var item := OptionListPopup.Item.new()
				item.id = instrument.index
				item.text = instrument.name
				
				if item.id == current_instrument.voice_index:
					selected_item = item
				_instrument_picker.options.push_back(item)
		
		else: # And this is an actual sublist.
			var sublist_options: Array[OptionListPopup.Item] = []
			for instrument in subcat.voices:
				var item := OptionListPopup.Item.new()
				item.id = instrument.index
				item.text = instrument.name
				
				if item.id == current_instrument.voice_index:
					selected_item = item
				sublist_options.push_back(item)
			
			var sublist := OptionListPopup.Item.new()
			sublist.id = sub_category_id
			sublist.text = subcat.name
			sublist.is_sublist = true
			sublist.sublist_options = sublist_options
			
			_instrument_picker.options.push_back(sublist)
			sub_category_id += 1
	
	_instrument_picker.commit_options()
	_instrument_picker.set_selected(selected_item)


func _update_selected_category() -> void:
	_category_picker.clear_selected()
	
	if not current_instrument:
		return
	
	for category_item in _category_picker.options:
		if category_item.text == current_instrument.category:
			_category_picker.set_selected(category_item)
			break


func _update_selected_instrument() -> void:
	_instrument_picker.clear_selected()
	
	if not current_instrument:
		return
	
	for linked_instrument_item in _instrument_picker.get_linked_options():
		if linked_instrument_item.value.id == current_instrument.voice_index:
			_instrument_picker.set_selected(linked_instrument_item.value)
			break


func _instrument_randomized() -> void:
	if Engine.is_editor_hint():
		return
		
	Controller.randomize_current_instrument()


func _category_selected() -> void:
	if Engine.is_editor_hint():
		return
	
	var category_name := _category_picker.get_selected().text
	Controller.set_current_instrument_by_category(category_name)


func _instrument_selected() -> void:
	if Engine.is_editor_hint():
		return
	
	var category_name := _category_picker.get_selected().text
	var instrument_name := _instrument_picker.get_selected().text
	Controller.set_current_instrument(category_name, instrument_name)


func _is_instrument_recording() -> bool:
	return current_pattern && current_pattern.record_instrument && current_pattern.instrument_idx == Controller.current_instrument_index


func _instrument_filter_changed() -> void:
	if not Controller.current_song || not current_instrument:
		return
	
	var slider_value := _lowpass_slider.get_current_value()
	
	if _is_instrument_recording():
		var current_position := Controller.music_player.get_next_pattern_time()
		if current_position >= 0:
			var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index, "pattern_recorded_filter%d" % [ current_position ])
			pattern_state.add_setget_property(current_pattern, "instrument_filter", slider_value,
				# Getter.
				func() -> Vector2i:
					var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
					return reference_pattern.get_instrument_filter(current_position)
					,
				# Setter.
				func(value: Vector2i) -> void:
					var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
					reference_pattern.record_instrument_filter(current_position, value.x, value.y)
			)
			
			Controller.state_manager.commit_state_change(pattern_state)
	
	else:
		var instrument_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.INSTRUMENT, Controller.current_instrument_index, "instrument_lp_filter")
		instrument_state.add_indexed_property(Controller.current_song.instruments, instrument_state.reference_id, "lp_cutoff", slider_value.x)
		instrument_state.add_indexed_property(Controller.current_song.instruments, instrument_state.reference_id, "lp_resonance", slider_value.y)
		
		Controller.state_manager.commit_state_change(instrument_state)


func _instrument_volume_changed() -> void:
	if not Controller.current_song || not current_instrument:
		return
	
	var slider_value := _volume_slider.get_current_value()
	
	if _is_instrument_recording():
		var current_position := Controller.music_player.get_next_pattern_time()
		if current_position >= 0:
			var pattern_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.PATTERN, Controller.current_pattern_index, "pattern_recorded_volume%d" % [ current_position ])
			pattern_state.add_setget_property(current_pattern, "instrument_volume", slider_value.y,
				# Getter.
				func() -> int:
					var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
					return reference_pattern.get_instrument_volume(current_position)
					,
				# Setter.
				func(value: int) -> void:
					var reference_pattern := Controller.current_song.patterns[pattern_state.reference_id]
					reference_pattern.record_instrument_volume(current_position, value)
			)
			
			Controller.state_manager.commit_state_change(pattern_state)
	else:
		var instrument_state := Controller.state_manager.create_state_change(StateManager.StateChangeType.INSTRUMENT, Controller.current_instrument_index, "instrument_volume")
		instrument_state.add_indexed_property(Controller.current_song.instruments, instrument_state.reference_id, "volume", slider_value.y)
		
		Controller.state_manager.commit_state_change(instrument_state)


# Instrument recording.

func _update_recording_state() -> void:
	if not is_inside_tree():
		return
	if not Controller.current_song || not current_pattern:
		return
	
	_recording_label.text = "! RECORDING: PATTERN %d !" % [ Controller.current_pattern_index + 1 ]
	
	if current_pattern.instrument_idx == Controller.current_instrument_index:
		_recording_label.visible = current_pattern.record_instrument
		_lowpass_slider.recording = current_pattern.record_instrument
		_volume_slider.recording = current_pattern.record_instrument
	else:
		_recording_label.visible = false
		_lowpass_slider.recording = false
		_volume_slider.recording = false
	
	queue_redraw()


func _update_sliders() -> void:
	if not Controller.current_song || not current_pattern:
		return
	
	# Not in the recording mode, so just use instrument values.
	if not current_pattern.record_instrument || current_pattern.instrument_idx != Controller.current_instrument_index:
		_lowpass_slider.set_current_value(Vector2i(current_instrument.lp_cutoff, current_instrument.lp_resonance))
		_volume_slider.set_current_value(Vector2i(0, current_instrument.volume))
		return
	
	# Update values in the recoding mode. Use pattern values if the pattern is being played, use
	# instrument values otherwise.
	var current_position := Controller.music_player.get_next_pattern_time()
	if current_pattern.is_playing && current_position >= 0:
		var recorded_values := current_pattern.recorded_instrument_values[current_position]
		
		_lowpass_slider.set_current_value(Vector2i(recorded_values.y, recorded_values.z))
		_volume_slider.set_current_value(Vector2i(0, recorded_values.x))
	else:
		_lowpass_slider.set_current_value(Vector2i(current_instrument.lp_cutoff, current_instrument.lp_resonance))
		_volume_slider.set_current_value(Vector2i(0, current_instrument.volume))
	
	# Update recorded values chart.
	
	var charted_lowpass_values: Array[Vector2i] = []
	var charted_volume_values: Array[Vector2i] = []
	
	for i in Controller.current_song.pattern_size:
		var record := current_pattern.recorded_instrument_values[i]
		charted_volume_values.push_back(Vector2i(0, record.x))
		charted_lowpass_values.push_back(Vector2i(record.y, record.z))
	
	_lowpass_slider.set_recorded_values(charted_lowpass_values)
	_volume_slider.set_recorded_values(charted_volume_values)
