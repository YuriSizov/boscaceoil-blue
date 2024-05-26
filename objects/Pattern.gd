###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A description of a single pattern contributing to the song's composition.
class_name Pattern extends Resource

signal key_changed()
signal scale_changed()
signal instrument_changed()
signal note_added(note_data: Vector3i)
signal notes_changed()

const OCTAVE_SIZE := 12
const MAX_NOTE_NUMBER := 128
const MAX_NOTE_VALUE := 104
const RECORD_FILTER_NUMBER := 32

## Key index.
@export var key: int = 0:
	set(value): key = ValueValidator.index(value, Note.MAX)
## Scale index.
@export var scale: int = 0:
	set(value): scale = ValueValidator.index(value, Scale.MAX)
## Instrument index, relative to the song.
@export var instrument_idx: int = 0:
	set(value): instrument_idx = ValueValidator.index(value, Instrument.INSTRUMENT_NUMBER)

## Note values as triplets: note index in the piano roll, note position in the pattern,
## note length. Middle C has the index of 60. There can be at most MAX_NOTE_NUMBER notes.
@export var notes: Array[Vector3i] = []
## Number of active notes. The note array is always allocated to its maximum. This
## tracks how many notes there actually are.
@export var note_amount: int = 0:
	set(value): note_amount = ValueValidator.range(value, 0, MAX_NOTE_NUMBER)

## Flag whether the record filter is on.
@export var record_filter_enabled: bool = false
## Filter values as triplets: volume, cutoff, resonance. There are exactly
## RECORD_FILTER_NUMBER values.
@export var record_filter_values: Array[Vector3i] = []

# Runtime properties.

## Simple sequential hash used when importing data from files.
var _hash: int = 0
## Flag whether the pattern is being played on this step.
var is_playing: bool = false
## Index of used unique note values, used when drawing a mini note map.
var active_note_span: PackedInt32Array = PackedInt32Array()
var _active_note_counts: Dictionary = {}


func _init() -> void:
	for i in MAX_NOTE_NUMBER:
		notes.push_back(Vector3i(-1, 0, 0))

	for i in RECORD_FILTER_NUMBER:
		record_filter_values.push_back(Vector3i(Instrument.VOLUME_MAX, Instrument.FILTER_CUTOFF_MAX, 0))


func clone() -> Pattern:
	var cloned := Pattern.new()
	cloned.key = key
	cloned.scale = scale
	cloned.instrument_idx = instrument_idx
	
	for note_index in note_amount:
		var note := notes[note_index]
		cloned.add_note(note.x, note.y, note.z, false)
	cloned.reindex_active_notes()
	
	cloned.record_filter_enabled = record_filter_enabled
	var filter_index := 0
	for filter_value in record_filter_values:
		cloned.record_filter_values[filter_index] = Vector3i(filter_value.x, filter_value.y, filter_value.z)
		filter_index += 1
	
	return cloned


# Properties.

func _get_valid_note_values() -> Array[int]:
	var valid_notes: Array[int] = []
	
	var next_valid_note := 0
	var scale_layout := Scale.get_scale_layout(scale)
	var scale_size := scale_layout.size()
	var scale_index := 0

	for note_value in MAX_NOTE_VALUE:
		if next_valid_note != note_value:
			continue
		valid_notes.push_back(note_value)
		
		next_valid_note += scale_layout[scale_index]
		scale_index += 1
		if scale_index >= scale_size:
			scale_index = 0
	
	return valid_notes


func change_key(new_key: int) -> void:
	var key_shift := new_key - key
	key = new_key
	
	# Adjust note values to the new key, preserving the overall pattern.
	
	for i in note_amount:
		notes[i].x += key_shift
	
	reindex_active_notes()
	key_changed.emit()


func change_scale(new_scale: int) -> void:
	scale = new_scale
	
	# Delete notes that don't fit the new scale.
	var valid_notes := _get_valid_note_values()
	var i := 0
	while i < note_amount:
		if not valid_notes.has(notes[i].x - key):
			remove_note_at(i)
			i -= 1
		i += 1
	
	reindex_active_notes()
	scale_changed.emit()


func shift_notes(offset: int) -> void:
	# Adjust note values to move them higher or lower, within the same key and scale.
	# Values reaching note range boundaries are kept at those boundary values.
	
	var valid_notes := _get_valid_note_values()
	
	# Notes are ordered by value, in the ascending order. We reverse the iterator
	# when going up to avoid collisions.
	var start_index := 0
	var max_index := note_amount
	var index_step := 1
	if offset > 0:
		start_index = note_amount - 1
		max_index = -1
		index_step = -1
	
	for i in range(start_index, max_index, index_step):
		var note_index := valid_notes.find(notes[i].x - key)
		var next_index := clampi(note_index + offset, 0, valid_notes.size() - 1)
		if next_index == note_index:
			continue
		
		# Don't move unless the space is unoccupied.
		if not has_note(valid_notes[next_index] + key, notes[i].y, true):
			notes[i].x = valid_notes[next_index] + key
	
	sort_notes()
	reindex_active_notes()
	notes_changed.emit()


