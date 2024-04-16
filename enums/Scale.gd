###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Scale extends Object

const SCALE_NORMAL             := 0
const SCALE_MAJOR              := 1
const SCALE_MINOR              := 2
const SCALE_BLUES              := 3
const SCALE_HARMONIC_MINOR     := 4
const SCALE_PENTATONIC_MAJOR   := 5
const SCALE_PENTATONIC_MINOR   := 6
const SCALE_PENTATONIC_BLUES   := 7
const SCALE_PENTATONIC_NEUTRAL := 8
const SCALE_ROMANIAN_FOLK      := 9
const SCALE_SPANISH_GYPSY      := 10
const SCALE_ARABIC_MAGAM       := 11
const SCALE_CHINESE            := 12
const SCALE_HUNGARIAN          := 13
const CHORD_MAJOR              := 14
const CHORD_MINOR              := 15
const CHORD_5TH                := 16
const CHORD_DOM_7TH            := 17
const CHORD_MAJOR_7TH          := 18
const CHORD_MINOR_7TH          := 19
const CHORD_MINOR_MAJOR_7TH    := 20
const CHORD_SUS4               := 21
const CHORD_SUS2               := 22
const MAX                      := 23

const _scale_name_map := {
	SCALE_NORMAL:             "Scale: Normal",
	SCALE_MAJOR:              "Scale: Major",
	SCALE_MINOR:              "Scale: Minor",
	SCALE_BLUES:              "Scale: Blues",
	SCALE_HARMONIC_MINOR:     "Scale: Harmonic Minor",
	SCALE_PENTATONIC_MAJOR:   "Scale: Pentatonic Major",
	SCALE_PENTATONIC_MINOR:   "Scale: Pentatonic Minor",
	SCALE_PENTATONIC_BLUES:   "Scale: Pentatonic Blues",
	SCALE_PENTATONIC_NEUTRAL: "Scale: Pentatonic Neutral",
	SCALE_ROMANIAN_FOLK:      "Scale: Romanian Folk",
	SCALE_SPANISH_GYPSY:      "Scale: Spanish Gypsy",
	SCALE_ARABIC_MAGAM:       "Scale: Arabic Magam",
	SCALE_CHINESE:            "Scale: Chinese",
	SCALE_HUNGARIAN:          "Scale: Hungarian",
	CHORD_MAJOR:              "Chord: Major",
	CHORD_MINOR:              "Chord: Minor",
	CHORD_5TH:                "Chord: 5th",
	CHORD_DOM_7TH:            "Chord: Dom 7th",
	CHORD_MAJOR_7TH:          "Chord: Major 7th",
	CHORD_MINOR_7TH:          "Chord: Minor 7th",
	CHORD_MINOR_MAJOR_7TH:    "Chord: Minor Major 7th",
	CHORD_SUS4:               "Chord: Sus4",
	CHORD_SUS2:               "Chord: sus2",
}


static func get_scale_name(scale: int) -> String:
	return _scale_name_map[scale]
