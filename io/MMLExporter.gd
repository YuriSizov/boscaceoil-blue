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
	var _patterns: Array[SongMerger.EncodedPattern] = []
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
				var last_track: SongMerger.EncodedPatternTrack = null
				
				write_line("/* Sequence #%d */" % [ j + 1 ])
				write_line("")
				write_sequence_config()
				write_line("")
				
				for enc_track in tracks:
					var instrument_index := enc_track.get_instrument_index()
					if instrument_index >= 0:
						if _used_drumkit_voices.has(instrument_index):
							var sub_index := get_drumkit_sub_index(instrument_index, enc_track.get_homogeneous_note())
							write_instrument_config(instrument_index, sub_index)
						else:
							write_instrument_config(instrument_index)
					
					if last_track:
						write_track(enc_track, last_track.get_track_residue())
					else:
						write_track(enc_track)
					
					last_track = enc_track
				
				write_line(";")
				write_line("")
				j += 1
			i += 1
	
	
	func write_track(track: SongMerger.EncodedPatternTrack, skip_notes: int = 0) -> void:
		var note_string := ""
		var last_octave := -1
		
		# Skipping is useful when we want to merge this track with another track that
		# has residue. Skipping sacrifices this track's rest commands.
		var i := 0
		var notes := track.get_notes()
		while i < notes.size():
			if i < skip_notes:
				note_string += EMPTY_NOTE_COMMAND
				i += 1
				continue
			
			var note := notes[i]
			if note:
				note_string += _stringify_note(note, last_octave)
				last_octave = note.octave
				i += note.length
			else:
				note_string += REST_COMMAND
				i += 1
		
		write_line(note_string)
	
	
	func _stringify_note(note: SongMerger.EncodedPatternNote, last_octave: int) -> String:
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
	
	
	# Data management.
	
	func encode_pattern(pattern: Pattern, instrument: Instrument) -> void:
		# Note that GDSiON's MML parser doesn't support sequence macros. If support is introduced,
		# there is a possibility to simplify the resulting MML file by assigning each repeated pattern
		# to a custom macro. There can only be up to 52 macros, though, which is way below the limit
		# on the number of Bosca Ceoil patterns.
		
		var enc_pattern := SongMerger.encode_pattern(pattern, instrument, pattern_size)
		_patterns.push_back(enc_pattern)
		
		# Store used instrument data for the whole song.
		
		if enc_pattern.used_instrument && not _used_instruments.has(pattern.instrument_idx):
			_used_instruments.push_back(pattern.instrument_idx)
		
		for drumkit_voice in enc_pattern.used_drumkit_voices:
			if not _used_drumkit_voices.has(pattern.instrument_idx):
				_used_drumkit_voices[pattern.instrument_idx] = []
			if not _used_drumkit_voices[pattern.instrument_idx].has(drumkit_voice):
				_used_drumkit_voices[pattern.instrument_idx].push_back(drumkit_voice)
	
	
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
		# We want as little sequences as possible, so we merge pattern tracks in a manner similar to
		# how we merged notes within patterns. For simplicity sequences are limited to patterns
		# of the same channel. In MML terms these are not actual channels, so this is an
		# artificial limitation.
		
		for i in Arrangement.CHANNEL_NUMBER:
			var mml_channel := MMLChannel.new()
			mml_channel.sequences = SongMerger.encode_arrangement_channel(arrangement, i, _patterns, pattern_size)
			
			_channels.push_back(mml_channel)


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


class MMLChannel:
	var sequences: Array[SongMerger.EncodedSequence] = []
