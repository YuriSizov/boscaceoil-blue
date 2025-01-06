###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name Effect extends Object

const EFFECT_DELAY      := 0
const EFFECT_CHORUS     := 1
const EFFECT_REVERB     := 2
const EFFECT_DISTORTION := 3
const EFFECT_LOW_BOOST  := 4
const EFFECT_COMPRESSOR := 5
const EFFECT_HIGH_PASS  := 6
const MAX               := 7

const _effect_name_map := {
	EFFECT_DELAY:      "DELAY",
	EFFECT_CHORUS:     "CHORUS",
	EFFECT_REVERB:     "REVERB",
	EFFECT_DISTORTION: "DISTORTION",
	EFFECT_LOW_BOOST:  "LOW BOOST",
	EFFECT_COMPRESSOR: "COMPRESSOR",
	EFFECT_HIGH_PASS:  "HIGH PASS",
}


static func get_effect_name(effect: int) -> String:
	return _effect_name_map[effect]
