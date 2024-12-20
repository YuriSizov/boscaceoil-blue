###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
extends EditorPlugin

const BoscaWebExportPlugin := preload("res://addons/bosca_exports/BoscaWebExportPlugin.gd")

var _export_plugin_web: EditorExportPlugin = null


func _enter_tree() -> void:
	_export_plugin_web = BoscaWebExportPlugin.new()
	add_export_plugin(_export_plugin_web)


func _exit_tree() -> void:
	if is_instance_valid(_export_plugin_web):
		remove_export_plugin(_export_plugin_web)
