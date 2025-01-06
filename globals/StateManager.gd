###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name StateManager extends RefCounted

signal state_changed()

const HISTORY_SIZE := 40
const HISTORY_ACCUMULATION_DELAY := 0.5 # In seconds.

enum StateChangeType {
	NONE = 0,
	SONG,
	PATTERN,
	INSTRUMENT,
	ARRANGEMENT,
}

## Safeguard to avoid conflicting states.
var _pending_changes: bool = false
## Backwards state change memory.
var _state_history: Array[StateChange] = []
## Forwards state change memory.
var _state_future: Array[StateChange] = []


# General history management.

func clear_state_memory() -> void:
	_state_history.clear()
	_state_future.clear()


func create_state_change(type: StateChangeType, ref_id: int = -1, accum_id: String = "") -> StateChange:
	_pending_changes = true
	
	# If this is an accumulating state change, check if the last one in the history matches.
	if not accum_id.is_empty() && not _state_history.is_empty():
		var last_state: StateChange = _state_history.back()
		if last_state.accumulation_id == accum_id && last_state.accumulation_timer.time_left > 0:
			last_state.accumulation_timer.time_left = HISTORY_ACCUMULATION_DELAY
			# Pop it out of history for now, will be committed to the future stack soon after.
			return _state_history.pop_back()
	
	var state := StateChange.new()
	state.type = type
	state.reference_id = ref_id
	
	if not accum_id.is_empty():
		state.accumulation_id = accum_id
		state.accumulation_pending = true # Blocks accumulation behavior until we commit once.
		state.accumulation_timer = Controller.get_tree().create_timer(HISTORY_ACCUMULATION_DELAY)
	
	return state


func commit_state_change(state: StateChange) -> void:
	_state_future.clear() # With the addition of the new state, our future has been erased.
	_state_future.push_front(state)
	_pending_changes = false
	
	if state.accumulation_pending:
		state.accumulation_pending = false
	
	# Execute the state change immediately.
	do_state_change()


func do_state_change() -> void:
	if _pending_changes:
		return # Can't do while there are changes being created.
	if _state_future.is_empty():
		return
	
	# Take the first upcoming state change and push it to the history stack.
	var state: StateChange = _state_future.pop_front()
	_state_history.push_back(state)
	# Make sure the history size is kept in check.
	if _state_history.size() > HISTORY_SIZE:
		_state_history.pop_front()
	
	# Execute instructions in the state change.
	for i in state.items.size():
		var item := state.items[i]
		
		if item is StateChangeProperty:
			var prop := item as StateChangeProperty
			
			if prop.commit.is_valid():
				prop.commit.call()
				print_verbose("StateManager: Done property change for '%s'." % [ prop.name ])
		
		elif item is StateChangeAction:
			var action := item as StateChangeAction
			
			if action.commit.is_valid():
				action.commit.call()
				print_verbose("StateManager: Done action.")
	
	print_verbose("StateManager: History size is %d, future size is %d." % [ _state_history.size(), _state_future.size() ])
	state_changed.emit()


func undo_state_change() -> void:
	if _pending_changes:
		return # Can't undo while there are changes being created.
	if _state_history.is_empty():
		return
	
	# Take the last stored state change and push it to the future stack.
	var state: StateChange = _state_history.pop_back()
	_state_future.push_front(state) # This naturally cannot be bigger than the history stack.
	
	# Execute instructions in the state change.
	for i in state.items.size():
		var item := state.items[i]
		
		if item is StateChangeProperty:
			var prop := item as StateChangeProperty
			
			if prop.rollback.is_valid():
				prop.rollback.call(prop.value)
				print_verbose("StateManager: Undone property change for '%s'." % [ prop.name ])
		
		elif item is StateChangeAction:
			var action := item as StateChangeAction
			
			if action.rollback.is_valid():
				action.rollback.call()
				print_verbose("StateManager: Undone action.")
	
	print_verbose("StateManager: History size is %d, future size is %d." % [ _state_history.size(), _state_future.size() ])
	state_changed.emit()


# State changes and instructions.

