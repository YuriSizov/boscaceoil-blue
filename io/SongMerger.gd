###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Helper class that abstracts a common need to glue together patterns into sequences where only
## one note can play at the same time.
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
		if (enc_note.position + enc_note.length) > pattern_size:
			enc_note.residue = (enc_note.position + enc_note.length) - pattern_size
		
		enc_note.set_mask(pattern_size)
		
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
			fitting_track = EncodedPatternTrack.new(pattern.instrument_idx, instrument.type, homogeneous_note, pattern_size)
			enc_pattern.tracks.push_back(fitting_track)
		
		fitting_track.add_note(enc_note)
		
		# Track used instruments and drumkits.
		
		enc_pattern.used_instrument = true
		
		if is_drumkit && not enc_pattern.used_drumkit_voices.has(enc_note.raw_value):
			enc_pattern.used_drumkit_voices.push_back(enc_note.raw_value)
	
	return enc_pattern


static func encode_arrangement_channel(arrangement: Arrangement, channel_num: int, encoded_patterns: Array[EncodedPattern], pattern_size: int) -> Array[EncodedSequence]:
	var sequences: Array[EncodedSequence] = []
	
	# Group pattern tracks into sequences. Avoid tracks which overlap (based on residue and
	# rest points).
	
	for i in arrangement.timeline_length:
		var pattern_index := arrangement.timeline_bars[i][channel_num]
		if pattern_index < 0:
			continue # No pattern.
		var enc_pattern := encoded_patterns[pattern_index]
		if not enc_pattern:
			continue # Pattern is somehow invalid, this shouldn't happen.
		
		for enc_track in enc_pattern.tracks:
			var fitting_sequence: EncodedSequence = null
			for sequence in sequences:
				if sequence.can_add_track(enc_track, i):
					fitting_sequence = sequence
					break
			
			if not fitting_sequence:
				fitting_sequence = EncodedSequence.new(pattern_size, i)
				sequences.push_back(fitting_sequence)
			
			fitting_sequence.add_track(enc_track, i)
	
	return sequences


static func encode_arrangement(arrangement: Arrangement, encoded_patterns: Array[EncodedPattern], pattern_size: int) -> Array[EncodedSequence]:
	var sequences: Array[EncodedSequence] = []
	
	# Group pattern tracks into sequences. Avoid tracks which overlap (based on residue and
	# rest points).
	
	for channel_num in Arrangement.CHANNEL_NUMBER:
		for i in arrangement.timeline_length:
			var pattern_index := arrangement.timeline_bars[i][channel_num]
			if pattern_index < 0:
				continue # No pattern.
			var enc_pattern := encoded_patterns[pattern_index]
			if not enc_pattern:
				continue # Pattern is somehow invalid, this shouldn't happen.
			
			for enc_track in enc_pattern.tracks:
				var fitting_sequence: EncodedSequence = null
				for sequence in sequences:
					if sequence.can_add_track(enc_track, i):
						fitting_sequence = sequence
						break
				
				if not fitting_sequence:
					fitting_sequence = EncodedSequence.new(pattern_size, i)
					sequences.push_back(fitting_sequence)
				
				fitting_sequence.add_track(enc_track, i)
	
	return sequences


class EncodedPatternNote:
	var value: int = -1
	var raw_value: int = -1
	var position: int = -1
	var length: int = 0
	var mask: int = 0
	var residue: int = 0
	
	var octave: int = 4
	var label: String = ""
	
	var recorded_values: Vector3i = Vector3i(-1, -1, -1)
	
	
	func set_mask(pattern_size: int) -> void:
		# Mask's bit pattern matches visuals in the app, makes debugging easier.
		# Mask only contains note bits within the limits of the pattern size. Everything
		# outside of that range is residue (since notes cannot start outside of the range). 
		var mask_length := length - residue
		var mask_position := pattern_size - position - mask_length
		
		@warning_ignore("narrowing_conversion")
		mask = pow(2, mask_length) - 1
		mask = mask << mask_position
	
	
	func get_mask_string(pattern_size: int) -> String:
		var mask_string := ""
		var n := mask
		for i in pattern_size:
			mask_string = "%d" % [ n & 1 ] + mask_string
			n = n >> 1
		
		return "0x" + mask_string


