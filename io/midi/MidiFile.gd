###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# This class is not used at the moment and serves as a collection of shared constants.
class_name MidiFile extends RefCounted

enum FileFormat {
	SINGLE_TRACK,
	MULTI_TRACK,
	MULTI_SONG,
}

const DEFAULT_RESOLUTION := 120
const DRUMKIT_CHANNEL := 9

const FILE_HEADER_MARKER := "MThd"
const FILE_TRACK_MARKER := "MTrk"
