###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name FileWrapper extends RefCounted

var _handler: FileAccess = null


func open(path: String, flags: int) -> int:
	_handler = FileAccess.open(path, flags)
	return FileAccess.get_open_error()


func write_text_contents(contents: String) -> int:
	if not is_instance_valid(_handler):
		return ERR_FILE_CANT_WRITE
	
	_handler.store_string(contents)
	return _handler.get_error()


func write_buffer_contents(contents: PackedByteArray) -> int:
	if not is_instance_valid(_handler):
		return ERR_FILE_CANT_WRITE
	
	_handler.store_buffer(contents)
	return _handler.get_error()


func finalize_write() -> int:
	# On web we must prompt the user to download the file.
	if OS.has_feature("web"):
		# FIXME: For some reason this doesn't work, the length is read correctly, but the buffer is empty. Engine bug?
		#_handler.seek(0)
		#_handler.get_buffer(_handler.get_length())
		
		# Unless we explicitly close the file or seek it to 0, the following call
		# returns an empty buffer. Another engine bug?
		_handler.close()
		
		var download_name := _handler.get_path().get_file()
		var file_buffer := FileAccess.get_file_as_bytes(_handler.get_path())
		var error := FileAccess.get_open_error()
		if error != OK:
			return error
		
		JavaScriptBridge.download_buffer(file_buffer, download_name)
	
	return OK
