###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name WavExporter extends RefCounted

const FILE_EXTENSION := "wav"

enum FormatChunkSize {
	FMT_16 = 16,
	FMT_18 = 18,
	FMT_40 = 40,
}

# Note, this is for completeness; only WAVE_FORMAT_PCM is currently supported.
enum WaveFormat {
	WAVE_FORMAT_PCM = 0x0001,        # PCM
	WAVE_FORMAT_IEEE_FLOAT = 0x0003, # IEEE float
	WAVE_FORMAT_ALAW = 0x0006,       # 8-bit ITU-T G.711 A-law
	WAVE_FORMAT_MULAW = 0x0007,      # 8-bit ITU-T G.711 µ-law
	WAVE_FORMAT_EXTENSIBLE = 0xFFFE, # Determined by SubFormat
}

const INT16_MAX := 32767

var _data: PackedByteArray = PackedByteArray()
var _file: PackedByteArray = PackedByteArray()
var _file_path: String = ""

var _fmt_chunk_size: int = FormatChunkSize.FMT_16
var _wave_format: int = WaveFormat.WAVE_FORMAT_PCM
var _channel_number: int = 2
var _sampling_rate: int = 44100
var _bits_per_sample: int = 16


func get_export_path() -> String:
	return _file_path


func set_export_path(path: String) -> bool:
	if path.get_extension() != FILE_EXTENSION:
		printerr("WavExporter: The waveform audio file must have a .%s extension." % [ FILE_EXTENSION ])
		return false
	
	FileAccess.open(path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("WavExporter: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return false
	
	_file_path = path
	return true


func append_data(buffer: PackedVector2Array) -> void:
	for sample in buffer:
		var offset := _data.size()
		_data.resize(offset + 4)
		_data.encode_s16(offset,     int(sample.x * INT16_MAX))
		_data.encode_s16(offset + 2, int(sample.y * INT16_MAX))


func save() -> bool:
	if _file_path.is_empty():
		printerr("WavExporter: Export path cannot be empty.")
		return false
	
	var file := FileAccess.open(_file_path, FileAccess.WRITE)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("WavExporter: Failed to open the file at '%s' for writing (code %d)." % [ _file_path, error ])
		return false
	
	_file.clear()
	_write_wav_header()
	_write_format_chunk()
	_write_data_chunk()

	# Try to write the file with the new contents.
	
	file.big_endian = false
	file.store_buffer(_file)
	error = file.get_error()
	if error != OK:
		printerr("WavExporter: Failed to write to the file at '%s' (code %d)." % [ _file_path, error ])
		return false
	
	return true


# File format writing.

func _precalculate_size() -> int:
	var size := 0
	
	size += 4 # WAVE literal length.
	size += _fmt_chunk_size + 8 # fmt chunk length, 4 + 4 for the chunk header.
	size += _data.size() + 8 # data chunk length, 4 + 4 for the chunk header.
	
	return size


func _write_string(value: String) -> void:
	_file.append_array(value.to_utf8_buffer())


func _write_int32(value: int) -> void:
	var offset := _file.size()
	_file.resize(offset + 4)
	_file.encode_s32(offset, value)


func _write_int16(value: int) -> void:
	var offset := _file.size()
	_file.resize(offset + 2)
	_file.encode_s16(offset, value)


func _write_wav_header() -> void:
	_write_string("RIFF") # WAV is a RIFF document.
	var total_size := _precalculate_size()
	_write_int32(total_size)
	_write_string("WAVE") # Wave file description.


func _write_format_chunk() -> void:
	_write_string("fmt ")
	_write_int32(_fmt_chunk_size)
	
	# WAVE_FORMAT_PCM format is assumed here.
	_write_int16(_wave_format)
	_write_int16(_channel_number)
	_write_int32(_sampling_rate)
	@warning_ignore("integer_division")
	_write_int32((_sampling_rate * _channel_number * _bits_per_sample) / 8) # Data rate (bytes/sec).
	@warning_ignore("integer_division")
	_write_int16((_channel_number * _bits_per_sample) / 8) # Data block alignment.
	_write_int16(_bits_per_sample)


func _write_data_chunk() -> void:
	_write_string("data")
	_write_int32(_data.size())
	
	_file.append_array(_data)
	# If data size is odd, a padding byte should be added. But it cannot be odd in our case.
