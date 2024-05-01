###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A container for the song's timeline, and the pattern arrangement on it.
class_name Arrangement extends Resource

## Maximum number of bars (the limit is arbitrary).
const BAR_NUMBER := 1000
## Maximum number of channels.
const CHANNEL_NUMBER := 8

## Maximum length of the timeline in timeline bars.
@export var timeline_length: int = 1:
	set(value): timeline_length = ValueValidator.positive(value)
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
		clear_bar(i)


# Timeline bars.

func insert_bar(at_index: int) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot insert a bar at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return
	if at_index >= timeline_length:
		return # Index is outside of the filled in range, so there is nothing to do.

	# Shift all bars to the right.
	for i in range(timeline_length + 1, at_index, -1):
		timeline_bars[i] = timeline_bars[i - 1] # Copy by value.

	clear_bar(at_index)
	timeline_length += 1


func clear_bar(index: int) -> void:
	var index_ := ValueValidator.index(index, BAR_NUMBER, "Arrangement: Cannot clear a bar at index %d, index is outside of the valid range [%d, %d]." % [ index, 0, BAR_NUMBER - 1 ])
	if index_ != index:
		return

	var channels := PackedInt32Array()
	channels.resize(CHANNEL_NUMBER)
	channels.fill(-1)
	timeline_bars[index] = channels


func remove_bar_at(index: int) -> void:
	var index_ := ValueValidator.index(index, BAR_NUMBER, "Arrangement: Cannot remove a bar at index %d, index is outside of the valid range [%d, %d]." % [ index, 0, BAR_NUMBER - 1 ])
	if index_ != index:
		return

	# Erase the bar by shifting to the left.
	for i in range(index, timeline_length + 1):
		timeline_bars[i] = timeline_bars[i + 1] # Copy by value.

	timeline_length -= 1


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


func clear_pattern(bar_idx: int, channel_idx: int) -> void:
	var bar_index_ := ValueValidator.index(bar_idx, BAR_NUMBER, "Arrangement: Cannot clear a pattern for a bar at %d, index is outside of the valid range [%d, %d]." % [ bar_idx, 0, BAR_NUMBER - 1 ])
	var channel_index_ := ValueValidator.index(channel_idx, CHANNEL_NUMBER, "Arrangement: Cannot clear a pattern for a channel %d, index is outside of the valid range [%d, %d]." % [ channel_idx, 0, CHANNEL_NUMBER - 1 ])
	if bar_index_ != bar_idx || channel_index_ != channel_idx:
		return

	timeline_bars[bar_idx][channel_idx] = -1

	var length_check := 0
	for i in timeline_length + 1:
		for j in CHANNEL_NUMBER:
			if timeline_bars[i][j] > -1:
				length_check = i

	timeline_length = length_check + 1


func copy_pattern_range(from_bar: int, to_bar: int) -> void:
	var from_bar_index_ := ValueValidator.index(from_bar, BAR_NUMBER, "Arrangement: Cannot copy patterns in a range starting from %d, index is outside of the valid range [%d, %d]." % [ from_bar, 0, BAR_NUMBER - 1 ])
	var to_bar_index_ := ValueValidator.index(to_bar, BAR_NUMBER, "Arrangement: Cannot copy patterns in a range ending at %d, index is outside of the valid range [%d, %d]." % [ to_bar, 0, BAR_NUMBER - 1 ])
	if from_bar_index_ != from_bar || to_bar_index_ != to_bar:
		return

	copy_buffer.clear()
	for i in range(from_bar, to_bar):
		copy_buffer.push_back(timeline_bars[i]) # Copy by value.


func paste_pattern_range(at_index: int) -> void:
	var index_ := ValueValidator.index(at_index, BAR_NUMBER, "Arrangement: Cannot insert a bar at index %d, index is outside of the valid range [%d, %d]." % [ at_index, 0, BAR_NUMBER - 1 ])
	if index_ != at_index:
		return

	# Create empty bars for the buffer.
	for i in copy_buffer.size():
		insert_bar(at_index)

	for i in range(at_index, at_index + copy_buffer.size()):
		timeline_bars[i] = copy_buffer[i - at_index] # Copy by value.
