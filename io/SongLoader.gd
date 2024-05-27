###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SongLoader extends RefCounted


static func load(path: String) -> Song:
	if path.get_extension() != Song.FILE_EXTENSION:
		printerr("SongLoader: The song file must have a .%s extension." % [ Song.FILE_EXTENSION ])
		return null
	
	var file := FileAccess.open(path, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("SongLoader: Failed to load and open the song file at '%s' (code %d)." % [ path, error ])
		return null
	
	var file_contents := file.get_as_text()
	var reader := SongFileReader.new(path, file_contents)
	
	# TODO: Add a validation step after loading, to update song data and remove invalid bits.
	
	if reader.get_version() == 1:
		return _load_v1(reader)
	if reader.get_version() == 2:
		return _load_v2(reader)
	if reader.get_version() == 3:
		return _load_v3(reader)
	
	printerr("SongLoader: The song file at '%s' has unsupported version %d, an empty song is created instead." % [ path, reader.get_version() ])
	return Song.create_default_song()


# Original release; due to a bug it never saved the instrument volume.
static func _load_v1(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Patterns can only go up to 16 notes in this version.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	var remainder := reader.get_read_remainder()
	if remainder > 0:
		printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	return song


# Second version; includes instrument volume, global swing.
static func _load_v2(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.swing = reader.read_int()
	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.volume = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Patterns can only go up to 16 notes in this version.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	var remainder := reader.get_read_remainder()
	if remainder > 0:
		printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	return song


# Third version; includes global effects, patterns can go up to 32 notes (but recorded filter still only has 16 notes).
static func _load_v3(reader: SongFileReader) -> Song:
	var song := Song.new()
	song.format_version = reader.get_version()
	song.filename = reader.get_path()
	
	# Basic information.

	song.swing = reader.read_int()
	song.global_effect = reader.read_int()
	song.global_effect_power = reader.read_int()

	song.bpm = reader.read_int()
	song.pattern_size = reader.read_int()
	song.bar_size = reader.read_int()
	
	# Instruments.
	
	var instrument_count := reader.read_int()
	for i in instrument_count:
		var voice_index := reader.read_int()
		var voice_data := Controller.voice_manager.get_voice_data_at(voice_index)
		var instrument := Controller.instance_instrument_by_voice(voice_data)
		
		instrument.voice_index = voice_index
		reader.read_int() # Empty read, we can determine the type by voice data.
		reader.read_int() # Empty read, we use the color palette from reference data.
		instrument.lp_cutoff = reader.read_int()
		instrument.lp_resonance = reader.read_int()
		instrument.volume = reader.read_int()
		instrument.update_filter()
		
		song.instruments.push_back(instrument)
	
	# Patterns.
	
	var pattern_count := reader.read_int()
	for i in pattern_count:
		var pattern := Pattern.new()
		
		pattern.key = reader.read_int()
		pattern.scale = reader.read_int()
		pattern.instrument_idx = reader.read_int()
		reader.read_int() # Empty read, we can determine the color palette by the instrument.
		
		var note_amount := reader.read_int()
		for j in note_amount:
			var note_value := reader.read_int()
			var note_length := reader.read_int()
			var note_position := reader.read_int()
			reader.read_int() # Empty read, this value is unused.
			pattern.add_note(note_value, note_position, note_length, false)
		
		pattern.sort_notes()
		pattern.reindex_active_notes()
		
		pattern.record_instrument = (reader.read_int() == 1)
		if pattern.record_instrument:
			for j in 16: # Due to a bug, only first 16 notes record their advanced filter values.
				pattern.recorded_instrument_values[j].x = reader.read_int() # Volume
				pattern.recorded_instrument_values[j].y = reader.read_int() # Cutoff
				pattern.recorded_instrument_values[j].z = reader.read_int() # Resonance
		
		song.patterns.push_back(pattern)
	
	# Arrangement.
	
	song.arrangement.timeline_length = reader.read_int()
	song.arrangement.loop_start = reader.read_int()
	song.arrangement.loop_end = reader.read_int()
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			channels[j] = reader.read_int()
		song.arrangement.timeline_bars[i] = channels
	
	var remainder := reader.get_read_remainder()
	if remainder > 0:
		printerr("SongLoader: Invalid song file at '%s' contains excessive data (%d)." % [ reader.get_path(), remainder ])
	
	return song


class SongFileReader extends RefCounted:
	const SEPARATOR := ","

	var _path: String = ""
	var _contents: String = ""
	var _version: int = -1

	var _offset: int = 0
	var _end_reached: bool = true
	var _next_value: String = ""
	
	
	func _init(path: String, contents: String) -> void:
		_path = path
		_contents = contents
		if _contents.length() > 0:
			_offset = 0
			_end_reached = false
		
		_version = read_int()
	
	
	func get_path() -> String:
		return _path
	
	
	func get_version() -> int:
		return _version
	
	
	func read_int() -> int:
		_next_value = ""
		
		while not _end_reached:
			var token := _contents[_offset]
			if token == SEPARATOR:
				break
			_next_value += token
			_offset += 1
			
			if _offset >= _contents.length():
				_end_reached = true
		
		if not _end_reached:
			_offset += 1 # Move past the separator.
			if _offset >= _contents.length():
				_end_reached = true
		
		return _next_value.to_int()
	
	
	func get_read_remainder() -> int:
		return _contents.length() - _offset
