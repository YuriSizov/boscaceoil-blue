###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Helper class that abstracts a common need to glue together patterns into sequences where only
## one note can play at the same time. From the topdown the approach is as follows:
##   
##   - Read Bosca patterns and encode notes. Encoded notes carry note data, as well as a note
##     mask, which defines where in the pattern it is and how much space it takes.
##   
##   - Use encoded notes to generate a collection of tracks for each pattern. The note mask is
##     used to pack the notes tightly on the tracks without overlaps. The goal is to have as
##     little tracks as possible, reusing gaps in the tracks to fit remaining notes.
##     
##     - While encoding patterns we also keep track of the instrument/drumkit item used by them,
##       unless the pattern is invalid/empty. This is needed to optimize resulting export files
##       by ignoring instruments which weren't used.
##   
##   - Encode the song arrangement using the pattern tracks from before. The arrangement is split
##     into sequences, each containing a collection of tracks. These are the tracks from patterns,
##     packed together as tightly as possible, similarly to how the notes were packed earlier. The
##     goal here is also similar: to have as little sequences as possible.
class_name SongMerger extends RefCounted


static func encode_pattern(pattern: Pattern, instrument: Instrument, pattern_size: int) -> EncodedPattern:
	var enc_pattern := EncodedPattern.new()
	
	# For drumkits we track which sub-voices was used by the pattern. This way we only need to encode
	# a few of them in the final document.
	var is_drumkit := instrument is DrumkitInstrument
	var drumkit_instrument := instrument as DrumkitInstrument
	
	# Prepare note data.
	for i in pattern.note_amount:
		var note_data := pattern.notes[i]
		if note_data.x < 0 || note_data.y < 0 || note_data.y >= pattern_size || note_data.z < 1:
			# X — note number is invalid.
			# Y — note position in the pattern is invalid.
			# Z — note length is shorter than 1 unit of length.
			continue
		
		# Encode the note itself.
		
		var enc_note := EncodedPatternNote.new()
		enc_note.raw_value = note_data.x
		if is_drumkit:
			enc_note.value = drumkit_instrument.get_note_value(note_data.x)
		else:
			enc_note.value = note_data.x
		
		enc_note.position = note_data.y
		enc_note.length = note_data.z
		enc_note.create_mask()
		
		@warning_ignore("integer_division")
		enc_note.octave = enc_note.value / Pattern.OCTAVE_SIZE # SiON octaves are 0-based.
		var note_label := Note.get_note_name(enc_note.value % Pattern.OCTAVE_SIZE)
		enc_note.label = note_label.to_lower().replace("#", "+")
		
		# Handled patterns with recorded instrument values.
		if pattern.record_instrument:
			enc_note.recorded_values = pattern.recorded_instrument_values[enc_note.position]
		
		# Group notes into tracks; the less tracks we end up with the better.
		# We iterate over notes and merge them together, if they don't overlap. Overlapping notes
		# create new tracks. Tracks are reused, as notes are tried against each of them in order,
		# until a fitting track is found (or created).
		
		var fitting_track: EncodedPatternTrack = null
		for mml_track in enc_pattern.tracks:
			if mml_track.can_add_note(enc_note):
				fitting_track = mml_track
				break
		
		if not fitting_track:
			# Use internal note value here, because it's unique. Mapped note values from a kit aren't.
			var homogeneous_note := enc_note.raw_value if is_drumkit else -1
			fitting_track = EncodedPatternTrack.new(pattern.instrument_idx, instrument.type, homogeneous_note)
			enc_pattern.tracks.push_back(fitting_track)
		
		fitting_track.add_note(enc_note)
		
		# Track used instruments and drumkits.
		
		enc_pattern.used_instrument = true
		
		if is_drumkit && not enc_pattern.used_drumkit_voices.has(enc_note.raw_value):
			enc_pattern.used_drumkit_voices.push_back(enc_note.raw_value)
	
	return enc_pattern


