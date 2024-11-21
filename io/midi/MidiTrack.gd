###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name MidiTrack extends RefCounted

var _events: Array[MidiTrackEvent] = []
var _events_unsorted: bool = false
var _end_of_track: MidiTrackEvent = null

@warning_ignore("integer_division")
var note_time: int = MidiFile.DEFAULT_RESOLUTION / 4


func _init() -> void:
	_end_of_track = MidiTrackEvent.new()
	_end_of_track.type = MidiTrackEvent.Type.META_EVENT
	
	var _end_payload := MidiTrackEvent.MetaPayload.new()
	_end_payload.meta_type = MidiTrackEvent.MetaType.END_OF_TRACK
	_end_of_track.payload = _end_payload # It's empty.


func get_buffer() -> PackedByteArray:
	# First, prepare the track data.
	if _events_unsorted:
		_events.sort_custom(_sort_events)
		_events_unsorted = false
	
	var content := PackedByteArray()
	var last_timestamp := 0
	for event in _events:
		ByteArrayUtil.write_vlen(content, event.timestamp - last_timestamp) # Delta time since last event.
		content.append_array(event.payload.pack())
		
		last_timestamp = event.timestamp
	
	# Add an end-of-track event.
	ByteArrayUtil.write_vlen(content, 0) # It's immediately after the last event.
	content.append_array(_end_of_track.payload.pack())
	
	# Now, pack track's meta information with prepared data.
	
	var output := PackedByteArray()
	ByteArrayUtil.write_string(output, MidiFile.FILE_TRACK_MARKER) # Track identifier.
	ByteArrayUtil.write_int32(output, content.size(), true)
	output.append_array(content)
	
	return output


func parse_event(event_type: int, timestamp: int, file: FileAccess) -> bool:
	var event := MidiTrackEvent.parse(event_type, timestamp, file)
	if not event:
		return false
	
	_events.push_back(event)
	return true


func get_events() -> Array[MidiTrackEvent]:
	return _events


func _sort_events(a: MidiTrackEvent, b: MidiTrackEvent) -> bool:
	if a.timestamp == b.timestamp:
		return a.order < b.order # Preserve insertion order when timestamp is the same.
	
	return a.timestamp < b.timestamp


# Meta events.

func add_meta_event(meta_type: MidiTrackEvent.MetaType, timestamp: int, data: PackedByteArray) -> void:
	var event := MidiTrackEvent.new()
	event.type = MidiTrackEvent.Type.META_EVENT
	event.timestamp = timestamp
	event.order = _events.size()
	
	var payload := MidiTrackEvent.MetaPayload.new()
	payload.meta_type = meta_type
	payload.data = data
	
	event.payload = payload
	_events.push_back(event)
	_events_unsorted = true


func add_time_signature(numerator: int, denominator: int, clocks_per_click: int = 24, quarter_note_resolution: int = 8) -> void:
	var event_data := PackedByteArray()
	
	# Denominator is stored as a power-of-2 value (e.g. 4 -> 2, 8 -> 3, etc).
	var po2_denominator := 0
	var n := denominator
	while n > 1:
		n >>= 1
		po2_denominator += 1
	
	event_data.append(numerator)
	event_data.append(po2_denominator)
	event_data.append(clocks_per_click)
	event_data.append(quarter_note_resolution)
	
	add_meta_event(MidiTrackEvent.MetaType.TIME_SIGNATURE, 0, event_data)


func add_tempo(bpm: int, denominator: int) -> void:
	var event_data := PackedByteArray()
	
	# Tempo is stored in microseconds per MIDI quarter-note.
	@warning_ignore("integer_division")
	var misec_per_beat := int(MidiFile.TEMPO_BASE / bpm * denominator / 4.0)
	
	# Value is always stored in 24 bits.
	event_data.append((misec_per_beat >> 16) & 0xFF)
	event_data.append((misec_per_beat >> 8 ) & 0xFF)
	event_data.append((misec_per_beat      ) & 0xFF)
	
	add_meta_event(MidiTrackEvent.MetaType.TEMPO_SETTING, 0, event_data)


# MIDI channel events.

func add_midi_event(midi_type: MidiTrackEvent.MidiType, channel_num: int, timestamp: int, data: PackedByteArray) -> void:
	var event := MidiTrackEvent.new()
	event.type = MidiTrackEvent.Type.MIDI_EVENT
	event.timestamp = timestamp
	event.order = _events.size()
	
	var payload := MidiTrackEvent.MidiPayload.new()
	payload.midi_type = midi_type
	payload.channel_num = channel_num
	payload.data = data
	
	event.payload = payload
	_events.push_back(event)
	_events_unsorted = true


func set_instrument(channel_num: int, voice_index: int) -> void:
	var event_data := PackedByteArray()
	
	# Note that mapped instruments are approximations and may not sound exactly the same.
	var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
	event_data.append(voice_data.midi_instrument)
	
	add_midi_event(MidiTrackEvent.MidiType.PROGRAM_CHANGE, channel_num, 0, event_data)


func add_note(channel_num: int, timestamp: int, pitch: int, length: int, volume: int) -> void:
	var midi_pitch := clampi(pitch, 0, 127)
	var midi_volume := clampi(floori(volume / 2.0), 0, 127)
	
	# Note ON event.
	var on_data := PackedByteArray()
	on_data.append(midi_pitch)
	on_data.append(midi_volume)
	
	add_midi_event(MidiTrackEvent.MidiType.NOTE_ON, channel_num, timestamp * note_time, on_data)
	
	# Note OFF event.
	var off_data := PackedByteArray()
	off_data.append(midi_pitch)
	off_data.append(0x00) # By convention OFF velocity is 0, which means release as quickly as possible.
	
	add_midi_event(MidiTrackEvent.MidiType.NOTE_OFF, channel_num, (timestamp + length) * note_time, on_data)
