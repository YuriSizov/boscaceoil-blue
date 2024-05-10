###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A specialized implementation of a drumkit instrument.
class_name DrumkitInstrument extends Instrument

## Collection of voices, one for each drumkit item.
var voices: Array[SiONVoice] = []


# Voice data.

func set_voice_data(voice_data: VoiceManager.VoiceData) -> void:
	super(voice_data)
	type = InstrumentType.INSTRUMENT_DRUMKIT
	
	voices.clear()

	var drumkit_data := _voice_data as VoiceManager.DrumkitData
	for item in drumkit_data.items:
		var voice := Controller.voice_manager.get_voice_preset(item.voice_preset)
		voices.push_back(voice)


func is_note_valid(note: Vector3i) -> bool:
	# Drumkits have a limited number of "notes" available, potentially below the normal cap.
	return note.x < voices.size()


func get_note_value(note: int) -> int:
	var drumkit_data := _voice_data as VoiceManager.DrumkitData
	return drumkit_data.items[note].note


func get_note_voice(note: int) -> SiONVoice:
	return voices[note]


func get_note_name(note: int) -> String:
	var drumkit_data := _voice_data as VoiceManager.DrumkitData
	return drumkit_data.items[note].name


func get_midi_note(note: int) -> int:
	var drumkit_data := _voice_data as VoiceManager.DrumkitData
	return drumkit_data.items[note].midi_note


# Filter state.

func update_filter() -> void:
	for voice in voices:
		if voice.velocity != volume:
			voice.update_volumes = true
			voice.velocity = volume

		if (voice.get_channel_params().filter_cutoff != lp_cutoff || voice.get_channel_params().filter_resonance != lp_resonance):
			voice.set_filter_envelope(0, lp_cutoff, lp_resonance)


func change_filter_to(cutoff_: int, resonance_: int, volume_: int) -> void:
	for voice in voices:
		voice.update_volumes = true
		voice.velocity = volume_
		voice.set_filter_envelope(0, cutoff_, resonance_)
