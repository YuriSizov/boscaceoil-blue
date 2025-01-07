###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ExportMasterPopup extends WindowPopup

enum ExportType {
	EXPORT_WAV,
	EXPORT_MIDI,
	EXPORT_MML,
	EXPORT_XM,
}

var _file_type: ExportType = ExportType.EXPORT_WAV

@onready var _file_type_picker: OptionPicker = %FileType
@onready var _export_wav_note: Control = %ExportNoteWAV
@onready var _export_midi_note: Control = %ExportNoteMIDI
@onready var _export_mml_note: Control = %ExportNoteMML
@onready var _export_xm_note: Control = %ExportNoteXM


func _ready() -> void:
	super()
	
	_populate_export_options()
	_update_export_notes()
	
	_file_type_picker.selected.connect(_change_file_type)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		# Since this is a part of an instantiated scene, these nodes are immediately available.
		# This allows us to use them safely before ready.
		_file_type_picker = %FileType
		_export_wav_note = %ExportNoteWAV
		_export_midi_note = %ExportNoteMIDI
		_export_mml_note = %ExportNoteMML
		_export_xm_note = %ExportNoteXM


# Lifecycle.

## Override.
func clear(keep_size: bool = false) -> void:
	_file_type = ExportType.EXPORT_WAV
	_update_export_notes()
	
	_file_type_picker.clear_selected()
	
	for i in _file_type_picker.options.size():
		var item := _file_type_picker.options[i]
		if item.id == ExportType.EXPORT_WAV:
			_file_type_picker.set_selected(item)
			break
	
	super(keep_size)


func _populate_export_options() -> void:
	var wav_item := OptionListPopup.Item.new()
	wav_item.id = ExportType.EXPORT_WAV
	wav_item.text = "WAV"
	_file_type_picker.options.push_back(wav_item)
	
	var mid_item := OptionListPopup.Item.new()
	mid_item.id = ExportType.EXPORT_MIDI
	mid_item.text = "MIDI"
	_file_type_picker.options.push_back(mid_item)
	
	var mml_item := OptionListPopup.Item.new()
	mml_item.id = ExportType.EXPORT_MML
	mml_item.text = "SiON MML"
	_file_type_picker.options.push_back(mml_item)
	
	var xm_item := OptionListPopup.Item.new()
	xm_item.id = ExportType.EXPORT_XM
	xm_item.text = "XM"
	_file_type_picker.options.push_back(xm_item)
	
	_file_type_picker.commit_options()
	_file_type_picker.set_selected(wav_item)


# Properties.

func _change_file_type() -> void:
	_file_type = _file_type_picker.get_selected().id as ExportType
	_update_export_notes()


func _update_export_notes() -> void:
	_export_wav_note.visible  = (_file_type == ExportType.EXPORT_WAV)
	_export_midi_note.visible = (_file_type == ExportType.EXPORT_MIDI)
	_export_mml_note.visible  = (_file_type == ExportType.EXPORT_MML)
	_export_xm_note.visible   = (_file_type == ExportType.EXPORT_XM)


# Config management.

func get_export_config() -> ExportConfig:
	var config := ExportConfig.new()
	config.type = _file_type
	
	return config


class ExportConfig extends RefCounted:
	var type: ExportType = ExportType.EXPORT_WAV
