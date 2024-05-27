###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# MML format implementation is based on the specificaiton description referenced from:
# - https://web.archive.org/web/20071214090601/http://www.nullsleep.com/treasure/mck_guide/
# - https://wiki.mabinogiworld.com/view/User:LexisMikaya/MML_101_Guide
# - https://mml-guide.readthedocs.io/

# MML is a flexible format and the exact syntax depends on the target driver. For convenience
# we implement this format with the feature set supported by GDSiON in mind.
#
# The target driver is also likely to have a hard limit on the number of tracks/channels used
# at the same time, but GDSiON, and Bosca Ceoil as a result, support an unlimited number of
# tracks in poliphonic playback. Each pattern can contain up to 128 notes played at the same
# time, and the song has up to 8 channels/patterns which can be played at the same time.
# We do our best to encode the song as it is, but it may be unplayable by certain drivers.

class_name MMLExporter extends RefCounted

const FILE_EXTENSION := "mml"

const EMPTY_NOTE_COMMAND := "     "
const REST_COMMAND := "  r  "


static func save(song: Song, path: String) -> bool:
	if path.get_extension() != FILE_EXTENSION:
		printerr("MMLExporter: The MML file must have a .%s extension." % [ FILE_EXTENSION ])
		return false
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("MMLExporter: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := MMLFileWriter.new()
	_write(writer, song)
	
	# Try to write the file with the new contents.
	
	file.store_string(writer.get_file_string())
	error = file.get_error()
	if error != OK:
		printerr("MMLExporter: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	return true


static func _write(writer: MMLFileWriter, song: Song) -> void:
	# Prepare data for reuse.
	
	writer.bpm = song.bpm
	writer.pattern_size = song.pattern_size
	
	for pattern in song.patterns:
		var instrument := song.instruments[pattern.instrument_idx]
		writer.encode_pattern(pattern, instrument)
	for instrument in song.instruments:
		writer.encode_instrument(instrument)
	writer.encode_channels(song.arrangement)
	
	# Header comment.
	writer.write_line("/** SiON MML flavor. Exported from Bosca Ceoil Blue */")
	writer.write_line("")
	
	# Instrument definitions.
	writer.write_line("/* BOSCA INSTRUMENTS */")
	writer.write_line("")
	writer.write_instrument_defs()
	
	# Sequences for each track of each channel.
	
	writer.write_channels()


class MMLFileWriter:
	var bpm: int = 120
	var pattern_size: int = 16
	
	var _output: String = ""
	var _patterns: Array[MMLPattern] = []
	var _instruments: Array[MMLInstrument] = []
	var _channels: Array[MMLChannel] = []
	
	var _used_instruments: Array[int] = []
	var _used_drumkit_voices: Dictionary = {}
	
	
	func get_file_string() -> String:
		return _output
	
	
	# Writing helpers.
	
	func write_line(value: String) -> void:
		_output += value + "\n"
	
	
	func write_instrument_defs() -> void:
		for instrument_index in _used_instruments:
			var mml_instrument := _instruments[instrument_index]
			for def_string in mml_instrument.definitions:
				_output += def_string + "\n"
	
	
	func write_instrument_config(instrument_index: int, sub_index: int = 0) -> void:
		var _instrument_index := ValueValidator.index(instrument_index, _instruments.size(), "MMLExporter: Invalid instrument index %d." % [ instrument_index ])
		if _instrument_index != instrument_index:
			return
		
		var _sub_index := ValueValidator.index(sub_index, _instruments[instrument_index].configs.size(), "MMLExporter: Invalid kit instrument index %d in instrument %d." % [ sub_index, instrument_index ])
		if _sub_index != sub_index:
			return
		
		_output += _instruments[instrument_index].configs[sub_index] + "\n"
	
	
	func write_sequence_config() -> void:
		# Note length is defined in n-ths of the driver's resolution. Standard note length in
		# GDSiON is 1/64th of the resolution, but Bosca Ceoil, historically, uses 4-unit-long
		# notes. This means for simplicity we define it as 1/16th in MML, and don't have to
		# change it later per note.
		_output += "t%d l%d\n" % [ bpm, 16 ]
	
	
	func write_channels() -> void:
		var i := 0
		for mml_channel in _channels:
			write_line("/* BOSCA CHANNEL #%d */" % [ i + 1 ])
			write_line("")
			
			var j := 0
			for mml_sequence in mml_channel.sequences:
				var tracks := mml_sequence.get_tracks()
				var last_track: MMLPatternTrack = null
				
				write_line("/* Sequence #%d */" % [ j + 1 ])
				write_line("")
				write_sequence_config()
				write_line("")
				
				for mml_track in tracks:
					var instrument_index := mml_track.get_instrument_index()
					if instrument_index >= 0:
						if _used_drumkit_voices.has(instrument_index):
							var sub_index := get_drumkit_sub_index(instrument_index, mml_track.get_homogeneous_note())
							write_instrument_config(instrument_index, sub_index)
						else:
							write_instrument_config(instrument_index)
					
					if last_track:
						write_line(mml_track.get_track_string(last_track.get_track_residue()))
					else:
						write_line(mml_track.get_track_string())
					
					last_track = mml_track
				
				write_line(";")
				write_line("")
				j += 1
			i += 1
	
	
	# Data management.
	
	func encode_pattern(pattern: Pattern, instrument: Instrument) -> void:
		# Note that GDSiON's MML parser doesn't support sequence macros. If support is introduced,
		# there is a possibility to simplify the resulting MML file by assigning each repeated pattern
		# to a custom macro. There can only be up to 52 macros, though, which is way below the limit
		# on the number of Bosca Ceoil patterns.
		
		var mml_pattern := MMLPattern.new()
		
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
			
			var mml_note := MMLPatternNote.new()
			mml_note.raw_value = note_data.x
			if is_drumkit:
				mml_note.value = drumkit_instrument.get_note_value(note_data.x)
			else:
				mml_note.value = note_data.x
			
			mml_note.position = note_data.y
			mml_note.length = note_data.z
			if (mml_note.position + mml_note.length) > pattern_size:
				mml_note.residue = (mml_note.position + mml_note.length) - pattern_size
			
			mml_note.set_mask(pattern_size)
			
			@warning_ignore("integer_division")
			mml_note.octave = mml_note.value / Pattern.OCTAVE_SIZE # SiON octaves are 0-based.
			var note_label := Note.get_note_name(mml_note.value % Pattern.OCTAVE_SIZE)
			mml_note.label = note_label.to_lower().replace("#", "+")
			
			# Handled patterns with recorded instrument values.
			if pattern.record_instrument:
				mml_note.recorded_values = pattern.recorded_instrument_values[mml_note.position]
			
			# Track used instruments and drumkits.
			
			if not _used_instruments.has(pattern.instrument_idx):
				_used_instruments.push_back(pattern.instrument_idx)
			
			if is_drumkit:
				if not _used_drumkit_voices.has(pattern.instrument_idx):
					_used_drumkit_voices[pattern.instrument_idx] = []
				if not _used_drumkit_voices[pattern.instrument_idx].has(note_data.x):
					_used_drumkit_voices[pattern.instrument_idx].push_back(note_data.x)
			
			# Group notes into tracks; the less tracks we end up with the better.
			# We iterate over notes and merge them together, if they don't overlap. Overlapping notes
			# create new tracks. Tracks are reused, as notes are tried against each of them in order,
			# until a fitting track is found (or created).
			
			var fitting_track: MMLPatternTrack = null
			for mml_track in mml_pattern.tracks:
				if mml_track.can_add_note(mml_note):
					fitting_track = mml_track
					break
			
			if not fitting_track:
				# Use internal note value here, because it's unique. Mapped note values from a kit aren't.
				var homogeneous_note := mml_note.raw_value if is_drumkit else -1
				fitting_track = MMLPatternTrack.new(pattern.instrument_idx, homogeneous_note, pattern_size)
				mml_pattern.tracks.push_back(fitting_track)
			
			fitting_track.add_note(mml_note)
		
		_patterns.push_back(mml_pattern)
	
	
	func get_pattern(pattern_index: int) -> MMLPattern:
		var _pattern_index := ValueValidator.index(pattern_index, _patterns.size(), "MMLExporter: Invalid pattern index %d." % [ pattern_index ])
		if _pattern_index != pattern_index:
			return null
		
		return _patterns[pattern_index]
	
	
	func encode_instrument(instrument: Instrument) -> void:
		var mml_instrument := MMLInstrument.new()
		mml_instrument.index = _instruments.size()
		
		if instrument is SingleVoiceInstrument:
			var single_instrument := instrument as SingleVoiceInstrument
			var instrument_index := mml_instrument.index
			var instrument_mml := single_instrument.voice.get_mml(instrument_index, "<autodetect>", false)
			
			mml_instrument.add_definition(mml_instrument.index, instrument.name, instrument_mml)
			mml_instrument.add_config(instrument_index, instrument.volume, instrument.lp_cutoff, instrument.lp_resonance)
		elif instrument is DrumkitInstrument:
			var drumkit_instrument := instrument as DrumkitInstrument
			
			if _used_drumkit_voices.has(mml_instrument.index) && _used_drumkit_voices[mml_instrument.index].size() > 0:
				var voice_index := 0
				for note_value: int in _used_drumkit_voices[mml_instrument.index]:
					var instrument_index := 100 * mml_instrument.index + voice_index
					var voice_mml := drumkit_instrument.get_note_voice(note_value).get_mml(instrument_index, "<autodetect>", false)
					
					mml_instrument.add_sub_definition(mml_instrument.index, voice_index, drumkit_instrument.get_note_name(note_value), voice_mml)
					mml_instrument.add_config(instrument_index, instrument.volume, instrument.lp_cutoff, instrument.lp_resonance)
					voice_index += 1
			else:
				# This drumkit is unused, but we need to encode it anyway to preserve indices.
				var instrument_index := mml_instrument.index
				
				mml_instrument.add_definition(mml_instrument.index, instrument.name, "")
				mml_instrument.add_config(instrument_index, instrument.volume, instrument.lp_cutoff, instrument.lp_resonance)
			
		
		else:
			printerr("MMLExporter: Unsupported instrument type in instrument # %d." % [ mml_instrument.index ])
			return
		
		_instruments.push_back(mml_instrument)
	
	
	func get_drumkit_sub_index(instrument_index: int, drumkit_note: int) -> int:
		var _instrument_index := ValueValidator.index(instrument_index, _instruments.size(), "MMLExporter: Invalid instrument index %d." % [ instrument_index ])
		if _instrument_index != instrument_index:
			return -1
		
		if not _used_drumkit_voices.has(instrument_index):
			return -1
		
		return _used_drumkit_voices[instrument_index].find(drumkit_note)
	
	
	func encode_channels(arrangement: Arrangement) -> void:
		# We want as little sequences as possible, so we pattern tracks in a manner similar to
		# how we merged notes within patterns. For simplicity sequences are limited to patterns
		# of the same channel. In MML terms these are not actual channels, so this is an
		# artificial limitation.
		
		for i in Arrangement.CHANNEL_NUMBER:
			var mml_channel := MMLChannel.new()
			
			# Group pattern tracks into sequences. Avoid tracks which overlap (based on residue and
			# rest points).
			
			for j in arrangement.timeline_length:
				var pattern_index := arrangement.timeline_bars[j][i]
				if pattern_index < 0:
					continue # No pattern.
				var mml_pattern := get_pattern(pattern_index)
				if not mml_pattern:
					continue # Pattern is somehow invalid, this shouldn't happen.
				
				for mml_track in mml_pattern.tracks:
					var fitting_sequence: MMLChannelSequence = null
					for sequence in mml_channel.sequences:
						if sequence.can_add_track(mml_track, j):
							fitting_sequence = sequence
							break
					
					if not fitting_sequence:
						fitting_sequence = MMLChannelSequence.new(pattern_size, j)
						mml_channel.sequences.push_back(fitting_sequence)
					
					fitting_sequence.add_track(mml_track, j)
			
			_channels.push_back(mml_channel)


class MMLPatternNote:
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


class MMLPatternTrack:
	var _instrument_index: int = -1
	var _homogeneous_note: int = -1 
	
	var _notes: Array[MMLPatternNote] = []
	var _track_mask: int = 0
	var _track_residue: int = 0
	var _track_first_note: int = -1
	
	
	func _init(instrument_index: int, homogeneous_note: int, pattern_size: int) -> void:
		_instrument_index = instrument_index
		_homogeneous_note = homogeneous_note
		_notes.resize(pattern_size)
	
	
	func get_instrument_index() -> int:
		return _instrument_index
	
	
	func get_homogeneous_note() -> int:
		return _homogeneous_note
	
	
	func can_add_note(note: MMLPatternNote) -> bool:
		return (_track_mask & note.mask) == 0 && (_homogeneous_note == -1 || _homogeneous_note == note.raw_value)
	
	
	func add_note(note: MMLPatternNote) -> void:
		_notes[note.position] = note
		_track_mask |= note.mask
		# Only the last note in the track can possibly have residue, but we don't
		# know when it's added, so we sum up all values.
		_track_residue += note.residue
		if _track_first_note == -1 || note.position < _track_first_note:
			_track_first_note = note.position
	
	
	func get_track_string(skip_notes: int = 0) -> String:
		var note_string := ""
		var last_octave := -1
		
		# Skipping is useful when we want to merge this track with another track that
		# has residue. Skipping sacrifices this track's rest commands.
		var i := 0
		while i < _notes.size():
			if i < skip_notes:
				note_string += EMPTY_NOTE_COMMAND
				i += 1
				continue
			
			var note := _notes[i]
			if note:
				note_string += _stringify_note(note, last_octave)
				last_octave = note.octave
				i += note.length
			else:
				note_string += REST_COMMAND
				i += 1
		
		return note_string
	
	
	func _stringify_note(note: MMLPatternNote, last_octave: int) -> String:
		# Extra spacing is added for formatting purposes and has no significance.
		# Do be careful, though, as it is not recommended to break up some parts
		# of the syntax, otherwise certain parsers will reject the song.
		
		# Regarding octave shift commands. I have learnt that there is no universal truth
		# whether < should mean "octave up" or "octave down". It all depends on the synth/
		# driver/platform that interprets the written MML. All that is agreed on is that
		# < and > should do opposite things.
		# Intuitively I would say < should mean "octave down", but SiON/GDSiON follow
		# the opposing convention. And thus so must we.
		
		var note_octave := "  "
		if (last_octave - 1) == note.octave: # Lowering by 1.
			note_octave = "> "
		elif (last_octave + 1) == note.octave: # Increasing by 1.
			note_octave = "< "
		elif last_octave != note.octave:
			note_octave = "o%d" % [ note.octave ]
		
		var note_label := note.label
		var note_slur := "&" if note.length > 1 else " "
		
		# Write initial note, then continue writing extensions for the remainder of the length.
		var note_string := "%s%s%s" % [ note_octave, note_label.rpad(2, " "), note_slur ]
		for i in range(1, note.length):
			note_slur = "&" if i < (note.length - 1) else " "
			note_string += "  %s%s" % [ note_label.rpad(2, " "), note_slur ]
		
		# Adjust note string with recorded instrument values if present.
		if note.recorded_values.x >= 0 && note.recorded_values.y >= 0 && note.recorded_values.z >= 0:
			@warning_ignore("integer_division")
			var normalized_volume := mini(15, note.recorded_values.x / 16)
			var volume_string := ("v%d" % [ normalized_volume ]).rpad(3, " ")
			var filter_string := ("@f%d,%d" % [ note.recorded_values.y, note.recorded_values.z ]).rpad(7, " ")
			note_string = volume_string + " " + filter_string + " " + note_string
		
		return note_string
	
	
	func get_track_mask_string(pattern_size: int) -> String:
		var mask_string := ""
		var n := _track_mask
		for i in pattern_size:
			mask_string = "%d" % [ n & 1 ] + mask_string
			n = n >> 1
		
		return "0x" + mask_string
	
	
	func get_track_first_note() -> int:
		return _track_first_note
	
	
	func get_track_residue() -> int:
		return _track_residue


class MMLPattern:
	var tracks: Array[MMLPatternTrack] = []


class MMLInstrument:
	var index: int = -1
	var definitions: Array[String] = []
	var configs: Array[String] = []
	
	
	func add_definition(instrument_index: int, name: String, mml: String) -> void:
		var def_string := "// #%d %s\n" % [ instrument_index + 1, name ]
		def_string += mml + "\n"
		
		definitions.push_back(def_string)
	
	
	func add_sub_definition(instrument_index: int, sub_index: int, name: String, mml: String) -> void:
		var def_string := "// #%d.%d %s\n" % [ instrument_index + 1, sub_index + 1, name ]
		def_string += mml + "\n"
		
		definitions.push_back(def_string)
	
	
	func add_config(instrument_index: int, volume: int, cutoff: int, resonance: int) -> void:
		@warning_ignore("integer_division")
		var normalized_volume := mini(15, volume / 16)
		var config_string := "%%6@%d v%d @f%d,%d" % [ instrument_index, normalized_volume, cutoff, resonance ]
		
		configs.push_back(config_string)


class MMLChannelSequence:
	var _pattern_size: int = -1
	var _tracks: Array[MMLPatternTrack] = []
	
	
	func _init(pattern_size: int, fill_tracks: int = 0) -> void:
		_pattern_size = pattern_size
		
		for i in fill_tracks:
			var empty_track := MMLPatternTrack.new(-1, -1, _pattern_size)
			_tracks.push_back(empty_track)
	
	
	func can_add_track(track: MMLPatternTrack, index: int) -> bool:
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
	
	
	func add_track(track: MMLPatternTrack, index: int) -> void:
		while _tracks.size() < index:
			var empty_track := MMLPatternTrack.new(-1, -1, _pattern_size)
			_tracks.push_back(empty_track)
		
		_tracks.push_back(track)
	
	
	func get_tracks() -> Array[MMLPatternTrack]:
		if _tracks.size() == 0:
			return []
		
		var padded_tracks: Array[MMLPatternTrack] = []
		padded_tracks.append_array(_tracks)
		
		# Accounts for possible final residue/slurs extending beyond the fixed pattern size.
		var empty_track := MMLPatternTrack.new(-1, -1, _pattern_size)
		padded_tracks.push_back(empty_track)
		
		return padded_tracks


class MMLChannel:
	var sequences: Array[MMLChannelSequence] = []
