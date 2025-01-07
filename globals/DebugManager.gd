###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Component responsible for various runtime debug tools.
class_name DebugManager extends RefCounted


func activate_debug(key: int) -> void:
	match key:
		0:
			_debug_song_merger()

# Helpers.

func _debug_song_merger() -> void:
	if Engine.is_editor_hint() || not Controller.current_song:
		return
	
	print("DebugManager: SongMerger debug activated.")
	var current_song := Controller.current_song
	
	print("")
	print("DebugManager: Encoding patterns with SongMerger.")
	var encoded_patterns: Array[SongMerger.EncodedPattern] = []
	
	var p := 0
	for pattern in current_song.patterns:
		print("# PATTERN %d" % [ p ])
		var instrument := current_song.instruments[pattern.instrument_idx]
		var enc_pattern := SongMerger.encode_pattern(pattern, instrument, current_song.pattern_size)
		encoded_patterns.push_back(enc_pattern)

		var t := 0
		for track in enc_pattern.tracks:
			print("## TRACK %d" % [ t ])
			prints(track.get_track_mask_string())
			
			print("   Track notes:")
			for note in track.get_notes():
				if note:
					prints(note.get_mask_string())
			
			t += 1
		
		p += 1
	
	var bytes_per_pattern := floori(current_song.pattern_size / 8.0)
	var pattern_inset := current_song.pattern_size + bytes_per_pattern
	var arrangement_bars := current_song.arrangement.timeline_bars.slice(0, current_song.arrangement.timeline_length)
	
	print("")
	print("DebugManager: Packing song per channel with SongMerger.")
	for i in Arrangement.CHANNEL_NUMBER:
		print("# CHANNEL %d" % [ i ])
		var channel_sequences := SongMerger.encode_arrangement_channel(arrangement_bars, i, encoded_patterns, current_song.pattern_size)
		
		var cs := 0
		for sequence in channel_sequences:
			print("## SEQUENCE %d" % [ cs ])
			prints("   Sequence time:", sequence._time, "(%d residue)" % [ sequence._last_residue ])
			print("   Sequence tracks:")
			
			var t := 0
			for track in sequence.get_tracks():
				print(" ".repeat(t * pattern_inset), track.get_track_mask_string())
				t += track.get_track_time(current_song.pattern_size)
			
			cs += 1
	
	print("")
	print("DebugManager: Packing full song with SongMerger.")
	var arrangement_sequences := SongMerger.encode_arrangement(arrangement_bars, encoded_patterns, current_song.pattern_size)
	
	var ars := 0
	for sequence in arrangement_sequences:
		print("# SEQUENCE %d" % [ ars ])
		prints("  Sequence time:", sequence._time, "(%d residue)" % [ sequence._last_residue ])
		print("  Sequence tracks:")
		
		var t := 0
		for track in sequence.get_tracks():
			print(" ".repeat(t * pattern_inset), track.get_track_mask_string())
			t += track.get_track_time(current_song.pattern_size)
		
		ars += 1
