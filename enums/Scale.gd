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

const _scale_layout_map := {
	SCALE_NORMAL:             [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
	SCALE_MAJOR:              [ 2, 2, 1, 2, 2, 2, 1 ],
	SCALE_MINOR:              [ 2, 1, 2, 2, 2, 2, 1 ],
	SCALE_BLUES:              [ 3, 2, 1, 1, 3, 2 ],
	SCALE_HARMONIC_MINOR:     [ 2, 1, 2, 2, 1, 3, 1 ],
	SCALE_PENTATONIC_MAJOR:   [ 2, 3, 2, 2, 3 ],
	SCALE_PENTATONIC_MINOR:   [ 3, 2, 2, 3, 2 ],
	SCALE_PENTATONIC_BLUES:   [ 3, 2, 1, 1, 3, 2 ],
	SCALE_PENTATONIC_NEUTRAL: [ 2, 3, 2, 3, 2 ],
	SCALE_ROMANIAN_FOLK:      [ 2, 1, 3, 1, 2, 1, 2 ],
	SCALE_SPANISH_GYPSY:      [ 2, 1, 3, 1, 2, 1, 2 ],
	SCALE_ARABIC_MAGAM:       [ 2, 2, 1, 1, 2, 2, 2 ],
	SCALE_CHINESE:            [ 4, 2, 1, 4, 1 ],
	SCALE_HUNGARIAN:          [ 2, 1, 3, 1, 1, 3, 1 ],
	CHORD_MAJOR:              [ 4, 3, 5 ],
	CHORD_MINOR:              [ 3, 4, 5 ],
	CHORD_5TH:                [ 7, 5 ],
	CHORD_DOM_7TH:            [ 4, 3, 3, 2 ],
	CHORD_MAJOR_7TH:          [ 4, 3, 4, 1 ],
	CHORD_MINOR_7TH:          [ 3, 4, 3, 2 ],
	CHORD_MINOR_MAJOR_7TH:    [ 3, 4, 4, 1 ],
	CHORD_SUS4:               [ 5, 2, 5 ],
	CHORD_SUS2:               [ 2, 5, 5 ],
}


static func get_scale_name(scale: int) -> String:
	return _scale_name_map[scale]


static func get_scale_layout(scale: int) -> Array[int]:
	var typed: Array[int] = []
	typed.assign(_scale_layout_map[scale])
	return typed
