###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A specialized implementation of a single voice instrument.
class_name SingleVoiceInstrument extends Instrument

## Main voice associated with this instrument.
var voice: SiONVoice = SiONVoice.new()


# Voice data.

func set_voice_data(voice_data: VoiceManager.VoiceData) -> void:
	super(voice_data)
	voice = Controller.voice_manager.get_voice_preset(_voice_data.voice_preset)


func is_note_valid(_note: Vector3i) -> bool:
	return true


func get_note_value(note: int) -> int:
	return note


func get_note_voice(_note: int) -> SiONVoice:
	return voice


# Filter state.

func update_filter() -> void:
	if not voice:
		return

	if voice.velocity != volume:
		voice.update_volumes = true
		voice.velocity = volume

	if (voice.get_channel_params().filter_cutoff != lp_cutoff || voice.get_channel_params().filter_resonance != lp_resonance):
		voice.set_filter_envelope(0, lp_cutoff, lp_resonance)


func change_filter_to(cutoff_: int, resonance_: int, volume_: int) -> void:
	if not voice:
		return

	voice.update_volumes = true
	voice.velocity = volume_
	voice.set_filter_envelope(0, cutoff_, resonance_)