class EncodedPatternTrack:
	var _instrument_index: int = -1
	var _instrument_type: int = -1
	var _homogeneous_note: int = -1 
	var _pattern_size: int = -1
	
	var _notes: Array[EncodedPatternNote] = []
	var _track_mask: int = 0
	var _track_residue: int = 0
	var _track_first_note: int = -1
	
	
	func _init(instrument_index: int, instrument_type: int, homogeneous_note: int, pattern_size: int) -> void:
		_instrument_index = instrument_index
		_instrument_type = instrument_type
		_homogeneous_note = homogeneous_note
		_pattern_size = pattern_size
		
		_notes.resize(_pattern_size)
	
	
	func get_instrument_index() -> int:
		return _instrument_index
	
	
	func get_instrument_type() -> int:
		return _instrument_type
	
	
	func get_homogeneous_note() -> int:
		return _homogeneous_note
	
	
	func can_add_note(note: EncodedPatternNote) -> bool:
		return (_track_mask & note.mask) == 0 && (_homogeneous_note == -1 || _homogeneous_note == note.raw_value)
	
	
	func add_note(note: EncodedPatternNote) -> void:
		_notes[note.position] = note
		_track_mask |= note.mask
		# Only the last note in the track can possibly have residue, but we don't
		# know when it's added, so we sum up all values.
		_track_residue += note.residue
		if _track_first_note == -1 || note.position < _track_first_note:
			_track_first_note = note.position
	
	
	func get_notes() -> Array[EncodedPatternNote]:
		return _notes
	
	
	func get_track_mask_string() -> String:
		var mask_string := ""
		var n := _track_mask
		for i in _pattern_size:
			mask_string = "%d" % [ n & 1 ] + mask_string
			n = n >> 1
		
		return "0x" + mask_string
	
	
	func get_track_first_note() -> int:
		return _track_first_note
	
	
	func get_track_residue() -> int:
		return _track_residue


class EncodedPattern:
	var tracks: Array[EncodedPatternTrack] = []
	var used_instrument: bool = false
	var used_drumkit_voices: Array[int] = []


class EncodedSequence:
	var _pattern_size: int = -1
	var _tracks: Array[EncodedPatternTrack] = []
	
	
	func _init(pattern_size: int, fill_tracks: int = 0) -> void:
		_pattern_size = pattern_size
		
		for i in fill_tracks:
			var empty_track := EncodedPatternTrack.new(-1, -1, -1, _pattern_size)
			_tracks.push_back(empty_track)
	
	
	func can_add_track(track: EncodedPatternTrack, index: int) -> bool:
		if _tracks.size() == 0:
			return true # Empty sequence accepts anything.
		if _tracks.size() > index:
			return false # Sequence is already past this point in time.
		
		var last_track := _tracks[_tracks.size() - 1]
		var last_track_residue := last_track.get_track_residue()
		if last_track_residue == 0:
			return true # Previous track has no residue, so it's safe to add more.
		
		var track_front_space := track.get_track_first_note()
		if last_track_residue < track_front_space:
			return true # Previous track fits with the next one.
		
		return false
	
	
	func add_track(track: EncodedPatternTrack, index: int) -> void:
		while _tracks.size() < index:
			var empty_track := EncodedPatternTrack.new(-1, -1, -1, _pattern_size)
			_tracks.push_back(empty_track)
		
		_tracks.push_back(track)
	
	
	func get_tracks() -> Array[EncodedPatternTrack]:
		if _tracks.size() == 0:
			return []
		
		var padded_tracks: Array[EncodedPatternTrack] = []
		padded_tracks.append_array(_tracks)
		
		# Accounts for possible final residue/slurs extending beyond the fixed pattern size.
		var empty_track := EncodedPatternTrack.new(-1, -1, -1, _pattern_size)
		padded_tracks.push_back(empty_track)
		
		return padded_tracks
