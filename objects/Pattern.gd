###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A description of a single pattern contributing to the song's composition.
class_name Pattern extends Resource

const NOTE_NUMBER := 128
const RECORD_FILTER_NUMBER := 16

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
## note length. Middle C has the index of 60. There can be at most NOTE_NUMBER notes.
@export var notes: Array[Vector3i] = []
## Number of active notes. The note array is always allocated to its maximum. This
## tracks how many notes there actually are.
@export var note_amount: int = 0:
	set(value): note_amount = ValueValidator.range(value, 0, NOTE_NUMBER)

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


func _init() -> void:
	for i in NOTE_NUMBER:
		notes.push_back(Vector3i(-1, 0, 0))

	for i in RECORD_FILTER_NUMBER:
		record_filter_values.push_back(Vector3i(Instrument.VOLUME_MAX, Instrument.FILTER_CUTOFF_MAX, 0))


func add_note(note: int, position: int, length: int, autosort: bool = true) -> void:
	if note < 0 || position < 0:
		printerr("Pattern: Cannot add a note %d at %d, values cannot be less than zero." % [ note, position ])
		return
	if note_amount >= NOTE_NUMBER:
		printerr("Pattern: Cannot add a new note, a pattern can only contain %d notes." % [ NOTE_NUMBER ])
		return

	notes[note_amount] = Vector3i(note, position, length)
	_hash = (_hash + (note * length)) % 2147483647

	if autosort: # Can be disabled and called manually when many notes are added quickly.
		sort_notes()
	note_amount += 1


func sort_notes() -> void:
	notes.sort_custom(func (a, b):
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


func has_note(note: int, position: int, exact: bool = false) -> bool:
	if note < 0 || position < 0:
		return false

	for i in note_amount:
		if notes[i].x != note:
			continue

		if exact && position == notes[i].y:
			return true
		if not exact && position >= notes[i].y && position < (notes[i].y + notes[i].z):
			return true

	return false


func remove_note(note: int, position: int, exact: bool = false) -> void:
	if note < 0 || position < 0:
		printerr("Pattern: Cannot remove a note %d at %d, values cannot be less than zero." % [ note, position ])
		return

	var i := 0
	while i < note_amount:
		if notes[i].x == note:
			if exact && position == notes[i].y:
				remove_note_at(i)
				i -= 1
			
			if not exact && position >= notes[i].y && position < (notes[i].y + notes[i].z):
				remove_note_at(i)
				i -= 1

		i += 1


func remove_note_at(index: int) -> void:
	var index_ := ValueValidator.index(index, note_amount, "Pattern: Cannot remove a note at index %d, index is outside of the valid range [%d, %d]." % [ index, 0, note_amount - 1 ])
	if index_ != index:
		return

	# Erase the note by shifting the array.
	for i in range(index, note_amount):
		notes[i] = notes[i + 1] # Copy by value.

	note_amount -= 1
