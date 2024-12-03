###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A container for all composition and playback details of an individual
## Bosca Ceoil song.
class_name Song extends Resource

signal song_changed()
signal pattern_added(pattern: Pattern)
signal pattern_removed(pattern: Pattern)
signal instrument_added(instrument: Instrument)
signal instrument_removed(instrument: Instrument)

const FILE_FORMAT := 3
const FILE_EXTENSION := "ceol"
const FILE_DEFAULT_NAME := "new_song"

# These numbers are probably limited by the MIDI specification. For example, instruments
# are translated into MIDI channels, and there can be only up to 16 channels (half a byte).
const MAX_INSTRUMENT_COUNT := 16
const MAX_PATTERN_COUNT := 4096

const DEFAULT_PATTERN_SIZE := 16
const MAX_PATTERN_SIZE := 32
const DEFAULT_BAR_SIZE := 4

const DEFAULT_BPM := 120
const MIN_BPM := 10
const MAX_BPM := 450 # This is obscenely large.

# Metadata.

## File format version.
@export var format_version: int = FILE_FORMAT
## Song's title.
@export var name: String = ""
## File name on disk, if available.
@export var filename: String = ""

# Base settings.

## Length of each pattern in notes.
@export var pattern_size: int = DEFAULT_PATTERN_SIZE:
	set(value): pattern_size = ValueValidator.range(value, 1, MAX_PATTERN_SIZE)
## Length of a bar in notes, purely visual.
@export var bar_size: int = DEFAULT_BAR_SIZE:
	set(value): bar_size = ValueValidator.range(value, 1, MAX_PATTERN_SIZE)
## Beats per minute.
@export var bpm: int = DEFAULT_BPM:
	set(value): bpm = ValueValidator.range(value, MIN_BPM, MAX_BPM)

# Advanced settings.

## Swing's direction and power.
@export var swing: int = 0:
	set(value): swing = ValueValidator.range(value, -10, 10)
## Index of the globally applied effect.
@export var global_effect: int = 0:
	# Max value is limited by the number of implemented effects.
	set(value): global_effect = ValueValidator.posizero(value)
## Power/intensity of the globally applied effect.
@export var global_effect_power: int = 0:
	# This is probably not intentional, but effect power can go up to 130% in the original Bosca Ceoil.
	set(value): global_effect_power = ValueValidator.range(value, 0, 130)

# Composition.

## Instruments used by the song.
@export var instruments: Array[Instrument] = []
## Note patterns defined for the song.
@export var patterns: Array[Pattern] = []
## Arrangement of the song.
@export var arrangement: Arrangement = Arrangement.new()

# Runtime properties.

var _dirty: bool = false


func _to_string() -> String:
	return "Song <v%d, %d/%d/%d, inst:%d, pat:%d, arr:%d>" % [ format_version, bpm, pattern_size, bar_size, instruments.size(), patterns.size(), arrangement.timeline_length ]


static func create_default_song() -> Song:
	var song := Song.new()
	
	# Create the default instrument, which is hard set to be MIDI Grand Piano.
	var voice_data := Controller.voice_manager.get_voice_data("MIDI", "Grand Piano")
	var default_instrument := SingleVoiceInstrument.new(voice_data)
	song.instruments.push_back(default_instrument)

	# There must be at least one pattern in the song.
	var default_pattern := Pattern.new()
	song.patterns.push_back(default_pattern)
	
	# By default make the first pattern active on the timeline.
	song.arrangement.set_pattern(0, 0, 0)
	
	return song


func get_safe_filename(extension: String = FILE_EXTENSION) -> String:
	if filename.is_empty():
		return "%s.%s" % [ FILE_DEFAULT_NAME, extension ]
	
	var base_name := filename.get_file().get_basename()
	return "%s.%s" % [ base_name, extension ]


# Patterns.

func add_pattern(pattern: Pattern, pattern_idx: int = -1) -> void:
	if pattern_idx < 0:
		patterns.push_back(pattern)
	else:
		patterns.insert(pattern_idx, pattern)
	
	pattern_added.emit(pattern)


func remove_pattern(pattern_idx: int) -> void:
	var pattern := patterns[pattern_idx]
	patterns.remove_at(pattern_idx)
	pattern_removed.emit(pattern)


# Instruments.

func add_instrument(instrument: Instrument, instrument_idx: int = -1) -> void:
	if instrument_idx < 0:
		instruments.push_back(instrument)
	else:
		instruments.insert(instrument_idx, instrument)
	
	instrument_added.emit(instrument)


func remove_instrument(instrument_idx: int) -> void:
	var instrument := instruments[instrument_idx]
	instruments.remove_at(instrument_idx)
	instrument_removed.emit(instrument)


# Composition.

func reset_arrangement() -> void:
	arrangement.current_bar_idx = arrangement.loop_start


func get_current_arrangement_bar() -> PackedInt32Array:
	return arrangement.get_current_bar()


func reset_playing_patterns() -> void:
	for pattern in patterns:
		pattern.is_playing = false


# Runtime.

func mark_dirty() -> void:
	_dirty = true
	song_changed.emit()


func mark_clean() -> void:
	_dirty = false


func is_dirty() -> bool:
	return _dirty
