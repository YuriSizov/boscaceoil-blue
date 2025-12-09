###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Voice manager component responsible for providing preset voice data
## and SiONVoice instances for insturments.
class_name VoiceManager extends RefCounted

## SiON tool with a bunch of pre-configured voices.
var _preset_util: SiONVoicePresetUtil = null
## Collection of registered voice data.
var _voices: Array[VoiceData] = []
## Collection of categories for registered voices.
var _categories: PackedStringArray = PackedStringArray()
var _sub_categories: Array[SubCategory] = []


func _init() -> void:
	# Generate presets with default flags.
	_preset_util = SiONVoicePresetUtil.generate_voices()

	# NOTE: Order of registration is important, as it is used for the save data format.
	# If we ever need to add more voices/instruments, this needs to be handled gracefully.
	
	_register_categories()
	_register_voices()
	_register_drumkits()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_preset_util.free()


# Initialization.

func _register_categories() -> void:
	_register_sub_category("MIDI", "Piano",    "midi.piano")
	_register_sub_category("MIDI", "Bells",    "midi.chrom")
	_register_sub_category("MIDI", "Organ",    "midi.organ")
	_register_sub_category("MIDI", "Guitar",   "midi.guitar")
	_register_sub_category("MIDI", "Bass",     "midi.bass")
	_register_sub_category("MIDI", "Strings",  "midi.strings")
	_register_sub_category("MIDI", "Ensemble", "midi.ensemble")
	_register_sub_category("MIDI", "Brass",    "midi.brass")
	_register_sub_category("MIDI", "Reed",     "midi.reed")
	_register_sub_category("MIDI", "Pipe",     "midi.pipe")
	_register_sub_category("MIDI", "Lead",     "midi.lead")
	_register_sub_category("MIDI", "Pads",     "midi.pad")
	_register_sub_category("MIDI", "Synth",    "midi.fx")
	_register_sub_category("MIDI", "World",    "midi.world")
	_register_sub_category("MIDI", "Drums",    "midi.percus")
	_register_sub_category("MIDI", "Effects",  "midi.se")
	
	_register_sub_category("CHIPTUNE", "", "")
	_register_sub_category("BASS",     "", "valsound.bass")
	_register_sub_category("BRASS",    "", "valsound.brass")
	_register_sub_category("BELL",     "", "valsound.bell")
	_register_sub_category("GUITAR",   "", "valsound.guitar")
	_register_sub_category("LEAD",     "", "valsound.lead")
	_register_sub_category("PIANO",    "", "valsound.piano")
	_register_sub_category("SPECIAL",  "", "valsound.s")
	_register_sub_category("STRINGS",  "", "valsound.strpad")
	_register_sub_category("WIND",     "", "valsound.wind")
	_register_sub_category("WORLD",    "", "valsound.world")
	_register_sub_category("DRUMKIT",  "", "drumkit")


