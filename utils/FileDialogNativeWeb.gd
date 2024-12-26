###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# Godot doesn't support native file dialogs on web, but we can fake them with
# input elements.
# 
# This class exposes a set of properties, signals, and methods to cover the
# basic uses for loading files into the app. Internally, it creates an input
# element via JavaScriptBridge and manipulates it to create a file dialog
# when the user interacts with the page.
# 
# It is possible to move parts of this logic to the front-end with some custom
# HTML shell, but everything is simple enough for us to implement via JS proxy.
# Though that means that the code here is poorly typed.

class_name FileDialogNativeWeb extends Object

signal file_selected(path: String)
signal canceled()

var _document: JavaScriptObject = null
var _element: JavaScriptObject = null
# We must keep references around, otherwise they get silently destroyed.
# JavaScriptBridge doesn't tick the reference counter, it seems.
var _event_handlers: Array[JavaScriptObject] = []


func _init() -> void:
	if not OS.has_feature("web"):
		printerr("FileDialogNativeWeb: Called in a non-web context!")
		return
	
	_document = JavaScriptBridge.get_interface("document")
	_element = _document.createElement("input")
	_element.type = "file"
	
	_add_event_handler(_element, "change", _file_selected)
	_add_event_handler(_element, "cancel", _dialog_cancelled)
	_document.body.appendChild(_element)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_element):
			_element.remove()


func add_filter(filter: String) -> void:
	if not is_instance_valid(_element):
		return
	
	if _element.accept.is_empty():
		_element.accept = filter
	else:
		_element.accept += ", " + filter


func clear_filters() -> void:
	_element.accept = ""


func popup() -> void:
	_element.click()


# Event handlers.

# Wrapper that simplifies attaching event handlers to JavaScript objects.
func _add_event_handler(object: JavaScriptObject, event: String, callback: Callable) -> void:
	var callback_ref := JavaScriptBridge.create_callback(func(args: Array) -> void:
		callback.call(args[0]) # The event object.
	)
	_event_handlers.push_back(callback_ref)
	
	object.addEventListener(event, callback_ref)


func _file_selected(_event: JavaScriptObject) -> void:
	if _element.files.length > 0:
		# When a file is selected, we aren't done. The file must be loaded into memory
		# as a buffer. Technically, a Blob can be converted directly, but it's an
		# async method, and that's a can of worms I don't want to touch.
		# If this was JavaScript, FileReader would be more verbose, but here it's the
		# simpler option.
		
		var file_name: String = _element.files[0].name.get_file()
		var file_reader: JavaScriptObject = JavaScriptBridge.create_object("FileReader")
		_add_event_handler(file_reader, "load", _file_loaded.bind(file_name))
		file_reader.readAsArrayBuffer(_element.files[0])
		_element.value = "" # Clear the input so the same file can be loaded in the future.


func _file_loaded(event: JavaScriptObject, filename: String) -> void:
	# When the reader loads the file, we stash it into the virtual file system, so
	# we can then use our standard flow to read and load it into the app.
	
	# We don't care about conflicts, it's all temporary anyway.
	var path := "/tmp/" + filename
	
	# The result is a JS ArrayBuffer, which cannot be used directly. We construct a
	# Uint8Array, which is effectively a byte array. Then we create a proper byte array
	# out of it.
	var buffer := PackedByteArray()
	var byte_array: Variant = JavaScriptBridge.create_object("Uint8Array", event.target.result)
	for i: int in byte_array.byteLength:
		buffer.push_back(byte_array[i]) # This only works if the byte_array is untyped. Some indexing operators missing?
	
	# Create the temporary file.
	
	var file := FileWrapper.new()
	var error := file.open(path, FileAccess.WRITE)
	if error != OK:
		printerr("FileDialogNativeWeb: Failed to open the file at '%s' for writing (code %d)." % [ path, error ])
		return
	
	error = file.write_buffer_contents(buffer)
	if error != OK:
		printerr("FileDialogNativeWeb: Failed to write to the file at '%s' (code %d)." % [ path, error ])
		return
	
	file._handler.close() # Clean up to avoid issues during the next step.
	
	# Success!
	file_selected.emit(path)


func _dialog_cancelled(_event: JavaScriptObject) -> void:
	canceled.emit()
