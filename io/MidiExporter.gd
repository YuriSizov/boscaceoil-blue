###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# MIDI format implementation is based on the specification description referenced from:
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
	
	# Track chunk 2. Non-drumkit instruments and notes.
	# Channel 9 is special and is used for drums, so we avoid it by splitting the list in two.
	
	# Indices 0-8.
	var main_track1 := writer.create_track()
	_write_instruments_to_track(main_track1, song, MidiFile.DRUMKIT_CHANNEL, 0)
	
	# Indices 9-15.
	if song.instruments.size() > MidiFile.DRUMKIT_CHANNEL:
		var main_track2 := writer.create_track()
		_write_instruments_to_track(main_track2, song, MidiFile.DRUMKIT_CHANNEL, MidiFile.DRUMKIT_CHANNEL)
	
	# Track chunk 3. Drumkit instrument and notes.
	
	var drum_track := writer.create_track()
	_write_drumkits_to_track(drum_track, song)
	
	# Prepare the rest of the file for output.
	writer.finalize()


static func _write_instruments_to_track(track: MidiTrack, song: Song, limit: int, offset: int) -> void:
	# Define all standard instruments in separate channels (up to limit, but no more than 16 overall).
	var max_instrument_size := mini(song.instruments.size() - offset, limit)
	for i in max_instrument_size:
		var instrument := song.instruments[i + offset]
		if instrument is DrumkitInstrument:
			continue
		
		track.set_instrument(i, instrument.voice_index)
	
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
				
				track.add_note(pattern.instrument_idx - offset, note_offset + note.y, note.x, note.z, instrument.volume)


static func _write_drumkits_to_track(track: MidiTrack, song: Song) -> void:
	# Use special drumkit channel and a catch-all instrument.
	track.set_instrument(MidiFile.DRUMKIT_CHANNEL, 0)

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
					
					track.add_note(MidiFile.DRUMKIT_CHANNEL, note_offset + note.y, note_value, note.z, instrument.volume)


class MidiFileWriter:
	var format: int = MidiFile.FileFormat.MULTI_TRACK
	var resolution: int = MidiFile.DEFAULT_RESOLUTION
	
	var _tracks: Array[MidiTrack] = []
	var _output: PackedByteArray = PackedByteArray()
	
	
	func get_file_buffer() -> PackedByteArray:
		return _output
	
	
	func write_midi_header() -> void:
		ByteArrayUtil.write_string(_output, MidiFile.FILE_HEADER_MARKER) # MIDI file description.
		ByteArrayUtil.write_int32(_output, 6, true) # Header length, it's always 6 bytes.
	
	
	func create_track() -> MidiTrack:
		var track := MidiTrack.new()
		_tracks.push_back(track)
		
		return track
	
	
	func finalize() -> void:
		ByteArrayUtil.write_int16(_output, format, true)
		ByteArrayUtil.write_int16(_output, _tracks.size(), true)
		ByteArrayUtil.write_int16(_output, resolution, true) # Unit of time for delta timing.
		
		for track in _tracks:
			_output.append_array(track.get_buffer())
