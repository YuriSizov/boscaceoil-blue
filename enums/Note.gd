###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
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

const _note_name_map := {
	NOTE_C:  "C",
	NOTE_CS: "C#",
	NOTE_D:  "D",
	NOTE_DS: "D#",
	NOTE_E:  "E",
	NOTE_F:  "F",
	NOTE_FS: "F#",
	NOTE_G:  "G",
	NOTE_GS: "G#",
	NOTE_A:  "A",
	NOTE_AS: "A#",
	NOTE_B:  "B",
}


static func get_note_name(note: int) -> String:
	return _note_name_map[note]
