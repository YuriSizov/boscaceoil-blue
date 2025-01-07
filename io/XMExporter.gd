###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# XM format implementation is based on Rob Hunter's XM tracker module, originally written
# for Bosca Ceoil. Additional reference material includes format specification as documented in:
# - https://en.wikipedia.org/wiki/Talk:XM_(file_format)#File_Format_information
# - https://github.com/milkytracker/MilkyTracker/blob/master/resources/reference/xm-form.txt
# - https://www.celersms.com/doc/XM_file_format.pdf

class_name XMExporter extends RefCounted

const FILE_EXTENSION := "xm"

const INT16_MAX := 32767


static func save(song: Song, path: String, export_config: ExportMasterPopup.ExportConfig) -> bool:
	if path.get_extension() != FILE_EXTENSION:
		printerr("XMExporter: The XM file must have a .%s extension." % [ FILE_EXTENSION ])
		return false
	
	var file := FileWrapper.new()
	var error := file.open(path, FileAccess.WRITE)
	if error != OK:
		printerr("XMExporter: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := XMFileWriter.new(path)
	_write(writer, song, export_config)
	
	# Try to write the file with the new contents.
	
	error = file.write_buffer_contents(writer.get_file_buffer())
	if error != OK:
		printerr("XMExporter: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	error = file.finalize_write()
	if error != OK:
		printerr("XMExporter: Failed to finalize write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	return true


static func _write(writer: XMFileWriter, song: Song, export_config: ExportMasterPopup.ExportConfig) -> void:
	writer.song_default_bpm = song.bpm
	writer.song_pattern_size = song.pattern_size
	writer.encode_song(song.arrangement, song.patterns, song.instruments, export_config.loop_start, export_config.loop_end)
	
	# Render out the samples before proceeding.
	var samples: Array[MusicPlayer.QueuedSample] = []
	for xm_instrument in writer.get_instruments():
		for xm_sample in xm_instrument.samples:
			samples.push_back(xm_sample.get_for_queue())
	Controller.music_player.render_samples(samples)
	
	# Meta information about the file format.
	writer.write_file_header()
	# Meta information about the encoded song.
	writer.write_song_header()
	# Pattern and instrument data.
	writer.write_patterns()
	writer.write_instruments()


class XMFileWriter:
	const MAX_LENGTH := 256
	const MAX_PATTERNS := 256
	const MAX_INSTRUMENTS := 128
	
	enum FrequencyTable {
		Amiga = 0x00,
		Linear = 0x01,
	}
	
	var song_name: String = ""
	var version_major: int = 1
	var version_minor: int = 4
	
	var _output: PackedByteArray = PackedByteArray()
	var _instruments: Array[XMInstrument] = []
	var _instrument_index_map: Dictionary = {}
	var _patterns: Array[XMPattern] = []
	var _pattern_unique_map: Dictionary = {}
	var _channels: Array[SongMerger.EncodedSequence] = []
	
	var _pattern_order_table: PackedByteArray = PackedByteArray()
	
	var _song_length: int = 0
	var _song_restart_index: int = 0
	
	var song_frequency_table: int = FrequencyTable.Linear
	var song_default_bpm: int = 120
	var song_pattern_size: int = 16
	
	
	func _init(path: String) -> void:
		song_name = path.get_file().get_basename().substr(0, 20)
		_pattern_order_table.resize(MAX_LENGTH) # This size is fixed, the song cannot be longer than that.
	
	
	func get_file_buffer() -> PackedByteArray:
		return _output
	
	
	# Writing helpers.
	
	func write_file_header() -> void:
		ByteArrayUtil.write_ascii_string(_output, "Extended Module:", 17)
		ByteArrayUtil.write_ascii_string(_output, song_name, 20)
		_output.append(0x1a) # Magic separator.
		ByteArrayUtil.write_ascii_string(_output, "FastTracker v2.00", 20) # Ensures maximum compatibility.
		
		_output.append(version_minor)
		_output.append(version_major)
	
	
	func write_song_header() -> void:
		# Header size (excluding the mandatory file header part). It's fixed at its minimum size,
		# although there can potentially be additional data added at the end. But we don't use that.
		ByteArrayUtil.write_int32(_output, 20 + _pattern_order_table.size())
		
		ByteArrayUtil.write_int16(_output, _song_length)
		ByteArrayUtil.write_int16(_output, _song_restart_index)
		ByteArrayUtil.write_int16(_output, _channels.size())
		ByteArrayUtil.write_int16(_output, _patterns.size())
		ByteArrayUtil.write_int16(_output, _instruments.size())
		
		ByteArrayUtil.write_int16(_output, song_frequency_table)
		@warning_ignore("integer_division")
		ByteArrayUtil.write_int16(_output, int(song_default_bpm / 20)) # This is taken from Rob Hunter's implementation.
		ByteArrayUtil.write_int16(_output, song_default_bpm)
		
		_output.append_array(_pattern_order_table)
	
	
	func write_patterns() -> void:
		for xm_pattern in _patterns:
			# Pattern section header.
			ByteArrayUtil.write_int32(_output, 9) # Fixed size, as we don't store additional data before the body.
			_output.append(0) # Packing type is always 0.
			ByteArrayUtil.write_int16(_output, xm_pattern.note_rows.size()) # Number of rows in the note matrix.
			
			var pattern_output := PackedByteArray()
			for note_line: Array[XMPatternNote] in xm_pattern.note_rows:
				for note: XMPatternNote in note_line:
					pattern_output.append_array(note.get_compressed())
			
			# Pattern data prefixed with its size (technically a part of the header).
			ByteArrayUtil.write_int16(_output, pattern_output.size())
			_output.append_array(pattern_output)
	
	
	func write_instruments() -> void:
		for xm_instrument in _instruments:
			# Instrument section header.
			
			var header_size := 29 # Fixed size for an empty instrument.
			if xm_instrument.samples.size() > 0:
				header_size = 263 # When there are any samples, the header is extended, but is still fixed.
			
			ByteArrayUtil.write_int32(_output, header_size)
			ByteArrayUtil.write_ascii_string(_output, xm_instrument.name, 22)
			_output.append(0) # Instrument type is always 0.
			ByteArrayUtil.write_int16(_output, xm_instrument.samples.size())
			
			# Extra header is only added when there are any samples.
			
			if xm_instrument.samples.size() > 0:
				ByteArrayUtil.write_int32(_output, 40) # Fixed size for a sample header.
				_output.append_array(xm_instrument.note_keymap)
				_output.append_array(xm_instrument.volume_envelope_points)
				_output.append_array(xm_instrument.panning_envelope_points)
				_output.append_array(xm_instrument.extra_header_data)
			
			# Sample headers and data (all headers, then all data).
			
			for xm_sample in xm_instrument.samples:
				xm_sample.convert_data_to_deltas()
				write_sample_header(xm_sample)
			
			for xm_sample in xm_instrument.samples:
				_output.append_array(xm_sample.get_deltas())
	
	
	func write_sample_header(xm_sample: XMInstrumentSample) -> void:
		ByteArrayUtil.write_int32(_output, xm_sample.get_deltas_size())
		ByteArrayUtil.write_int32(_output, xm_sample.loop_start)
		ByteArrayUtil.write_int32(_output, xm_sample.loop_length)
		ByteArrayUtil.write_uint8(_output, xm_sample.volume)
		_output.append(xm_sample.finetune)
		_output.append(xm_sample.type)
		_output.append(xm_sample.panning)
		_output.append(xm_sample.relative_note_number)
		_output.append(0x00) # Reserved.
		
		ByteArrayUtil.write_ascii_string(_output, xm_sample.name, 22)
	
	
	# Data management.
	
	func encode_song(arrangement: Arrangement, patterns: Array[Pattern], instruments: Array[Instrument], from_bar: int, to_bar: int) -> void:
		# Each bar is converted to an XM pattern, containing all notes by all instruments played in it.
		# One extra "bar" is added for slurs/residual sounds, but the total size is capped at MAX_LENGTH.
		var arrangement_bars: Array[PackedInt32Array] = arrangement.timeline_bars.slice(from_bar, to_bar)
		arrangement_bars.push_back(arrangement.create_empty_bar())
		_song_length = mini(MAX_LENGTH, arrangement_bars.size())
		
		var bosca_patterns: Array[SongMerger.EncodedPattern] = []
		for pattern in patterns:
			var instrument := instruments[pattern.instrument_idx]
			var enc_pattern := SongMerger.encode_pattern(pattern, instrument, song_pattern_size)
			bosca_patterns.push_back(enc_pattern)
			
			# Encode used instruments.
			if enc_pattern.used_instrument:
				if instrument is SingleVoiceInstrument:
					var single_instrument := instrument as SingleVoiceInstrument
					var unique_index := _get_unique_instrument_index(pattern.instrument_idx)
					
					if not _instrument_index_map.has(unique_index):
						var xm_instrument := _encode_xm_instrument(single_instrument.name, single_instrument.voice, single_instrument.volume)
						_instrument_index_map[unique_index] = xm_instrument.index
				
				# Drumkits are expanded into multiple voices.
				elif instrument is DrumkitInstrument:
					var drumkit_instrument := instrument as DrumkitInstrument
					for drumkit_note in enc_pattern.used_drumkit_voices:
						var unique_index := _get_unique_instrument_index(pattern.instrument_idx, drumkit_note)
						
						if not _instrument_index_map.has(unique_index):
							var instrument_name := drumkit_instrument.get_note_name(drumkit_note)
							var instrument_voice := drumkit_instrument.get_note_voice(drumkit_note)
							var instrument_note := drumkit_instrument.get_note_value(drumkit_note)
							
							var xm_instrument := _encode_xm_instrument(instrument_name, instrument_voice, drumkit_instrument.volume, instrument_note)
							_instrument_index_map[unique_index] = xm_instrument.index
		
		_channels = SongMerger.encode_arrangement(arrangement_bars, bosca_patterns, song_pattern_size)
		
		# Each XM pattern can have up to 256 rows. This means that with the pattern size of 16 we
		# can only put 16 arrangement bars into one XM pattern. There can also only be at most 256
		# unique patterns and at most 256 patterns chained together to make a song.
		# These are pretty strict limitations and it is possible to have a Bosca song that will
		# never export correctly into the XM format.
		
		# So, given that, our approach here is to be simple but effective for the cases that we
		# can support. In future it may be possible to do more effective packing and utilize
		# these limits better, but for now we go with the most straightforward approach.
		
		# We take each arrangement bar and consider it to be an XM pattern. Its composition gives
		# it a unique key, which we can use to reuse patterns. Notes which extend beyond the
		# pattern size are left to be handled automatically. As a small improvement, we also add
		# an empty pattern at the end of the song, letting residual sounds to play out.
		
		# Since encoded sequences respect residual notes, we have to get a bit creative with tracking
		# our place in them. We track the time and the set of remaining tracks for each sequence.
		var channel_times := PackedInt32Array()
		channel_times.resize(_channels.size())
		var channel_tracks: Array[Array] = []
		for sequence in _channels:
			channel_tracks.push_back(sequence.get_tracks())
		
		for current_time in _song_length:
			var bar_patterns := arrangement_bars[current_time]
			var unique_hash := 0
			for pattern_idx in bar_patterns:
				unique_hash = hash("%d" % [ unique_hash + pattern_idx ])
			
			if _pattern_unique_map.has(unique_hash):
				var known_pattern: XMPattern = _pattern_unique_map[unique_hash]
				_pattern_order_table[current_time] = known_pattern.index
				continue
			
			var xm_pattern := _encode_xm_pattern(current_time, channel_times, channel_tracks)
			_pattern_unique_map[unique_hash] = xm_pattern
			_pattern_order_table[current_time] = xm_pattern.index
	
	
	func _encode_xm_pattern(current_time: int, channel_times: PackedInt32Array, channel_tracks: Array[Array]) -> XMPattern:
		# Patterns are fixed at the Bosca pattern size for simplicity. See the explanation in encode_song().
		var xm_pattern := XMPattern.new(song_pattern_size, _channels.size())
		xm_pattern.index = _patterns.size()
		_patterns.push_back(xm_pattern)
		
		for j in _channels.size():
			var sequence_time := channel_times[j]
			if sequence_time != current_time:
				continue # This sequence is either ahead or behind the time cursor.
			
			var sequence_tracks := channel_tracks[j]
			if sequence_tracks.is_empty():
				continue # This sequence is exhausted and containes no more tracks.
			
			var active_track: SongMerger.EncodedPatternTrack = sequence_tracks.pop_front()
			var track_notes := active_track.get_notes()
			
			for i in xm_pattern.note_rows.size():
				if not track_notes[i]:
					continue
				
				var instrument_index := 0
				# Use adjusted instrument index which accounts for drumkits expanded into unique voices.
				if active_track.get_instrument_type() == Instrument.InstrumentType.INSTRUMENT_DRUMKIT:
					instrument_index = _get_xm_instrument_index(active_track.get_instrument_index(), active_track.get_homogeneous_note())
				else:
					instrument_index = _get_xm_instrument_index(active_track.get_instrument_index())
				
				xm_pattern.add_note(i, j, track_notes[i], instrument_index)
			
			# Progress the time.
			channel_times[j] += active_track.get_track_time(song_pattern_size)
			
		return xm_pattern
	
	
	func _encode_xm_instrument(name: String, voice: SiONVoice, volume: int, note: int = 60) -> XMInstrument:
		var xm_instrument := XMInstrument.new()
		xm_instrument.set_name(name)
		xm_instrument.index = _instruments.size() + 1
		_instruments.push_back(xm_instrument)
		
		# Prepare samples for recording.
		# For now we only record one sample per instrument, just like the original implementation.
		# There may be some benefit from recording multiple, but I'm not entirely sure right now.
		
		var xm_sample := XMInstrumentSample.new(voice, note)
		xm_sample.set_name(voice.name)
		xm_sample.set_type(XMInstrumentSample.Loopness.NO_LOOP, XMInstrumentSample.Bitness.BIT_16)
		
		xm_sample.volume = clamp(volume, 0, 255) # One uint byte.
		
		xm_instrument.samples.push_back(xm_sample)
		
		return xm_instrument
	
	
	func _get_unique_instrument_index(base_index: int, note_value: int = -1) -> int:
		var unique_index := base_index
		if note_value >= 0:
			unique_index = 100 * base_index + note_value
		
		return unique_index
	
	
	func _get_xm_instrument_index(base_index: int, note_value: int = -1) -> int:
		var unique_index := _get_unique_instrument_index(base_index, note_value)
		if _instrument_index_map.has(unique_index):
			return _instrument_index_map[unique_index]
		
		return -1
	
	
	func get_instruments() -> Array[XMInstrument]:
		return _instruments


class XMPattern:
	var index: int = -1
	# Matrix of XMPatternNote.
	var note_rows: Array[Array] = []
	
	
	func _init(row_amount: int, channel_amount: int) -> void:
		for i in row_amount:
			var note_row: Array[XMPatternNote] = []
			
			for j in channel_amount:
				var xm_note := XMPatternNote.new()
				note_row.push_back(xm_note)
			
			note_rows.push_back(note_row)
	
	
	func add_note(row_index: int, channel_index: int, enc_note: SongMerger.EncodedPatternNote, instrument_index: int) -> void:
		# TODO: It may be possible to support at least recorded volume values here.
		# Filter values don't seem possible though. 
		
		var xm_note: XMPatternNote = note_rows[row_index][channel_index]
		
		# Zero means no value, so add one to match the range. Some notes will be too high
		# for XM, we clamp them as a best-effort approach.
		xm_note.value = clampi(enc_note.value + 1, 0, 96)
		xm_note.instrument = instrument_index
		
		# Notes that don't have an off signal before the end of the pattern are
		# handled automatically. They are expected to play out and die off
		# naturally, unless the entire song ends at this point.
		# This is hopefully prevented by defining better patterns, such that all
		# notes are handled within them without going beyond.
		
		var note_end_row := enc_note.position + enc_note.length
		if note_end_row < note_rows.size():
			var xm_note_off: XMPatternNote = note_rows[note_end_row][channel_index]
			xm_note_off.value = 97 # Special "Key off" value.


class XMPatternNote:
	# 0 - no note, 97 - note off, 1-96 - allowed values.
	var value: int = 0
	var instrument: int = 0
	var volume: int = 0
	var effect_type: int = 0
	var effect_value: int = 0
	
	
	func get_compressed() -> PackedByteArray:
		var note_output := PackedByteArray()
		var follow_flags := 0 # Follow flags are set in the normal order from the LSB.
		
		if value > 0:
			follow_flags += 1 << 0
			note_output.append(value)
		if instrument > 0:
			follow_flags += 1 << 1
			note_output.append(instrument)
		if volume > 0:
			follow_flags += 1 << 2
			note_output.append(volume)
		if effect_type > 0:
			follow_flags += 1 << 3
			note_output.append(effect_type)
		if effect_value > 0:
			follow_flags += 1 << 4
			note_output.append(effect_value)
		
		if note_output.size() == 5:
			return note_output
		
		var compressed_output := PackedByteArray()
		compressed_output.append(follow_flags + (1 << 7)) # Set the MSB to enable compression.
		compressed_output.append_array(note_output)
		return compressed_output


class XMInstrument:
	const MAX_SAMPLES := 16
	
	var index: int = -1
	var name: String = ""
	var samples: Array[XMInstrumentSample] = []
	
	var note_keymap: PackedByteArray = PackedByteArray()
	var volume_envelope_points: PackedByteArray = PackedByteArray()
	var panning_envelope_points: PackedByteArray = PackedByteArray()
	var extra_header_data: PackedByteArray = PackedByteArray()
	
	
	func _init() -> void:
		note_keymap.resize(96)
		volume_envelope_points.resize(48)
		panning_envelope_points.resize(48)
		extra_header_data.resize(38)
	
	
	func set_name(value: String) -> void:
		name = value.substr(0, 22)


class XMInstrumentSample:
	enum Loopness {
		NO_LOOP       = 0x0000,
		FORWARD       = 0x0001,
		BIDIRECTIONAL = 0x0010,
	}
	enum Bitness {
		BIT_8  = 0x0000,
		BIT_16 = 0x0001,
	}
	
	var _voice: SiONVoice = null
	var _note_value: int = -1
	var _data: PackedInt32Array = PackedInt32Array()
	var _deltas: PackedByteArray = PackedByteArray()
	
	var name: String = ""
	var type: int = 0
	
	var loop_start: int = 0
	var loop_length: int = 0
	var volume: int = 0
	var finetune: int = 0
	var panning: int = 128
	# For unclear reasons we need to shift notes like that to make it sound close to the original.
	var relative_note_number: int = 15
	
	
	func _init(voice: SiONVoice, note_value: int) -> void:
		_voice = voice
		_note_value = note_value
	
	
	func get_for_queue() -> MusicPlayer.QueuedSample:
		var queued_sample := MusicPlayer.QueuedSample.new()
		queued_sample.voice = _voice
		queued_sample.note_value = _note_value
		
		queued_sample.callback = _append_data
		
		return queued_sample
	
	
	func set_name(value: String) -> void:
		name = value.substr(0, 22)
	
	
	func set_type(loopness: Loopness, bitness: Bitness) -> void:
		type = loopness + (bitness << 4)
	
	
	func _append_data(data: PackedFloat64Array) -> void:
		for value in data:
			_data.push_back(int(value * INT16_MAX))
	
	
	func convert_data_to_deltas() -> void:
		_deltas.clear()
		
		# Raw data must be converted to deltas.
		var last_sample := 0
		for this_sample in _data:
			var delta := this_sample - last_sample
			ByteArrayUtil.write_int16(_deltas, delta)
			
			last_sample = this_sample
	
	
	func get_deltas() -> PackedByteArray:
		return _deltas
	
	
	func get_deltas_size() -> int:
		return _deltas.size()
