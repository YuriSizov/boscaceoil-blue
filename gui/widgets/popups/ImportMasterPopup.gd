###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ImportMasterPopup extends WindowPopup

enum ImportType {
	NONE,
	IMPORT_MIDI,
}

var _current_file: String = ""

@onready var _select_file_button: SquishyButton = %SelectFile
@onready var _file_path_label: FilePathLabel = %FilePathLabel
@onready var _pattern_size_value: Stepper = %PatternSizeValue


func _ready() -> void:
	super()
	
	_select_file_button.pressed.connect(_show_file_dialog)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		# Since this is a part of an instantiated scene, these nodes are immediately available.
		# This allows us to use them safely before ready.
		_file_path_label = %FilePathLabel
		_pattern_size_value = %PatternSizeValue


# Lifecycle.

## Override.
func clear(keep_size: bool = false) -> void:
	_current_file = ""
	_file_path_label.text = _current_file
	
	super(keep_size)


# Helpers.

func _show_file_dialog() -> void:
	if OS.has_feature("web"):
		var import_dialog_web := Controller.get_file_dialog_web()
		import_dialog_web.add_filter(".mid")
		import_dialog_web.file_selected.connect(_confirm_file_dialog, CONNECT_ONE_SHOT)
		
		import_dialog_web.popup()
		return
	
	var import_dialog := Controller.get_file_dialog()
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.title = "Select File to Import"
	import_dialog.add_filter("*.mid", "MIDI File")
	import_dialog.current_file = ""
	import_dialog.file_selected.connect(_confirm_file_dialog, CONNECT_ONE_SHOT)
	
	Controller.show_file_dialog(import_dialog)


func _confirm_file_dialog(path: String) -> void:
	_current_file = path
	_file_path_label.text = _current_file


# Config management.

func get_import_config() -> ImportConfig:
	var config := ImportConfig.new()
	config.type = ImportType.IMPORT_MIDI
	config.path = _current_file
	config.pattern_size = _pattern_size_value.value
	
	return config


class ImportConfig extends RefCounted:
	var type: ImportType = ImportType.NONE
	var path: String = ""
	var pattern_size: int = 0
