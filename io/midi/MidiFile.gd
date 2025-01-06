###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# This class is not used at the moment and serves as a collection of shared constants.
class_name MidiFile extends RefCounted

enum FileFormat {
	SINGLE_TRACK,
	MULTI_TRACK,
	MULTI_SONG,
}

const DEFAULT_RESOLUTION := 96
const DRUMKIT_CHANNEL := 9

const TEMPO_BASE := 60_000_000

const FILE_HEADER_MARKER := "MThd"
const FILE_TRACK_MARKER := "MTrk"
