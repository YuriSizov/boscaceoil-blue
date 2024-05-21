###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ShortcutLine extends HBoxContainer

@export var key_text: String = "KEY":
	set = set_key_text
@export var key_is_action: bool = true:
	set = set_key_is_action
@export var description_text: String = "Description":
	set = set_description_text

@onready var _key_label: Label = $KeyLabel
@onready var _description_label: Label = $DescriptionLabel


func _ready() -> void:
	_update_labels()


func _update_labels() -> void:
	if not is_inside_tree():
		return
	
	if key_is_action:
		_key_label.text = _get_action_as_string(key_text)
	else:
		_key_label.text = key_text
	
	_description_label.text = description_text


func _get_action_as_string(action_text: String) -> String:
	var bound_events := InputMap.action_get_events(action_text)
	if bound_events.size() <= 0:
		return "[UNBOUND]"
	
	var first_event := bound_events[0]
	if first_event is InputEventKey:
		var key_event := first_event as InputEventKey
		var key_bits := PackedStringArray()
		
		if key_event.shift_pressed:
			key_bits.push_back("SHIFT")
		if key_event.ctrl_pressed:
			key_bits.push_back("CTRL")
		if key_event.meta_pressed:
			if OS.has_feature("macos") || OS.has_feature("web_macos"):
				key_bits.push_back("CMD")
			elif OS.has_feature("windows") || OS.has_feature("web_windows"):
				key_bits.push_back("WIN")
			else:
				key_bits.push_back("META")
		if key_event.alt_pressed:
			key_bits.push_back("ALT")
		
		var keycode_string := OS.get_keycode_string(key_event.keycode)
		if key_event.keycode in [ KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT ]:
			keycode_string = "ARROW " + keycode_string
		key_bits.append(keycode_string)
		
		return " + ".join(key_bits)
	
	return first_event.as_text()


func set_key_text(value: String) -> void:
	key_text = value
	_update_labels()


func set_key_is_action(value: bool) -> void:
	key_is_action = value
	_update_labels()


func set_description_text(value: String) -> void:
	description_text = value
	_update_labels()
