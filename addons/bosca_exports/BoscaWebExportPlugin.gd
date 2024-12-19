###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends EditorExportPlugin

const TARGET_SUFFIXES := [ "pck", "wasm", "side.wasm" ]

var _target_path: String = ""
var _target_extensions: PackedStringArray = PackedStringArray()


func _get_name() -> String:
	return "BoscaWebExportPlugin"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() == "Web"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_target_path = path
	_target_extensions.clear()


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if type == "GDExtension":
		_target_extensions.push_back(path.get_file().get_basename())


func _export_end() -> void:
	# Collect extra data to pass to the HTML shell.
	var bosca_file_sizes := {}
	
	var target_dir := _target_path.get_base_dir()
	var target_name := _target_path.get_file().get_basename()
	
	# Collect file sizes, including files not accounted by Godot.
	
	for suffix in TARGET_SUFFIXES:
		var file_name := "%s.%s" % [ target_name, suffix ]
		var file_path := target_dir.path_join(file_name)
		
		var file := FileAccess.open(file_path, FileAccess.READ)
		bosca_file_sizes[file_name] = file.get_length()
	
	if not _target_extensions.is_empty():
		var fs := DirAccess.open(target_dir)
		var files := fs.get_files()
		
		for extension in _target_extensions:
			for file_name in files:
				if file_name.begins_with(extension):
					var file_path := target_dir.path_join(file_name)
					var file := FileAccess.open(file_path, FileAccess.READ)
					bosca_file_sizes[file_name] = file.get_length()
	
	# Prepare the HTML shell for editing.
	var html_file := FileAccess.open(_target_path, FileAccess.READ_WRITE)
	var html_text := html_file.get_as_text()
	
	# Replace placeholders with data.
	html_text = html_text.replace("$BOSCA_FILE_SIZES", JSON.stringify(bosca_file_sizes))
	
	# Finish.
	html_file.store_string(html_text)
