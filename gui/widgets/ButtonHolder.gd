###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ButtonHolder extends RefCounted

## Stepper is accelerated to make it easier to scroll through the range of values.
## These are arbitrary fine-tuned values.
const HOLD_THRESHOLDS := [ 0.4, 0.38, 0.32, 0.22, 0.11, 0.088, 0.064 ]

var _owner: Control = null
var _press_callback: Callable
var _release_callback: Callable

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
