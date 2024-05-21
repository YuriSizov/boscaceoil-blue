###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A container for the song's timeline, and the pattern arrangement on it.
class_name Arrangement extends Resource

signal patterns_changed()
signal loop_changed()

## Maximum number of bars (the limit is arbitrary).
const BAR_NUMBER := 1000
## Maximum number of channels.
const CHANNEL_NUMBER := 8

## Maximum length of the timeline in timeline bars.
@export var timeline_length: int = 1:
	set(value): timeline_length = ValueValidator.posizero(value)
## Start bar on the timeline.
@export var loop_start: int = 0:
	set(value): loop_start = ValueValidator.posizero(value)
## End bar on the timeline.
@export var loop_end: int = 1:
	set(value): loop_end = ValueValidator.posizero(value)

## Pattern indices, grouped by timeline bars. The packed array is exactly
## CHANNEL_NUMBER long.
@export var timeline_bars: Array[PackedInt32Array] = []

# Runtime properties.

## Index of the currently playing bar.
var current_bar_idx: int = 0:
	set(value): current_bar_idx = ValueValidator.index(value, BAR_NUMBER)

## Clipboard for copy-pasting pattern ranges.
var copy_buffer: Array[PackedInt32Array] = []


func _init() -> void:
	timeline_bars.resize(BAR_NUMBER)
	for i in BAR_NUMBER:
		clear_bar(i, true)


# Timeline bars.

func insert_bar(at_index: int, silent: bool = false) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot insert a bar at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return
	if at_index >= timeline_length:
		return # Index is outside of the filled in range, so there is nothing to do.
	
	# Shift all bars to the right.
	for i in range(timeline_length + 1, at_index, -1):
		timeline_bars[i] = timeline_bars[i - 1].duplicate()
	
	clear_bar(at_index, true)
	timeline_length += 1
	
	if not silent:
		patterns_changed.emit()


func clear_bar(at_index: int, silent: bool = false) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot clear a bar at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return
	
	var channels := PackedInt32Array()
	channels.resize(CHANNEL_NUMBER)
	channels.fill(-1)
	timeline_bars[at_index] = channels
	
	if not silent:
		patterns_changed.emit()


func remove_bar(at_index: int, silent: bool = false) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot remove a bar at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return
	if at_index >= timeline_length:
		return # Index is outside of the filled in range, so there is nothing to do.
	
	# Erase the bar by shifting to the left.
	for i in range(at_index, timeline_length):
		# Erase the last bar by clearing it.
		if i == (BAR_NUMBER - 1):
			var channels := PackedInt32Array()
			channels.resize(CHANNEL_NUMBER)
			channels.fill(-1)
			timeline_bars[i] = channels
		else:
			timeline_bars[i] = timeline_bars[i + 1].duplicate()
	
	timeline_length -= 1
	
	if not silent:
		patterns_changed.emit()


func copy_bar_range(from_bar: int, to_bar: int) -> void:
	var from_bar_index_ := ValueValidator.index(from_bar, BAR_NUMBER, "Arrangement: Cannot copy bars in a range starting from %d, index is outside of the valid range [%d, %d]." % [ from_bar, 0, BAR_NUMBER - 1 ])
	var to_bar_index_ := ValueValidator.index(to_bar, BAR_NUMBER, "Arrangement: Cannot copy bars in a range ending at %d, index is outside of the valid range [%d, %d]." % [ to_bar, 0, BAR_NUMBER - 1 ])
	if from_bar_index_ != from_bar || to_bar_index_ != to_bar:
		return
	
	copy_buffer.clear()
	for i in range(from_bar, to_bar):
		copy_buffer.push_back(timeline_bars[i].duplicate())


func paste_bar_range(at_index: int) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot insert copied bars at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return
	ValueValidator.index(at_index + copy_buffer.size(), BAR_NUMBER, "Arrangement: Cannot insert all of the copied bars at index %d, range end %d is outside of the valid range [%d, %d]." % [ at_index, at_index + copy_buffer.size(), 0, BAR_NUMBER - 1 ])
	
	# Create empty bars for the buffer.
	for i in copy_buffer.size():
		insert_bar(at_index, true)
	
	var max_bar_idx := mini(BAR_NUMBER - 1, at_index + copy_buffer.size())
	for i in range(at_index, max_bar_idx):
		timeline_bars[i] = copy_buffer[i - at_index].duplicate()
	
	if max_bar_idx >= timeline_length:
		timeline_length = max_bar_idx + 1
	
	patterns_changed.emit()


func get_current_bar() -> PackedInt32Array:
	return timeline_bars[current_bar_idx]


# Patterns.

func set_pattern(bar_idx: int, channel_idx: int, value: int) -> void:
	var bar_index_ := ValueValidator.index(bar_idx, BAR_NUMBER, "Arrangement: Cannot set a pattern for a bar at %d, index is outside of the valid range [%d, %d]." % [ bar_idx, 0, BAR_NUMBER - 1 ])
	var channel_index_ := ValueValidator.index(channel_idx, CHANNEL_NUMBER, "Arrangement: Cannot set a pattern for a channel %d, index is outside of the valid range [%d, %d]." % [ channel_idx, 0, CHANNEL_NUMBER - 1 ])
	if bar_index_ != bar_idx || channel_index_ != channel_idx:
		return
	
	timeline_bars[bar_idx][channel_idx] = value
	if bar_idx >= timeline_length:
		timeline_length = bar_idx + 1
	
	patterns_changed.emit()


func clear_pattern(bar_idx: int, channel_idx: int) -> void:
	var bar_index_ := ValueValidator.index(bar_idx, BAR_NUMBER, "Arrangement: Cannot clear a pattern for a bar at %d, index is outside of the valid range [%d, %d]." % [ bar_idx, 0, BAR_NUMBER - 1 ])
	var channel_index_ := ValueValidator.index(channel_idx, CHANNEL_NUMBER, "Arrangement: Cannot clear a pattern for a channel %d, index is outside of the valid range [%d, %d]." % [ channel_idx, 0, CHANNEL_NUMBER - 1 ])
	if bar_index_ != bar_idx || channel_index_ != channel_idx:
		return
	
	timeline_bars[bar_idx][channel_idx] = -1
	
	# If we modified the last bar, check the timeline length for changes.
	if bar_idx == (timeline_length - 1):
		while timeline_length > 0:
			var matched := false
			for i in CHANNEL_NUMBER:
				if timeline_bars[timeline_length - 1][i] > -1:
					matched = true
					break
			if matched:
				break
			
			timeline_length -= 1
	
	patterns_changed.emit()


# Loop.

func set_loop(start_idx: int, end_idx: int) -> void:
	loop_start = start_idx
	loop_end = end_idx
	
	if current_bar_idx < loop_start || current_bar_idx >= loop_end:
		current_bar_idx = loop_start
	
	loop_changed.emit()


func progress_loop() -> bool:
	var next_bar := current_bar_idx + 1
	if next_bar >= loop_end:
		current_bar_idx = loop_start
		return true # Looped.
	else:
		current_bar_idx = next_bar
		return false # Didn't loop.
