###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Note extends Object

const NOTE_C  := 0
const NOTE_CS := 1
const NOTE_D  := 2
const NOTE_DS := 3
const NOTE_E  := 4
const NOTE_F  := 5
const NOTE_FS := 6
const NOTE_G  := 7
const NOTE_GS := 8
const NOTE_A  := 9
const NOTE_AS := 10
const NOTE_B  := 11
const MAX     := 12

# We don't expect the note enum to change, so we just assume the same order here, for compactness.
const _note_name_map_cdefgab := [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ]
const _note_name_map_doremi :=  [ "Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si" ]
const _note_name_map_mml :=     [ "c", "c+", "d", "d+", "e", "f", "f+", "g", "g+", "a", "a+", "b" ]


static func get_note_name(note: int) -> String:
	var normalized := note % MAX
	
	var note_format := -1
	if not Engine.is_editor_hint():
		note_format = Controller.settings_manager.get_note_format()
	
	match note_format:
		SettingsManager.NoteFormat.FORMAT_CDEFGAB:
			return _note_name_map_cdefgab[normalized]
		SettingsManager.NoteFormat.FORMAT_DOREMI:
			return _note_name_map_doremi[normalized]
	
	return _note_name_map_cdefgab[normalized]


static func get_note_mml(note: int) -> String:
	var normalized := note % MAX
	return _note_name_map_mml[normalized]


static func get_note_octave(note: int) -> int:
	@warning_ignore("integer_division")
	return note / MAX # SiON octave numbers are 0-based.


static func is_note_sharp(note: int) -> bool:
	var normalized := note % MAX
	return normalized in [ 1, 3, 6, 8, 10 ]
