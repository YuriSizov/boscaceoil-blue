###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SongSaver extends RefCounted


static func save(song: Song, path: String) -> bool:
	if path.get_extension() != Song.FILE_EXTENSION:
		printerr("SongSaver: The song file must have a .%s extension." % [ Song.FILE_EXTENSION ])
		return false
	
	var file := FileWrapper.new()
	var error := file.open(path, FileAccess.WRITE)
	if error != OK:
		printerr("SongSaver: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	var writer := SongFileWriter.new(path)
	_write(writer, song)
	
	# Try to write the file with the new contents.
	
	error = file.write_text_contents(writer.get_file_string())
	if error != OK:
		printerr("SongSaver: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	error = file.finalize_write()
	if error != OK:
		printerr("SongSaver: Failed to finalize write to the file at '%s' (code %d)." % [ path, error ])
		return false
	
	song.filename = path
	return true


static func _write(writer: SongFileWriter, song: Song) -> void:
	# Basic information.
	
	song.format_version = Song.FILE_FORMAT # Bump the version as we save the song in the modern format.
	writer.write_int(song.format_version)
	
	writer.write_int(song.swing)
	writer.write_int(song.global_effect)
	writer.write_int(song.global_effect_power)
	
	writer.write_int(song.bpm)
	writer.write_int(song.pattern_size)
	writer.write_int(song.bar_size)
	
	# Instruments.
	
	writer.write_int(song.instruments.size())
	
	for instrument in song.instruments:
		writer.write_int(instrument.voice_index)
		writer.write_int(instrument.type) # For compatibility, but not actually needed.
		writer.write_int(instrument.color_palette)
		writer.write_int(instrument.lp_cutoff)
		writer.write_int(instrument.lp_resonance)
		writer.write_int(instrument.volume)
	
	# Patterns.
	
	writer.write_int(song.patterns.size())
	
	for pattern in song.patterns:
		writer.write_int(pattern.key)
		writer.write_int(pattern.scale)
		writer.write_int(pattern.instrument_idx)
		writer.write_int(0) # Empty write, the color palette is determined by the instrument.
		
		writer.write_int(pattern.note_amount)
		for i in pattern.note_amount:
			writer.write_int(pattern.notes[i].x) # Note value
			writer.write_int(pattern.notes[i].z) # Note length
			writer.write_int(pattern.notes[i].y) # Note position
			writer.write_int(0) # Empty write, this value is not used.
		
		writer.write_int(1 if pattern.record_instrument else 0)
		if pattern.record_instrument:
			# FIXME: Format v3 only handles the first 16 notes, but patterns can contain up to 32. Requires v4.
			for i in 16:
				writer.write_int(pattern.recorded_instrument_values[i].x) # Volume
				writer.write_int(pattern.recorded_instrument_values[i].y) # Cutoff
				writer.write_int(pattern.recorded_instrument_values[i].z) # Resonance
	
	# Arrangement.
	
	writer.write_int(song.arrangement.timeline_length)
	writer.write_int(song.arrangement.loop_start)
	writer.write_int(song.arrangement.loop_end)
	
	for i in song.arrangement.timeline_length:
		var channels := song.arrangement.timeline_bars[i]
		for j in Arrangement.CHANNEL_NUMBER:
			writer.write_int(channels[j])


class SongFileWriter extends RefCounted:
	const SEPARATOR := ","
	
	var _path: String = ""
	var _contents: String = ""
	
	
	func _init(path: String) -> void:
		_path = path
	
	
	func get_path() -> String:
		return _path
	
	
	func get_file_string() -> String:
		return _contents
	
	
	func write_int(value: int) -> void:
		_contents += ("%d" % value) + SEPARATOR
