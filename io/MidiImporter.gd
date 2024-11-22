###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# MIDI format implementation is based on the specification description referenced from:
# - https://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html
# - https://ccrma.stanford.edu/~craig/14q/midifile/MidiFileFormat.html

class_name MidiImporter extends RefCounted

const FILE_EXTENSION := "mid"


static func prepare_import(path: String) -> bool:
	var file := _open_file(path)
	if not file:
		return false
	
	return true


static func import(path: String, config: Config) -> Song:
	var file := _open_file(path)
	if not file:
		return null
	
	var reader := MidiFileReader.new(file, config)
	return _read(reader)


static func _open_file(path: String) -> FileAccess:
	if path.get_extension() != FILE_EXTENSION:
		printerr("MidiImporter: The MIDI file must have a .%s extension." % [ FILE_EXTENSION ])
		return null
	
	var file := FileAccess.open(path, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("MidiImporter: Failed to open the file at '%s' for reading (code %d)." % [ path, error ])
		return null
	
	file.big_endian = true
	return file


static func _read(reader: MidiFileReader) -> Song:
	var song := Song.new()
	
	if not reader.read_midi_header():
		return null
	if not reader.read_midi_tracks():
		return null
	
	reader.extract_song_settings(song)
	reader.extract_composition(song)
	reader.create_patterns(song)
	
	song.mark_dirty() # Imported song is not saved.
	return song


class Config:
	var pattern_size: int = 0


class MidiFileReader:
	var format: int = MidiFile.FileFormat.MULTI_TRACK
	var resolution: int = MidiFile.DEFAULT_RESOLUTION
	
	var _tracks: Array[MidiTrack] = []
	var _instruments_index_map: Dictionary = {}
	var _notes_instrument_map: Dictionary = {}
	
	var _file: FileAccess = null
	var _config: Config = null
	
	
	func _init(file: FileAccess, config: Config) -> void:
		_file = file
		_file.seek(0)
		_config = config
	
	
	func read_midi_header() -> bool:
		var marker := ByteArrayUtil.read_string(_file, 4)
		if marker != MidiFile.FILE_HEADER_MARKER:
			printerr("MidiImporter: Failed to read the file at '%s', header marker is missing." % [ _file.get_path() ])
			return false
		
		# Read header bytes in order.
		_file.get_32() # Header size.
		format = _file.get_16()
		var track_num := _file.get_16()
		resolution = _file.get_16()
		
		for i in track_num:
			var track := MidiTrack.new()
			track.beat_resolution = resolution
			_tracks.push_back(track)
		
		return true
	
	
	func read_midi_tracks() -> bool:
		var i := 0
		for track in _tracks:
			var marker := ByteArrayUtil.read_string(_file, 4)
			if marker != MidiFile.FILE_TRACK_MARKER:
				printerr("MidiImporter: Failed to read the file at '%s', track marker is missing in track #%d." % [ _file.get_path(), i ])
				return false
			
			var track_size := _file.get_32()
			var track_end_position := _file.get_position() + track_size
			if track_end_position > _file.get_length():
				printerr("MidiImporter: Failed to read the file at '%s', track length extends beyond file length in track #%d." % [ _file.get_path(), i ])
				return false
			
			var event_timestamp := 0
			while _file.get_position() < track_end_position:
				var event_delta := ByteArrayUtil.read_vlen(_file)
				var event_type := _file.get_8()
				
				event_timestamp += event_delta
				if not track.parse_event(event_type, event_timestamp, _file):
					printerr("MidiImporter: Failed to read the file at '%s', track event (0x%02X) at %d is malformed or unknown in track #%d." % [ _file.get_path(), event_type, event_timestamp, i ])
					return false
			
			i += 1
		
		if _file.get_position() < _file.get_length():
			printerr("MidiImporter: The file at '%s' contains excessive data, it's either malformed or contains unsupported events." % [ _file.get_path() ])
			return false
		
		return true
	
	
	func extract_song_settings(song: Song) -> void:
		var signature_found := false
		var tempo_found := false
		
		# Default values per MIDI spec.
		var signature_numerator := 4
		var signature_denominator := 4
		var tempo := 500_000
		
		# Look for the settings in any track. Usually it's the first one, but we can't be sure.
		for track in _tracks:
			var events := track.get_events()
			
			for event in events:
				if not event.payload || event.payload is not MidiTrackEvent.MetaPayload:
					continue
				var meta_payload := event.payload as MidiTrackEvent.MetaPayload
				
				if not signature_found && meta_payload.meta_type == MidiTrackEvent.MetaType.TIME_SIGNATURE:
					signature_numerator = meta_payload.data[0]
					signature_denominator = 1 << meta_payload.data[1]
					
					# Bosca only supports one time signature per song, which isn't necessarily
					# true for MIDI files. Can't do much about it, so using the first one and praying.
					print_verbose("MidiImporter: Found a time signature message (%d, %d)." % [ signature_numerator, signature_denominator ])
					signature_found = true
				
				if not tempo_found && meta_payload.meta_type == MidiTrackEvent.MetaType.TEMPO_SETTING:
					# Tempo is stored in 24 bits.
					tempo = 0
					tempo += meta_payload.data[0] << 16
					tempo += meta_payload.data[1] << 8
					tempo += meta_payload.data[2]
					
					# Similarly, only one tempo setting is used, even though songs can contain
					# many which change throughout the tracks.
					print_verbose("MidiImporter: Found a tempo message (%d)." % [ tempo ])
					tempo_found = true
				
				if signature_found && tempo_found:
					break
			if signature_found && tempo_found:
				break
		
		# Compute pattern size and BPM based on our findings.
		
		# For starters, see the long explanation on the relation between the
		# pattern size and the time signature in MidiExporter._write_time_signature.
		
		# In short, the numerator is the number of beats per one song measure/meter.
		# On Bosca terms we assume that the whole measure is the pattern size. Which
		# makes the numerator the number of beats per pattern. So we can get the
		# pattern size by utilizing our knowledge of GDSiON's time units and Bosca's
		# note length.
		
		# The number of beats is a whole, integer number, which means that irregular
		# patterns are not possible as a result of the import process. For songs
		# previously exported from Bosca this means that the pattern size may be
		# larger than it was originally, rounded up to the next best value. This
		# leads to notes being badly grouped into patterns, but no data is lost.
		
		# This is fixable, but we do one better — a configuration screen ahead of
		# the import, where the user can specify any valid value to influence the
		# importer.
		
		if _config && _config.pattern_size > 0:
			song.pattern_size = _config.pattern_size
		else:
			var pattern_size := int(signature_numerator * 16 / MusicPlayer.NOTE_LENGTH)
			song.pattern_size = clampi(pattern_size, 1, Song.MAX_PATTERN_SIZE)
		
		@warning_ignore("integer_division")
		song.bpm = roundi(MidiFile.TEMPO_BASE / tempo * signature_denominator / 4.0)
	
	
	func extract_composition(song: Song) -> void:
		var i := 0
		for track in _tracks:
			var events := track.get_events()
			for event in events:
				if not event.payload || event.payload is not MidiTrackEvent.MidiPayload:
					continue
				var midi_payload := event.payload as MidiTrackEvent.MidiPayload
				
				if midi_payload.midi_type == MidiTrackEvent.MidiType.PROGRAM_CHANGE:
					_extract_instrument(i, midi_payload, song)
				
				if midi_payload.midi_type == MidiTrackEvent.MidiType.NOTE_ON:
					_extract_note(i, midi_payload, event.timestamp)
				
				if midi_payload.midi_type == MidiTrackEvent.MidiType.NOTE_OFF:
					_change_note_length(i, midi_payload, event.timestamp)
			
			i += 1
	
	
	func _extract_instrument(track_idx: int, midi_payload: MidiTrackEvent.MidiPayload, song: Song) -> void:
		var midi_instrument := MidiInstrument.new()
		midi_instrument.track_index = track_idx
		midi_instrument.channel_num = midi_payload.channel_num
		midi_instrument.midi_voice = midi_payload.data[0]
		
		# Keep a map for future use by notes.
		var index_key := midi_instrument.get_index_key()
		_instruments_index_map[index_key] = song.instruments.size()
		var instrument_notes: Array[MidiNote] = []
		_notes_instrument_map[index_key] = instrument_notes
		
		# Create the instrument itself and add it to the song.
		if midi_instrument.channel_num == MidiFile.DRUMKIT_CHANNEL: # This is drums, map to a drumkit.
			var voice_data := Controller.voice_manager.get_voice_data("DRUMKIT", "MIDI Drumkit")
			
			var bosca_drums := DrumkitInstrument.new(voice_data)
			bosca_drums.volume = 0 # Will be set when iterating notes.
			song.instruments.push_back(bosca_drums)
		else:
			var voice_data := Controller.voice_manager.get_voice_data_for_midi(midi_instrument.midi_voice)
			if not voice_data:
				# If there is no match, you can't go wrong with a piano. But there should always be a match.
				voice_data = Controller.voice_manager.get_voice_data("MIDI", "Grand Piano")
			
			var bosca_instrument := SingleVoiceInstrument.new(voice_data)
			bosca_instrument.volume = 0 # Will be set when iterating notes.
			song.instruments.push_back(bosca_instrument)
	
	
	func _extract_note(track_idx: int, midi_payload: MidiTrackEvent.MidiPayload, timestamp: int) -> void:
		var midi_volume := midi_payload.data[1]
		# When a note on event comes with zero velocity/volume, it's actually a note off event.
		if midi_volume == 0:
			_change_note_length(track_idx, midi_payload, timestamp)
			return
		
		var midi_track := _tracks[track_idx]
		
		var midi_note := MidiNote.new()
		midi_note.track_index = track_idx
		midi_note.channel_num = midi_payload.channel_num
		midi_note.timestamp = timestamp
		
		# Set pitch and volume, but keep length at -1 until we find the note off event.
		midi_note.pitch = midi_payload.data[0]
		midi_note.volume = midi_volume * 2
		@warning_ignore("integer_division")
		midi_note.position = midi_track.get_note_units_from_timestamp(timestamp)
		
		var instrument_key := midi_note.get_instrument_key()
		var instrument_notes: Array[MidiNote] = _notes_instrument_map[instrument_key]
		instrument_notes.push_back(midi_note)
	
	
	func _change_note_length(track_idx: int, midi_payload: MidiTrackEvent.MidiPayload, timestamp: int) -> void:
		var instrument_key := Vector2i(track_idx, midi_payload.channel_num)
		var instrument_notes: Array[MidiNote] = _notes_instrument_map[instrument_key]
		var midi_track := _tracks[track_idx]
		var note_pitch := midi_payload.data[0]
		
		# We first try to find a note that has been around for a bit and turn it off.
		# So we're skipping all notes which aren't valid. But in case we don't find
		# any, we should turn off the first "not-so-valid" note at least. Hence,
		# candidates.
		var candidates: Array[MidiNote] = []
		var check_candidates := true
		
		var i := instrument_notes.size() - 1
		while i >= 0:
			var midi_note := instrument_notes[i]
			if midi_note.pitch == note_pitch && midi_note.length < 0:
				candidates.push_back(midi_note)
				
				@warning_ignore("integer_division")
				var new_length := midi_track.get_note_units_from_timestamp(timestamp - midi_note.timestamp)
				if new_length > 0:
					midi_note.length = new_length
					check_candidates = false
					break
			
			i -= 1
		
		if check_candidates:
			var midi_note: MidiNote = candidates.pop_front()
			@warning_ignore("integer_division")
			midi_note.length = midi_track.get_note_units_from_timestamp(timestamp - midi_note.timestamp)
	
	
	func create_patterns(song: Song) -> void:
		for instrument_key: Vector2i in _notes_instrument_map:
			var instrument_index: int = _instruments_index_map[instrument_key]
			var instrument := song.instruments[instrument_index]
			var instrument_notes: Array[MidiNote] = _notes_instrument_map[instrument_key]
			
			var bar_idx := 0
			var current_time := 0
			var bar_end_time := song.pattern_size
			
			var pattern := Pattern.new()
			pattern.instrument_idx = _instruments_index_map[instrument_key]
			
			var note_idx := 0
			while note_idx < instrument_notes.size():
				var next_note := instrument_notes[note_idx]
				current_time = next_note.position
				
				if current_time >= bar_end_time:
					# The next note is outside of the current bar.
					# Commit the pattern, move cursors and start a new one.
					_commit_pattern_to_arrangement(pattern, song, bar_idx)
					
					@warning_ignore("integer_division")
					bar_idx = current_time / song.pattern_size
					bar_end_time = (bar_idx + 1) * song.pattern_size
					
					pattern = Pattern.new()
					pattern.instrument_idx = _instruments_index_map[instrument_key]
				
				var note_value := next_note.pitch
				if next_note.channel_num == MidiFile.DRUMKIT_CHANNEL:
					var drumkit_instrument := instrument as DrumkitInstrument
					note_value = drumkit_instrument.get_note_from_midi_note(next_note.pitch)
				
				if next_note.volume > instrument.volume:
					instrument.volume = next_note.volume
				
				pattern.add_note(note_value, next_note.position % song.pattern_size, next_note.length, false)
				note_idx += 1
			
			_commit_pattern_to_arrangement(pattern, song, bar_idx)
			song.arrangement.set_loop(0, bar_idx + 1)
	
	
	func _commit_pattern_to_arrangement(pattern: Pattern, song: Song, bar_idx: int) -> void:
		var pattern_index := song.patterns.size()
		var reusing_pattern := false
		
		# First, check if this is a duplicate of another pattern. Use the previous one if it is.
		var i := 0
		for other_pattern in song.patterns:
			if other_pattern.instrument_idx == pattern.instrument_idx && other_pattern.get_hash() == pattern.get_hash():
				pattern_index = i
				reusing_pattern = true
				break
			
			i += 1
		
		# If it's not a duplicate, finalize the pattern, and add it to the song.
		if not reusing_pattern:
			pattern.sort_notes()
			pattern.reindex_active_notes()
			
			song.patterns.push_back(pattern)
		
		# In either case, try to write the pattern to the arrangement.
		var pattern_added := false
		for j in Arrangement.CHANNEL_NUMBER:
			if song.arrangement.has_pattern(bar_idx, j):
				continue
			
			song.arrangement.set_pattern(bar_idx, j, pattern_index)
			pattern_added = true
			break
		
		if not pattern_added:
			printerr("MidiImporter: Couldn't find a free channel for pattern %d at bar %d." % [ pattern_index, bar_idx ])


class MidiInstrument:
	var track_index: int = -1
	var channel_num: int = -1
	
	var midi_voice: int = -1
	
	
	func get_index_key() -> Vector2i:
		return Vector2i(track_index, channel_num)


class MidiNote:
	var track_index: int = -1
	var channel_num: int = -1
	var timestamp: int = -1
	
	var pitch: int = -1
	var volume: int = -1
	var position: int = -1
	var length: int = -1
	
	
	func get_instrument_key() -> Vector2i:
		return Vector2i(track_index, channel_num)