static func _encode_sequences(arrangement: Arrangement, encoded_patterns: Array[EncodedPattern], pattern_size: int, from_channel: int, to_channel: int) -> Array[EncodedSequence]:
	var sequences: Array[EncodedSequence] = []
	
	# Group pattern tracks into sequences. Avoid tracks which overlap.
	
	var channel_num := from_channel
	while channel_num <= to_channel:
		for bar_idx in arrangement.timeline_length:
			var pattern_index := arrangement.timeline_bars[bar_idx][channel_num]
			if pattern_index < 0:
				continue # No pattern.
			var enc_pattern := encoded_patterns[pattern_index]
			if not enc_pattern:
				continue # Pattern is somehow invalid, this shouldn't happen.
			
			for enc_track in enc_pattern.tracks:
				var fitting_sequence: EncodedSequence = null
				for sequence in sequences:
					if sequence.can_add_track(enc_track, bar_idx):
						fitting_sequence = sequence
						break
				
				if not fitting_sequence:
					fitting_sequence = EncodedSequence.new(pattern_size, bar_idx)
					sequences.push_back(fitting_sequence)
				
				fitting_sequence.add_track(enc_track, bar_idx, pattern_size)
		channel_num += 1
	
	return sequences


static func encode_arrangement_channel(arrangement: Arrangement, channel_num: int, encoded_patterns: Array[EncodedPattern], pattern_size: int) -> Array[EncodedSequence]:
	return _encode_sequences(arrangement, encoded_patterns, pattern_size, channel_num, channel_num)


static func encode_arrangement(arrangement: Arrangement, encoded_patterns: Array[EncodedPattern], pattern_size: int) -> Array[EncodedSequence]:
	return _encode_sequences(arrangement, encoded_patterns, pattern_size, 0, Arrangement.CHANNEL_NUMBER - 1)


## Encoded data of a pattern note. Notes are grouped into tracks using their masks.
class EncodedPatternNote:
	var value: int = -1
	var raw_value: int = -1
	var position: int = -1
	var length: int = 0
	
	var mask_bytes: PackedByteArray = PackedByteArray()
	
	var octave: int = 4
	var label: String = ""
	
	var recorded_values: Vector3i = Vector3i(-1, -1, -1)
	
	
	func create_mask() -> void:
		# The note can have an arbitrary length, extending far beyond the pattern size. We
		# account for that by splitting the mask into an even number of bytes, and storing
		# them as an array.
		
		mask_bytes.clear()
		
		var total_length := position + length
		var byte_length := ceili(total_length / 8.0) # Byte size
		mask_bytes.resize(byte_length)
		
		var start_offset := position
		var end_offset := position + length
		for i in byte_length:
			var start := start_offset - i * 8
			var end := end_offset - i * 8
			
			if start >= 8: # Nothing in this byte.
				continue
			if end < 0: # Already processed everything meaningful.
				break
			
			# Get local part of the mask, its position and size.
			var offset_length := mini(end - start, 8 - start)
			var offset_shift := (8 - start - offset_length)
			
			@warning_ignore("narrowing_conversion")
			var byte: int = pow(2, offset_length) - 1
			byte = byte << offset_shift
			
			# Write to the array.
			mask_bytes[i] = byte
	
	
	func get_mask_string() -> String:
		var mask_string := ""
		for byte in mask_bytes:
			mask_string += ByteArrayUtil.binary_to_string(byte, 8) + "|"
		
		mask_string = mask_string.trim_suffix("|")
		
		return mask_string


## A collection of pattern notes which do not overlap and thus can be stringed together.
## Patterns are split into these tracks with the goal to have as little tracks as
## possible. Tracks are then taken out of patterns and grouped into sequences using
## their masks.
class EncodedPatternTrack:
	var _instrument_index: int = -1
	var _instrument_type: int = -1
	var _homogeneous_note: int = -1
	
	var _notes: Array[EncodedPatternNote] = []
	var _track_mask_bytes: PackedByteArray = PackedByteArray()
	var _track_first_sound: int = -1
	var _track_last_sound: int = -1
	
	
	func _init(instrument_index: int, instrument_type: int, homogeneous_note: int) -> void:
		_instrument_index = instrument_index
		_instrument_type = instrument_type
		_homogeneous_note = homogeneous_note
	
	
	func set_minimum_notes(notes_amount: int) -> void:
		_notes.resize(notes_amount)
		
		var byte_length := ceili(notes_amount / 8.0) # Byte size
		_track_mask_bytes.resize(byte_length)
	
	
	func get_instrument_index() -> int:
		return _instrument_index
	
	
	func get_instrument_type() -> int:
		return _instrument_type
	
	
	func get_homogeneous_note() -> int:
		return _homogeneous_note
	
	
	func can_add_note(note: EncodedPatternNote) -> bool:
		if _homogeneous_note != -1 && _homogeneous_note != note.raw_value:
			return false # This track expects homogeneous notes, and this one is not.
		
		for i in note.mask_bytes.size():
			if i >= _track_mask_bytes.size():
				return true # This track has nothing past this point.
			
			var note_byte := note.mask_bytes[i]
			var track_byte := _track_mask_bytes[i]
			
			if (track_byte & note_byte) != 0:
				return false # This note overlaps with existing notes in the track.
		
		# Good to go!
		return true
	
	
	func add_note(note: EncodedPatternNote) -> void:
		# Make sure to leave blank spaces for other notes. Avoids depending on
		# the pattern size.
		if note.position >= _notes.size():
			_notes.resize(note.position + 1)
		
		_notes[note.position] = note
		
		if _track_mask_bytes.size() < note.mask_bytes.size():
			_track_mask_bytes.resize(note.mask_bytes.size())
		
		for i in note.mask_bytes.size():
			var note_byte := note.mask_bytes[i]
			var track_byte := _track_mask_bytes[i]
			
			_track_mask_bytes[i] = track_byte | note_byte

		if _track_first_sound == -1 || note.position < _track_first_sound:
			_track_first_sound = note.position
		if _track_last_sound == -1 || (note.position + note.length) > _track_last_sound:
			_track_last_sound = note.position + note.length
	
	
	func get_notes() -> Array[EncodedPatternNote]:
		return _notes
	
	
	func get_track_mask_string() -> String:
		var mask_string := ""
		for byte in _track_mask_bytes:
			mask_string += ByteArrayUtil.binary_to_string(byte, 8) + "|"
		
		mask_string = mask_string.trim_suffix("|")
		
		return mask_string
	
	
	func get_track_first_sound() -> int:
		return _track_first_sound
	
	
	func get_track_last_sound() -> int:
		return _track_last_sound


