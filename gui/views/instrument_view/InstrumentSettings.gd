###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends PanelContainer

var current_instrument: Instrument = null

@onready var _category_picker: OptionPicker = %CategoryPicker
@onready var _instrument_picker: OptionPicker = %InstrumentPicker
@onready var _prev_instrument_button: Button = %PrevInstrument
@onready var _next_instrument_button: Button = %NextInstrument


func _ready() -> void:
	_set_category_options()
	
	_category_picker.selected.connect(_category_selected)
	_instrument_picker.selected.connect(_instrument_selected)
	_prev_instrument_button.pressed.connect(_instrument_picker.select_previous)
	_next_instrument_button.pressed.connect(_instrument_picker.select_next)
	
	_edit_current_instrument()
	if not Engine.is_editor_hint():
		Controller.song_loaded.connect(_edit_current_instrument)
		Controller.song_instrument_changed.connect(_edit_current_instrument)


func _set_category_options() -> void:
	var categories := Controller.voice_manager.get_categories()
	var category_id := 0
	for category in categories:
		var item := OptionPicker.Item.new()
		item.id = category_id
		item.text = category
		
		_category_picker.options.push_back(item)
		category_id += 1
	_category_picker.commit_options()


func _set_instrument_options() -> void:
	_instrument_picker.options = []
	_instrument_picker.clear_selected()
	_category_picker.clear_selected()
	
	if not current_instrument:
		_instrument_picker.commit_options()
		return
	
	# Update the category name.
	
	for category_item in _category_picker.options:
		if category_item.text == current_instrument.category:
			_category_picker.set_selected(category_item)
			break
	
	# Update the instrument picker.
	
	var sub_categories := Controller.voice_manager.get_sub_categories(current_instrument.category)
	var sub_category_id := 1000000
	var selected_item: OptionPicker.Item = null
	for subcat in sub_categories:
		if subcat.name.is_empty(): # This is a top-level subcategory.
			for instrument in subcat.voices:
				var item := OptionPicker.Item.new()
				item.id = instrument.index
				item.text = instrument.name
				
				if item.id == current_instrument.voice_index:
					selected_item = item
				_instrument_picker.options.push_back(item)
		
		else: # And this is an actual sublist.
			var sublist_options: Array[OptionPicker.Item] = []
			for instrument in subcat.voices:
				var item := OptionPicker.Item.new()
				item.id = instrument.index
				item.text = instrument.name
				
				if item.id == current_instrument.voice_index:
					selected_item = item
				sublist_options.push_back(item)
			
			var sublist := OptionPicker.Item.new()
			sublist.id = sub_category_id
			sublist.text = subcat.name
			sublist.is_sublist = true
			sublist.sublist_options = sublist_options
			
			_instrument_picker.options.push_back(sublist)
			sub_category_id += 1
	
	_instrument_picker.commit_options()
	_instrument_picker.set_selected(selected_item)


func _edit_current_instrument() -> void:
	if Engine.is_editor_hint():
		return
	if not Controller.current_song:
		return
	
	var next_instrument := Controller.get_current_instrument()
	if next_instrument == current_instrument:
		return
	
	# Update the instrument reference and pickers.
	
	var category_changed := true
	if next_instrument && current_instrument && next_instrument.category == current_instrument.category:
		category_changed = false
	
	current_instrument = next_instrument
	theme = Controller.get_current_instrument_theme()
	
	if category_changed:
		_set_instrument_options()
	
	# TODO: Update sliders.


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
