###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name IOConfigPopup extends WindowPopup

enum View {
	NONE,
	MIDI_IMPORT,
}
const ViewSize := {
	View.NONE:        Vector2.ZERO,
	View.MIDI_IMPORT: Vector2(420, 200),
}

var _current_view: View = View.NONE

@onready var _midi_import_box: VBoxContainer = %MidiImportBox
@onready var _midi_import_pattern_size: Stepper = %PatternSizeValue


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		# Since this is a part of an instantiated scene, these nodes are immediately available.
		# This allows us to use them safely before ready.
		_midi_import_box = %MidiImportBox
		_midi_import_pattern_size = %PatternSizeValue


# Lifecycle.

## Override.
func clear(keep_size: bool = false) -> void:
	activate_view(View.NONE)
	
	super(keep_size)


# Config views.

func activate_view(view: View) -> void:
	_current_view = view
	
	_midi_import_box.visible = (view == View.MIDI_IMPORT)


func get_view_size() -> Vector2:
	return ViewSize[_current_view]


func get_view_config() -> RefCounted:
	match _current_view:
		View.MIDI_IMPORT:
			var config := MidiImporter.Config.new()
			config.pattern_size = _midi_import_pattern_size.value
			
			return config
	
	return null