class StateChange:
	var type: StateChangeType = StateChangeType.NONE
	var reference_id: int = -1
	var accumulation_id: String = ""
	var accumulation_pending: bool = false
	var accumulation_timer: SceneTreeTimer = null
	
	var items: Array[StateChangeItem] = []
	var _item_prop_key_map: Dictionary = {} # String: StateChangeProperty.
	
	# We need a reference type to make sure it can be shared by lambdas. We also need it
	# not to leak, so it's allocated with the state.
	var _context: Dictionary = {}
	
	
	func _should_accumulate() -> bool:
		return not accumulation_id.is_empty() && not accumulation_pending
	
	
	func get_context() -> Dictionary:
		return _context
	
	
	# Suitable for tracking properties of persistent objects, like songs and arrangements.
	# When change accumulation is enabled, finds the original item and redefines its do action.
	func add_property(object: Object, prop_name: String, new_value: Variant) -> StateChangeProperty:
		var prop_key := "%d_%s" % [ object.get_instance_id(), prop_name ]
		var prop: StateChangeProperty
		
		if _should_accumulate() && _item_prop_key_map.has(prop_key):
			prop = _item_prop_key_map[prop_key] as StateChangeProperty
			
			# Redefine the do action to set the latest value. The rest remains as is.
			prop.commit = func() -> void:
				object.set(prop.name, new_value)
			
			print_verbose("StateManager: Accumulated property change for '%s'." % [ prop_name ])
			return prop
		
		prop = StateChangeProperty.new()
		prop.name = prop_name
		prop.value = object.get(prop.name)
		
		prop.commit = func() -> void:
			object.set(prop.name, new_value)
		
		prop.rollback = func(old_value: Variant) -> void:
			object.set(prop.name, old_value)
		
		items.push_back(prop)
		_item_prop_key_map[prop_key] = prop
		
		return prop
	
	
	# Suitable for tracking nested or complex properties of persistent objects, like arrangements.
	# When change accumulation is enabled, finds the original item and redefines its do action.
	func add_setget_property(object: Object, prop_name: String, new_value: Variant, prop_getter: Callable, prop_setter: Callable) -> StateChangeProperty:
		var prop_key := "%d_%s" % [ object.get_instance_id(), prop_name ]
		var prop: StateChangeProperty
		
		if _should_accumulate() && _item_prop_key_map.has(prop_key):
			prop = _item_prop_key_map[prop_key] as StateChangeProperty
			
			# Redefine the do action to set the latest value. The rest remains as is.
			prop.commit = func() -> void:
				prop_setter.call(new_value)
			
			print_verbose("StateManager: Accumulated property change for '%s'." % [ prop_name ])
			return prop
		
		prop = StateChangeProperty.new()
		prop.name = prop_name
		prop.value = prop_getter.call()
		
		prop.commit = func() -> void:
			prop_setter.call(new_value)
		
		prop.rollback = func(old_value: Variant) -> void:
			prop_setter.call(old_value)
		
		items.push_back(prop)
		_item_prop_key_map[prop_key] = prop
		
		return prop
	
	
	# Suitable for tracking properties of indexed members of persistent objects, like patterns and instruments of a song.
	# When change accumulation is enabled, finds the original item and redefines its do action.
	func add_indexed_property(object_array: Array, index: int, prop_name: String, new_value: Variant) -> StateChangeProperty:
		var prop_object: Object = object_array[index]
		var prop_key := "%d_%s" % [ prop_object.get_instance_id(), prop_name ]
		var prop: StateChangeProperty
		
		if _should_accumulate() && _item_prop_key_map.has(prop_key):
			prop = _item_prop_key_map[prop_key] as StateChangeProperty
			
			# Redefine the do action to set the latest value. The rest remains as is.
			prop.commit = func() -> void:
				var state_object: Object = object_array[index]
				state_object.set(prop.name, new_value)
			
			print_verbose("StateManager: Accumulated property change for '%s'." % [ prop_name ])
			return prop
		
		prop = StateChangeProperty.new()
		prop.name = prop_name
		prop.value = prop_object.get(prop.name)
		
		prop.commit = func() -> void:
			var state_object: Object = object_array[index]
			state_object.set(prop.name, new_value)
		
		prop.rollback = func(old_value: Variant) -> void:
			var state_object: Object = object_array[index]
			state_object.set(prop.name, old_value)
		
		items.push_back(prop)
		_item_prop_key_map[prop_key] = prop
		
		return prop
	
	
	# Suitable for finalizing actions when property changes require some additional steps afterwards.
	# When change accumulation is enabled, new actions are ignored on subsequent calls.
	func add_action(callback: Callable) -> StateChangeAction:
		if _should_accumulate():
			return null # Ignore.
		
		var action := StateChangeAction.new()
		action.commit = callback
		action.rollback = callback
		
		items.push_back(action)
		return action
	
	
	# Suitable for actions which should only be performed on do.
	# When change accumulation is enabled, new actions are ignored on subsequent calls.
	func add_do_action(callback: Callable) -> StateChangeAction:
		if _should_accumulate():
			return null # Ignore.
		
		var action := StateChangeAction.new()
		action.commit = callback
		
		items.push_back(action)
		return action
	
	
	# Suitable for actions which should only be performed on undo.
	# When change accumulation is enabled, new actions are ignored on subsequent calls.
	func add_undo_action(callback: Callable) -> StateChangeAction:
		if _should_accumulate():
			return null # Ignore.
		
		var action := StateChangeAction.new()
		action.rollback = callback
		
		items.push_back(action)
		return action


class StateChangeItem:
	pass


class StateChangeProperty extends StateChangeItem:
	var name: String = ""
	var value: Variant = null
	var commit: Callable = Callable()
	var rollback: Callable = Callable()


class StateChangeAction extends StateChangeItem:
	var commit: Callable = Callable()
	var rollback: Callable = Callable()