## Encoded data of a pattern. It stores a collection of note tracks and instruments used by
## this pattern. A pattern that has no (valid) notes is not considered to be using an
## instrument.
class EncodedPattern:
	var tracks: Array[EncodedPatternTrack] = []
	var used_instrument: bool = false
	var used_drumkit_voices: Array[int] = []


## A sequence of note tracks which do not overlap and thus can be stringed together. The
## goal is to have as little sequences as possible. Sequences are mapped to something in
## the external format that represents a single unit of simultaneously played sounds.
## It can be called a sequences, a channel, a track, etc.
class EncodedSequence:
	var _pattern_size: int = 0
	var _tracks: Array[EncodedPatternTrack] = []
	## Time in arrangement bars, which are in pattern size units.
	var _time: int = 0
	## Residue size of the last track that goes beyond the time value.
	var _last_residue: int = 0
	
	
	func _init(pattern_size: int, fill_tracks: int = 0) -> void:
		_pattern_size = pattern_size
		_time = fill_tracks
		_last_residue = 0
		
		for i in fill_tracks:
			_tracks.push_back(_create_empty_track())
	
	
	func _create_empty_track() -> EncodedPatternTrack:
		var empty_track := EncodedPatternTrack.new(-1, -1, -1)
		empty_track.set_minimum_notes(_pattern_size)
		return empty_track
	
	
	func can_add_track(track: EncodedPatternTrack, index: int) -> bool:
		if _time == 0:
			return true # Empty sequence accepts anything.
		if _time > index:
			return false # Sequence is already past this point in time.
		
		if _time < index:
			return true # Previous track is more than one unit of time removed from this one.
		
		# Previous track ends around this time, so check for residue.
		
		if _last_residue == 0:
			return true # Previous track has no residue, so it's safe to add more.
		if _last_residue <= track.get_track_first_sound():
			return true # Previous track fits with this one.
		
		return false
	
	
	func add_track(track: EncodedPatternTrack, index: int, pattern_size: int) -> void:
		# Compensate for the gap between the last track and the next one.
		while _time < index:
			_tracks.push_back(_create_empty_track())
			_time += 1
			_last_residue = 0 # This can be safely reset.
		
		_tracks.push_back(track)
		
		# Progress the time and the residue trackers.
		var track_total_length := track.get_track_last_sound()
		var track_time := maxi(1, floori(track_total_length / float(pattern_size)))
		var track_residue := maxi(0, track_total_length - track_time * pattern_size)
		
		_time += track_time
		_last_residue = track_residue
	
	
	func get_tracks() -> Array[EncodedPatternTrack]:
		if _tracks.size() == 0:
			return []
		
		var padded_tracks: Array[EncodedPatternTrack] = []
		padded_tracks.append_array(_tracks)
		
		# Accounts for possible final residue/slurs extending beyond the fixed pattern size.
		padded_tracks.push_back(_create_empty_track())
		
		return padded_tracks