func _register_voices() -> void:
	_register_single_voice("MIDI", "Grand Piano",       "midi.piano1",    BoscaColorPalette.PALETTE_BLUE,   0)
	_register_single_voice("MIDI", "Bright Piano",      "midi.piano2",    BoscaColorPalette.PALETTE_PURPLE, 1)
	_register_single_voice("MIDI", "Electric Grand",    "midi.piano3",    BoscaColorPalette.PALETTE_RED,    2)
	_register_single_voice("MIDI", "Honky Tonk",        "midi.piano4",    BoscaColorPalette.PALETTE_ORANGE, 3)
	_register_single_voice("MIDI", "Electric Piano 1",  "midi.piano5",    BoscaColorPalette.PALETTE_GREEN,  4)
	_register_single_voice("MIDI", "Electric Piano 2",  "midi.piano6",    BoscaColorPalette.PALETTE_CYAN,   5)
	_register_single_voice("MIDI", "Harpsichord",       "midi.piano7",    BoscaColorPalette.PALETTE_BLUE,   6)
	_register_single_voice("MIDI", "Clavichord",        "midi.piano8",    BoscaColorPalette.PALETTE_PURPLE, 7)
	_register_single_voice("MIDI", "Celesta",           "midi.chrom1",    BoscaColorPalette.PALETTE_RED,    8)
	_register_single_voice("MIDI", "Glockenspiel",      "midi.chrom2",    BoscaColorPalette.PALETTE_ORANGE, 9)
	_register_single_voice("MIDI", "Music Box",         "midi.chrom3",    BoscaColorPalette.PALETTE_GREEN,  10)
	_register_single_voice("MIDI", "Vibraphone",        "midi.chrom4",    BoscaColorPalette.PALETTE_CYAN,   11)
	_register_single_voice("MIDI", "Marimba",           "midi.chrom5",    BoscaColorPalette.PALETTE_BLUE,   12)
	_register_single_voice("MIDI", "Xylophone",         "midi.chrom6",    BoscaColorPalette.PALETTE_PURPLE, 13)
	_register_single_voice("MIDI", "Tubular Bells",     "midi.chrom7",    BoscaColorPalette.PALETTE_RED,    14)
	_register_single_voice("MIDI", "Dulcimer",          "midi.chrom8",    BoscaColorPalette.PALETTE_ORANGE, 15)
	_register_single_voice("MIDI", "Drawbar Organ",     "midi.organ1",    BoscaColorPalette.PALETTE_GREEN,  16)
	_register_single_voice("MIDI", "Percussive Organ",  "midi.organ2",    BoscaColorPalette.PALETTE_CYAN,   17)
	_register_single_voice("MIDI", "Rock Organ",        "midi.organ3",    BoscaColorPalette.PALETTE_BLUE,   18)
	_register_single_voice("MIDI", "Church Organ",      "midi.organ4",    BoscaColorPalette.PALETTE_PURPLE, 19)
	_register_single_voice("MIDI", "Reed Organ",        "midi.organ5",    BoscaColorPalette.PALETTE_RED,    20)
	_register_single_voice("MIDI", "Accordion",         "midi.organ6",    BoscaColorPalette.PALETTE_ORANGE, 21)
	_register_single_voice("MIDI", "Harmonica",         "midi.organ7",    BoscaColorPalette.PALETTE_GREEN,  22)
	_register_single_voice("MIDI", "Tango Accordion",   "midi.organ8",    BoscaColorPalette.PALETTE_CYAN,   23)
	_register_single_voice("MIDI", "Nylon Guitar",      "midi.guitar1",   BoscaColorPalette.PALETTE_BLUE,   24)
	_register_single_voice("MIDI", "Steel Guitar",      "midi.guitar2",   BoscaColorPalette.PALETTE_PURPLE, 25)
	_register_single_voice("MIDI", "Jazz Guitar",       "midi.guitar3",   BoscaColorPalette.PALETTE_RED,    26)
	_register_single_voice("MIDI", "Clean Electric",    "midi.guitar4",   BoscaColorPalette.PALETTE_ORANGE, 27)
	_register_single_voice("MIDI", "Muted Electric",    "midi.guitar5",   BoscaColorPalette.PALETTE_GREEN,  28)
	_register_single_voice("MIDI", "Overdriven Guitar", "midi.guitar6",   BoscaColorPalette.PALETTE_CYAN,   29)
	_register_single_voice("MIDI", "Distortion Guitar", "midi.guitar7",   BoscaColorPalette.PALETTE_BLUE,   30)
	_register_single_voice("MIDI", "Guitar Harmonics",  "midi.guitar8",   BoscaColorPalette.PALETTE_PURPLE, 31)
	_register_single_voice("MIDI", "Acoustic Bass",     "midi.bass1",     BoscaColorPalette.PALETTE_RED,    32)
	_register_single_voice("MIDI", "Finger Bass",       "midi.bass2",     BoscaColorPalette.PALETTE_ORANGE, 33)
	_register_single_voice("MIDI", "Pick Bass",         "midi.bass3",     BoscaColorPalette.PALETTE_GREEN,  34)
	_register_single_voice("MIDI", "Fretless Bass",     "midi.bass4",     BoscaColorPalette.PALETTE_CYAN,   35)
	_register_single_voice("MIDI", "Slap Bass 1",       "midi.bass5",     BoscaColorPalette.PALETTE_BLUE,   36)
	_register_single_voice("MIDI", "Slap Bass 2",       "midi.bass6",     BoscaColorPalette.PALETTE_PURPLE, 37)
	_register_single_voice("MIDI", "Synth Bass 1",      "midi.bass7",     BoscaColorPalette.PALETTE_RED,    38)
	_register_single_voice("MIDI", "Synth Bass 2",      "midi.bass8",     BoscaColorPalette.PALETTE_ORANGE, 39)
	_register_single_voice("MIDI", "Violin",            "midi.strings1",  BoscaColorPalette.PALETTE_GREEN,  40)
	_register_single_voice("MIDI", "Viola",             "midi.strings2",  BoscaColorPalette.PALETTE_CYAN,   41)
	_register_single_voice("MIDI", "Cello",             "midi.strings3",  BoscaColorPalette.PALETTE_BLUE,   42)
	_register_single_voice("MIDI", "Contrabass",        "midi.strings4",  BoscaColorPalette.PALETTE_PURPLE, 43)
	_register_single_voice("MIDI", "Tremolo Strings",   "midi.strings5",  BoscaColorPalette.PALETTE_RED,    44)
	_register_single_voice("MIDI", "Pizzicato Strings", "midi.strings6",  BoscaColorPalette.PALETTE_ORANGE, 45)
	_register_single_voice("MIDI", "Orchestral Harp",   "midi.strings7",  BoscaColorPalette.PALETTE_GREEN,  46)
	_register_single_voice("MIDI", "Timpani",           "midi.strings8",  BoscaColorPalette.PALETTE_CYAN,   47)
	_register_single_voice("MIDI", "String Ensemble 1", "midi.ensemble1", BoscaColorPalette.PALETTE_BLUE,   48)
	_register_single_voice("MIDI", "String Ensemble 2", "midi.ensemble2", BoscaColorPalette.PALETTE_PURPLE, 49)
	_register_single_voice("MIDI", "Synth Strings 1",   "midi.ensemble3", BoscaColorPalette.PALETTE_RED,    50)
	_register_single_voice("MIDI", "Synth Strings 2",   "midi.ensemble4", BoscaColorPalette.PALETTE_ORANGE, 51)
	_register_single_voice("MIDI", "Choir Aahs",        "midi.ensemble5", BoscaColorPalette.PALETTE_GREEN,  52)
	_register_single_voice("MIDI", "Voice Oohs",        "midi.ensemble6", BoscaColorPalette.PALETTE_CYAN,   53)
	_register_single_voice("MIDI", "Synth Voice",       "midi.ensemble7", BoscaColorPalette.PALETTE_BLUE,   54)
	_register_single_voice("MIDI", "Orchestra Hit",     "midi.ensemble8", BoscaColorPalette.PALETTE_PURPLE, 55)
	_register_single_voice("MIDI", "Trumpet",           "midi.brass1",    BoscaColorPalette.PALETTE_RED,    56)
	_register_single_voice("MIDI", "Trombone",          "midi.brass2",    BoscaColorPalette.PALETTE_ORANGE, 57)
	_register_single_voice("MIDI", "Tuba",              "midi.brass3",    BoscaColorPalette.PALETTE_GREEN,  58)
	_register_single_voice("MIDI", "Muted Trumpet",     "midi.brass4",    BoscaColorPalette.PALETTE_CYAN,   59)
	_register_single_voice("MIDI", "French Horn",       "midi.brass5",    BoscaColorPalette.PALETTE_BLUE,   60)
	_register_single_voice("MIDI", "Brass Section",     "midi.brass6",    BoscaColorPalette.PALETTE_PURPLE, 61)
	_register_single_voice("MIDI", "Synth Brass 1",     "midi.brass7",    BoscaColorPalette.PALETTE_RED,    62)
	_register_single_voice("MIDI", "Synth Brass 2",     "midi.brass8",    BoscaColorPalette.PALETTE_ORANGE, 63)
	_register_single_voice("MIDI", "Soprano Sax",       "midi.reed1",     BoscaColorPalette.PALETTE_GREEN,  64)
	_register_single_voice("MIDI", "Alto Sax",          "midi.reed2",     BoscaColorPalette.PALETTE_CYAN,   65)
	_register_single_voice("MIDI", "Tenor Sax",         "midi.reed3",     BoscaColorPalette.PALETTE_BLUE,   66)
	_register_single_voice("MIDI", "Baritone Sax",      "midi.reed4",     BoscaColorPalette.PALETTE_PURPLE, 67)
	_register_single_voice("MIDI", "Oboe",              "midi.reed5",     BoscaColorPalette.PALETTE_RED,    68)
	_register_single_voice("MIDI", "English Horn",      "midi.reed6",     BoscaColorPalette.PALETTE_ORANGE, 69)
	_register_single_voice("MIDI", "Bassoon",           "midi.reed7",     BoscaColorPalette.PALETTE_GREEN,  70)
	_register_single_voice("MIDI", "Clarinet",          "midi.reed8",     BoscaColorPalette.PALETTE_CYAN,   71)
	_register_single_voice("MIDI", "Piccolo",           "midi.pipe1",     BoscaColorPalette.PALETTE_BLUE,   72)
	_register_single_voice("MIDI", "Flute",             "midi.pipe2",     BoscaColorPalette.PALETTE_PURPLE, 73)
	_register_single_voice("MIDI", "Recorder",          "midi.pipe3",     BoscaColorPalette.PALETTE_RED,    74)
	_register_single_voice("MIDI", "Pan Flute",         "midi.pipe4",     BoscaColorPalette.PALETTE_ORANGE, 75)
	_register_single_voice("MIDI", "Blown Bottle",      "midi.pipe5",     BoscaColorPalette.PALETTE_GREEN,  76)
	_register_single_voice("MIDI", "Shakuhachi",        "midi.pipe6",     BoscaColorPalette.PALETTE_CYAN,   77)
	_register_single_voice("MIDI", "Whistle",           "midi.pipe7",     BoscaColorPalette.PALETTE_BLUE,   78)
	_register_single_voice("MIDI", "Ocarina",           "midi.pipe8",     BoscaColorPalette.PALETTE_PURPLE, 79)
	_register_single_voice("MIDI", "Square Lead",       "midi.lead1",     BoscaColorPalette.PALETTE_RED,    80)
	_register_single_voice("MIDI", "Saw Lead",          "midi.lead2",     BoscaColorPalette.PALETTE_ORANGE, 81)
	_register_single_voice("MIDI", "Calliope Lead",     "midi.lead3",     BoscaColorPalette.PALETTE_GREEN,  82)
	_register_single_voice("MIDI", "Chiff Lead",        "midi.lead4",     BoscaColorPalette.PALETTE_CYAN,   83)
	_register_single_voice("MIDI", "Charang Lead",      "midi.lead5",     BoscaColorPalette.PALETTE_BLUE,   84)
	_register_single_voice("MIDI", "Voice Lead",        "midi.lead6",     BoscaColorPalette.PALETTE_PURPLE, 85)
	_register_single_voice("MIDI", "Fifths Lead",       "midi.lead7",     BoscaColorPalette.PALETTE_RED,    86)
	_register_single_voice("MIDI", "Bass & Lead",       "midi.lead8",     BoscaColorPalette.PALETTE_ORANGE, 87)
	_register_single_voice("MIDI", "New Age Pad",       "midi.pad1",      BoscaColorPalette.PALETTE_GREEN,  88)
	_register_single_voice("MIDI", "Warm Pad",          "midi.pad2",      BoscaColorPalette.PALETTE_CYAN,   89)
	_register_single_voice("MIDI", "Polysynth Pad",     "midi.pad3",      BoscaColorPalette.PALETTE_BLUE,   90)
	_register_single_voice("MIDI", "Choir Pad",         "midi.pad4",      BoscaColorPalette.PALETTE_PURPLE, 91)
	_register_single_voice("MIDI", "Bowed Pad",         "midi.pad5",      BoscaColorPalette.PALETTE_RED,    92)
	_register_single_voice("MIDI", "Metallic Pad",      "midi.pad6",      BoscaColorPalette.PALETTE_ORANGE, 93)
	_register_single_voice("MIDI", "Halo Pad",          "midi.pad7",      BoscaColorPalette.PALETTE_GREEN,  94)
	_register_single_voice("MIDI", "Sweep Pad",         "midi.pad8",      BoscaColorPalette.PALETTE_CYAN,   95)
	_register_single_voice("MIDI", "Rain",              "midi.fx1",       BoscaColorPalette.PALETTE_BLUE,   96)
	_register_single_voice("MIDI", "Soundtrack",        "midi.fx2",       BoscaColorPalette.PALETTE_PURPLE, 97)
	_register_single_voice("MIDI", "Crystal",           "midi.fx3",       BoscaColorPalette.PALETTE_RED,    98)
	_register_single_voice("MIDI", "Atmosphere",        "midi.fx4",       BoscaColorPalette.PALETTE_ORANGE, 99)
	_register_single_voice("MIDI", "Bright",            "midi.fx5",       BoscaColorPalette.PALETTE_GREEN,  100)
	_register_single_voice("MIDI", "Goblins",           "midi.fx6",       BoscaColorPalette.PALETTE_CYAN,   101)
	_register_single_voice("MIDI", "Echoes",            "midi.fx7",       BoscaColorPalette.PALETTE_BLUE,   102)
	_register_single_voice("MIDI", "Sci-Fi",            "midi.fx8",       BoscaColorPalette.PALETTE_PURPLE, 103)
	_register_single_voice("MIDI", "Sitar",             "midi.world1",    BoscaColorPalette.PALETTE_RED,    104)
	_register_single_voice("MIDI", "Banjo",             "midi.world2",    BoscaColorPalette.PALETTE_ORANGE, 105)
	_register_single_voice("MIDI", "Shamisen",          "midi.world3",    BoscaColorPalette.PALETTE_GREEN,  106)
	_register_single_voice("MIDI", "Koto",              "midi.world4",    BoscaColorPalette.PALETTE_CYAN,   107)
	_register_single_voice("MIDI", "Kalimba",           "midi.world5",    BoscaColorPalette.PALETTE_BLUE,   108)
	_register_single_voice("MIDI", "Bagpipe",           "midi.world6",    BoscaColorPalette.PALETTE_PURPLE, 109)
	_register_single_voice("MIDI", "Fiddle",            "midi.world7",    BoscaColorPalette.PALETTE_RED,    110)
	_register_single_voice("MIDI", "Shanai",            "midi.world8",    BoscaColorPalette.PALETTE_ORANGE, 111)
	_register_single_voice("MIDI", "Tinkle Bell",       "midi.percus1",   BoscaColorPalette.PALETTE_GREEN,  112)
	_register_single_voice("MIDI", "Agogo",             "midi.percus2",   BoscaColorPalette.PALETTE_CYAN,   113)
	_register_single_voice("MIDI", "Steel Drums",       "midi.percus3",   BoscaColorPalette.PALETTE_BLUE,   114)
	_register_single_voice("MIDI", "Wood Block",        "midi.percus4",   BoscaColorPalette.PALETTE_PURPLE, 115)
	_register_single_voice("MIDI", "Taiko Drum",        "midi.percus5",   BoscaColorPalette.PALETTE_RED,    116)
	_register_single_voice("MIDI", "Melodic Tom",       "midi.percus6",   BoscaColorPalette.PALETTE_ORANGE, 117)
	_register_single_voice("MIDI", "Synth Drum",        "midi.percus7",   BoscaColorPalette.PALETTE_GREEN,  118)
	_register_single_voice("MIDI", "Reverse Cymbal",    "midi.percus8",   BoscaColorPalette.PALETTE_CYAN,   119)
	_register_single_voice("MIDI", "Fret Noise",        "midi.se1",       BoscaColorPalette.PALETTE_BLUE,   120)
	_register_single_voice("MIDI", "Breath Noise",      "midi.se2",       BoscaColorPalette.PALETTE_PURPLE, 121)
	_register_single_voice("MIDI", "Seashore",          "midi.se3",       BoscaColorPalette.PALETTE_RED,    122)
	_register_single_voice("MIDI", "Bird Tweet",        "midi.se4",       BoscaColorPalette.PALETTE_ORANGE, 123)
	_register_single_voice("MIDI", "Telephone",         "midi.se5",       BoscaColorPalette.PALETTE_GREEN,  124)
	_register_single_voice("MIDI", "Helicopter",        "midi.se6",       BoscaColorPalette.PALETTE_CYAN,   125)
	_register_single_voice("MIDI", "Applause",          "midi.se7",       BoscaColorPalette.PALETTE_BLUE,   126)
	_register_single_voice("MIDI", "Gunshot",           "midi.se8",       BoscaColorPalette.PALETTE_PURPLE, 127)
	
	_register_single_voice("CHIPTUNE", "Square Wave",    "square",     BoscaColorPalette.PALETTE_BLUE,   6)
	_register_single_voice("CHIPTUNE", "Saw Wave",       "saw",        BoscaColorPalette.PALETTE_PURPLE, 81)
	_register_single_voice("CHIPTUNE", "Triangle Wave",  "triangle",   BoscaColorPalette.PALETTE_RED,    80)
	_register_single_voice("CHIPTUNE", "Sine Wave",      "sine",       BoscaColorPalette.PALETTE_ORANGE, 102)
	_register_single_voice("CHIPTUNE", "Noise",          "noise",      BoscaColorPalette.PALETTE_GRAY,   127)
	_register_single_voice("CHIPTUNE", "Dual Square",    "dualsquare", BoscaColorPalette.PALETTE_BLUE,   4)
	_register_single_voice("CHIPTUNE", "Dual Saw",       "dualsaw",    BoscaColorPalette.PALETTE_PURPLE, 7)
	_register_single_voice("CHIPTUNE", "Triangle Lo-Fi", "triangle8",  BoscaColorPalette.PALETTE_RED,    72)
	_register_single_voice("CHIPTUNE", "Konami Wave",    "konami",     BoscaColorPalette.PALETTE_GREEN,  3)
	_register_single_voice("CHIPTUNE", "Ramp Wave",      "ramp",       BoscaColorPalette.PALETTE_GREEN,  18)
	_register_single_voice("CHIPTUNE", "Pulse Wave",     "beep",       BoscaColorPalette.PALETTE_GREEN,  29)
	_register_single_voice("CHIPTUNE", "MA-3 Wave",      "ma1",        BoscaColorPalette.PALETTE_GREEN,  25)
	_register_single_voice("CHIPTUNE", "Noise (Bass)",   "bassdrumm",  BoscaColorPalette.PALETTE_GRAY,   115)
	_register_single_voice("CHIPTUNE", "Noise (Snare)",  "snare",      BoscaColorPalette.PALETTE_GRAY,   118)
	_register_single_voice("CHIPTUNE", "Noise (Hi-Hat)", "closedhh",   BoscaColorPalette.PALETTE_GRAY,   126)
	
	_register_single_voice("BASS", "Analog Bass (FB)",        "valsound.bass1",  BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Analog Bass #2",          "valsound.bass2",  BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Analog Bass #2 (q2)",     "valsound.bass3",  BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Chopper Bass 0",          "valsound.bass4",  BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Chopper Bass 1",          "valsound.bass5",  BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Chopper Bass 2 (Cut)",    "valsound.bass6",  BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Chopper Bass 3",          "valsound.bass7",  BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Electric Chopper +4",     "valsound.bass8",  BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Effect Bass 1",           "valsound.bass9",  BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Effect Bass 2 (Up)",      "valsound.bass10", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Effect Bass 3",           "valsound.bass11", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Mohaaa",                  "valsound.bass12", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Effect FB Bass #5",       "valsound.bass13", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Magical Bass",            "valsound.bass14", BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Electric Bass #6",        "valsound.bass15", BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Electric Bass #7",        "valsound.bass16", BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Electric Bass 70",        "valsound.bass17", BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "VAL006 Bass (Euro)",      "valsound.bass18", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Electric Bass x2",        "valsound.bass19", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Electric Bass x4",        "valsound.bass20", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Metal Pick Bass x5",      "valsound.bass21", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Groove Bass #1",          "valsound.bass22", BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Analog Groove #2",        "valsound.bass23", BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Harmonics #1",            "valsound.bass24", BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Low Bass x1",             "valsound.bass25", BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Low Bass x2 (Little FB)", "valsound.bass26", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Low Bass x1 (Rezz)",      "valsound.bass27", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Low Bass Picked",         "valsound.bass28", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Metal Bass",              "valsound.bass29", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "E.N. Bass 1",             "valsound.bass30", BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "PSG Bass 1",              "valsound.bass31", BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "PSG Bass 2",              "valsound.bass32", BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Rezonance Bass",          "valsound.bass33", BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Slap Bass",               "valsound.bass34", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Slap Bass 1",             "valsound.bass35", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Slap Bass 2 (1+)",        "valsound.bass36", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Slap Bass #3",            "valsound.bass37", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Slap Bass (Pull)",        "valsound.bass38", BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Slap Bass (Mute)",        "valsound.bass39", BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Slap Bass (Pick+Pipe)",   "valsound.bass40", BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Super Bass #2",           "valsound.bass41", BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "SP Bass #3 (Soft)",       "valsound.bass42", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "SP Bass #4 (Soft*2)",     "valsound.bass43", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "SP Bass #5 (Attack)",     "valsound.bass44", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "SP Bass #6 (Rezz)",       "valsound.bass45", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Synth Bass 1",            "valsound.bass46", BoscaColorPalette.PALETTE_RED, 37)
	_register_single_voice("BASS", "Synth Bass 2 (myon)",     "valsound.bass47", BoscaColorPalette.PALETTE_RED, 38)
	_register_single_voice("BASS", "Synth Bass #3 (cho!)",    "valsound.bass48", BoscaColorPalette.PALETTE_RED, 39)
	_register_single_voice("BASS", "Synth Wind Bass #4",      "valsound.bass49", BoscaColorPalette.PALETTE_RED, 32)
	_register_single_voice("BASS", "Synth Bass #5 (q2)",      "valsound.bass50", BoscaColorPalette.PALETTE_RED, 33)
	_register_single_voice("BASS", "Old Wood Bass",           "valsound.bass51", BoscaColorPalette.PALETTE_RED, 34)
	_register_single_voice("BASS", "Wood Bass (Bright)",      "valsound.bass52", BoscaColorPalette.PALETTE_RED, 35)
	_register_single_voice("BASS", "Wood Bass x2 (Bow)",      "valsound.bass53", BoscaColorPalette.PALETTE_RED, 36)
	_register_single_voice("BASS", "Wood Bass 3 (Muted)",     "valsound.bass54", BoscaColorPalette.PALETTE_RED, 37)
	
	_register_single_voice("BRASS", "Brass Strings",            "valsound.brass1",  BoscaColorPalette.PALETTE_BLUE,   56)
	_register_single_voice("BRASS", "Electric Trumpet (Muted)", "valsound.brass2",  BoscaColorPalette.PALETTE_PURPLE, 57)
	_register_single_voice("BRASS", "Horn 2",                   "valsound.brass3",  BoscaColorPalette.PALETTE_RED,    58)
	_register_single_voice("BRASS", "Alpine Horn #3",           "valsound.brass4",  BoscaColorPalette.PALETTE_ORANGE, 59)
	_register_single_voice("BRASS", "Lead Brass",               "valsound.brass5",  BoscaColorPalette.PALETTE_GREEN,  60)
	_register_single_voice("BRASS", "Normal Horn",              "valsound.brass6",  BoscaColorPalette.PALETTE_CYAN,   61)
	_register_single_voice("BRASS", "Synth Oboe",               "valsound.brass7",  BoscaColorPalette.PALETTE_BLUE,   62)
	_register_single_voice("BRASS", "Oboe 2",                   "valsound.brass8",  BoscaColorPalette.PALETTE_PURPLE, 63)
	_register_single_voice("BRASS", "Attack Brass (q2)",        "valsound.brass9",  BoscaColorPalette.PALETTE_RED,    56)
	_register_single_voice("BRASS", "Sax",                      "valsound.brass10", BoscaColorPalette.PALETTE_ORANGE, 57)
	_register_single_voice("BRASS", "Soft Brass (Lead)",        "valsound.brass11", BoscaColorPalette.PALETTE_GREEN,  58)
	_register_single_voice("BRASS", "Synth Brass 1 (Old)",      "valsound.brass12", BoscaColorPalette.PALETTE_CYAN,   59)
	_register_single_voice("BRASS", "Synth Brass 2 (Old)",      "valsound.brass13", BoscaColorPalette.PALETTE_BLUE,   60)
	_register_single_voice("BRASS", "Synth Brass 3",            "valsound.brass14", BoscaColorPalette.PALETTE_PURPLE, 61)
	_register_single_voice("BRASS", "Synth Brass #4",           "valsound.brass15", BoscaColorPalette.PALETTE_RED,    62)
	_register_single_voice("BRASS", "Synth Brass 5 (Long)",     "valsound.brass16", BoscaColorPalette.PALETTE_ORANGE, 63)
	_register_single_voice("BRASS", "Synth Brass 6",            "valsound.brass17", BoscaColorPalette.PALETTE_GREEN,  56)
	_register_single_voice("BRASS", "Trumpet",                  "valsound.brass18", BoscaColorPalette.PALETTE_CYAN,   57)
	_register_single_voice("BRASS", "Trumpet 2",                "valsound.brass19", BoscaColorPalette.PALETTE_BLUE,   58)
	_register_single_voice("BRASS", "Twin Horn",                "valsound.brass20", BoscaColorPalette.PALETTE_PURPLE, 59)
	
	_register_single_voice("BELL", "Calm Bell",          "valsound.bell1",  BoscaColorPalette.PALETTE_PURPLE, 8)
	_register_single_voice("BELL", "China Bell Double",  "valsound.bell2",  BoscaColorPalette.PALETTE_RED,    9)
	_register_single_voice("BELL", "Church Bell",        "valsound.bell3",  BoscaColorPalette.PALETTE_ORANGE, 10)
	_register_single_voice("BELL", "Church Bell 2",      "valsound.bell4",  BoscaColorPalette.PALETTE_GREEN,  11)
	_register_single_voice("BELL", "Glocken 1",          "valsound.bell5",  BoscaColorPalette.PALETTE_CYAN,   12)
	_register_single_voice("BELL", "Harp #1",            "valsound.bell6",  BoscaColorPalette.PALETTE_BLUE,   13)
	_register_single_voice("BELL", "Harp #2",            "valsound.bell7",  BoscaColorPalette.PALETTE_PURPLE, 14)
	_register_single_voice("BELL", "Kirakira",           "valsound.bell8",  BoscaColorPalette.PALETTE_RED,    15)
	_register_single_voice("BELL", "Marimba",            "valsound.bell9",  BoscaColorPalette.PALETTE_ORANGE, 8)
	_register_single_voice("BELL", "Old Bell",           "valsound.bell10", BoscaColorPalette.PALETTE_GREEN,  9)
	_register_single_voice("BELL", "Percussive Bell",    "valsound.bell11", BoscaColorPalette.PALETTE_CYAN,   10)
	_register_single_voice("BELL", "Pretty Bell",        "valsound.bell12", BoscaColorPalette.PALETTE_BLUE,   11)
	_register_single_voice("BELL", "Synth Bell #0",      "valsound.bell13", BoscaColorPalette.PALETTE_PURPLE, 12)
	_register_single_voice("BELL", "Synth Bell #1 (o5)", "valsound.bell14", BoscaColorPalette.PALETTE_RED,    13)
	_register_single_voice("BELL", "Synth Bell 2",       "valsound.bell15", BoscaColorPalette.PALETTE_ORANGE, 14)
	_register_single_voice("BELL", "Vibraphone",         "valsound.bell16", BoscaColorPalette.PALETTE_GREEN,  15)
	_register_single_voice("BELL", "Twin Marinba",       "valsound.bell17", BoscaColorPalette.PALETTE_CYAN,   8)
	_register_single_voice("BELL", "Bellend",            "valsound.bell18", BoscaColorPalette.PALETTE_BLUE,   9)
	
	_register_single_voice("GUITAR", "VeloLow Guitar",         "valsound.guitar1",  BoscaColorPalette.PALETTE_BLUE,   24)
	_register_single_voice("GUITAR", "VeloHigh Guitar",        "valsound.guitar2",  BoscaColorPalette.PALETTE_PURPLE, 25)
	_register_single_voice("GUITAR", "Acoustic Guitar #3",     "valsound.guitar3",  BoscaColorPalette.PALETTE_RED,    26)
	_register_single_voice("GUITAR", "Cutting Electric",       "valsound.guitar4",  BoscaColorPalette.PALETTE_ORANGE, 27)
	_register_single_voice("GUITAR", "Distortion Synth (Old)", "valsound.guitar5",  BoscaColorPalette.PALETTE_GREEN,  28)
	_register_single_voice("GUITAR", "Distortion (Dra-spi)",   "valsound.guitar6",  BoscaColorPalette.PALETTE_CYAN,   29)
	_register_single_voice("GUITAR", "Distortion 3-",          "valsound.guitar7",  BoscaColorPalette.PALETTE_BLUE,   30)
	_register_single_voice("GUITAR", "Distortion 3+",          "valsound.guitar8",  BoscaColorPalette.PALETTE_PURPLE, 31)
	_register_single_voice("GUITAR", "Feedback Guitar 1",      "valsound.guitar9",  BoscaColorPalette.PALETTE_RED,    24)
	_register_single_voice("GUITAR", "Hard Distortion 1",      "valsound.guitar10", BoscaColorPalette.PALETTE_ORANGE, 25)
	_register_single_voice("GUITAR", "Hard Distortion 3",      "valsound.guitar11", BoscaColorPalette.PALETTE_GREEN,  26)
	_register_single_voice("GUITAR", "Distortion ('94 Hard)",  "valsound.guitar12", BoscaColorPalette.PALETTE_CYAN,   27)
	_register_single_voice("GUITAR", "New Distortion 1",       "valsound.guitar13", BoscaColorPalette.PALETTE_BLUE,   28)
	_register_single_voice("GUITAR", "New Distortion 2",       "valsound.guitar14", BoscaColorPalette.PALETTE_PURPLE, 29)
	_register_single_voice("GUITAR", "New Distortion 3",       "valsound.guitar15", BoscaColorPalette.PALETTE_RED,    30)
	_register_single_voice("GUITAR", "Overdriven Guitar",      "valsound.guitar16", BoscaColorPalette.PALETTE_ORANGE, 31)
	_register_single_voice("GUITAR", "Metal Strings",          "valsound.guitar17", BoscaColorPalette.PALETTE_GREEN,  24)
	_register_single_voice("GUITAR", "Soft Distortion",        "valsound.guitar18", BoscaColorPalette.PALETTE_CYAN,   25)
	
	_register_single_voice("LEAD", "Acoustic Code",          "valsound.lead1",  BoscaColorPalette.PALETTE_BLUE,   80)
	_register_single_voice("LEAD", "Analog Synth 1",         "valsound.lead2",  BoscaColorPalette.PALETTE_PURPLE, 81)
	_register_single_voice("LEAD", "Bosco Lead",             "valsound.lead3",  BoscaColorPalette.PALETTE_RED,    82)
	_register_single_voice("LEAD", "Cosmo Lead",             "valsound.lead4",  BoscaColorPalette.PALETTE_ORANGE, 83)
	_register_single_voice("LEAD", "Cosmo Lead 2",           "valsound.lead5",  BoscaColorPalette.PALETTE_GREEN,  84)
	_register_single_voice("LEAD", "Digital Lead #1",        "valsound.lead6",  BoscaColorPalette.PALETTE_CYAN,   85)
	_register_single_voice("LEAD", "Double Sin Wave",        "valsound.lead7",  BoscaColorPalette.PALETTE_BLUE,   86)
	_register_single_voice("LEAD", "Bright Organ",           "valsound.lead8",  BoscaColorPalette.PALETTE_PURPLE, 16)
	_register_single_voice("LEAD", "Voice Organ",            "valsound.lead9",  BoscaColorPalette.PALETTE_RED,    17)
	_register_single_voice("LEAD", "Click Organ 4",          "valsound.lead10", BoscaColorPalette.PALETTE_ORANGE, 18)
	_register_single_voice("LEAD", "Click Organ 5",          "valsound.lead11", BoscaColorPalette.PALETTE_GREEN,  19)
	_register_single_voice("LEAD", "Electric Organ 6",       "valsound.lead12", BoscaColorPalette.PALETTE_CYAN,   20)
	_register_single_voice("LEAD", "Church Organ",           "valsound.lead13", BoscaColorPalette.PALETTE_BLUE,   21)
	_register_single_voice("LEAD", "Metal Lead",             "valsound.lead14", BoscaColorPalette.PALETTE_PURPLE, 87)
	_register_single_voice("LEAD", "Metal Lead 3",           "valsound.lead15", BoscaColorPalette.PALETTE_RED,    80)
	_register_single_voice("LEAD", "Mono Lead",              "valsound.lead16", BoscaColorPalette.PALETTE_ORANGE, 81)
	_register_single_voice("LEAD", "PSG like PC88 (Long)",   "valsound.lead17", BoscaColorPalette.PALETTE_GREEN,  82)
	_register_single_voice("LEAD", "PSG Cut 1",              "valsound.lead18", BoscaColorPalette.PALETTE_CYAN,   83)
	_register_single_voice("LEAD", "Attack Synth",           "valsound.lead19", BoscaColorPalette.PALETTE_BLUE,   84)
	_register_single_voice("LEAD", "Sin Wave",               "valsound.lead20", BoscaColorPalette.PALETTE_PURPLE, 85)
	_register_single_voice("LEAD", "Synth & Bell 2",         "valsound.lead21", BoscaColorPalette.PALETTE_RED,    86)
	_register_single_voice("LEAD", "Chorus #2 & Bell",       "valsound.lead22", BoscaColorPalette.PALETTE_ORANGE, 87)
	_register_single_voice("LEAD", "Synth 8-4 (Cut)",        "valsound.lead23", BoscaColorPalette.PALETTE_GREEN,  80)
	_register_single_voice("LEAD", "Synth 8-4 (Long)",       "valsound.lead24", BoscaColorPalette.PALETTE_CYAN,   81)
	_register_single_voice("LEAD", "Acoustic Code #2",       "valsound.lead25", BoscaColorPalette.PALETTE_BLUE,   82)
	_register_single_voice("LEAD", "Acoustic Code #3",       "valsound.lead26", BoscaColorPalette.PALETTE_PURPLE, 83)
	_register_single_voice("LEAD", "Synth FB 4 (Long)",      "valsound.lead27", BoscaColorPalette.PALETTE_RED,    84)
	_register_single_voice("LEAD", "Synth FB 5 (Long)",      "valsound.lead28", BoscaColorPalette.PALETTE_ORANGE, 85)
	_register_single_voice("LEAD", "Synth Lead 0",           "valsound.lead29", BoscaColorPalette.PALETTE_GREEN,  86)
	_register_single_voice("LEAD", "Synth Lead 1",           "valsound.lead30", BoscaColorPalette.PALETTE_CYAN,   87)
	_register_single_voice("LEAD", "Synth Lead 2",           "valsound.lead31", BoscaColorPalette.PALETTE_BLUE,   80)
	_register_single_voice("LEAD", "Synth Lead 3",           "valsound.lead32", BoscaColorPalette.PALETTE_PURPLE, 81)
	_register_single_voice("LEAD", "Synth Lead 4",           "valsound.lead33", BoscaColorPalette.PALETTE_RED,    82)
	_register_single_voice("LEAD", "Synth Lead 5",           "valsound.lead34", BoscaColorPalette.PALETTE_ORANGE, 83)
	_register_single_voice("LEAD", "Synth Lead 6",           "valsound.lead35", BoscaColorPalette.PALETTE_GREEN,  84)
	_register_single_voice("LEAD", "Synth Lead 7 (Soft FB)", "valsound.lead36", BoscaColorPalette.PALETTE_CYAN,   85)
	_register_single_voice("LEAD", "Synth PSG",              "valsound.lead37", BoscaColorPalette.PALETTE_BLUE,   86)
	_register_single_voice("LEAD", "Synth PSG 2",            "valsound.lead38", BoscaColorPalette.PALETTE_PURPLE, 87)
	_register_single_voice("LEAD", "Synth PSG 3",            "valsound.lead39", BoscaColorPalette.PALETTE_RED,    80)
	_register_single_voice("LEAD", "Synth PSG 4",            "valsound.lead40", BoscaColorPalette.PALETTE_ORANGE, 81)
	_register_single_voice("LEAD", "Synth PSG 5",            "valsound.lead41", BoscaColorPalette.PALETTE_GREEN,  82)
	_register_single_voice("LEAD", "Sin Water Synth",        "valsound.lead42", BoscaColorPalette.PALETTE_CYAN,   83)
	
	_register_single_voice("PIANO", "Acoustic Piano 2 (Attack)", "valsound.piano1",  BoscaColorPalette.PALETTE_RED,    0)
	_register_single_voice("PIANO", "Clavichord 1 (Backing)",    "valsound.piano2",  BoscaColorPalette.PALETTE_ORANGE, 1)
	_register_single_voice("PIANO", "Clavichord 2",              "valsound.piano3",  BoscaColorPalette.PALETTE_GREEN,  2)
	_register_single_voice("PIANO", "Deep Piano 1",              "valsound.piano4",  BoscaColorPalette.PALETTE_CYAN,   3)
	_register_single_voice("PIANO", "Deep Piano 3",              "valsound.piano5",  BoscaColorPalette.PALETTE_BLUE,   4)
	_register_single_voice("PIANO", "Electric Piano #2",         "valsound.piano6",  BoscaColorPalette.PALETTE_PURPLE, 5)
	_register_single_voice("PIANO", "Electric Piano #3",         "valsound.piano7",  BoscaColorPalette.PALETTE_RED,    6)
	_register_single_voice("PIANO", "Electric Piano #4 (2+)",    "valsound.piano8",  BoscaColorPalette.PALETTE_ORANGE, 7)
	_register_single_voice("PIANO", "Electric Piano #5 (Bell)",  "valsound.piano9",  BoscaColorPalette.PALETTE_GREEN,  0)
	_register_single_voice("PIANO", "Electric Piano #6",         "valsound.piano10", BoscaColorPalette.PALETTE_CYAN,   1)
	_register_single_voice("PIANO", "Electric Piano #7",         "valsound.piano11", BoscaColorPalette.PALETTE_BLUE,   2)
	_register_single_voice("PIANO", "Harpsichord 1",             "valsound.piano12", BoscaColorPalette.PALETTE_PURPLE, 3)
	_register_single_voice("PIANO", "Harpsichord 2",             "valsound.piano13", BoscaColorPalette.PALETTE_RED,    4)
	_register_single_voice("PIANO", "Piano 1",                   "valsound.piano14", BoscaColorPalette.PALETTE_ORANGE, 5)
	_register_single_voice("PIANO", "Piano 3",                   "valsound.piano15", BoscaColorPalette.PALETTE_GREEN,  6)
	_register_single_voice("PIANO", "Piano 4",                   "valsound.piano16", BoscaColorPalette.PALETTE_CYAN,   7)
	_register_single_voice("PIANO", "Digital Piano #5",          "valsound.piano17", BoscaColorPalette.PALETTE_BLUE,   0)
	_register_single_voice("PIANO", "Piano 6 (High-tone)",       "valsound.piano18", BoscaColorPalette.PALETTE_PURPLE, 1)
	_register_single_voice("PIANO", "Panning Harpsichord",       "valsound.piano19", BoscaColorPalette.PALETTE_RED,    2)
	_register_single_voice("PIANO", "Yam Harpsichord",           "valsound.piano20", BoscaColorPalette.PALETTE_ORANGE, 3)
	
	_register_single_voice("SPECIAL", "Effect 1 (o2c)",           "valsound.se1",      BoscaColorPalette.PALETTE_GREEN,  120)
	_register_single_voice("SPECIAL", "Effect 2 (o0-o2)",         "valsound.se2",      BoscaColorPalette.PALETTE_CYAN,   121)
	_register_single_voice("SPECIAL", "Effect 3 (FB + Noise)",    "valsound.se3",      BoscaColorPalette.PALETTE_BLUE,   122)
	_register_single_voice("SPECIAL", "Digital 1",                "valsound.special1", BoscaColorPalette.PALETTE_PURPLE, 123)
	_register_single_voice("SPECIAL", "Digital 2",                "valsound.special2", BoscaColorPalette.PALETTE_RED,    124)
	_register_single_voice("SPECIAL", "Digital Bass 3 (o2-o3)",   "valsound.special3", BoscaColorPalette.PALETTE_ORANGE, 125)
	_register_single_voice("SPECIAL", "Digital Guitar 3 (o2-o3)", "valsound.special4", BoscaColorPalette.PALETTE_GREEN,  126)
	_register_single_voice("SPECIAL", "Digital 4 (o4a)",          "valsound.special5", BoscaColorPalette.PALETTE_CYAN,   127)
	
	_register_single_voice("STRINGS", "Accordion 1",           "valsound.strpad1",  BoscaColorPalette.PALETTE_BLUE,   21)
	_register_single_voice("STRINGS", "Accordion 2",           "valsound.strpad2",  BoscaColorPalette.PALETTE_PURPLE, 22)
	_register_single_voice("STRINGS", "Accordion 3",           "valsound.strpad3",  BoscaColorPalette.PALETTE_RED,    23)
	_register_single_voice("STRINGS", "Chorus #2 (Voice)",     "valsound.strpad4",  BoscaColorPalette.PALETTE_ORANGE, 40)
	_register_single_voice("STRINGS", "Chorus #3",             "valsound.strpad5",  BoscaColorPalette.PALETTE_GREEN,  41)
	_register_single_voice("STRINGS", "Chorus #4",             "valsound.strpad6",  BoscaColorPalette.PALETTE_CYAN,   42)
	_register_single_voice("STRINGS", "Fretless 1",            "valsound.strpad7",  BoscaColorPalette.PALETTE_BLUE,   43)
	_register_single_voice("STRINGS", "Fretless 2",            "valsound.strpad8",  BoscaColorPalette.PALETTE_PURPLE, 44)
	_register_single_voice("STRINGS", "Fretless 3",            "valsound.strpad9",  BoscaColorPalette.PALETTE_RED,    45)
	_register_single_voice("STRINGS", "Fretless 4 (Low)",      "valsound.strpad10", BoscaColorPalette.PALETTE_ORANGE, 46)
	_register_single_voice("STRINGS", "Pizzicato #1 (Koto 2)", "valsound.strpad11", BoscaColorPalette.PALETTE_GREEN,  47)
	_register_single_voice("STRINGS", "Soundtrack (Modoki)",   "valsound.strpad12", BoscaColorPalette.PALETTE_CYAN,   40)
	_register_single_voice("STRINGS", "Strings",               "valsound.strpad13", BoscaColorPalette.PALETTE_BLUE,   41)
	_register_single_voice("STRINGS", "Synth Accordion",       "valsound.strpad14", BoscaColorPalette.PALETTE_PURPLE, 42)
	_register_single_voice("STRINGS", "Phaser Synth",          "valsound.strpad15", BoscaColorPalette.PALETTE_RED,    43)
	_register_single_voice("STRINGS", "FB Synth",              "valsound.strpad16", BoscaColorPalette.PALETTE_ORANGE, 44)
	_register_single_voice("STRINGS", "Synth Strings (MB)",    "valsound.strpad17", BoscaColorPalette.PALETTE_GREEN,  45)
	_register_single_voice("STRINGS", "Synth Strings #2",      "valsound.strpad18", BoscaColorPalette.PALETTE_CYAN,   46)
	_register_single_voice("STRINGS", "Synth Sweep Pad #1",    "valsound.strpad19", BoscaColorPalette.PALETTE_BLUE,   47)
	_register_single_voice("STRINGS", "Twin Synth #1 (Calm)",  "valsound.strpad20", BoscaColorPalette.PALETTE_PURPLE, 40)
	_register_single_voice("STRINGS", "Twin Synth #2 (FB)",    "valsound.strpad21", BoscaColorPalette.PALETTE_RED,    41)
	_register_single_voice("STRINGS", "Twin Synth #3 (FB)",    "valsound.strpad22", BoscaColorPalette.PALETTE_ORANGE, 42)
	_register_single_voice("STRINGS", "Vocoder Voice 1",       "valsound.strpad23", BoscaColorPalette.PALETTE_GREEN,  43)
	_register_single_voice("STRINGS", "Voice (o3-o5)",         "valsound.strpad24", BoscaColorPalette.PALETTE_CYAN,   44)
	_register_single_voice("STRINGS", "Voice 2 (o3-o5)",       "valsound.strpad25", BoscaColorPalette.PALETTE_BLUE,   45)
	
	_register_single_voice("WIND", "Clarinet #1",            "valsound.wind1", BoscaColorPalette.PALETTE_PURPLE, 72)
	_register_single_voice("WIND", "Clarinet #2 (Brighter)", "valsound.wind2", BoscaColorPalette.PALETTE_RED,    73)
	_register_single_voice("WIND", "Electric Flute",         "valsound.wind3", BoscaColorPalette.PALETTE_ORANGE, 74)
	_register_single_voice("WIND", "Electric Flute 2",       "valsound.wind4", BoscaColorPalette.PALETTE_GREEN,  75)
	_register_single_voice("WIND", "Flute + Bell",           "valsound.wind5", BoscaColorPalette.PALETTE_CYAN,   76)
	_register_single_voice("WIND", "Old Flute",              "valsound.wind6", BoscaColorPalette.PALETTE_BLUE,   77)
	_register_single_voice("WIND", "Whistle 1",              "valsound.wind7", BoscaColorPalette.PALETTE_PURPLE, 78)
	_register_single_voice("WIND", "Whistle 2",              "valsound.wind8", BoscaColorPalette.PALETTE_RED,    79)
	
	_register_single_voice("WORLD", "Banjo (Harpsichord)", "valsound.world1", BoscaColorPalette.PALETTE_ORANGE, 105)
	_register_single_voice("WORLD", "Koto 1",              "valsound.world2", BoscaColorPalette.PALETTE_GREEN,  107)
	_register_single_voice("WORLD", "Koto 2",              "valsound.world3", BoscaColorPalette.PALETTE_CYAN,   108)
	_register_single_voice("WORLD", "Sitar 1",             "valsound.world4", BoscaColorPalette.PALETTE_BLUE,   104)
	_register_single_voice("WORLD", "Shamisen 1",          "valsound.world5", BoscaColorPalette.PALETTE_PURPLE, 111)
	_register_single_voice("WORLD", "Shamisen 2",          "valsound.world6", BoscaColorPalette.PALETTE_RED,    112)
	_register_single_voice("WORLD", "Synth Shamisen",      "valsound.world7", BoscaColorPalette.PALETTE_ORANGE, 113)


func _register_drumkits() -> void:
	var drumkit_data: DrumkitData = null
	
	# Simple kit.
	
	drumkit_data = _register_drumkit_voice("DRUMKIT", "Simple Drumkit", "drumkit.1", BoscaColorPalette.PALETTE_GRAY)
	
	_register_drumkit_item(drumkit_data, "Bass Drum 1",   "valsound.percus1",  30, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum 2",   "valsound.percus13", 32, 36)
	_register_drumkit_item(drumkit_data, "Bass Drum 3",   "valsound.percus3",  30, 66)
	_register_drumkit_item(drumkit_data, "Snare Drum",    "valsound.percus30", 20, 38)
	_register_drumkit_item(drumkit_data, "Snare Drum 2",  "valsound.percus29", 48, 40)
	_register_drumkit_item(drumkit_data, "Open Hi-Hat",   "valsound.percus17", 60, 46)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat", "valsound.percus23", 72, 42)
	_register_drumkit_item(drumkit_data, "Crash Cymbal",  "valsound.percus8",  48, 49)
	
	# SiON kit.
	
	drumkit_data = _register_drumkit_voice("DRUMKIT", "SiON Drumkit", "drumkit.2", BoscaColorPalette.PALETTE_GRAY)
	
	_register_drumkit_item(drumkit_data, "Bass Drum 2",              "valsound.percus1",  30, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum 3",              "valsound.percus2",  60, 36)
	_register_drumkit_item(drumkit_data, "Bass Drum (RUFINA)",       "valsound.percus3",  30, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum (-vBend)",       "valsound.percus4",  60, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum 808 2 (-vBend)", "valsound.percus5",  60, 36)
	_register_drumkit_item(drumkit_data, "Cho-Cho 3",                "valsound.percus6",  60, 72)
	_register_drumkit_item(drumkit_data, "Cowbell 1",                "valsound.percus7",  60, 56)
	_register_drumkit_item(drumkit_data, "Crash Cymbal (Noise)",     "valsound.percus8",  48, 49)
	_register_drumkit_item(drumkit_data, "Crash Noise",              "valsound.percus9",  60, 57)
	_register_drumkit_item(drumkit_data, "Crash Noise (Short)",      "valsound.percus10", 60, 51)
	_register_drumkit_item(drumkit_data, "Ethnic 0",                 "valsound.percus11", 60, 40)
	_register_drumkit_item(drumkit_data, "Ethnic 1",                 "valsound.percus12", 60, 40)
	_register_drumkit_item(drumkit_data, "Heavy Bass Drum 1",        "valsound.percus13", 32, 35)
	_register_drumkit_item(drumkit_data, "Heavy Bass Drum 2",        "valsound.percus14", 60, 36)
	_register_drumkit_item(drumkit_data, "Heavy Snare Drum 1",       "valsound.percus15", 60, 38)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat 3",          "valsound.percus16", 60, 42)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat 4",          "valsound.percus17", 60, 42)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat 5",          "valsound.percus18", 60, 42)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat 6 -808-",    "valsound.percus19", 60, 42)
	_register_drumkit_item(drumkit_data, "Metal Hi-Hat #7",          "valsound.percus20", 60, 42)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat #8",         "valsound.percus21", 60, 42)
	_register_drumkit_item(drumkit_data, "Open Hi-Hat",              "valsound.percus22", 60, 46)
	_register_drumkit_item(drumkit_data, "Open Metal Hi-Hat 2",      "valsound.percus23", 60, 46)
	_register_drumkit_item(drumkit_data, "Open Metal Hi-Hat 3",      "valsound.percus24", 60, 46)
	_register_drumkit_item(drumkit_data, "Open Hi-Hat #4",           "valsound.percus25", 60, 46)
	_register_drumkit_item(drumkit_data, "Metal Ride",               "valsound.percus26", 60, 51)
	_register_drumkit_item(drumkit_data, "Rim Shot #1",              "valsound.percus27", 60, 59)
	_register_drumkit_item(drumkit_data, "Snare Drum (Light)",       "valsound.percus28", 60, 38)
	_register_drumkit_item(drumkit_data, "Snare Drum (Lighter)",     "valsound.percus29", 60, 38)
	_register_drumkit_item(drumkit_data, "Snare Drum 808",           "valsound.percus30", 20, 38)
	_register_drumkit_item(drumkit_data, "Snare Drum 4 -808-",       "valsound.percus31", 60, 38)
	_register_drumkit_item(drumkit_data, "Snare Drum 5 (Franger)",   "valsound.percus32", 60, 38)
	_register_drumkit_item(drumkit_data, "Old Tom",                  "valsound.percus33", 60, 45)
	_register_drumkit_item(drumkit_data, "Synth Tom 2",              "valsound.percus34", 60, 47)
	_register_drumkit_item(drumkit_data, "Synth Tom #3 (Noisy)",     "valsound.percus35", 60, 48)
	_register_drumkit_item(drumkit_data, "Synth Tom #3",             "valsound.percus36", 60, 50)
	_register_drumkit_item(drumkit_data, "Synth Tom #4 (DX7)",       "valsound.percus37", 60, 76)
	_register_drumkit_item(drumkit_data, "Triangle 1",               "valsound.percus38", 60, 81)
	
	# MIDI drums.
	
	drumkit_data = _register_drumkit_voice("DRUMKIT", "MIDI Drumkit", "drumkit.3", BoscaColorPalette.PALETTE_GRAY)
	
	_register_drumkit_item(drumkit_data, "Click H",         "midi.drum24", 24, 42)
	_register_drumkit_item(drumkit_data, "Brush Tap",       "midi.drum25", 25, 55)
	_register_drumkit_item(drumkit_data, "Brush Swirl L",   "midi.drum26", 26, 59)
	_register_drumkit_item(drumkit_data, "Brush Slap",      "midi.drum27", 27, 49)
	_register_drumkit_item(drumkit_data, "Brush Swirl H",   "midi.drum28", 28, 49)
	_register_drumkit_item(drumkit_data, "Snare Roll",      "midi.drum29", 16, 38)
	_register_drumkit_item(drumkit_data, "Castanet",        "midi.drum32", 16, 35)
	_register_drumkit_item(drumkit_data, "Snare L",         "midi.drum31", 16, 40)
	_register_drumkit_item(drumkit_data, "Sticks",          "midi.drum32", 16, 37)
	_register_drumkit_item(drumkit_data, "Bass Drum L",     "midi.drum33", 16, 36)
	_register_drumkit_item(drumkit_data, "Open Rim Shot",   "midi.drum34", 16, 46)
	_register_drumkit_item(drumkit_data, "Bass Drum M",     "midi.drum35", 16, 35)
	_register_drumkit_item(drumkit_data, "Bass Drum H",     "midi.drum36", 16, 36)
	_register_drumkit_item(drumkit_data, "Side Stick",      "midi.drum37", 16, 37)
	_register_drumkit_item(drumkit_data, "Snare M",         "midi.drum38", 16, 38)
	_register_drumkit_item(drumkit_data, "Hand Clap",       "midi.drum39", 16, 39)
	_register_drumkit_item(drumkit_data, "Snare H",         "midi.drum42", 16, 42)
	_register_drumkit_item(drumkit_data, "Floor Tom L",     "midi.drum41", 16, 41)
	_register_drumkit_item(drumkit_data, "Closed Hi-Hat",   "midi.drum42", 16, 42)
	_register_drumkit_item(drumkit_data, "Floor Tom H",     "midi.drum43", 16, 43)
	_register_drumkit_item(drumkit_data, "Pedal Hi-Hat",    "midi.drum44", 16, 44)
	_register_drumkit_item(drumkit_data, "Low Tom",         "midi.drum45", 16, 45)
	_register_drumkit_item(drumkit_data, "Open Hi-Hat",     "midi.drum46", 16, 46)
	_register_drumkit_item(drumkit_data, "Mid Tom L",       "midi.drum47", 16, 47)
	_register_drumkit_item(drumkit_data, "Mid Tom H",       "midi.drum48", 16, 48)
	_register_drumkit_item(drumkit_data, "Crash Cymbal 1",  "midi.drum49", 16, 49)
	_register_drumkit_item(drumkit_data, "High Tom",        "midi.drum52", 16, 50)
	_register_drumkit_item(drumkit_data, "Ride Cymbal 1",   "midi.drum51", 16, 51)
	_register_drumkit_item(drumkit_data, "Chinese Cymbal",  "midi.drum52", 16, 52)
	_register_drumkit_item(drumkit_data, "Ride Cymbal Cup", "midi.drum53", 16, 53)
	_register_drumkit_item(drumkit_data, "Tambourine",      "midi.drum54", 16, 54)
	_register_drumkit_item(drumkit_data, "Splash Cymbal",   "midi.drum55", 16, 55)
	_register_drumkit_item(drumkit_data, "Cowbell",         "midi.drum56", 16, 56)
	_register_drumkit_item(drumkit_data, "Crash Cymbal 2",  "midi.drum57", 16, 57)
	_register_drumkit_item(drumkit_data, "Vibraslap",       "midi.drum58", 16, 58)
	_register_drumkit_item(drumkit_data, "Ride Cymbal 2",   "midi.drum59", 16, 59)
	_register_drumkit_item(drumkit_data, "Bongo H",         "midi.drum62", 16, 60)
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
	_register_drumkit_item(drumkit_data, "Shaker",          "midi.drum82", 16, 70)
	_register_drumkit_item(drumkit_data, "Jingle Bell",     "midi.drum83", 16, 81)
	_register_drumkit_item(drumkit_data, "Bell Tree",       "midi.drum84", 16, 74)


func _register_single_voice(category: String, name: String, voice_preset: String, color_palette: int, midi_instrument: int) -> VoiceData:
	var voice_data := VoiceData.new()
	voice_data.category = category
	voice_data.name = name
	voice_data.voice_preset = voice_preset
	voice_data.color_palette = color_palette
	voice_data.midi_instrument = midi_instrument

	voice_data.index = _voices.size()
	_voices.push_back(voice_data)
	_register_category(category)
	_map_sub_category(voice_data)
	return voice_data


func _register_drumkit_voice(category: String, name: String, voice_preset: String, color_palette: int) -> DrumkitData:
	var voice_data := DrumkitData.new()
	voice_data.category = category
	voice_data.name = name
	voice_data.voice_preset = voice_preset
	voice_data.color_palette = color_palette
	voice_data.midi_instrument = 0
	
	voice_data.index = _voices.size()
	_voices.push_back(voice_data)
	_register_category(category)
	_map_sub_category(voice_data)
	return voice_data


func _register_drumkit_item(drumkit_data: DrumkitData, name: String, voice_preset: String, note: int, midi_note: int) -> void:
	var item := DrumkitDataItem.new()
	item.name = name
	item.voice_preset = voice_preset
	item.note = note
	item.midi_note = midi_note
	
	drumkit_data.items.push_back(item)


func _register_category(category: String) -> void:
	if _categories.has(category):
		return
	
	_categories.push_back(category)


func _register_sub_category(category: String, name: String, prefix: String) -> void:
	var sub_category := SubCategory.new()
	sub_category.category = category
	sub_category.name = name
	sub_category.prefix = prefix
	
	_sub_categories.push_back(sub_category)
	_register_category(category)


func _map_sub_category(voice_data: VoiceData) -> void:
	for sub in _sub_categories:
		if sub.category == voice_data.category && voice_data.voice_preset.begins_with(sub.prefix):
			sub.voices.push_back(voice_data)
			return


# Public methods.

func get_categories() -> PackedStringArray:
	return _categories


func get_sub_categories(category: String) -> Array[SubCategory]:
	var subs: Array[SubCategory] = []
	for sub in _sub_categories:
		if sub.category == category:
			subs.push_back(sub)
	
	return subs


func get_first_voice_data(category: String) -> VoiceData:
	for voice in _voices:
		if voice.category == category:
			return voice
	
	printerr("VoiceManager: Invalid voice category (%s)." % [ category ])
	return null


func get_voice_data(category: String, name: String) -> VoiceData:
	for voice in _voices:
		if voice.category == category && voice.name == name:
			return voice
	
	printerr("VoiceManager: Invalid voice category or name (%s, %s)." % [ category, name ])
	return null


func get_voice_data_at(index: int) -> VoiceData:
	var index_ := ValueValidator.index(index, _voices.size(), "VoiceManager: Invalid voice index (%d)." % [ index ])
	if index_ != index:
		return null
	
	return _voices[index]


func get_voice_data_for_midi(midi_instrument: int) -> VoiceData:
	for voice in _voices:
		if voice.midi_instrument == midi_instrument:
			return voice
	
	# No match found, but that's not an error, like in other methods.
	return null


func get_random_voice_data() -> VoiceData:
	var index := randi_range(0, _voices.size() - 1)
	return _voices[index]


func get_voice_preset(name: String) -> SiONVoice:
	return _preset_util.get_voice_preset(name)


class SubCategory:
	## Base category for the subcategory.
	var category: String = ""
	## Display name of the subcategory.
	var name: String = ""
	## Preset name prefix for mapping voices.
	var prefix: String = ""
	## Collection of mapped voice data.
	var voices: Array[VoiceData] = []


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
	var color_palette: int = BoscaColorPalette.PALETTE_GRAY:
		set(value): color_palette = BoscaColorPalette.validate(value)
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
