###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Component responsible for help elements and guided tours.
class_name HelpManager extends RefCounted

signal highlight_requested(callable: Callable)
signal highlight_cleared()

const INFO_POPUP_SCENE := preload("res://gui/widgets/popups/InfoPopup.tscn")
const BASIC_GUIDE_RESOURCE := preload("res://help/basic_guide.tres")
const ADVANCED_GUIDE_RESOURCE := preload("res://help/advanced_guide.tres")

enum GuideType {
	BASIC_GUIDE,
	ADVANCED_GUIDE,
}

enum StepNodeRef {
	NONE = 0,
	
	NAVIGATION_FILE = 1,
	NAVIGATION_ARRANGEMENT,
	NAVIGATION_INSTRUMENT,
	
	PATTERN_EDITOR_VIEW = 100,
	PATTERN_EDITOR_NOTEMAP,
	PATTERN_EDITOR_SCROLLBAR,
	PATTERN_EDITOR_INSTRUMENT_PICKER,
	PATTERN_EDITOR_KEY_SCALE_PICKERS,
	PATTERN_EDITOR_NOTE_SHIFTER,
	PATTERN_EDITOR_RECORD_BUTTON,
	
	ARRANGEMENT_EDITOR_VIEW = 200,
	ARRANGEMENT_EDITOR_PATTERNMAP,
	ARRANGEMENT_EDITOR_ADD_NEW,
	ARRANGEMENT_EDITOR_TIMELINE,
	ARRANGEMENT_EDITOR_TIMELINE_SINGLE_BAR,
	ARRANGEMENT_EDITOR_TIMELINE_BAR_SPAN,
	
	INSTRUMENT_EDITOR_VIEW = 300,
	INSTRUMENT_EDITOR_ADD_NEW,
	INSTRUMENT_EDITOR_BOTH_PICKERS,
	INSTRUMENT_EDITOR_VOLUME_SLIDER,
	INSTRUMENT_EDITOR_FILTER_PAD,
	INSTRUMENT_EDITOR_BOTH_PAD_SLIDERS,
	INSTRUMENT_EDITOR_DOCK,
	
	HELP_VIEW = 400,
	HELP_SHORTCUT_SHORTLIST,
}

enum StepTrigger {
	NONE = 0,
	
	MENU_FILE_NAVIGATED = 1,
	MENU_ARRANGEMENT_NAVIGATED,
	MENU_INSTRUMENT_NAVIGATED,
	
	ARRANGEMENT_EDITOR_PATTERN_CREATED = 200,
	
	INSTRUMENT_EDITOR_INSTRUMENT_CREATED = 300,
}

var _info_popup: InfoPopup = null
var _node_references: Dictionary = {}

var _current_guide: HelpGuide = null
var _current_step: int = -1
var _current_trigger_signal: Signal
var _current_trigger_handler: Callable


func _init() -> void:
	_info_popup = INFO_POPUP_SCENE.instantiate()
	_info_popup.button_autoswap = false
	_info_popup.button_alignment = HORIZONTAL_ALIGNMENT_FILL
	_info_popup.about_to_hide.connect(_finish_guide)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_info_popup):
			_info_popup.queue_free()


# Reference data.

func reference_node(step_key: StepNodeRef, rect_getter: Callable) -> void:
	if step_key == StepNodeRef.NONE:
		printerr("HelpManager: Cannot add node reference for StepNodeRef.NONE.")
		return
	if _node_references.has(step_key):
		printerr("HelpManager: Node reference for the step %d already exists." % [ step_key ])
		return
	
	# Mapping a callable allows us to update the highlight on resize without extra steps.
	_node_references[step_key] = rect_getter


func _highlight_node(step_key: StepNodeRef) -> void:
	if step_key == StepNodeRef.NONE || not _node_references.has(step_key):
		highlight_cleared.emit()
		return
	
	var rect_getter: Callable = _node_references[step_key]
	if not rect_getter.is_valid():
		highlight_cleared.emit()
		return
	
	highlight_requested.emit(rect_getter)


# Guide management.

func start_guide(guide_type: GuideType) -> void:
	if _current_guide:
		_info_popup.close_popup()
	
	_info_popup.clear()
	_current_guide = null
	_current_step = -1
	
	match guide_type:
		GuideType.BASIC_GUIDE:
			_current_guide = BASIC_GUIDE_RESOURCE
		GuideType.ADVANCED_GUIDE:
			_current_guide = ADVANCED_GUIDE_RESOURCE
	
	_show_next_step()


