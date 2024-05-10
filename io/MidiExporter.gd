###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# Midi format implementation is based on the specification description referenced from:
# - https://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html
# - https://ccrma.stanford.edu/~craig/14q/midifile/MidiFileFormat.html

class_name MidiExporter extends RefCounted

const FILE_EXTENSION := "mid"


static func save(song: Song, path: String) -> bool:
	if path.get_extension() != FILE_EXTENSION:
		printerr("MidiExporter: The MIDI file must have a .%s extension." % [ FILE_EXTENSION ])
		return false
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("MidiExporter: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := MidiFileWriter.new()
	_write(writer, song)
	
	# Try to write the file with the new contents.
	
	file.store_buffer(writer.get_file_buffer())
	error = file.get_error()
	if error != OK:
		printerr("MidiExporter: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	return true


static func _write(writer: MidiFileWriter, song: Song) -> void:
	# Basic information.
	writer.write_midi_header()
	
	# Track chunk 1. Meta events.
	
	var meta_track := writer.create_track()
	meta_track.add_time_signature(4, 2, 24, 8)
	meta_track.add_tempo(song.bpm)
	
	# Track chunk 2. Instruments and non-drumkit notes.
	
	var main_track := writer.create_track()
	
	# Define all instruments in separate channels (up to 16).
	for i in song.instruments.size():
		main_track.set_instrument(i, song.instruments[i].voice_index)
	
	# Write all non-drumkit notes.
	for i in song.arrangement.timeline_length:
		var note_offset := i * song.pattern_size
		
		for j in Arrangement.CHANNEL_NUMBER:
			var pattern_index := song.arrangement.timeline_bars[i][j]
			if pattern_index == -1:
				continue
			
			var pattern := song.patterns[pattern_index]
			var instrument := song.instruments[pattern.instrument_idx]
			if instrument is DrumkitInstrument:
				continue
			
			for k in pattern.note_amount:
				var note := pattern.notes[k]
				
				main_track.add_note(pattern.instrument_idx, note_offset + note.y, note.x, note.z, instrument.volume)
	
	# Track chunk 3. Drumkit notes.
	
	var drum_track := writer.create_track()
	
	# Channel 9 is special and is used for drumkits.
	drum_track.set_instrument(9, 0)

	# Write all drumkit notes.
	for i in song.arrangement.timeline_length:
		var note_offset := i * song.pattern_size
		
		for j in Arrangement.CHANNEL_NUMBER:
			var pattern_index := song.arrangement.timeline_bars[i][j]
			if pattern_index == -1:
				continue
			
			var pattern := song.patterns[pattern_index]
			var instrument := song.instruments[pattern.instrument_idx]
			if instrument is DrumkitInstrument:
				var drumkit_instrument := instrument as DrumkitInstrument
				
				for k in pattern.note_amount:
					var note := pattern.notes[k]
					var note_value := drumkit_instrument.get_midi_note(note.x)
					
					drum_track.add_note(9, note_offset + note.y, note_value, note.z, instrument.volume)
	
	# Prepare the rest of the file for output.
	writer.finalize()


class MidiFileWriter:
	enum FileFormat {
		SINGLE_TRACK,
		MULTI_TRACK,
		MULTI_SONG,
	}
	
	var format: int = FileFormat.MULTI_TRACK
	var division: int = 120
	
	var _tracks: Array[MidiTrack] = []
	var _output: PackedByteArray = PackedByteArray()
	
	
	func get_file_buffer() -> PackedByteArray:
		return _output
	
	
	func write_midi_header() -> void:
		ByteArrayUtil.write_string(_output, "MThd") # MIDI file description.
		ByteArrayUtil.write_int32(_output, 6, true) # Header length, it's always 6 bytes.
	
	
	func create_track() -> MidiTrack:
		var track := MidiTrack.new()
		_tracks.push_back(track)
		
		return track
	
	
	func finalize() -> void:
		ByteArrayUtil.write_int16(_output, format, true)
		ByteArrayUtil.write_int16(_output, _tracks.size(), true)
		ByteArrayUtil.write_int16(_output, division, true) # Unit of time for delta timing.
		
		for track in _tracks:
			_output.append_array(track.get_buffer())


class MidiTrack:
	var _events: Array[MidiTrackEvent] = []
	var _events_unsorted: bool = false
	var _end_of_track: MidiTrackEvent = null
	
	var note_time: int = 30 # Quarter of MidiFileWriter.duration
	
	
	func _init() -> void:
		_end_of_track = MidiTrackEvent.new()
		_end_of_track.type = MidiTrackEvent.Type.META_EVENT
		
		_end_of_track.data.append(0xFF) # Meta event identifier.
		_end_of_track.data.append(MidiTrackEvent.MetaType.END_OF_TRACK)
		_end_of_track.data.append(0x00) # It's empty.
	
	
	func get_buffer() -> PackedByteArray:
		# First, prepare the track data.
		if _events_unsorted:
			_events.sort_custom(_sort_events)
			_events_unsorted = false
		
		var content := PackedByteArray()
		var last_timestamp := 0
		for event in _events:
			ByteArrayUtil.write_vlen(content, event.timestamp - last_timestamp) # Delta time since last event.
			content.append_array(event.data)
			
			last_timestamp = event.timestamp
		
		# Add an end-of-track event.
		ByteArrayUtil.write_vlen(content, 0) # It's immediately after the last event.
		content.append_array(_end_of_track.data)
		
		# Now, pack track's meta information with prepared data.
		
		var output := PackedByteArray()
		ByteArrayUtil.write_string(output, "MTrk") # Track identifier.
		ByteArrayUtil.write_int32(output, content.size(), true)
		output.append_array(content)
		
		return output
	
	
	func _sort_events(a: MidiTrackEvent, b: MidiTrackEvent) -> bool:
		return a.timestamp < b.timestamp
	
	
	# Meta events.
	
	func add_meta_event(meta_type: MidiTrackEvent.MetaType, timestamp: int, data: PackedByteArray) -> void:
		var event := MidiTrackEvent.new()
		event.type = MidiTrackEvent.Type.META_EVENT
		event.timestamp = timestamp
		
		var packed_data := PackedByteArray()
		packed_data.append(0xFF) # Meta event identifier.
		packed_data.append(meta_type)
		ByteArrayUtil.write_vlen(packed_data, data.size())
		packed_data.append_array(data)
		
		event.data = packed_data
		_events.push_back(event)
		_events_unsorted = true
	
	
	func add_time_signature(numerator: int, denominator: int, clocks_per_click: int, notated_notes: int) -> void:
		var event_data := PackedByteArray()
		event_data.append(numerator)
		event_data.append(denominator)
		event_data.append(clocks_per_click)
		event_data.append(notated_notes)
		
		add_meta_event(MidiTrackEvent.MetaType.TIME_SIGNATURE, 0, event_data)
	
	
	func add_tempo(bpm: int) -> void:
		var event_data := PackedByteArray()
		
		# Tempo is stored in microseconds per MIDI quarter-note.
		@warning_ignore("integer_division")
		var misec_per_beat := 60_000_000 / bpm
		
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
		
		var packed_data := PackedByteArray()
		packed_data.append(midi_type + channel_num) # MIDI channel event identifier.
		packed_data.append_array(data)
		
		event.data = packed_data
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


class MidiTrackEvent:
	enum Type {
		MIDI_EVENT,
		SYSEX_EVENT,
		META_EVENT,
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
	var data: PackedByteArray = PackedByteArray()
