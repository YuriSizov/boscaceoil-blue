###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends EditorExportPlugin

const WEB_ASSETS_PATH := "res://dist/web_assets"
const TARGET_SUFFIXES := [ "pck", "wasm", "side.wasm" ]

var _target_path: String = ""
var _target_gdextensions: PackedStringArray = PackedStringArray()


func _get_name() -> String:
	return "BoscaWebExportPlugin"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() == "Web"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_target_path = path
	_target_gdextensions.clear()


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if type == "GDExtension":
		_target_gdextensions.push_back(path.get_file().get_basename())


func _export_end() -> void:
	_copy_assets()
	_update_html_shell()


func _copy_assets() -> void:
	var target_dir := _target_path.get_base_dir()
	
	var fs := DirAccess.open(WEB_ASSETS_PATH)
	var asset_names := fs.get_files()
	
	for file_name in asset_names:
		if file_name == ".gdignore":
			continue
		
		var source_path := WEB_ASSETS_PATH.path_join(file_name)
		var target_path := target_dir.path_join(file_name)
		fs.copy(source_path, target_path)
		
		print("BoscaWebExportPlugin: Copying asset %s to %s" % [ file_name, target_path ])


func _update_html_shell() -> void:
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
		print("BoscaWebExportPlugin: Calculated size for %s (%d)" % [ file_name, bosca_file_sizes[file_name] ])
	
	if not _target_gdextensions.is_empty():
		var fs := DirAccess.open(target_dir)
		var files := fs.get_files()
		
		for gdextension in _target_gdextensions:
			for file_name in files:
				if file_name.begins_with(gdextension):
					var file_path := target_dir.path_join(file_name)
					var file := FileAccess.open(file_path, FileAccess.READ)
					bosca_file_sizes[file_name] = file.get_length()
					print("BoscaWebExportPlugin: Calculated size for %s (%d)" % [ file_name, bosca_file_sizes[file_name] ])
	
	# Prepare the HTML shell for editing.
	var html_file := FileAccess.open(_target_path, FileAccess.READ_WRITE)
	var html_text := html_file.get_as_text()
	
	# Replace placeholders with data.
	html_text = html_text.replace("$BOSCA_FILE_SIZES", JSON.stringify(bosca_file_sizes))
	
	# Finish.
	html_file.store_string(html_text)
