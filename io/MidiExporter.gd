###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# MIDI format implementation is based on the specification description referenced from:
# - https://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html
# - https://ccrma.stanford.edu/~craig/14q/midifile/MidiFileFormat.html

class_name MidiExporter extends RefCounted

const FILE_EXTENSION := "mid"


static func save(song: Song, path: String, _export_config: ExportMasterPopup.ExportConfig) -> bool:
	if path.get_extension() != FILE_EXTENSION:
		printerr("MidiExporter: The MIDI file must have a .%s extension." % [ FILE_EXTENSION ])
		return false
	
	var file := FileWrapper.new()
	var error := file.open(path, FileAccess.WRITE)
	if error != OK:
		printerr("MidiExporter: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := MidiFileWriter.new()
	_write(writer, song)
	
	# Try to write the file with the new contents.
	
	error = file.write_buffer_contents(writer.get_file_buffer())
	if error != OK:
		printerr("MidiExporter: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	error = file.finalize_write()
	if error != OK:
		printerr("MidiExporter: Failed to finalize write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	return true


static func _write(writer: MidiFileWriter, song: Song) -> void:
	# Basic information.
	writer.write_midi_header()
	
	# Track chunk 1. Meta events.
	
	var meta_track := writer.create_track()
	_write_time_signature(meta_track, song)
	
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


static func _write_time_signature(track: MidiTrack, song: Song) -> void:
	# The time signature consists of two parts: the numerator and the denominator:
	# - The denominator is the size of the beat in parts of a whole tone (note). In
	#   GDSiON that's always 1/4th, i.e. a quarter note. This is also the default in
	#   MIDI.
	# - The numerator is the number of beats that compose one measure of a song
	#   (song's meter). As far as I can appreciate it, this value is for humans to
	#   help structure music sheets, and doesn't affect the actual timing of notes
	#   being played. In Bosca the whole measure can be assumed to be the pattern size.
	
	# To calculate the number of beats per pattrn size we need to know the unit size
	# of Bosca's notes (not to be confused with the whole tone/note referenced above).
	# Luckily, this is a fixed value. GDSiON uses 1/16th of a beat as its basic timing
	# unit, and Bosca defines its note as 4/16th of a beat respectively. So one square
	# on a pattern grid in Bosca is a quarter of a beat.
	
	# With this understood the numerator computation becomes trivial. It is the number
	# of beats per pattern, where the pattern consists of the pattern_size number of
	# items, each with the length of 4/16th of a beat.
	
	# One caveat here is that the pattern size can be irregular, which would lead to
	# an uneven number of beats per pattern (e.g. with patter_size of 13 we have 3.25
	# beats per pattern). I don't think that this can be addressed by changing the
	# denominator, as that directly affects timing and the meaning of a beat. So we
	# do the next best thing and round up the number of beats in these cases. (e.g
	# the above gives us 4 beats per pattern instead).
	
	# This shouldn't affect MIDI playback, only how the measure is displayed. On import
	# back to Bosca this guarantees no data loss, but makes patterns padded to the
	# rounded size. As a result, notes no longer group nicely into patterns. To address
	# that we let the user decide before the import, what pattern size is preferable.
	
	var note_numerator := ceili((MusicPlayer.NOTE_LENGTH * song.pattern_size) / 16)
	# This is a fixed value in GDSiON, as explained above.
	var note_denominator := 4
	
	track.add_time_signature(note_numerator, note_denominator)
	track.add_tempo(song.bpm, note_denominator)


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
				if not pattern.is_note_valid(note, song.pattern_size):
					continue
				
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
					if not pattern.is_note_valid(note, song.pattern_size):
						continue
					
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
		track.beat_resolution = resolution
		_tracks.push_back(track)
		
		return track
	
	
	func finalize() -> void:
		ByteArrayUtil.write_int16(_output, format, true)
		ByteArrayUtil.write_int16(_output, _tracks.size(), true)
		ByteArrayUtil.write_int16(_output, resolution, true) # Unit of time for delta timing.
		
		for track in _tracks:
			_output.append_array(track.get_buffer())