func _finish_guide() -> void:
	if _info_popup.is_popped():
		_info_popup.close_popup()
	_info_popup.clear()
	highlight_cleared.emit()
	
	_current_guide = null
	_current_step = -1
	_clear_trigger()


func _show_next_step() -> void:
	if not _current_guide:
		return
	
	_current_step += 1
	if _current_step >= _current_guide.steps.size():
		return
	
	_show_current_step()


func _show_previous_step() -> void:
	if not _current_guide:
		return
	
	_current_step -= 1
	if _current_step < 0:
		return
	
	_show_current_step()


func _show_current_step() -> void:
	if not _current_guide:
		return
	
	_clear_trigger()
	_info_popup.clear()
	
	var step := _current_guide.steps[_current_step]
	_info_popup.title = step.title
	_info_popup.content = step.description
	
	if step.ref_image && step.ref_image_position != InfoPopup.ImagePosition.HIDDEN:
		_info_popup.add_image(step.ref_image, step.ref_image_size, step.ref_image_position)
	
	# Always create both buttons so they are spaced correctly, even when visible alone.
	var button_prev := _info_popup.add_button("PREVIOUS", _show_previous_step)
	button_prev.visible = _current_step > 0
	
	if _current_step < (_current_guide.steps.size() - 1):
		_info_popup.add_button("NEXT", _show_next_step)
	else:
		_info_popup.add_button("FINISH", _finish_guide)
	
	# Resize, position, and show the popup.
	
	_info_popup.size = step.size
	if _info_popup.is_popped():
		# TODO: It would be nice to have these transitions animated, but that requires additional work.
		# The final size and the final position are calculated behind the scenes as we adjust anchors.
		# Working around this would require us to replicate anchor calculations in scripts, and then
		# change position instead. Maybe some day...
		_info_popup.move_anchored(step.position_anchor, step.position_direction)
	else:
		_info_popup.popup_anchored(step.position_anchor, step.position_direction, false)
	
	# Navigate to the target view and highlight the target control, if there is one.
	Controller.navigate_to(step.navigation_target)
	_highlight_node(step.node_target)
	
	# Enable the interactive trigger, if there is one.
	_setup_trigger(step.trigger_target)


func _clear_trigger() -> void:
	if not _current_trigger_signal.is_null() && _current_trigger_handler.is_valid():
		_current_trigger_signal.disconnect(_current_trigger_handler)
		_current_trigger_signal = Signal()
		_current_trigger_handler = Callable()


func _setup_trigger(trigger_key: StepTrigger) -> void:
	_clear_trigger()
	
	if trigger_key == StepTrigger.NONE:
		return
	
	match trigger_key:
		StepTrigger.MENU_FILE_NAVIGATED:
			_current_trigger_signal = Controller.navigation_succeeded
			_current_trigger_handler = _handle_navigation_trigger.bind(Menu.NavigationTarget.FILE)
		
		StepTrigger.MENU_ARRANGEMENT_NAVIGATED:
			_current_trigger_signal = Controller.navigation_succeeded
			_current_trigger_handler = _handle_navigation_trigger.bind(Menu.NavigationTarget.ARRANGEMENT)
		
		StepTrigger.MENU_INSTRUMENT_NAVIGATED:
			_current_trigger_signal = Controller.navigation_succeeded
			_current_trigger_handler = _handle_navigation_trigger.bind(Menu.NavigationTarget.INSTRUMENT)
		
		StepTrigger.ARRANGEMENT_EDITOR_PATTERN_CREATED:
			_current_trigger_signal = Controller.song_pattern_created
			_current_trigger_handler = _handle_song_changed_trigger
		
		StepTrigger.INSTRUMENT_EDITOR_INSTRUMENT_CREATED:
			_current_trigger_signal = Controller.song_instrument_created
			_current_trigger_handler = _handle_song_changed_trigger
		
	
	if not _current_trigger_signal.is_null() && _current_trigger_handler.is_valid():
		_current_trigger_signal.connect(_current_trigger_handler)


func _handle_navigation_trigger(target: Menu.NavigationTarget, desired_target: Menu.NavigationTarget) -> void:
	if target == desired_target:
		_show_next_step()


func _handle_song_changed_trigger() -> void:
	_show_next_step()
