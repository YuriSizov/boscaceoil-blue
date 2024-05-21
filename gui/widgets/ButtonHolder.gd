###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ButtonHolder extends RefCounted

## Stepper is accelerated to make it easier to scroll through the range of values.
## These are arbitrary fine-tuned values.
const HOLD_THRESHOLDS := [ 0.4, 0.36, 0.3, 0.2, 0.088, 0.042 ]

var _owner: Control = null
var _press_callback: Callable
var _release_callback: Callable
var _button_action_map: Dictionary = {}

var _current_threshold_idx := 0
var _hold_button: Button = null
var _hold_interval: float = 0


func _init(owner: Control, first_button: Button, second_button: Button) -> void:
	_owner = owner
	_owner.set_process(false)
	
	first_button.button_down.connect(_button_press_started.bind(first_button))
	second_button.button_down.connect(_button_press_started.bind(second_button))
	first_button.button_up.connect(_button_press_stopped)
	second_button.button_up.connect(_button_press_stopped)


func set_press_callback(callback: Callable) -> void:
	_press_callback = callback


func set_release_callback(callback: Callable) -> void:
	_release_callback = callback


func set_button_action(button: Button, action_name: String) -> void:
	_button_action_map[action_name] = button


func process(delta: float) -> void:
	if not _hold_button:
		return

	_hold_interval += delta
	if _hold_interval >= HOLD_THRESHOLDS[_current_threshold_idx]:
		_hold_interval = 0
		if _current_threshold_idx < (HOLD_THRESHOLDS.size() - 1):
			_current_threshold_idx += 1
		
		if _press_callback.is_valid():
			_press_callback.call(_hold_button)


func input(event: InputEvent, only_release: bool = false) -> void:
	for action_name: String in _button_action_map:
		if not event.is_action(action_name, true):
			continue
		
		var event_pressed := event.is_action_pressed(action_name, true, true)
		var action_button: Button = _button_action_map[action_name]
		
		# The button is already being tracked as pressed.
		if event_pressed && _hold_button == action_button:
			return
		
		# No button or a different button is being pressed, switch.
		if event_pressed && not only_release:
			_button_press_started(action_button)
			return
		
		# The pressed button is being released.
		if not event_pressed && _hold_button == action_button:
			_button_press_stopped()
			return


func _button_press_started(button: Button) -> void:
	_current_threshold_idx = 0
	_hold_button = button

	if _press_callback.is_valid():
		_press_callback.call(_hold_button)
	
	_owner.set_process(true)


func _button_press_stopped() -> void:
	_owner.set_process(false)

	if _release_callback.is_valid():
		_release_callback.call(_hold_button)

	_hold_button = null
	_hold_interval = 0
