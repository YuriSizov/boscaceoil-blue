###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Voice manager component responsible for providing preset voice data
## and SiONVoice instances for insturments.
class_name VoiceManager extends Object

## SiON tool with a bunch of pre-configured voices.
var _preset_util: SiONVoicePresetUtil = SiONVoicePresetUtil.new()
## Collection of registered voice data.
var _voices: Array[VoiceData] = []


func _init() -> void:
	# NOTE: Order of registration is important, as it is used for the save data format.
	# If we ever need to add more voices/instruments, this needs to be handled gracefully.

	_register_voices()
	_register_drumkits()


# Initialization.

func _register_voices() -> void:
	_register_single_voice("MIDI", "Grand Piano",       "midi.piano1",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Bright Piano",      "midi.piano2",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Electric Grand",    "midi.piano3",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Honky Tonk",        "midi.piano4",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Electric Piano 1",  "midi.piano5",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Electric Piano 2",  "midi.piano6",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Harpsichord",       "midi.piano7",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Clavi",             "midi.piano8",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Celesta",           "midi.chrom1",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Glockenspiel",      "midi.chrom2",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Music Box",         "midi.chrom3",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Vibraphone",        "midi.chrom4",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Marimba",           "midi.chrom5",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Xylophone",         "midi.chrom6",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Tubular Bells",     "midi.chrom7",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Dulcimer",          "midi.chrom8",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Drawbar Organ",     "midi.organ1",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Percussive Organ",  "midi.organ2",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Rock Organ",        "midi.organ3",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Church Organ",      "midi.organ4",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Reed Organ",        "midi.organ5",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Accordion",         "midi.organ6",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Harmonica",         "midi.organ7",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Tango Accordion",   "midi.organ8",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Nylon Guitar",      "midi.guitar1",   ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Steel Guitar",      "midi.guitar2",   ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Jazz Guitar",       "midi.guitar3",   ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Electric Guitar",   "midi.guitar4",   ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Muted Guitar",      "midi.guitar5",   ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Overdrive Guitar",  "midi.guitar6",   ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Distorted Guitar",  "midi.guitar7",   ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Guitar harmonics",  "midi.guitar8",   ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Acoustic Bass",     "midi.bass1",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Finger Bass",       "midi.bass2",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Pick Bass",         "midi.bass3",     ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Fretless Bass",     "midi.bass4",     ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Slap Bass 1",       "midi.bass5",     ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Slap Bass 2",       "midi.bass6",     ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Synth Bass 1",      "midi.bass7",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Synth Bass 2",      "midi.bass8",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Violin",            "midi.strings1",  ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Viola",             "midi.strings2",  ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Cello",             "midi.strings3",  ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Contrabass",        "midi.strings4",  ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Tremolo Strings",   "midi.strings5",  ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Pizzicato Strings", "midi.strings6",  ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Harp",              "midi.strings7",  ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Timpani",           "midi.strings8",  ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "String Ensemble 1", "midi.ensemble1", ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "String Ensemble 2", "midi.ensemble2", ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Synth Strings 1",   "midi.ensemble3", ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Synth Strings 2",   "midi.ensemble4", ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Choir Aahs",        "midi.ensemble5", ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Voice Oohs",        "midi.ensemble6", ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Synth Voice",       "midi.ensemble7", ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Orchestra Hit",     "midi.ensemble8", ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Trumpet",           "midi.brass1",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Trombone",          "midi.brass2",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Tuba",              "midi.brass3",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Muted Trumpet",     "midi.brass4",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "French Horn",       "midi.brass5",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Brass Section",     "midi.brass6",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Synth Brass 1",     "midi.brass7",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Synth Brass 2",     "midi.brass8",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Soprano Sax",       "midi.reed1",     ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Alto Sax",          "midi.reed2",     ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Tenor Sax",         "midi.reed3",     ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Baritone Sax",      "midi.reed4",     ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Oboe",              "midi.reed5",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "English Horn",      "midi.reed6",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Bassoon",           "midi.reed7",     ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Clarinet",          "midi.reed8",     ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Piccolo",           "midi.pipe1",     ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Flute",             "midi.pipe2",     ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Recorder",          "midi.pipe3",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Pan Flute",         "midi.pipe4",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Bottle",            "midi.pipe5",     ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Shakuhachi",        "midi.pipe6",     ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Whistle",           "midi.pipe7",     ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Ocarina",           "midi.pipe8",     ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Square Lead",       "midi.lead1",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Saw Lead",          "midi.lead2",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Calliope Lead",     "midi.lead3",     ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Chiff Lead",        "midi.lead4",     ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Charang Lead",      "midi.lead5",     ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Voice Lead",        "midi.lead6",     ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Fifths Lead",       "midi.lead7",     ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Bass and Lead",     "midi.lead8",     ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "New Age Pad",       "midi.pad1",      ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Warm Pad",          "midi.pad2",      ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Polysynth Pad",     "midi.pad3",      ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Choir Pad",         "midi.pad4",      ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Bowed Pad",         "midi.pad5",      ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Metallic Pad",      "midi.pad6",      ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Halo Pad",          "midi.pad7",      ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Sweep Pad",         "midi.pad8",      ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Rain",              "midi.fx1",       ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Soundtrack",        "midi.fx2",       ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Crystal",           "midi.fx3",       ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Atmosphere",        "midi.fx4",       ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Bright",            "midi.fx5",       ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Goblins",           "midi.fx6",       ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Echoes",            "midi.fx7",       ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Sci-Fi",            "midi.fx8",       ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Sitar",             "midi.world1",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Banjo",             "midi.world2",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Shamisen",          "midi.world3",    ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Koto",              "midi.world4",    ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Kalimba",           "midi.world5",    ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Bagpipe",           "midi.world6",    ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Fiddle",            "midi.world7",    ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Shanai",            "midi.world8",    ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Tinkle Bell",       "midi.percus1",   ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Agogo",             "midi.percus2",   ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Steel Drums",       "midi.percus3",   ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Wood Block",        "midi.percus4",   ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Taiko Drum",        "midi.percus5",   ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Melodic Tom",       "midi.percus6",   ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Synth Drum",        "midi.percus7",   ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Reverse Cymbal",    "midi.percus8",   ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Fret Noise",        "midi.se1",       ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Breath Noise",      "midi.se2",       ColorPalette.PALETTE_PURPLE)
	_register_single_voice("MIDI", "Seashore",          "midi.se3",       ColorPalette.PALETTE_RED)
	_register_single_voice("MIDI", "Tweet",             "midi.se4",       ColorPalette.PALETTE_ORANGE)
	_register_single_voice("MIDI", "Telephone",         "midi.se5",       ColorPalette.PALETTE_GREEN)
	_register_single_voice("MIDI", "Helicopter",        "midi.se6",       ColorPalette.PALETTE_CYAN)
	_register_single_voice("MIDI", "Applause",          "midi.se7",       ColorPalette.PALETTE_BLUE)
	_register_single_voice("MIDI", "Gunshot",           "midi.se8",       ColorPalette.PALETTE_PURPLE)

	_register_single_voice("CHIPTUNE", "Square Wave",    "square",     ColorPalette.PALETTE_BLUE,    6)
	_register_single_voice("CHIPTUNE", "Saw Wave",       "saw",        ColorPalette.PALETTE_PURPLE,  81)
	_register_single_voice("CHIPTUNE", "Triangle Wave",  "triangle",   ColorPalette.PALETTE_RED,     80)
	_register_single_voice("CHIPTUNE", "Sine Wave",      "sine",       ColorPalette.PALETTE_ORANGE,  102)
	_register_single_voice("CHIPTUNE", "Noise",          "noise",      ColorPalette.PALETTE_GRAY,    127)
	_register_single_voice("CHIPTUNE", "Dual Square",    "dualsquare", ColorPalette.PALETTE_BLUE,    4)
	_register_single_voice("CHIPTUNE", "Dual Saw",       "dualsaw",    ColorPalette.PALETTE_PURPLE,  7)
	_register_single_voice("CHIPTUNE", "Triangle LO-FI", "triangle8",  ColorPalette.PALETTE_RED,     72)
	_register_single_voice("CHIPTUNE", "Konami Wave",    "konami",     ColorPalette.PALETTE_GREEN,   3)
	_register_single_voice("CHIPTUNE", "Ramp Wave",      "ramp",       ColorPalette.PALETTE_GREEN,   18)
	_register_single_voice("CHIPTUNE", "Pulse Wave",     "beep",       ColorPalette.PALETTE_GREEN,   29)
	_register_single_voice("CHIPTUNE", "MA3 Wave",       "ma1",        ColorPalette.PALETTE_GREEN,   25)
	_register_single_voice("CHIPTUNE", "Noise (Bass)",   "bassdrumm",  ColorPalette.PALETTE_GRAY,    115)
	_register_single_voice("CHIPTUNE", "Noise (Snare)",  "snare",      ColorPalette.PALETTE_GRAY,    118)
	_register_single_voice("CHIPTUNE", "Noise (Hi-Hat)", "closedhh",   ColorPalette.PALETTE_GRAY,    126)

	_register_single_voice("BASS", "Analog Bass",          "valsound.bass1",  ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Analog Bass #2",       "valsound.bass2",  ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Analog Bass #2 (q2)",  "valsound.bass3",  ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Chopper Bass 0",       "valsound.bass4",  ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Chopper Bass 1",       "valsound.bass5",  ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Chopper Bass 2 (CUT)", "valsound.bass6",  ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Chopper Bass 3",       "valsound.bass7",  ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Elec.Chopper Bass",    "valsound.bass8",  ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Effect Bass 1",        "valsound.bass9",  ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Effect Bass 2 to UP",  "valsound.bass10", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Effect Bass 3",        "valsound.bass11", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Mohaaa",               "valsound.bass12", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Effect FB Bass #5",    "valsound.bass13", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Magical Bass",         "valsound.bass14", ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "E.Bass #6",            "valsound.bass15", ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "E.Bass #7",            "valsound.bass16", ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "E.Bass 70",            "valsound.bass17", ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "VAL006 Euro",          "valsound.bass18", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "E.Bass x2",            "valsound.bass19", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "E.Bass x4",            "valsound.bass20", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Metal pick Bass X5",   "valsound.bass21", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Groove Bass #1",       "valsound.bass22", ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Analog Groove #2",     "valsound.bass23", ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Harmonics #1",         "valsound.bass24", ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Low Bass x1",          "valsound.bass25", ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Low Bass x2",          "valsound.bass26", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Low Bass Rezzo",       "valsound.bass27", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Low Bass Picked",      "valsound.bass28", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Metal Bass",           "valsound.bass29", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "E.N.Bass 1",           "valsound.bass30", ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "PSG Bass 1",           "valsound.bass31", ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "PSG Bass 2",           "valsound.bass32", ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Rezonance Bass",       "valsound.bass33", ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Slap Bass",            "valsound.bass34", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Slap Bass 1",          "valsound.bass35", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Slap Bass 2 (1+)",     "valsound.bass36", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Slap Bass #3",         "valsound.bass37", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Slap Bass pull",       "valsound.bass38", ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Slap Bass mute",       "valsound.bass39", ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Slap Bass pick",       "valsound.bass40", ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Super Bass #2",        "valsound.bass41", ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "SP bass#3 soft",       "valsound.bass42", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "SP bass#4 soft*2",     "valsound.bass43", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "SP bass#5 attack",     "valsound.bass44", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "SP Bass#6 rezz",       "valsound.bass45", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Synth Bass 1",         "valsound.bass46", ColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Synth Bass 2 myon",    "valsound.bass47", ColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Synth Bass #3 cho!",   "valsound.bass48", ColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Synth Wind Bass #4",   "valsound.bass49", ColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Synth Bass #5 q2",     "valsound.bass50", ColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "old wood Bass",        "valsound.bass51", ColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "W.Bass bright",        "valsound.bass52", ColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "W.Bass x2 bow",        "valsound.bass53", ColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Wood Bass 3",          "valsound.bass54", ColorPalette.PALETTE_RED, 37)

	_register_single_voice("BRASS", "Brass strings",        "valsound.brass1",  ColorPalette.PALETTE_BLUE,   56)
	_register_single_voice("BRASS", "E.mute Trampet",       "valsound.brass2",  ColorPalette.PALETTE_PURPLE, 57)
	_register_single_voice("BRASS", "HORN 2",               "valsound.brass3",  ColorPalette.PALETTE_RED,    58)
	_register_single_voice("BRASS", "Alpine Horn #3",       "valsound.brass4",  ColorPalette.PALETTE_ORANGE, 59)
	_register_single_voice("BRASS", "Lead brass",           "valsound.brass5",  ColorPalette.PALETTE_GREEN,  60)
	_register_single_voice("BRASS", "Normal HORN",          "valsound.brass6",  ColorPalette.PALETTE_CYAN,   61)
	_register_single_voice("BRASS", "Synth Oboe",           "valsound.brass7",  ColorPalette.PALETTE_BLUE,   62)
	_register_single_voice("BRASS", "Oboe 2",               "valsound.brass8",  ColorPalette.PALETTE_PURPLE, 63)
	_register_single_voice("BRASS", "Attack Brass (q2)",    "valsound.brass9",  ColorPalette.PALETTE_RED,    56)
	_register_single_voice("BRASS", "SAX",                  "valsound.brass10", ColorPalette.PALETTE_ORANGE, 57)
	_register_single_voice("BRASS", "Soft brass(lead)",     "valsound.brass11", ColorPalette.PALETTE_GREEN,  58)
	_register_single_voice("BRASS", "Synth Brass 1 OLD",    "valsound.brass12", ColorPalette.PALETTE_CYAN,   59)
	_register_single_voice("BRASS", "Synth Brass 2 OLD",    "valsound.brass13", ColorPalette.PALETTE_BLUE,   60)
	_register_single_voice("BRASS", "Synth Brass 3",        "valsound.brass14", ColorPalette.PALETTE_PURPLE, 61)
	_register_single_voice("BRASS", "Synth Brass #4",       "valsound.brass15", ColorPalette.PALETTE_RED,    62)
	_register_single_voice("BRASS", "Syn.Brass 5(long)",    "valsound.brass16", ColorPalette.PALETTE_ORANGE, 63)
	_register_single_voice("BRASS", "Synth Brass 6",        "valsound.brass17", ColorPalette.PALETTE_GREEN,  56)
	_register_single_voice("BRASS", "Trumpet",              "valsound.brass18", ColorPalette.PALETTE_CYAN,   57)
	_register_single_voice("BRASS", "Trumpet 2",            "valsound.brass19", ColorPalette.PALETTE_BLUE,   58)
	_register_single_voice("BRASS", "Twin Horn (or OL=25)", "valsound.brass20", ColorPalette.PALETTE_PURPLE, 59)

	_register_single_voice("BELL", "Calm Bell",         "valsound.bell1",  ColorPalette.PALETTE_PURPLE, 8)
	_register_single_voice("BELL", "China Bell Double", "valsound.bell2",  ColorPalette.PALETTE_RED,    9)
	_register_single_voice("BELL", "Church Bell",       "valsound.bell3",  ColorPalette.PALETTE_ORANGE, 10)
	_register_single_voice("BELL", "Church Bell 2",     "valsound.bell4",  ColorPalette.PALETTE_GREEN,  11)
	_register_single_voice("BELL", "Glocken 1",         "valsound.bell5",  ColorPalette.PALETTE_CYAN,   12)
	_register_single_voice("BELL", "Harp #1",           "valsound.bell6",  ColorPalette.PALETTE_BLUE,   13)
	_register_single_voice("BELL", "Harp #2",           "valsound.bell7",  ColorPalette.PALETTE_PURPLE, 14)
	_register_single_voice("BELL", "Kirakira",          "valsound.bell8",  ColorPalette.PALETTE_RED,    15)
	_register_single_voice("BELL", "Marimba",           "valsound.bell9",  ColorPalette.PALETTE_ORANGE, 8)
	_register_single_voice("BELL", "Old Bell",          "valsound.bell10", ColorPalette.PALETTE_GREEN,  9)
	_register_single_voice("BELL", "Percus. Bell",      "valsound.bell11", ColorPalette.PALETTE_CYAN,   10)
	_register_single_voice("BELL", "Pretty Bell",       "valsound.bell12", ColorPalette.PALETTE_BLUE,   11)
	_register_single_voice("BELL", "Synth Bell #0",     "valsound.bell13", ColorPalette.PALETTE_PURPLE, 12)
	_register_single_voice("BELL", "Synth Bell #1 o5",  "valsound.bell14", ColorPalette.PALETTE_RED,    13)
	_register_single_voice("BELL", "Synth Bell 2",      "valsound.bell15", ColorPalette.PALETTE_ORANGE, 14)
	_register_single_voice("BELL", "Viberaphone",       "valsound.bell16", ColorPalette.PALETTE_GREEN,  15)
	_register_single_voice("BELL", "Twin Marinba",      "valsound.bell17", ColorPalette.PALETTE_CYAN,   8)
	_register_single_voice("BELL", "Bellend",           "valsound.bell18", ColorPalette.PALETTE_BLUE,   9)

	_register_single_voice("GUITAR", "Guitar VeloLow",        "valsound.guitar1",  ColorPalette.PALETTE_BLUE,   24)
	_register_single_voice("GUITAR", "Guitar VeloHigh",       "valsound.guitar2",  ColorPalette.PALETTE_PURPLE, 25)
	_register_single_voice("GUITAR", "A.Guitar #3",           "valsound.guitar3",  ColorPalette.PALETTE_RED,    26)
	_register_single_voice("GUITAR", "Cutting E.Guitar",      "valsound.guitar4",  ColorPalette.PALETTE_ORANGE, 27)
	_register_single_voice("GUITAR", "Dis. Synth (old)",      "valsound.guitar5",  ColorPalette.PALETTE_GREEN,  28)
	_register_single_voice("GUITAR", "Dra-spi-Dis.G.",        "valsound.guitar6",  ColorPalette.PALETTE_CYAN,   29)
	_register_single_voice("GUITAR", "Dis.Guitar 3-",         "valsound.guitar7",  ColorPalette.PALETTE_BLUE,   30)
	_register_single_voice("GUITAR", "Dis.Guitar 3+",         "valsound.guitar8",  ColorPalette.PALETTE_PURPLE, 31)
	_register_single_voice("GUITAR", "Feed-back Guitar 1",    "valsound.guitar9",  ColorPalette.PALETTE_RED,    24)
	_register_single_voice("GUITAR", "Hard Dis. Guitar 1",    "valsound.guitar10", ColorPalette.PALETTE_ORANGE, 25)
	_register_single_voice("GUITAR", "Hard Dis.Guitar 3",     "valsound.guitar11", ColorPalette.PALETTE_GREEN,  26)
	_register_single_voice("GUITAR", "Dis.Guitar '94 Hard",   "valsound.guitar12", ColorPalette.PALETTE_CYAN,   27)
	_register_single_voice("GUITAR", "New Dis.Guitar 1",      "valsound.guitar13", ColorPalette.PALETTE_BLUE,   28)
	_register_single_voice("GUITAR", "New Dis.Guitar 2",      "valsound.guitar14", ColorPalette.PALETTE_PURPLE, 29)
	_register_single_voice("GUITAR", "New Dis.Guitar 3",      "valsound.guitar15", ColorPalette.PALETTE_RED,    30)
	_register_single_voice("GUITAR", "Overdrive.G. (AL=013)", "valsound.guitar16", ColorPalette.PALETTE_ORANGE, 31)
	_register_single_voice("GUITAR", "METAL",                 "valsound.guitar17", ColorPalette.PALETTE_GREEN,  24)
	_register_single_voice("GUITAR", "Soft Dis.Guitar",       "valsound.guitar18", ColorPalette.PALETTE_CYAN,   25)

	_register_single_voice("LEAD", "Aco code",               "valsound.lead1",  ColorPalette.PALETTE_BLUE,   80)
	_register_single_voice("LEAD", "Analog synthe 1",        "valsound.lead2",  ColorPalette.PALETTE_PURPLE, 81)
	_register_single_voice("LEAD", "Bosco-lead",             "valsound.lead3",  ColorPalette.PALETTE_RED,    82)
	_register_single_voice("LEAD", "Cosmo Lead",             "valsound.lead4",  ColorPalette.PALETTE_ORANGE, 83)
	_register_single_voice("LEAD", "Cosmo Lead 2",           "valsound.lead5",  ColorPalette.PALETTE_GREEN,  84)
	_register_single_voice("LEAD", "Digital lead #1",        "valsound.lead6",  ColorPalette.PALETTE_CYAN,   85)
	_register_single_voice("LEAD", "Double sin wave",        "valsound.lead7",  ColorPalette.PALETTE_BLUE,   86)
	_register_single_voice("LEAD", "E.Organ 2 bright",       "valsound.lead8",  ColorPalette.PALETTE_PURPLE, 16)
	_register_single_voice("LEAD", "E.Organ 2 (voice)",      "valsound.lead9",  ColorPalette.PALETTE_RED,    17)
	_register_single_voice("LEAD", "E.Organ 4 Click",        "valsound.lead10", ColorPalette.PALETTE_ORANGE, 18)
	_register_single_voice("LEAD", "E.Organ 5 Click",        "valsound.lead11", ColorPalette.PALETTE_GREEN,  19)
	_register_single_voice("LEAD", "E.Organ 6",              "valsound.lead12", ColorPalette.PALETTE_CYAN,   20)
	_register_single_voice("LEAD", "E.Organ 7 Church",       "valsound.lead13", ColorPalette.PALETTE_BLUE,   21)
	_register_single_voice("LEAD", "Metal Lead",             "valsound.lead14", ColorPalette.PALETTE_PURPLE, 87)
	_register_single_voice("LEAD", "Metal Lead 3",           "valsound.lead15", ColorPalette.PALETTE_RED,    80)
	_register_single_voice("LEAD", "MONO Lead",              "valsound.lead16", ColorPalette.PALETTE_ORANGE, 81)
	_register_single_voice("LEAD", "PSG like PC88 (long)",   "valsound.lead17", ColorPalette.PALETTE_GREEN,  82)
	_register_single_voice("LEAD", "PSG Cut 1",              "valsound.lead18", ColorPalette.PALETTE_CYAN,   83)
	_register_single_voice("LEAD", "Attack Synth",           "valsound.lead19", ColorPalette.PALETTE_BLUE,   84)
	_register_single_voice("LEAD", "Sin wave",               "valsound.lead20", ColorPalette.PALETTE_PURPLE, 85)
	_register_single_voice("LEAD", "Synth, Bell 2",          "valsound.lead21", ColorPalette.PALETTE_RED,    86)
	_register_single_voice("LEAD", "Chorus #2(Voice)+bell",  "valsound.lead22", ColorPalette.PALETTE_ORANGE, 87)
	_register_single_voice("LEAD", "Synth Cut 8-4",          "valsound.lead23", ColorPalette.PALETTE_GREEN,  80)
	_register_single_voice("LEAD", "Synth long 8-4",         "valsound.lead24", ColorPalette.PALETTE_CYAN,   81)
	_register_single_voice("LEAD", "ACO_Code #2",            "valsound.lead25", ColorPalette.PALETTE_BLUE,   82)
	_register_single_voice("LEAD", "ACO_Code #3",            "valsound.lead26", ColorPalette.PALETTE_PURPLE, 83)
	_register_single_voice("LEAD", "Synth FB long 4",        "valsound.lead27", ColorPalette.PALETTE_RED,    84)
	_register_single_voice("LEAD", "Synth FB long 5",        "valsound.lead28", ColorPalette.PALETTE_ORANGE, 85)
	_register_single_voice("LEAD", "Synth Lead 0",           "valsound.lead29", ColorPalette.PALETTE_GREEN,  86)
	_register_single_voice("LEAD", "Synth Lead 1",           "valsound.lead30", ColorPalette.PALETTE_CYAN,   87)
	_register_single_voice("LEAD", "Synth Lead 2",           "valsound.lead31", ColorPalette.PALETTE_BLUE,   80)
	_register_single_voice("LEAD", "Synth Lead 3",           "valsound.lead32", ColorPalette.PALETTE_PURPLE, 81)
	_register_single_voice("LEAD", "Synth Lead 4",           "valsound.lead33", ColorPalette.PALETTE_RED,    82)
	_register_single_voice("LEAD", "Synth Lead 5",           "valsound.lead34", ColorPalette.PALETTE_ORANGE, 83)
	_register_single_voice("LEAD", "Synth Lead 6",           "valsound.lead35", ColorPalette.PALETTE_GREEN,  84)
	_register_single_voice("LEAD", "Synth Lead 7 (Soft FB)", "valsound.lead36", ColorPalette.PALETTE_CYAN,   85)
	_register_single_voice("LEAD", "Synth PSG",              "valsound.lead37", ColorPalette.PALETTE_BLUE,   86)
	_register_single_voice("LEAD", "Synth PSG 2",            "valsound.lead38", ColorPalette.PALETTE_PURPLE, 87)
	_register_single_voice("LEAD", "Synth PSG 3",            "valsound.lead39", ColorPalette.PALETTE_RED,    80)
	_register_single_voice("LEAD", "Synth PSG 4",            "valsound.lead40", ColorPalette.PALETTE_ORANGE, 81)
	_register_single_voice("LEAD", "Synth PSG 5",            "valsound.lead41", ColorPalette.PALETTE_GREEN,  82)
	_register_single_voice("LEAD", "Sin water synth",        "valsound.lead42", ColorPalette.PALETTE_CYAN,   83)

	_register_single_voice("PIANO", "Aco Piano2 (Attack)",   "valsound.piano1",  ColorPalette.PALETTE_RED,    0)
	_register_single_voice("PIANO", "Backing 1 (Clav.)",     "valsound.piano2",  ColorPalette.PALETTE_ORANGE, 1)
	_register_single_voice("PIANO", "Clav. coad",            "valsound.piano3",  ColorPalette.PALETTE_GREEN,  2)
	_register_single_voice("PIANO", "Deep Piano 1",          "valsound.piano4",  ColorPalette.PALETTE_CYAN,   3)
	_register_single_voice("PIANO", "Deep Piano 3",          "valsound.piano5",  ColorPalette.PALETTE_BLUE,   4)
	_register_single_voice("PIANO", "E.piano #2",            "valsound.piano6",  ColorPalette.PALETTE_PURPLE, 5)
	_register_single_voice("PIANO", "E.piano #3",            "valsound.piano7",  ColorPalette.PALETTE_RED,    6)
	_register_single_voice("PIANO", "E.piano #4(2+)",        "valsound.piano8",  ColorPalette.PALETTE_ORANGE, 7)
	_register_single_voice("PIANO", "E.(Bell)Piano #5",      "valsound.piano9",  ColorPalette.PALETTE_GREEN,  0)
	_register_single_voice("PIANO", "E.Piano #6",            "valsound.piano10", ColorPalette.PALETTE_CYAN,   1)
	_register_single_voice("PIANO", "E.Piano #7",            "valsound.piano11", ColorPalette.PALETTE_BLUE,   2)
	_register_single_voice("PIANO", "Harpci chord 1",        "valsound.piano12", ColorPalette.PALETTE_PURPLE, 3)
	_register_single_voice("PIANO", "Harpci 2",              "valsound.piano13", ColorPalette.PALETTE_RED,    4)
	_register_single_voice("PIANO", "Piano1 (ML1,10,05,01)", "valsound.piano14", ColorPalette.PALETTE_ORANGE, 5)
	_register_single_voice("PIANO", "Piano3",                "valsound.piano15", ColorPalette.PALETTE_GREEN,  6)
	_register_single_voice("PIANO", "Piano4",                "valsound.piano16", ColorPalette.PALETTE_CYAN,   7)
	_register_single_voice("PIANO", "Digital Piano #5",      "valsound.piano17", ColorPalette.PALETTE_BLUE,   0)
	_register_single_voice("PIANO", "Piano 6 High-tone",     "valsound.piano18", ColorPalette.PALETTE_PURPLE, 1)
	_register_single_voice("PIANO", "Panning Harpci",        "valsound.piano19", ColorPalette.PALETTE_RED,    2)
	_register_single_voice("PIANO", "Yam Harpci chord",      "valsound.piano20", ColorPalette.PALETTE_ORANGE, 3)

	_register_single_voice("SPECIAL", "S.E.(Detune is needed o2c)", "valsound.se1",      ColorPalette.PALETTE_GREEN,  120)
	_register_single_voice("SPECIAL", "S.E. 2 o0-1-2",              "valsound.se2",      ColorPalette.PALETTE_CYAN,   121)
	_register_single_voice("SPECIAL", "S.E. 3(Feedin /noise add.)", "valsound.se3",      ColorPalette.PALETTE_BLUE,   122)
	_register_single_voice("SPECIAL", "Digital 1",                  "valsound.special1", ColorPalette.PALETTE_PURPLE, 123)
	_register_single_voice("SPECIAL", "Digital 2",                  "valsound.special2", ColorPalette.PALETTE_RED,    124)
	_register_single_voice("SPECIAL", "Digital[BAS] 3 o2-o3",       "valsound.special3", ColorPalette.PALETTE_ORANGE, 125)
	_register_single_voice("SPECIAL", "Digital[GTR] 3 o2-o3",       "valsound.special4", ColorPalette.PALETTE_GREEN,  126)
	_register_single_voice("SPECIAL", "Digital 4 o4a",              "valsound.special5", ColorPalette.PALETTE_CYAN,   127)

	_register_single_voice("STRINGS", "Accordion1",          "valsound.strpad1",  ColorPalette.PALETTE_BLUE,   21)
	_register_single_voice("STRINGS", "Accordion2",          "valsound.strpad2",  ColorPalette.PALETTE_PURPLE, 22)
	_register_single_voice("STRINGS", "Accordion3",          "valsound.strpad3",  ColorPalette.PALETTE_RED,    23)
	_register_single_voice("STRINGS", "Chorus #2(Voice)",    "valsound.strpad4",  ColorPalette.PALETTE_ORANGE, 40)
	_register_single_voice("STRINGS", "Chorus #3",           "valsound.strpad5",  ColorPalette.PALETTE_GREEN,  41)
	_register_single_voice("STRINGS", "Chorus #4",           "valsound.strpad6",  ColorPalette.PALETTE_CYAN,   42)
	_register_single_voice("STRINGS", "F.Strings 1",         "valsound.strpad7",  ColorPalette.PALETTE_BLUE,   43)
	_register_single_voice("STRINGS", "F.Strings 2",         "valsound.strpad8",  ColorPalette.PALETTE_PURPLE, 44)
	_register_single_voice("STRINGS", "F.Strings 3",         "valsound.strpad9",  ColorPalette.PALETTE_RED,    45)
	_register_single_voice("STRINGS", "F.Strings 4 (low)",   "valsound.strpad10", ColorPalette.PALETTE_ORANGE, 46)
	_register_single_voice("STRINGS", "Pizzicate#1(KOTO2)",  "valsound.strpad11", ColorPalette.PALETTE_GREEN,  47)
	_register_single_voice("STRINGS", "sound truck modoki",  "valsound.strpad12", ColorPalette.PALETTE_CYAN,   40)
	_register_single_voice("STRINGS", "Strings",             "valsound.strpad13", ColorPalette.PALETTE_BLUE,   41)
	_register_single_voice("STRINGS", "Synth Accordion",     "valsound.strpad14", ColorPalette.PALETTE_PURPLE, 42)
	_register_single_voice("STRINGS", "Phaser synthe.",      "valsound.strpad15", ColorPalette.PALETTE_RED,    43)
	_register_single_voice("STRINGS", "FB Synth.",           "valsound.strpad16", ColorPalette.PALETTE_ORANGE, 44)
	_register_single_voice("STRINGS", "Synth Strings MB",    "valsound.strpad17", ColorPalette.PALETTE_GREEN,  45)
	_register_single_voice("STRINGS", "Synth Strings #2",    "valsound.strpad18", ColorPalette.PALETTE_CYAN,   46)
	_register_single_voice("STRINGS", "Synth.Sweep Pad #1",  "valsound.strpad19", ColorPalette.PALETTE_BLUE,   47)
	_register_single_voice("STRINGS", "Twin synth. #1 Calm", "valsound.strpad20", ColorPalette.PALETTE_PURPLE, 40)
	_register_single_voice("STRINGS", "Twin synth. #2 FB",   "valsound.strpad21", ColorPalette.PALETTE_RED,    41)
	_register_single_voice("STRINGS", "Twin synth. #3 FB",   "valsound.strpad22", ColorPalette.PALETTE_ORANGE, 42)
	_register_single_voice("STRINGS", "Vocoder voice1",      "valsound.strpad23", ColorPalette.PALETTE_GREEN,  43)
	_register_single_voice("STRINGS", "Voice o3-o5",         "valsound.strpad24", ColorPalette.PALETTE_CYAN,   44)
	_register_single_voice("STRINGS", "Voice' o3-o5",        "valsound.strpad25", ColorPalette.PALETTE_BLUE,   45)

	_register_single_voice("WIND", "Clarinet #1",          "valsound.wind1", ColorPalette.PALETTE_PURPLE, 72)
	_register_single_voice("WIND", "Clarinet #2 Brighter", "valsound.wind2", ColorPalette.PALETTE_RED,    73)
	_register_single_voice("WIND", "E.Flute",              "valsound.wind3", ColorPalette.PALETTE_ORANGE, 74)
	_register_single_voice("WIND", "E.Flute 2",            "valsound.wind4", ColorPalette.PALETTE_GREEN,  75)
	_register_single_voice("WIND", "Flute + Bell",         "valsound.wind5", ColorPalette.PALETTE_CYAN,   76)
	_register_single_voice("WIND", "Old flute",            "valsound.wind6", ColorPalette.PALETTE_BLUE,   77)
	_register_single_voice("WIND", "Whistle 1",            "valsound.wind7", ColorPalette.PALETTE_PURPLE, 78)
	_register_single_voice("WIND", "Whistle 2",            "valsound.wind8", ColorPalette.PALETTE_RED,    79)

	_register_single_voice("WORLD", "Banjo (Harpci)", "valsound.world1", ColorPalette.PALETTE_ORANGE, 105)
	_register_single_voice("WORLD", "KOTO",           "valsound.world2", ColorPalette.PALETTE_GREEN,  107)
	_register_single_voice("WORLD", "Koto 2",         "valsound.world3", ColorPalette.PALETTE_CYAN,   108)
	_register_single_voice("WORLD", "Sitar 1",        "valsound.world4", ColorPalette.PALETTE_BLUE,   104)
	_register_single_voice("WORLD", "Shamisen 2",     "valsound.world5", ColorPalette.PALETTE_PURPLE, 111)
	_register_single_voice("WORLD", "Shamisen 1",     "valsound.world6", ColorPalette.PALETTE_RED,    112)
	_register_single_voice("WORLD", "Synth Shamisen", "valsound.world7", ColorPalette.PALETTE_ORANGE, 113)


func _register_drumkits() -> void:
	var drumkit_data: DrumkitData = null

	# Simple kit.

	drumkit_data = _register_drumkit_voice("DRUMKIT", "Simple Drumkit", "drumkit.1", ColorPalette.PALETTE_GRAY)

	_register_drumkit_item(drumkit_data, "Bass Drum 1",   "valsound.percus1",  30)
	_register_drumkit_item(drumkit_data, "Bass Drum 2",   "valsound.percus13", 32)
	_register_drumkit_item(drumkit_data, "Bass Drum 3",   "valsound.percus3",  30)
	_register_drumkit_item(drumkit_data, "Snare Drum",    "valsound.percus30", 20)
	_register_drumkit_item(drumkit_data, "Snare Drum 2",  "valsound.percus29", 48)
	_register_drumkit_item(drumkit_data, "Open Hi-Hat",   "valsound.percus17", 60)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat", "valsound.percus23", 72)
	_register_drumkit_item(drumkit_data, "Crash Cymbal",  "valsound.percus8",  48)

	# SiON kit.

	drumkit_data = _register_drumkit_voice("DRUMKIT", "SiON Drumkit", "drumkit.2", ColorPalette.PALETTE_GRAY)

	_register_drumkit_item(drumkit_data, "Bass Drum 2",           "valsound.percus1",  30)
	_register_drumkit_item(drumkit_data, "Bass Drum 3 o1f",       "valsound.percus2")
	_register_drumkit_item(drumkit_data, "RUFINA BD o2c",         "valsound.percus3",  30)
	_register_drumkit_item(drumkit_data, "B.D.(-vBend)",          "valsound.percus4")
	_register_drumkit_item(drumkit_data, "BD808_2(-vBend)",       "valsound.percus5")
	_register_drumkit_item(drumkit_data, "Cho cho 3 (o2e)",       "valsound.percus6")
	_register_drumkit_item(drumkit_data, "Cow-Bell 1",            "valsound.percus7")
	_register_drumkit_item(drumkit_data, "Crash Cymbal (noise)",  "valsound.percus8",  48)
	_register_drumkit_item(drumkit_data, "Crash Noise",           "valsound.percus9")
	_register_drumkit_item(drumkit_data, "Crash Noise Short",     "valsound.percus10")
	_register_drumkit_item(drumkit_data, "ETHNIC Percus.0",       "valsound.percus11")
	_register_drumkit_item(drumkit_data, "ETHNIC Percus.1",       "valsound.percus12")
	_register_drumkit_item(drumkit_data, "Heavy BD.",             "valsound.percus13", 32)
	_register_drumkit_item(drumkit_data, "Heavy BD2",             "valsound.percus14")
	_register_drumkit_item(drumkit_data, "Heavy SD1",             "valsound.percus15")
	_register_drumkit_item(drumkit_data, "Hi-Hat close 5_",       "valsound.percus16")
	_register_drumkit_item(drumkit_data, "Hi-Hat close 4",        "valsound.percus17")
	_register_drumkit_item(drumkit_data, "Hi-Hat close 5",        "valsound.percus18")
	_register_drumkit_item(drumkit_data, "Hi-Hat Close 6 -808-",  "valsound.percus19")
	_register_drumkit_item(drumkit_data, "Hi-hat #7 Metal o3-6",  "valsound.percus20")
	_register_drumkit_item(drumkit_data, "Hi-Hat Close #8 o4",    "valsound.percus21")
	_register_drumkit_item(drumkit_data, "Hi-hat Open o4e-g+",    "valsound.percus22")
	_register_drumkit_item(drumkit_data, "Open-hat2 Metal o4c-",  "valsound.percus23")
	_register_drumkit_item(drumkit_data, "Open-hat3 Metal",       "valsound.percus24")
	_register_drumkit_item(drumkit_data, "Hi-Hat Open #4 o4f",    "valsound.percus25")
	_register_drumkit_item(drumkit_data, "Metal ride o4c or o5c", "valsound.percus26")
	_register_drumkit_item(drumkit_data, "Rim Shot #1 o3c",       "valsound.percus27")
	_register_drumkit_item(drumkit_data, "Snare Drum Light",      "valsound.percus28")
	_register_drumkit_item(drumkit_data, "Snare Drum Lighter",    "valsound.percus29")
	_register_drumkit_item(drumkit_data, "Snare Drum 808 o2-o3",  "valsound.percus30", 20)
	_register_drumkit_item(drumkit_data, "Snare4 -808type- o2",   "valsound.percus31")
	_register_drumkit_item(drumkit_data, "Snare5 o1-2(Franger)",  "valsound.percus32")
	_register_drumkit_item(drumkit_data, "Tom (old)",             "valsound.percus33")
	_register_drumkit_item(drumkit_data, "Synth tom 2 algo 3",    "valsound.percus34")
	_register_drumkit_item(drumkit_data, "Synth (Noisy) Tom #3",  "valsound.percus35")
	_register_drumkit_item(drumkit_data, "Synth Tom #3",          "valsound.percus36")
	_register_drumkit_item(drumkit_data, "Synth -DX7- Tom #4",    "valsound.percus37")
	_register_drumkit_item(drumkit_data, "Triangle 1 o5c",        "valsound.percus38")

	# MIDI drums.

	drumkit_data = _register_drumkit_voice("DRUMKIT", "MIDI Drumkit", "drumkit.3", ColorPalette.PALETTE_GRAY)

	_register_drumkit_item(drumkit_data, "Seq Click H",     "midi.drum24", 24, 24)
	_register_drumkit_item(drumkit_data, "Brush Tap",       "midi.drum25", 25, 25)
	_register_drumkit_item(drumkit_data, "Brush Swirl",     "midi.drum26", 26, 26)
	_register_drumkit_item(drumkit_data, "Brush Slap",      "midi.drum27", 27, 27)
	_register_drumkit_item(drumkit_data, "Brush Tap Swirl", "midi.drum28", 28, 28)
	_register_drumkit_item(drumkit_data, "Snare Roll",      "midi.drum29", 16, 29)
	_register_drumkit_item(drumkit_data, "Castanet",        "midi.drum32", 16, 32)
	_register_drumkit_item(drumkit_data, "Snare L",         "midi.drum31", 16, 31)
	_register_drumkit_item(drumkit_data, "Sticks",          "midi.drum32", 16, 32)
	_register_drumkit_item(drumkit_data, "Bass Drum L",     "midi.drum33", 16, 33)
	_register_drumkit_item(drumkit_data, "Open Rim Shot",   "midi.drum34", 16, 34)
	_register_drumkit_item(drumkit_data, "Bass Drum M",     "midi.drum35", 16, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum H",     "midi.drum36", 16, 36)
	_register_drumkit_item(drumkit_data, "Closed Rim Shot", "midi.drum37", 16, 37)
	_register_drumkit_item(drumkit_data, "Snare M",         "midi.drum38", 16, 38)
	_register_drumkit_item(drumkit_data, "Hand Clap",       "midi.drum39", 16, 39)
	_register_drumkit_item(drumkit_data, "Snare H",         "midi.drum42", 16, 42)
	_register_drumkit_item(drumkit_data, "Floor Tom L",     "midi.drum41", 16, 41)
	_register_drumkit_item(drumkit_data, "Hi-Hat Closed",   "midi.drum42", 16, 42)
	_register_drumkit_item(drumkit_data, "Floor Tom H",     "midi.drum43", 16, 43)
	_register_drumkit_item(drumkit_data, "Hi-Hat Pedal",    "midi.drum44", 16, 44)
	_register_drumkit_item(drumkit_data, "Low Tom",         "midi.drum45", 16, 45)
	_register_drumkit_item(drumkit_data, "Hi-Hat Open",     "midi.drum46", 16, 46)
	_register_drumkit_item(drumkit_data, "Mid Tom L",       "midi.drum47", 16, 47)
	_register_drumkit_item(drumkit_data, "Mid Tom H",       "midi.drum48", 16, 48)
	_register_drumkit_item(drumkit_data, "Crash Cymbal 1",  "midi.drum49", 16, 49)
	_register_drumkit_item(drumkit_data, "High Tom",        "midi.drum52", 16, 52)
	_register_drumkit_item(drumkit_data, "Ride Cymbal 1",   "midi.drum51", 16, 51)
	_register_drumkit_item(drumkit_data, "Chinese Cymbal",  "midi.drum52", 16, 52)
	_register_drumkit_item(drumkit_data, "Ride Cymbal Cup", "midi.drum53", 16, 53)
	_register_drumkit_item(drumkit_data, "Tambourine",      "midi.drum54", 16, 54)
	_register_drumkit_item(drumkit_data, "Splash Cymbal",   "midi.drum55", 16, 55)
	_register_drumkit_item(drumkit_data, "Cowbell",         "midi.drum56", 16, 56)
	_register_drumkit_item(drumkit_data, "Crash Cymbal 2",  "midi.drum57", 16, 57)
	_register_drumkit_item(drumkit_data, "Vibraslap",       "midi.drum58", 16, 58)
	_register_drumkit_item(drumkit_data, "Ride Cymbal 2",   "midi.drum59", 16, 59)
	_register_drumkit_item(drumkit_data, "Bongo H",         "midi.drum62", 16, 62)
	_register_drumkit_item(drumkit_data, "Bongo L",         "midi.drum61", 16, 61)
	_register_drumkit_item(drumkit_data, "Conga H Mute",    "midi.drum62", 16, 62)
	_register_drumkit_item(drumkit_data, "Conga H Open",    "midi.drum63", 16, 63)
	_register_drumkit_item(drumkit_data, "Conga L",         "midi.drum64", 16, 64)
	_register_drumkit_item(drumkit_data, "Timbale H",       "midi.drum65", 16, 65)
	_register_drumkit_item(drumkit_data, "Timbale L",       "midi.drum66", 16, 66)
	_register_drumkit_item(drumkit_data, "Agogo H",         "midi.drum67", 16, 67)
	_register_drumkit_item(drumkit_data, "Agogo L",         "midi.drum68", 16, 68)
	_register_drumkit_item(drumkit_data, "Cabasa",          "midi.drum69", 16, 69)
	_register_drumkit_item(drumkit_data, "Maracas",         "midi.drum72", 16, 72)
	_register_drumkit_item(drumkit_data, "Samba Whistle H", "midi.drum71", 16, 71)
	_register_drumkit_item(drumkit_data, "Samba Whistle L", "midi.drum72", 16, 72)
	_register_drumkit_item(drumkit_data, "Guiro Short",     "midi.drum73", 16, 73)
	_register_drumkit_item(drumkit_data, "Guiro Long",      "midi.drum74", 16, 74)
	_register_drumkit_item(drumkit_data, "Claves",          "midi.drum75", 16, 75)
	_register_drumkit_item(drumkit_data, "Wood Block H",    "midi.drum76", 16, 76)
	_register_drumkit_item(drumkit_data, "Wood Block L",    "midi.drum77", 16, 77)
	_register_drumkit_item(drumkit_data, "Cuica Mute",      "midi.drum78", 16, 78)
	_register_drumkit_item(drumkit_data, "Cuica Open",      "midi.drum79", 16, 79)
	_register_drumkit_item(drumkit_data, "Triangle Mute",   "midi.drum80", 16, 80)
	_register_drumkit_item(drumkit_data, "Triangle Open",   "midi.drum81", 16, 81)
	_register_drumkit_item(drumkit_data, "Shaker",          "midi.drum82", 16, 82)
	_register_drumkit_item(drumkit_data, "Jingle Bells",    "midi.drum83", 16, 83)
	_register_drumkit_item(drumkit_data, "Bell Tree",       "midi.drum84", 16, 84)


func _register_single_voice(category: String, name: String, voice_preset: String, color_palette: int, midi_instrument: int = -1) -> VoiceData:
	var voice_data := VoiceData.new()
	voice_data.category = category
	voice_data.name = name
	voice_data.voice_preset = voice_preset
	voice_data.color_palette = color_palette

	if midi_instrument == -1:
		voice_data.midi_instrument = _voices.size() % 128
	else:
		voice_data.midi_instrument = midi_instrument

	voice_data.index = _voices.size()
	_voices.push_back(voice_data)
	return voice_data


func _register_drumkit_voice(category: String, name: String, voice_preset: String, color_palette: int) -> DrumkitData:
	var voice_data := DrumkitData.new()
	voice_data.category = category
	voice_data.name = name
	voice_data.voice_preset = voice_preset
	voice_data.color_palette = color_palette
	voice_data.midi_instrument = _voices.size() % 128

	voice_data.index = _voices.size()
	_voices.push_back(voice_data)
	return voice_data


func _register_drumkit_item(drumkit_data: DrumkitData, name: String, voice_preset: String, note: int = 60, midi_note: int = -1) -> void:
	var item := DrumkitDataItem.new()
	item.name = name
	item.voice_preset = voice_preset
	item.note = note

	if midi_note != -1:
		item.midi_note = midi_note

	drumkit_data.items.push_back(item)


# Public methods.

func get_voice_data(category: String, name: String) -> VoiceData:
	for i in _voices.size():
		var voice := _voices[i]
		if voice.category == category && voice.name == name:
			return voice

	printerr("VoiceManager: Invalid voice category or name (%s, %s)." % [ category, name ])
	return null


func get_voice_data_at(index: int) -> VoiceData:
	var index_ := ValueValidator.index(index, _voices.size(), "VoiceManager: Invalid voice index (%d)." % [ index ])
	if index_ != index:
		return null

	return _voices[index]


func get_voice_preset(name: String) -> SiONVoice:
	return _preset_util.get_voice_preset(name)


class VoiceData:
	## Sequential index used for serialization.
	var index: int = -1

	## General category of the voice.
	var category: String = ""
	## Display name of the voice.
	var name: String = ""
	## Name of the voice preset, used to uniquely identify voice data and
	## to fetch configuration from the SiON util.
	var voice_preset: String = ""
	## Color palette used for color coding the voice.
	var color_palette: int = ColorPalette.PALETTE_GRAY:
		set(value): color_palette = ColorPalette.validate(value)
	## Mapping to the closest MIDI instrument.
	var midi_instrument: int = -1


class DrumkitDataItem:
	## Display name of the drumkit's item.
	var name: String = ""
	## Name of the voice preset, used to uniquely identify item and
	## to fetch configuration from the SiON util.
	var voice_preset: String = ""
	## Fixed note for the drumkit's item.
	var note: int = 0
	## Mapping to the closest MIDI note.
	var midi_note: int = -1


class DrumkitData extends VoiceData:
	## Drumkit comprising voice items.
	var items: Array[DrumkitDataItem] = []
