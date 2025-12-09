###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A description of a musical instrument and its configuration.
class_name Instrument extends Resource

const INSTRUMENT_NUMBER := 16

enum InstrumentType {
	INSTRUMENT_SINGLE,
	INSTRUMENT_DRUMKIT,
	MAX
}

const MAX_VOLUME := 256
const MAX_FILTER_CUTOFF := 128
const MAX_FILTER_RESONANCE := 9

# Metadata.

## Type of the instrument, see InstrumentType.
@export var type: int = 0:
	set(value): type = ValueValidator.index(value, InstrumentType.MAX)
## Internal index of the instrument voice.
@export var voice_index: int = 0:
	set(value): voice_index = ValueValidator.posizero(value) # Max value is limited by the number of registered voices.

# Voice data (runtime only).

## Reference to the voice data for the instrument.
var _voice_data: VoiceManager.VoiceData = null

## Category of the instrument, used for grouping in UI.
var category: String:
	get: return _voice_data.category if _voice_data else "[UNKNOWN]"
	set(value): pass
## Name of the instrument, used in UI.
var name: String:
	get: return _voice_data.name if _voice_data else "[Unknown]"
	set(value): pass
## Color palette for the instrument, used to color code the UI.
var color_palette: int:
	get: return _voice_data.color_palette if _voice_data else BoscaColorPalette.PALETTE_GRAY
	set(value): pass

# Adjustments.

## Volume.
@export var volume: int = MAX_VOLUME:
	set(value): volume = ValueValidator.range(value, 0, MAX_VOLUME)
## Low pass filter cutoff.
@export var lp_cutoff: int = MAX_FILTER_CUTOFF:
	set(value): lp_cutoff = ValueValidator.range(value, 0, MAX_FILTER_CUTOFF)
## Low pass filter resonance.
@export var lp_resonance: int = 0:
	set(value): lp_resonance = ValueValidator.range(value, 0, MAX_FILTER_RESONANCE)


func _init(voice_data: VoiceManager.VoiceData) -> void:
	set_voice_data(voice_data)


# Voice data.

func set_voice_data(voice_data: VoiceManager.VoiceData) -> void:
	_voice_data = voice_data
	voice_index = _voice_data.index


func is_note_valid(_note: Vector3i) -> bool:
	return true


func get_note_value(note: int) -> int:
	return note


func get_note_voice(_note: int) -> SiONVoice:
	return null


# Filter state.

func update_filter() -> void:
	pass # No default implementation.


func change_filter_to(_cutoff: int, _resonance: int, _volume: int) -> void:
	pass # No default implementation.
