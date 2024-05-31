###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name MidiTrackEvent extends RefCounted

enum Type {
	MIDI_EVENT,
	SYSTEM_EVENT,
	META_EVENT, # Meta is kind of a subtype of system events, but it's rather unique.
}

# There may be some other system events, but it's unlikely that those are stored in MIDI files.
enum SystemType {
	SYSTEM_EXCLUSIVE     = 0xF0,
	SYSTEM_EXCLUSIVE_END = 0xF7,
	META_EVENT           = 0xFF,
}

enum MetaType {
	SEQUENCE_NUMBER     = 0x00,
	TEXT_EVENT          = 0x01,
	COPYRIGHT_NOTICE    = 0x02,
	SEQUENCE_TRACK_NAME = 0x03,
	INSTRUMENT_NAME     = 0x04,
	LYRIC               = 0x05,
	MARKER              = 0x06,
	CUE_POINT           = 0x07,
	MIDI_CHANNEL_PREFIX = 0x20,
	END_OF_TRACK        = 0x2F,
	TEMPO_SETTING       = 0x51,
	SMPTE_OFFSET        = 0x54,
	TIME_SIGNATURE      = 0x58,
	KEY_SIGNATURE       = 0x59,
	SEQUENCER_SPECIFIC  = 0x7F,
}

# Only top nibble is relevant, this value is combined with the channel number to form a byte.
enum MidiType {
	NOTE_OFF            = 0x80,
	NOTE_ON             = 0x90,
	POLYPHONIC_PRESSURE = 0xA0,
	CONTROL_CHANGE      = 0xB0,
	PROGRAM_CHANGE      = 0xC0,
	CHANNEL_PRESSURE    = 0xD0,
	PITCH_BEND          = 0xE0,
}

var type: Type = Type.META_EVENT
var timestamp: int = 0
var payload: Payload = null


static func parse(event_type: int, event_timestamp: int, file: FileAccess) -> MidiTrackEvent:
	if event_type == SystemType.META_EVENT:
		var event := MidiTrackEvent.new()
		event.type = Type.META_EVENT
		event.timestamp = event_timestamp
		
		var meta_payload := MetaPayload.new()
		meta_payload.meta_type = file.get_8()
		var data_length := ByteArrayUtil.read_vlen(file)
		meta_payload.data = file.get_buffer(data_length)
		
		event.payload = meta_payload
		return event
	
	if event_type == SystemType.SYSTEM_EXCLUSIVE || event_type == SystemType.SYSTEM_EXCLUSIVE_END:
		var event := MidiTrackEvent.new()
		event.type = Type.SYSTEM_EVENT
		event.timestamp = event_timestamp
		
		var sys_payload := SystemPayload.new()
		sys_payload.system_type = event_type
		var data_length := ByteArrayUtil.read_vlen(file)
		sys_payload.data = file.get_buffer(data_length)
		
		event.payload = sys_payload
		return event
	
	var midi_type_nibble := event_type >> 4
	if midi_type_nibble >= 0x8 && midi_type_nibble <= 0xE:
		var event := MidiTrackEvent.new()
		event.type = Type.MIDI_EVENT
		event.timestamp = event_timestamp
		
		var midi_payload := MidiPayload.new()
		midi_payload.midi_type = midi_type_nibble << 4
		midi_payload.channel_num = event_type & 0x0F
		
		# In MIDI events, data has fixed size dependent on the MIDI event type.
		if midi_payload.midi_type == MidiType.PROGRAM_CHANGE || midi_payload.midi_type == MidiType.CHANNEL_PRESSURE:
			midi_payload.data = file.get_buffer(1) # One byte of data.
		else:
			midi_payload.data = file.get_buffer(2) # Two bytes of data.
		
		event.payload = midi_payload
		return event
	
	return null


class Payload:
	func pack() -> PackedByteArray:
		return PackedByteArray()


class SystemPayload extends Payload:
	var system_type: int = -1
	var data: PackedByteArray = PackedByteArray()
	
	
	func pack() -> PackedByteArray:
		var packed_data := PackedByteArray()
		packed_data.append(system_type)
		
		ByteArrayUtil.write_vlen(packed_data, data.size())
		packed_data.append_array(data)
		
		return packed_data


class MetaPayload extends Payload:
	var meta_type: int = -1
	var data: PackedByteArray = PackedByteArray()
	
	
	func pack() -> PackedByteArray:
		var packed_data := PackedByteArray()
		packed_data.append(SystemType.META_EVENT) # Meta event identifier.
		packed_data.append(meta_type)
		
		ByteArrayUtil.write_vlen(packed_data, data.size())
		packed_data.append_array(data)
		
		return packed_data


class MidiPayload extends Payload:
	var midi_type: int = -1
	var channel_num: int = -1
	var data: PackedByteArray = PackedByteArray()
	
	
	func pack() -> PackedByteArray:
		var packed_data := PackedByteArray()
		packed_data.append(midi_type + channel_num) # MIDI channel event identifier.
		packed_data.append_array(data)
		
		return packed_data