func change_instrument(new_idx: int, instrument: Instrument) -> void:
	instrument_idx = new_idx
	
	# Delete notes that don't fit the new instrument.
	if instrument.type == Instrument.InstrumentType.INSTRUMENT_DRUMKIT:
		var drumkit_instrument := instrument as DrumkitInstrument
		var i := 0
		while i < note_amount:
			if notes[i].x >= drumkit_instrument.voices.size():
				remove_note_at(i)
				i -= 1
			i += 1
	
	instrument_changed.emit()


# Note map.

func reindex_active_notes() -> void:
	active_note_span.clear()
	_active_note_counts.clear()
	
	for i in note_amount:
		var note_value := notes[i].x
		if not active_note_span.has(note_value):
			active_note_span.push_back(note_value)
			_active_note_counts[note_value] = 0
		
		_active_note_counts[note_value] += 1
	
	active_note_span.sort()


func _index_note(note_value: int) -> void:
	if not active_note_span.has(note_value):
		active_note_span.push_back(note_value)
		active_note_span.sort()
		_active_note_counts[note_value] = 0
	
	_active_note_counts[note_value] += 1


func _unindex_note(note_value: int) -> void:
	if not active_note_span.has(note_value):
		return
	
	_active_note_counts[note_value] -= 1
	if _active_note_counts[note_value] <= 0:
		var span_idx := active_note_span.find(note_value)
		active_note_span.remove_at(span_idx)
		_active_note_counts.erase(note_value)


func get_active_note_span_size() -> int:
	if note_amount <= 0:
		return 0
	
	return active_note_span[active_note_span.size() - 1] - active_note_span[0] + 1


func add_note(value: int, position: int, length: int, full_update: bool = true) -> void:
	if value < 0 || position < 0:
		printerr("Pattern: Cannot add a note %d at %d, values cannot be less than zero." % [ value, position ])
		return
	if note_amount >= MAX_NOTE_NUMBER:
		printerr("Pattern: Cannot add a new note, a pattern can only contain %d notes." % [ MAX_NOTE_NUMBER ])
		return

	var note_data := Vector3i(value, position, length)
	notes[note_amount] = note_data
	_hash = (_hash + (value * length)) % 2147483647

	if full_update: # Can be disabled and called manually when many notes are added quickly.
		sort_notes()
		_index_note(value)
	
	note_amount += 1
	
	if full_update:
		note_added.emit(note_data)
		notes_changed.emit()


func sort_notes() -> void:
	notes.sort_custom(func (a: Vector3i, b: Vector3i) -> bool:
		if a.x < 0: # Empty record, sort to the end.
			return false
		if b.x < 0: # Empty record, sort to the end.
			return true
		if a.x < b.x: # Sort by note value first.
			return true
		if a.x == b.x && a.y < b.y: # Then sort by note position in a pattern row.
			return true
		return false
	)


func has_note(value: int, position: int, exact: bool = false) -> bool:
	if value < 0 || position < 0:
		return false

	for i in note_amount:
		if notes[i].x != value:
			continue

		if exact && position == notes[i].y:
			return true
		if not exact && position >= notes[i].y && position < (notes[i].y + notes[i].z):
			return true

	return false


func remove_note(value: int, position: int, exact: bool = false) -> void:
	if value < 0 || position < 0:
		printerr("Pattern: Cannot remove a note %d at %d, values cannot be less than zero." % [ value, position ])
		return
	
	var i := 0
	while i < note_amount:
		if notes[i].x == value:
			if exact && position == notes[i].y:
				remove_note_at(i)
				i -= 1
			
			if not exact && position >= notes[i].y && position < (notes[i].y + notes[i].z):
				remove_note_at(i)
				i -= 1
		i += 1
	
	notes_changed.emit()


func remove_note_at(index: int) -> void:
	var index_ := ValueValidator.index(index, note_amount, "Pattern: Cannot remove a note at index %d, index is outside of the valid range [%d, %d]." % [ index, 0, note_amount - 1 ])
	if index_ != index:
		return
	
	_unindex_note(notes[index].x)
	
	# Erase the note by shifting the array.
	for i in range(index, note_amount):
		notes[i] = notes[i + 1] # Copy by value.
	
	note_amount -= 1
